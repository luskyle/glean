/**
 * Service Worker（简洁版，V1.1「万物皆可轻松收藏」）：
 * - 右键「收藏到 Glean」→ 子菜单：选分类后收藏… / 收藏当前网页 / 各分类直达
 * - 右键「图片收藏到 Glean」（contexts: image）：图片引用必存，原图尝试下载到媒体库
 * - 右键「媒体收藏到 Glean」（contexts: video/audio）：视频音频引用必存，
 *   可下载媒体直传（>50MB 自动降级引用），封面取页面 og:image
 * - 右键「链接文件收藏到 Glean」（contexts: link）：PDF/压缩包等可下载文件直传，
 *   网页型链接引导走「网页收藏」
 * - 划词收藏：经 content script 取选区 HTML，随条目存 htmlClip（文本 + 快照）
 * - 整页收藏：fetch 页面抓 description / og:image 补充元数据（失败静默降级）
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
  if (msg && msg.resolveOversize) {
    resolveOversize(msg.action).then(sendResponse);
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
    // 媒体（video/audio 元素）与链接文件
    chrome.contextMenus.create({
      id: 'glean-save-media',
      title: '媒体收藏到 Glean',
      contexts: ['video', 'audio'],
    });
    chrome.contextMenus.create({
      id: 'glean-save-file',
      title: '链接文件收藏到 Glean',
      contexts: ['link'],
    });
    // V2：整页离线归档（单文件 HTML，静态资源尽力内联）
    chrome.contextMenus.create({
      id: 'glean-offline-page',
      title: '整页离线收藏到 Glean',
      contexts: ['page'],
    });
    // V2：批量收藏页面全部图片（引用）
    chrome.contextMenus.create({
      id: 'glean-page-images',
      title: '批量收藏页面图片',
      contexts: ['page'],
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
    const r = await saveImageWith(imgUrl, url, title, null);
    if (r.pending) return; // 超过体积：弹窗询问中
    notify(r.ok ? r.msg : (r.msg || '收藏失败：请先在弹窗配置 WebDAV'), r.ok);
    return;
  }

  // ---- 媒体收藏（右键 video/audio 元素 → 引用 + 尽力直传）----
  if (info.menuItemId === 'glean-save-media') {
    const srcUrl = info.srcUrl || '';
    const mediaType = info.mediaType === 'audio' ? 'audio' : 'video';
    const r = await saveMediaWith(srcUrl, mediaType, url, title, null);
    if (r.pending) return; // 超过体积：弹窗询问中
    notify(r.ok ? r.msg : (r.msg || '收藏失败：请先在弹窗配置 WebDAV'), r.ok);
    return;
  }

  // ---- 链接文件收藏（右键链接 → 可下载文件直传，网页链接引导收藏网页）----
  if (info.menuItemId === 'glean-save-file') {
    const r = await saveFileWith(info.linkUrl || '', url, title, null);
    if (r.pending) return; // 超过体积：弹窗询问中
    notify(r.ok ? r.msg : (r.msg || '收藏失败：请先在弹窗配置 WebDAV'), r.ok);
    return;
  }

  // ---- 整页离线收藏（V2：单文件 HTML + 静态资源内联）----
  if (info.menuItemId === 'glean-offline-page') {
    const r = await savePageOffline(url, title, null);
    notify(r.ok ? r.msg : (r.msg || '收藏失败：请先在弹窗配置 WebDAV'), r.ok);
    return;
  }

  // ---- 批量收藏页面图片（V2：引用模式，一次收集 ≤30 张）----
  if (info.menuItemId === 'glean-page-images') {
    const r = await savePageImages(url, title, null, tab);
    notify(r.ok ? r.msg : (r.msg || '收藏失败：请先在弹窗配置 WebDAV'), r.ok);
    return;
  }

  // ---- 网页收藏（无划词文本；内容 = 页面标题）----
  if (typeof info.menuItemId === 'string' &&
      info.menuItemId.startsWith('page-col-')) {
    const collectionId = parseInt(info.menuItemId.slice('page-col-'.length), 10) || null;
    const ok = await savePageWith(url, title, collectionId);
    notify(ok ? '已收藏当前网页' : '收藏失败：请先在弹窗配置 WebDAV', ok);
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
    notify(ok ? '已收藏到所选分类' : '收藏失败：请先在弹窗配置 WebDAV', ok);
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
 * 返回 { ok, msg }；msg 仅在成功时有效。
 */
async function saveImageWith(imgUrl, pageUrl, pageTitle, collectionId) {
  if (!imgUrl || !/^https?:\/\//i.test(imgUrl)) return { ok: false };
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return { ok: false };
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};

    // 尽力下载原图（跨域/防盗链失败 → mediaPath=null，仅留引用）
    const dl = await downloadMedia(cfg, imgUrl, MEDIA_MAX_BYTES);
    if (dl.skipped === 'too-large') {
      // 超过体积：打开弹窗询问「收藏源文件 / 仅收藏链接」
      await askOversize('image', {
        srcUrl: imgUrl, pageUrl, pageTitle, collectionId, limitMb: 50,
      });
      return { ok: false, pending: true };
    }

    appendItem(snap, pageTitle || imgUrl, {
      url: imgUrl,
      title: pageTitle,
      collectionId,
      mediaType: 'image',
      mediaPath: dl.path,
      source: 'image',
    });
    await davPut(cfg, snap); // davPut 内部会 pingDesktop
    return {
      ok: true,
      msg: dl.path ? '已收藏图片' : '已收藏图片（原图未下载）',
    };
  } catch (e) {
    console.error('glean image save failed', e);
    return { ok: false };
  }
}

/**
 * 收藏视频/音频：引用必存，可下载媒体直传（>50MB 自动降级），封面取页面 og:image。
 */
async function saveMediaWith(srcUrl, mediaType, pageUrl, pageTitle, collectionId) {
  if (!srcUrl || !/^https?:\/\//i.test(srcUrl)) return { ok: false };
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return { ok: false };
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};

    const meta = await fetchPageMeta(pageUrl); // og:image 封面（尽力）
    const dl = await downloadMedia(cfg, srcUrl, MEDIA_MAX_BYTES);
    if (dl.skipped === 'too-large') {
      await askOversize(mediaType, {
        srcUrl, pageUrl, pageTitle, collectionId, limitMb: 50,
      });
      return { ok: false, pending: true };
    }

    appendItem(snap, pageTitle || srcUrl, {
      url: srcUrl,
      title: pageTitle,
      collectionId,
      mediaType,
      mediaPath: dl.path,
      coverUrl: meta?.coverUrl || null,
      source: mediaType === 'audio' ? 'audio' : 'video',
    });
    await davPut(cfg, snap);
    const label = mediaType === 'audio' ? '音频' : '视频';
    return {
      ok: true,
      msg: dl.path ? `已收藏${label}` : `已收藏${label}（仅引用）`,
    };
  } catch (e) {
    console.error('glean media save failed', e);
    return { ok: false };
  }
}

/**
 * 收藏链接文件（PDF/压缩包等）：可下载则直传媒体库；
 * 网页型链接引导走「网页收藏」，过大体积自动降级引用。
 */
async function saveFileWith(linkUrl, pageUrl, pageTitle, collectionId) {
  if (!linkUrl || !/^https?:\/\//i.test(linkUrl)) return { ok: false };
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return { ok: false };
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};

    const dl = await downloadMedia(cfg, linkUrl, FILE_MAX_BYTES);
    if (dl.skipped === 'not-file') {
      return { ok: false, msg: '该链接是网页，请用「网页收藏」' };
    }
    if (dl.skipped === 'too-large') {
      await askOversize('file', {
        srcUrl: linkUrl, pageUrl, pageTitle, collectionId, limitMb: 100,
      });
      return { ok: false, pending: true };
    }
    if (!dl.path) {
      return { ok: true, msg: '已收藏文件（仅引用）' };
    }

    appendItem(snap, pageTitle || linkUrl, {
      url: linkUrl,
      title: pageTitle,
      collectionId,
      mediaType: 'file',
      mediaPath: dl.path,
      source: 'file',
    });
    await davPut(cfg, snap);
    return { ok: true, msg: '已收藏文件' };
  } catch (e) {
    console.error('glean file save failed', e);
    return { ok: false };
  }
}

/** 媒体/文件下载上限（防网盘配额与 SW 内存爆掉）。 */
const MEDIA_MAX_BYTES = 50 * 1024 * 1024; // 视频/音频
const FILE_MAX_BYTES = 100 * 1024 * 1024; // 普通文件
// 用户确认「收藏源文件」后的绝对保护上限（防超大文件拖垮 SW）
const OVERSIZE_HARD_MAX = 500 * 1024 * 1024;

/**
 * 尝试下载资源到媒体库。
 * 返回 { path, skipped }：path 非空 = 已上传；skipped 为降级原因
 * （'network' 网络失败 / 'not-file' 网页型 / 'too-large' 超过上限 / null 成功）。
 */
async function downloadMedia(cfg, srcUrl, maxBytes) {
  try {
    const res = await fetch(srcUrl, { cache: 'no-store' });
    if (!res.ok) return { path: null, skipped: 'network' };
    const type = res.headers.get('content-type') || '';
    const len = Number(res.headers.get('content-length') || 0);
    if (type.startsWith('text/html')) return { path: null, skipped: 'not-file' };
    if (len > maxBytes) return { path: null, skipped: 'too-large' };
    const blob = await res.blob();
    if (blob.size > maxBytes) return { path: null, skipped: 'too-large' };
    const rawExt = (blob.type.split('/')[1] || guessExtFromUrl(srcUrl))
      .replace(/[^a-z0-9]/gi, '').slice(0, 5);
    const ext = rawExt || 'bin';
    const path = await davPutBinary(cfg, blob, ext);
    return { path, skipped: path ? null : 'network' };
  } catch (_) {
    return { path: null, skipped: 'network' };
  }
}

/** 从 URL 兜底猜扩展名。 */
function guessExtFromUrl(u) {
  try {
    const m = u.match(/\.([a-z0-9]{2,5})(?:[?#]|$)/i);
    return m ? m[1].toLowerCase() : 'bin';
  } catch (_) {
    return 'bin';
  }
}

/**
 * 超体积询问：右键流程（contextMenus.onClicked）无法弹对话框，
 * 把待确认收藏存入 storage 并打开弹窗作为确认界面。
 * 用户选择经 resolveOversize 继续执行（收藏源文件 / 仅收藏链接）。
 */
async function askOversize(kind, info) {
  await chrome.storage.local.set({ pendingOversize: { kind, ...info } });
  try {
    await chrome.action.openPopup();
  } catch (_) {}
}

/** 处理弹窗确认结果。action: 'file' 收藏源文件（突破常规阈值）| 'link' 仅收藏链接。 */
async function resolveOversize(action) {
  try {
    const st = await chrome.storage.local.get('pendingOversize');
    const p = st?.pendingOversize;
    if (!p) return { ok: false, msg: '没有待处理的收藏' };
    await chrome.storage.local.remove('pendingOversize');

    const cfg = await loadConfig();
    if (!cfg.url) return { ok: false, msg: '请先在弹窗配置 WebDAV' };
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};

    let mediaPath = null;
    if (action === 'file') {
      // 用户确认后仍保留绝对保护上限（防超大文件拖垮 SW）
      const dl = await downloadMedia(cfg, p.srcUrl, OVERSIZE_HARD_MAX);
      mediaPath = dl.path;
      if (!mediaPath && dl.skipped === 'too-large') {
        return { ok: false, msg: '文件超过 500MB，已取消上传（可仅收藏链接）' };
      }
    }

    appendItem(snap, p.pageTitle || p.srcUrl, {
      url: p.srcUrl,
      title: p.pageTitle,
      collectionId: p.collectionId,
      mediaType: p.kind,
      mediaPath,
      source: p.kind,
    });
    await davPut(cfg, snap); // davPut 内部会 pingDesktop
    return { ok: true, msg: mediaPath ? '已收藏源文件' : '已收藏（仅链接）' };
  } catch (e) {
    console.error('resolve oversize failed', e);
    return { ok: false, msg: '收藏失败' };
  }
}

/** 离线归档限额（防网盘配额与 SW 内存/生命周期爆掉）。 */
const OFFLINE_RES_MAX = 40; // 最多内联资源数
const OFFLINE_ASSET_MAX = 4 * 1024 * 1024; // 单个资源 ≤ 4MB
const OFFLINE_TOTAL_MAX = 15 * 1024 * 1024; // 总内联 ≤ 15MB
const OFFLINE_HTML_MAX = 8 * 1024 * 1024; // 页面 HTML ≤ 8MB

/**
 * 整页离线收藏：抓取页面 HTML，把 img / video poster / source 静态资源
 * 下载并以 base64 内联进单文件 HTML → 上传到媒体库（/glean/media/<id>.html）。
 * 任何失败静默降级为「网页元数据收藏」（引用兜底，收藏动作永不失败）。
 */
async function savePageOffline(url, title, collectionId) {
  if (!/^https?:\/\//i.test(url || '')) return { ok: false };
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return { ok: false };
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};

    let offlinePath = null;
    let msg = '已收藏离线页面';
    try {
      const res = await fetch(url, { cache: 'no-store' });
      if (res.ok) {
        const len = Number(res.headers.get('content-length') || 0);
        const htmlText = await res.text();
        if (htmlText.length <= OFFLINE_HTML_MAX && (len === 0 || len <= OFFLINE_HTML_MAX)) {
          const inlined = await inlinePageResources(htmlText, url);
          const blob = new Blob([inlined], { type: 'text/html' });
          offlinePath = await davPutBinary(cfg, blob, 'html');
          if (!offlinePath) {
            msg = '离线页面上传失败，已收藏链接';
          }
        } else {
          msg = '页面过大，已收藏链接';
        }
      } else {
        msg = '页面抓取失败，已收藏链接';
      }
    } catch (_) {
      msg = '页面抓取失败，已收藏链接';
    }

    const meta = await fetchPageMeta(url);
    appendItem(snap, title || url, {
      url,
      title,
      collectionId,
      note: meta?.description || null,
      coverUrl: meta?.coverUrl || null,
      mediaType: offlinePath ? 'html' : null,
      mediaPath: offlinePath,
      source: 'html',
    });
    await davPut(cfg, snap); // davPut 内部会 pingDesktop
    return { ok: true, msg };
  } catch (e) {
    console.error('glean offline save failed', e);
    return { ok: false };
  }
}

/**
 * 批量收藏页面图片（引用模式，一次 ≤30 张）：
 * content script 收集页面 img（currentSrc 优先）→ 每条一个条目，一次快照写入。
 */
async function savePageImages(pageUrl, pageTitle, collectionId, tab) {
  try {
    const cfg = await loadConfig();
    if (!cfg.url) return { ok: false };
    const urls = await collectPageImages(tab);
    if (!urls || urls.length === 0) {
      return { ok: false, msg: '页面上没有发现图片' };
    }
    const snap = (await davGet(cfg)) || emptySnapshot();
    if (!snap.rows) snap.rows = {};
    for (const u of urls) {
      appendItem(snap, pageTitle || u, {
        url: u,
        title: pageTitle,
        collectionId,
        mediaType: 'image',
        source: 'image',
      });
    }
    await davPut(cfg, snap); // davPut 内部会 pingDesktop
    return { ok: true, msg: `已收藏 ${urls.length} 张图片（引用）` };
  } catch (e) {
    console.error('glean page images failed', e);
    return { ok: false };
  }
}

/** 从内容脚本收集页面图片 URL（失败返回空数组）。 */
async function collectPageImages(tab) {
  if (!tab?.id) return [];
  try {
    return (await chrome.tabs.sendMessage(tab.id, { getImages: true })) || [];
  } catch (_) {
    return [];
  }
}

/**
 * 把页面 HTML 中的静态资源（img / video poster / source）下载并以
 * data URI 内联。stylesheets/scripts 保留原引用（离线打开时静默降级）。
 */
async function inlinePageResources(html, baseUrl) {
  let used = 0;
  let count = 0;
  const cache = new Map(); // 绝对 URL -> data URI

  const toAbsolute = (u) => {
    try {
      return new URL(u, baseUrl).href;
    } catch (_) {
      return null;
    }
  };

  // 收集候选资源（去重）
  const needs = new Set();
  const collect = (re, group) => {
    let m;
    while ((m = re.exec(html)) !== null) {
      const abs = toAbsolute(m[group]);
      if (abs && /^https:/i.test(abs)) needs.add(abs);
    }
  };
  collect(/<img\s[^>]*?src=["']([^"']+)["']/gi, 1);
  collect(/<video[^>]*?poster=["']([^"']+)["']/gi, 1);
  collect(/<source[^>]*?src=["']([^"']+)["']/gi, 1);

  // 逐个下载内联（限额内尽力而为）
  for (const abs of needs) {
    if (count >= OFFLINE_RES_MAX || used >= OFFLINE_TOTAL_MAX) break;
    try {
      const res = await fetch(abs, { cache: 'no-store' });
      if (!res.ok) continue;
      const len = Number(res.headers.get('content-length') || 0);
      if (len > OFFLINE_ASSET_MAX) continue;
      const blob = await res.blob();
      if (blob.size > OFFLINE_ASSET_MAX) continue;
      if (used + blob.size > OFFLINE_TOTAL_MAX) continue;
      const b64 = await blobToBase64(blob);
      used += blob.size;
      count += 1;
      cache.set(abs, `data:${blob.type || 'application/octet-stream'};base64,${b64}`);
    } catch (_) {}
  }

  // 同步替换（cache 内命中才替换，失败资源保留原引用降级）
  html = html.replace(
    /(<img\s[^>]*?src=["'])([^"']+)(["'][^>]*?>)/gi,
    (m, pre, src, post) => {
      const abs = toAbsolute(src);
      const d = abs ? cache.get(abs) : null;
      return d ? `${pre}${d}${post}` : m;
    },
  );
  html = html.replace(
    /(<video[^>]*?poster=["'])([^"']+)(["'][^>]*?>)/gi,
    (m, pre, poster, post) => {
      const abs = toAbsolute(poster);
      const d = abs ? cache.get(abs) : null;
      return d ? `${pre}${d}${post}` : m;
    },
  );
  html = html.replace(
    /(<source[^>]*?src=["'])([^"']+)(["'][^>]*?\/?>)/gi,
    (m, pre, src, post) => {
      const abs = toAbsolute(src);
      const d = abs ? cache.get(abs) : null;
      return d ? `${pre}${d}${post}` : m;
    },
  );
  return html;
}

/** blob 转 base64（SW 环境：arrayBuffer + btoa，不依赖 FileReader）。 */
async function blobToBase64(blob) {
  const buf = await blob.arrayBuffer();
  const bytes = new Uint8Array(buf);
  let bin = '';
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin);
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

function notify(msg, ok = true) {
  chrome.action.setBadgeText({ text: ok ? '✓' : '!' });
  chrome.action.setBadgeBackgroundColor({ color: '#2F6BFF' });
  setTimeout(() => chrome.action.setBadgeText({ text: '' }), 3000);
}