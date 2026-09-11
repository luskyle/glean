/**
 * 选区捕获（content script）：
 * 记录最近一次非空选区 { text, html }，供右键收藏时随条目入库（html 截断 20KB）。
 * background 通过 chrome.tabs.sendMessage({ getSelection: true }) 取走并清空。
 */
(() => {
  if (window.__gleanSelectionInstalled) return;
  window.__gleanSelectionInstalled = true;

  let latest = { text: '', html: '' };

  document.addEventListener(
    'selectionchange',
    () => {
      const sel = window.getSelection();
      if (!sel || sel.isCollapsed) return;
      const text = sel.toString().trim();
      if (!text || text.length > 2000) return;
      try {
        const range = sel.getRangeAt(0);
        const div = document.createElement('div');
        div.appendChild(range.cloneContents());
        latest = { text, html: div.innerHTML.slice(0, 20000) };
      } catch (_) {
        latest = { text, html: '' };
      }
    },
    { passive: true },
  );

  chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
    if (msg && msg.getSelection) {
      sendResponse(latest);
      latest = { text: '', html: '' };
    }
  });
})();