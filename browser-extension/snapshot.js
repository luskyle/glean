/**
 * WebDAV 读写（快照契约：glean/backup.json；媒体文件库：glean/media/）。
 * 与 Glean App 的云盘同步共用同一份 JSON——插件收藏即被各端合并入库。
 * 条目上新增的字段（htmlClip/mediaType/mediaPath/coverUrl）App 旧版白名单忽略。
 */
const REMOTE_PATH = '/glean/backup.json';
const MEDIA_DIR = '/glean/media';

async function loadConfig() {
  const cfg = await chrome.storage.local.get(['davUrl', 'davUser', 'davPass']);
  return {
    url: (cfg.davUrl || '').trim(),
    user: cfg.davUser || '',
    pass: cfg.davPass || '',
  };
}

function authHeaders(cfg) {
  const token = btoa(`${cfg.user}:${cfg.pass}`);
  return { Authorization: `Basic ${token}` };
}

async function davGet(cfg) {
  const res = await fetch(cfg.url + REMOTE_PATH, { headers: authHeaders(cfg), cache: 'no-store' });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`读取云端失败（HTTP ${res.status}）`);
  return res.json();
}

/** 确保媒体目录存在（MKCOL，已存在时忽略错误）。 */
async function ensureMediaDir(cfg) {
  try {
    await fetch(cfg.url + MEDIA_DIR, { method: 'MKCOL' });
  } catch (_) {}
}

/** 上传媒体文件（二进制）到 media/，返回相对路径；失败返回 null（调用方降级引用）。 */
async function davPutBinary(cfg, blob, ext) {
  try {
    await ensureMediaDir(cfg);
    const name = `${nextId()}.${ext}`;
    const res = await fetch(cfg.url + MEDIA_DIR + '/' + name, {
      method: 'PUT',
      headers: {
        ...authHeaders(cfg),
        'Content-Type': blob.type || 'application/octet-stream',
      },
      body: blob,
    });
    if (!res.ok) return null;
    return `${MEDIA_DIR}/${name}`;
  } catch (_) {
    return null;
  }
}

async function davPut(cfg, payload) {
  // 确保父目录存在（MKCOL，已存在时忽略错误）
  try {
    await fetch(cfg.url + '/glean', { method: 'MKCOL' });
  } catch (_) {}
  const res = await fetch(cfg.url + REMOTE_PATH, {
    method: 'PUT',
    headers: { ...authHeaders(cfg), 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(`写入云端失败（HTTP ${res.status}）`);
  // 通知本机 Glean 桌面端立即同步（实时效果；未运行桌面端时静默）
  pingDesktop();
}

/** 通知桌面端 Glean 有新版数据（本地 9797 端口，秒级同步用）。 */
function pingDesktop() {
  try {
    fetch('http://127.0.0.1:9797/ping', { mode: 'no-cors' }).catch(() => {});
  } catch (_) {}
}

/** 生成不冲突的 id：负整数（避开 App 正值自增）；时间戳基 + 自增保证跨会话唯一。 */
let _seq = 0;
function nextId() {
  _seq += 1;
  return -(Date.now() * 1000 + _seq);
}

/** 简单语言判定（与 App 启发式一致：假名→ja，汉字→zh，拉丁→en）。 */
function guessLang(text) {
  if (/[\u3040-\u30ff]/.test(text)) return 'ja';
  if (/[\u3400-\u9fff]/.test(text)) return 'zh';
  if (/[a-zA-Z]/.test(text)) return 'en';
  return 'other';
}

/**
 * 追加一条收藏（进收件箱：status=inbox，与 App 收件箱对应）。
 * 返回新的快照（在传入 rows 上原地追加并返回引用）。
 * 不生成 cards/review_logs 段（Glean 无对应表，App 合并时忽略）。
 * 可选 V2 字段：htmlClip（选区 HTML）、mediaType/mediaPath（媒体）、coverUrl（封面）。
 */
function appendItem(snapshot, text, {
  url, title, note, collectionId,
  htmlClip, mediaType, mediaPath, coverUrl, source = 'browser',
} = {}) {
  const rows = snapshot.rows;
  rows.items = rows.items || [];
  rows.item_collections = rows.item_collections || [];

  const now = new Date().toISOString();
  const itemId = nextId();

  const row = {
    id: itemId,
    source,
    mediaPath: mediaPath || null,
    originalUrl: url || null,
    mediaAssetId: null,
    sourceTitle: title || null,
    note: note || null,
    lang: guessLang(text),
    status: 'inbox',
    createdAt: now,
  };
  if (htmlClip) row.htmlClip = htmlClip;
  if (mediaType) row.mediaType = mediaType;
  if (mediaPath) row.mediaType = row.mediaType || 'file';
  if (coverUrl) row.coverUrl = coverUrl;
  rows.items.push(row);

  if (collectionId) {
    rows.item_collections.push({ itemId, collectionId, isPrimary: true });
  }
  return snapshot;
}

/** 快照中的分类列表（popup 下拉用）。失败返回 null，调用方保留现状。 */
async function fetchCollections() {
  const cfg = await loadConfig();
  if (!cfg.url) return null;
  let snap;
  try {
    snap = await davGet(cfg);
  } catch (_) {
    return null;
  }
  if (!snap || !snap.rows) return null;
  return snap.rows.collections || null;
}

// 浏览器端：popup/background 通过 <script>/importScripts 共享全局作用域调用上述函数。