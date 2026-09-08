/**
 * Service Worker：
 * - 右键「收藏到拾忆」→ 子菜单：选分类后收藏… / 各分类直达
 * - 菜单中的分类列表来自云端快照（桌面新增/删除分类后自动可见）
 * - 菜单树是持久化缓存：基础项仅建一次；分类项做差异更新
 *   （onShown 在菜单即将显示时后台同步云端，绝不动正在显示的菜单）
 * - 写入 WebDAV 后 ping 桌面端 → 即时同步
 */
importScripts('snapshot.js');

// SW 每次被唤醒（点图标/消息/启动）都重建右键菜单：
// 解压扩展的「刷新」不会触发 onInstalled，只有运行期执行 create 才生效。
// 冷启动/无菜单显示中，removeAll 安全；运行期一律走差异更新（syncMenuCategories）。
rebuildMenus();

// 当前已注册的分类直达项：id -> name（差异更新依据）。
let _menuCols = new Map();

// ---- 菜单构建（仅冷启动/重装时全量；运行期用差异更新） ----

async function rebuildMenus() {
  let cols = await fetchCollections();
  if (cols == null) return; // 未配置/拉取失败：保留现有菜单
  chrome.contextMenus.removeAll(() => {
    _menuCols.clear();
    _createBaseMenus();
    for (const c of cols) _createColMenu(c);
  });
}

function _createBaseMenus() {
  chrome.contextMenus.create({
    id: 'shiyi-root',
    title: '收藏到拾忆',
    contexts: ['selection'], // 仅划词（选中文本）时显示
  });
  chrome.contextMenus.create({
    id: 'shiyi-with-cat',
    parentId: 'shiyi-root',
    title: '选分类后收藏…',
    contexts: ['selection'],
  });
  chrome.contextMenus.create({
    parentId: 'shiyi-root',
    type: 'separator',
    contexts: ['selection'],
  });
}

function _createColMenu(c) {
  chrome.contextMenus.create({
    id: `col-${c.id}`,
    parentId: 'shiyi-root',
    title: `收藏到「${c.name}」`,
    contexts: ['selection'],
  });
  _menuCols.set(c.id, c.name);
}

/// 运行期分类差异更新（不 removeAll，不碰正在显示的菜单）：
/// 云端有而本地没有 → 新增；改名 → update；云端已删 → remove。
async function syncMenuCategories() {
  const cols = await fetchCollections();
  if (cols == null) return; // 拉取失败：保留现状
  const cloud = new Map(cols.map((c) => [c.id, c.name]));

  for (const [id, name] of _menuCols) {
    if (!cloud.has(id)) {
      chrome.contextMenus.remove(`col-${id}`, () => _menuCols.delete(id));
    }
  }
  for (const c of cols) {
    if (!_menuCols.has(c.id)) {
      _createColMenu(c);
    } else if (_menuCols.get(c.id) !== c.name) {
      chrome.contextMenus.update(`col-${c.id}`, {
        title: `收藏到「${c.name}」`,
      });
      _menuCols.set(c.id, c.name);
    }
  }
}

chrome.runtime.onInstalled.addListener(() => rebuildMenus());
chrome.runtime.onStartup.addListener(() => rebuildMenus());
chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg && msg.rebuildMenus) {
    rebuildMenus().then(sendResponse);
    return true;
  }
});

// 菜单显示前同步：划词右键 → onShown 触发 → 后台差异更新分类直达项。
// 监听器本身必须同步返回（async 会让 Chrome 等 Promise 才显示菜单）；
// 这里同步触发后台任务，菜单立即显示，更新完成后 refresh() 推入新分类。
chrome.contextMenus.onShown.addListener((_info, _tab) => {
  syncMenuCategories()
    .then(() => chrome.contextMenus.refresh())
    .catch(() => {});
});

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  const text = (info.selectionText || '').trim();
  if (!text) return;

  if (info.menuItemId === 'shiyi-with-cat') {
    await chrome.storage.local.set({
      pendingText: text,
      pendingUrl: tab?.url || '',
    });
    chrome.action.openPopup();
    return;
  }
  if (typeof info.menuItemId === 'string' && info.menuItemId.startsWith('col-')) {
    const collectionId = parseInt(info.menuItemId.slice(4), 10) || null;
    const ok = await saveWith(text, tab?.url, collectionId);
    notify(ok ? '已收藏到所选分类' : '收藏失败：请先在弹窗配置 WebDAV');
  }
});

/** 收藏（带可选分类），写入云端成功后通知桌面端实时同步。 */
async function saveWith(text, url, collectionId) {
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return false;
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};
    appendCard(snap, text, '', { url, collectionId });
    await davPut(cfg, snap); // davPut 内部会 pingDesktop
    return true;
  } catch (e) {
    console.error('shiyi save failed', e);
    return false;
  }
}

function emptySnapshot() {
  return {
    app: 'shiyi',
    version: '0.1.0',
    exported_at: new Date().toISOString(),
    rows: {
      collections: [], items: [], cards: [],
      review_logs: [], item_collections: [], item_tags: [],
    },
  };
}

function notify(msg) {
  chrome.action.setBadgeText({ text: msg.startsWith('已') ? '✓' : '!' });
  chrome.action.setBadgeBackgroundColor({ color: '#2F6BFF' });
  setTimeout(() => chrome.action.setBadgeText({ text: '' }), 3000);
}