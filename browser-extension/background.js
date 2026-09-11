/**
 * Service Worker（简洁版，V2「万物皆可轻松收藏」）：
 * - 右键「收藏到 Glean」→ 子菜单：选分类后收藏… / 收藏当前网页 / 各分类直达
 * - 右键「图片收藏到 Glean」（contexts: image）：图片引用必存，原图尝试下载到媒体库
 * - 划词收藏：经 content script 取选区 HTML，随条目存 htmlClip（文本 + 快照）
 * - 整页收藏：fetch 页面抓 description / og:image 补充元数据（失败静默降级）
 * - 菜单在 SW 启动 / 扩展安装更新 / 弹窗打开时重建；分类列表来自云端快照
 * - 写入 WebDAV 后 ping 桌面端 → 即时同步
 */
importScripts('snapshot.js');

// SW 每次被唤醒（点图标/消息/启动）都重建右键菜单：
// 解压扩展的「刷新」不触发 onInstalled，只有运行期执行 create 才生效。
rebuildMenus();

chrome.runtime.onInstalled.addListener(() => rebuildMenus());
chrome.runtime.onStartup.addListener(() => rebuildMenus());
chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg && msg.rebuildMenus) {
    rebuildMenus().then(sendResponse);
    return true;
  }
});

/** 重建完整菜单（整树）：此刻菜单未在显示中，removeAll 安全。 */
async function rebuildMenus() {
  chrome.contextMenus.removeAll(() => {
    // 根菜单：划词与网页上下文都出现
    chrome.contextMenus.create({
      id: 'glean-root',
      title: '收藏到 Glean',
      contexts: ['selection', 'page'],
    });
    // 划词 → 弹窗选分类收藏（带选区文本）
    chrome.contextMenus.create({
      id: 'glean-with-cat',
      parentId: 'glean-root',
      title: '选分类后收藏…',
      contexts: ['selection'],
    });
    chrome.contextMenus.create({
      parentId: 'glean-root',
      type: 'separator',
      contexts: ['selection', 'page'],
    });
    // 图片独立入口（不挂在根菜单下：contexts 不同）
    chrome.contextMenus.create({
      id: 'glean-save-image',
      title: '图片收藏到 Glean',
      contexts: ['image'],
    });
    // 云端分类直达：划词收藏到分类 / 网页收藏到分类 两组
    (async () => {
      let cols = await fetchCollections();
      if (cols == null) cols = [];
      for (const c of cols) {
        try {
          chrome.contextMenus.create({
            id: `col-${c.id}`,
            parentId: 'glean-root',
            title: `划词收藏到「${c.name}」`,
            contexts: ['selection'],
          });
          chrome.contextMenus.create({
            id: `page-col-${c.id}`,
            parentId: 'glean-root',
            title: `网页收藏到「${c.name}」`,
            contexts: ['page'],
          });
        } catch (_) {}
      }
    })();
  });
}

/** 从内容脚本取最近选区 HTML；文本不一致时丢弃（防御旧选区）。失败返回空。 */
async function fetchSelectionHtml(tab, text) {
  if (!tab?.id) return '';
  try {
    const r = await chrome.tabs.sendMessage(tab.id, { getSelection: true });
    if (r && r.text === text && r.html) return r.html;
    return '';
  } catch (_) {
    return '';
  }
}

/** 抓取页面元数据（description / og:image）；跨域或解析失败返回 null（静默降级）。 */
async function fetchPageMeta(url) {
  try {
    const res = await fetch(url, { cache: 'no-store' });
    if (!res.ok) return null;
    const html = await res.text();
    const grab = (pattern) => {
      const m = html.match(pattern);
      return m ? m[1].slice(0, 500) : null;
    };
    const description = grab(
      /<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']/i) ||
      grab(/<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)["']/i);
    const coverUrl = grab(
      /<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i);
    if (!description && !coverUrl) return null;
    return { description, coverUrl };
  } catch (_) {
    return null;
  }
}

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  const url = tab?.url || '';
  const title = tab?.title || '';

  // ---- 图片收藏（右键图片 → 引用 + 尽力下载原图）----
  if (info.menuItemId === 'glean-save-image') {
    const imgUrl = info.srcUrl || '';
    const ok = await saveImageWith(imgUrl, url, title, null);
    notify(ok ? '已收藏图片' : '收藏失败：请先在弹窗配置 WebDAV');
    return;
  }

  // ---- 网页收藏（无划词文本；内容 = 页面标题）----
  if (typeof info.menuItemId === 'string' &&
      info.menuItemId.startsWith('page-col-')) {
    const collectionId = parseInt(info.menuItemId.slice('page-col-'.length), 10) || null;
    const ok = await savePageWith(url, title, collectionId);
    notify(ok ? '已收藏当前网页' : '收藏失败：请先在弹窗配置 WebDAV');
    return;
  }

  // ---- 划词收藏 ----
  const text = (info.selectionText || '').trim();
  if (!text) return;
  const selHtml = await fetchSelectionHtml(tab, text);

  if (info.menuItemId === 'glean-with-cat') {
    // openPopup 必须在用户手势同步上下文：storage.set 不 await
    chrome.storage.local.set({
      pendingText: text,
      pendingHtml: selHtml,
      pendingUrl: url,
      pendingTitle: title,
    });
    chrome.action.openPopup();
    return;
  }
  if (typeof info.menuItemId === 'string' && info.menuItemId.startsWith('col-')) {
    const collectionId = parseInt(info.menuItemId.slice(4), 10) || null;
    const ok = await saveWith(text, url, title, collectionId, selHtml);
    notify(ok ? '已收藏到所选分类' : '收藏失败：请先在弹窗配置 WebDAV');
  }
});

/** 收藏划词（含选区 HTML 快照），写入云端成功后通知桌面端实时同步。 */
async function saveWith(text, url, title, collectionId, htmlClip) {
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return false;
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};
    appendItem(snap, text, { url, title, collectionId, htmlClip });
    await davPut(cfg, snap); // davPut 内部会 pingDesktop
    return true;
  } catch (e) {
    console.error('glean save failed', e);
    return false;
  }
}

/** 收藏当前网页：内容 = 页面标题，附 description / og:image 元数据（尽力而为）。 */
async function savePageWith(url, title, collectionId) {
  if (!url) return false;
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return false;
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};
    const meta = await fetchPageMeta(url);
    appendItem(snap, title || url, {
      url,
      title,
      collectionId,
      note: meta?.description || null,
      coverUrl: meta?.coverUrl || null,
    });
    await davPut(cfg, snap);
    return true;
  } catch (e) {
    console.error('glean save page failed', e);
    return false;
  }
}

/**
 * 收藏图片：引用（originalUrl=图片 URL）必存；
 * 原图尝试下载到 WebDAV 媒体库（mediaPath），任何失败静默降级为纯引用。
 */
async function saveImageWith(imgUrl, pageUrl, pageTitle, collectionId) {
  if (!imgUrl || !/^https?:\/\//i.test(imgUrl)) return false;
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return false;
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};

    // 尽力下载原图（跨域/防盗链失败 → mediaPath=null，仅留引用）
    let mediaPath = null;
    try {
      const res = await fetch(imgUrl, { cache: 'no-store' });
      if (res.ok) {
        const blob = await res.blob();
        const rawExt = (blob.type.split('/')[1] || 'jpg')
          .replace(/[^a-z0-9]/gi, '').slice(0, 5);
        const ext = rawExt || 'jpg';
        mediaPath = await davPutBinary(cfg, blob, ext);
      }
    } catch (_) {
      mediaPath = null;
    }

    appendItem(snap, pageTitle || imgUrl, {
      url: imgUrl,
      title: pageTitle,
      collectionId,
      mediaType: 'image',
      mediaPath,
      source: 'image',
    });
    await davPut(cfg, snap); // davPut 内部会 pingDesktop
    return true;
  } catch (e) {
    console.error('glean image save failed', e);
    return false;
  }
}

function emptySnapshot() {
  return {
    app: 'glean',
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