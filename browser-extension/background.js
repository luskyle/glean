/**
 * Service Worker：
 * - 右键「收藏到拾忆」→ 子菜单：选分类后收藏… / 各分类直达
 * - 菜单中的分类列表来自云端快照（桌面新增/删除分类后自动可见）
 * - 菜单树是浏览器持久化缓存：基础项幂等创建（已存在则跳过）；
 *   分类项做差异更新（onShown 时后台同步云端，绝不动正在显示的菜单）
 * - 写入 WebDAV 后 ping 桌面端 → 即时同步
 */
importScripts('snapshot.js');

// 当前已注册的分类直达项：id -> name（差异更新依据）。
// SW 每次唤醒脚本重跑，此表会清空；以 getAll() 实际状态为基准重建。
let _menuCols = new Map();

// SW 每次被唤醒（点图标/消息/启动/划词右键）都确保基础菜单存在：
// 解压扩展的「刷新」不触发 onInstalled，只有运行期执行 create 才生效。
// 运行期路径绝不 removeAll（会摧毁正在显示的菜单），只做增量补建。
ensureBaseMenus().catch(() => {});

/** 幂等补建基础菜单：已存在则跳过（Duplicate id 捕获）；顺带清理历史遗留项。 */
async function ensureBaseMenus() {
  for (const staleId of ['shiyi-save']) {
    try {
      await chrome.contextMenus.remove(staleId);
    } catch (_) {}
  }
  for (const item of [
    { id: 'shiyi-root', title: '收藏到拾忆' },
    { id: 'shiyi-with-cat', parentId: 'shiyi-root', title: '选分类后收藏…' },
    { parentId: 'shiyi-root', type: 'separator' },
  ]) {
    try {
      await chrome.contextMenus.create({ ...item, contexts: ['selection'] });
    } catch (_) {
      /* 已存在：跳过 */
    }
  }
}

/** 全新安装/升级时整树重建（此刻无菜单显示中，removeAll 安全）。 */
function rebuildMenusFromScratch() {
  chrome.contextMenus.removeAll(() => {
    _menuCols.clear();
    for (const item of [
      { id: 'shiyi-root', title: '收藏到拾忆' },
      { id: 'shiyi-with-cat', parentId: 'shiyi-root', title: '选分类后收藏…' },
      { parentId: 'shiyi-root', type: 'separator' },
    ]) {
      try {
        chrome.contextMenus.create({ ...item, contexts: ['selection'] });
      } catch (_) {}
    }
  });
}

async function _createColMenu(c) {
  try {
    await chrome.contextMenus.create({
      id: `col-${c.id}`,
      parentId: 'shiyi-root',
      title: `收藏到「${c.name}」`,
      contexts: ['selection'],
    });
    _menuCols.set(c.id, c.name);
  } catch (_) {
    /* 已存在：由下方 update 处理改名 */
  }
}

/// 运行期分类差异更新：以浏览器实际菜单状态为基准，绝不 removeAll。
/// 云端有而本地没有 → 新增；改名 → update；云端已删 → remove。
/// 拉取失败时静默保留现状。
async function syncMenuCategories() {
  // SW 唤醒后内存态丢失：先从浏览器实际菜单恢复已注册分类
  await _refreshMenuColsMap();
  const cols = await fetchCollections();
  if (cols == null) return; // 拉取失败：保留现状
  const cloud = new Map(cols.map((c) => [c.id, c.name]));

  for (const [id] of _menuCols) {
    if (!cloud.has(id)) {
      try {
        await chrome.contextMenus.remove(`col-${id}`);
      } catch (_) {}
      _menuCols.delete(id);
    }
  }
  for (const c of cols) {
    if (!_menuCols.has(c.id)) {
      await _createColMenu(c);
    } else if (_menuCols.get(c.id) !== c.name) {
      try {
        await chrome.contextMenus.update(`col-${c.id}`, {
          title: `收藏到「${c.name}」`,
        });
        _menuCols.set(c.id, c.name);
      } catch (_) {}
    }
  }
}

/** 从浏览器实际菜单恢复已注册分类（getAll 兼容回调/Promise 两种形态）。 */
function _refreshMenuColsMap() {
  return new Promise((resolve) => {
    const done = (items) => {
      _menuCols.clear();
      for (const it of items || []) {
        if (it.id && it.id.startsWith('col-') && it.title) {
          const id = parseInt(it.id.slice(4), 10);
          if (!Number.isNaN(id)) {
            _menuCols.set(id, it.title.replace(/^收藏到「|」$/g, ''));
          }
        }
      }
      resolve();
    };
    try {
      chrome.contextMenus.getAll(done);
    } catch (_) {
      done([]);
    }
  });
}

// 全新安装/升级：整树重建（无菜单显示中，removeAll 安全）；
// 其余唤醒路径只做增量补建（ensureBaseMenus）。
chrome.runtime.onInstalled.addListener(() => rebuildMenusFromScratch());
chrome.runtime.onStartup.addListener(() => rebuildMenusFromScratch());
chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg && msg.rebuildMenus) {
    syncMenuCategories().then(sendResponse);
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
    // openPopup 必须处于用户手势同步上下文：storage.set 发起后
    // 不 await（openPopup 前没有任何 await，仍同步执行）
    chrome.storage.local.set({
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