/**
 * Service Worker：
 * - 「收藏到拾忆」：右键划词 → 立即可入库（默认未分类，明天复习）
 * - 「收藏到拾忆（选分类…）」：打开弹窗选分类后再写
 * 需要先在弹窗「设置」里配置 WebDAV（如坚果云 dav.jianguoyun.com/dav/）。
 */
importScripts('snapshot.js');

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'shiyi-save-selection',
    title: '收藏到拾忆',
    contexts: ['selection'],
  });
  chrome.contextMenus.create({
    id: 'shiyi-save-with-cat',
    title: '收藏到拾忆（选分类…）',
    contexts: ['selection'],
  });
});

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === 'shiyi-save-with-cat') {
    // 缓存选区 → 打开弹窗让用户选分类
    await chrome.storage.local.set({
      pendingText: (info.selectionText || '').trim(),
      pendingUrl: tab?.url || '',
    });
    chrome.action.openPopup();
    return;
  }
  if (info.menuItemId !== 'shiyi-save-selection') return;
  const text = (info.selectionText || '').trim();
  if (!text) return;

  const ok = await saveSelection(text, tab?.url);
  notify(ok ? '已收藏到拾忆 · 明天开始复习' : '收藏失败：请先在弹窗里配置 WebDAV');
});

async function saveSelection(text, url) {
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return false;
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};
    appendInbox(snap, text, { url });
    await davPut(cfg, snap);
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