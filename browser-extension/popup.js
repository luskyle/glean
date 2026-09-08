/**
 * 弹窗逻辑：右键划选后打开，文本自动带入；可选分类；写云端。
 * 正文字段在 popup.html 中；snapshot.js 提供 WebDAV/快照工具。
 */
const $ = (id) => document.getElementById(id);

let lastCollections = [];

async function refreshCollections() {
  lastCollections = await fetchCollections();
  const sel = $('collection');
  sel.innerHTML = '';
  const opt = document.createElement('option');
  opt.value = '';
  opt.textContent = '未分类';
  sel.appendChild(opt);
  for (const c of lastCollections) {
    const o = document.createElement('option');
    o.value = c.id;
    o.textContent = c.name;
    sel.appendChild(o);
  }
  // 同步重建右键分类子菜单（桌面新增/删除分类后立即可见）
  chrome.runtime.sendMessage({ rebuildMenus: true }).catch(() => {});
}

async function loadSettings() {
  const cfg = await loadConfig();
  $('davUrl').value = cfg.url || '';
  $('davUser').value = cfg.user || '';
  $('davPass').value = cfg.pass || '';
}

async function saveSettings() {
  await chrome.storage.local.set({
    davUrl: $('davUrl').value.trim(),
    davUser: $('davUser').value.trim(),
    davPass: $('davPass').value,
  });
  setMsg('设置已保存', true);
  await refreshCollections();
}

async function saveSelection() {
  const text = $('text').value.trim();
  if (!text) { setMsg('先输入要收藏的内容', false); return; }
  const cfg = await loadConfig();
  if (!cfg.url) { setMsg('请先配置 WebDAV', false); $('settingsBox').open = true; return; }
  try {
    const snap = (await davGet(cfg)) || {
      app: 'shiyi', version: '0.1.0', exported_at: new Date().toISOString(),
      rows: { collections: lastCollections, items: [], cards: [],
              review_logs: [], item_collections: [], item_tags: [] },
    };
    if (!snap.rows) snap.rows = {};
    if (!snap.rows.collections || !snap.rows.collections.length) {
      snap.rows.collections = lastCollections;
    }
    const collectionId = parseInt($('collection').value, 10) || null;
    // 已成卡直接进复习队列
    appendCard(snap, text, '', { url: $('pageUrl').value || null, collectionId });
    await davPut(cfg, snap);
    setMsg('已收藏，明天开始复习 ✓', true);
    $('text').value = '';
  } catch (e) {
    setMsg('收藏失败：' + e.message, false);
  }
}

function setMsg(t, ok) {
  const m = $('msg');
  m.textContent = t;
  m.className = 'msg ' + (ok ? 'ok' : 'err');
  setTimeout(() => { m.textContent = ''; m.className = 'msg'; }, 4000);
}

// 划选文本带入：background 收到右键收藏前先把选区存起来
chrome.storage.local.get(['pendingText', 'pendingUrl'], (r) => {
  if (r.pendingText) {
    $('text').value = r.pendingText;
    $('pageUrl').value = r.pendingUrl || '';
    chrome.storage.local.remove(['pendingText', 'pendingUrl']);
  }
});

document.getElementById('btnSave').addEventListener('click', saveSelection);
document.getElementById('btnSaveCfg').addEventListener('click', saveSettings);
document.getElementById('btnSettings').addEventListener('click', () => {
  $('settingsBox').open = !$('settingsBox').open;
});

(async () => {
  await loadSettings();
  await refreshCollections();
})();