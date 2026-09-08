/**
 * Service Worker：
 * - 右键「收藏到拾忆」→ 子菜单：选分类后收藏… / 各分类直达
 * - 菜单中的分类列表来自云端快照（桌面新增分类后自动可见）
 *   （menu 在 SW 启动时与弹窗刷新时重建）
 * - 写入 WebDAV 后 ping 桌面端 → 即时同步
 */
importScripts('snapshot.js');

// SW 每次被唤醒（点图标/消息/启动）都重建右键菜单：
// 解压扩展的「刷新」不会触发 onInstalled，只有运行期执行 create 才生效。
rebuildMenus();

chrome.runtime.onInstalled.addListener(() => rebuildMenus());
chrome.runtime.onStartup.addListener(() => rebuildMenus());
chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg && msg.rebuildMenus) {
    rebuildMenus().then(sendResponse);
    return true;
  }
});

async function rebuildMenus() {
  chrome.contextMenus.removeAll(() => {
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
    // 云端分类直达（异步拉取后追加；失败则只有上面一项）
    (async () => {
      const cols = await fetchCollections();
      for (const c of cols) {
        chrome.contextMenus.create({
          id: `col-${c.id}`,
          parentId: 'shiyi-root',
          title: `收藏到「${c.name}」`,
          contexts: ['selection'],
        });
      }
    })();
  });
}

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