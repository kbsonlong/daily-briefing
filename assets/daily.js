/* ═══════════════════════════════════════
   daily.js — Client-side markdown renderer
   Fetches report.md, splits by ## headings into tabs
   ═══════════════════════════════════════ */
(async function () {
  'use strict';

  const WEEKDAYS = ['日', '一', '二', '三', '四', '五', '六'];

  // ── Detect current date from URL path ──
  const match = location.pathname.match(/daily\/(\d{4}-\d{2}-\d{2})/);
  const currentDate = match ? match[1] : null;

  if (!currentDate) {
    document.getElementById('content').innerHTML =
      '<p class="error-msg">无效的日期路径</p>';
    return;
  }

  // ── Set page metadata ──
  document.title = `每日科技简报 · ${currentDate}`;
  const dateEl = document.getElementById('current-date');
  if (dateEl) dateEl.textContent = fmtDate(currentDate);

  // ── Load dates list for prev/next nav ──
  let dates = [];
  try {
    const r = await fetch(resolve('../../dates.json'));
    if (r.ok) dates = await r.json();
  } catch (e) { /* nav disabled */ }
  setupNav(currentDate, dates);

  // ── Configure marked ──
  marked.setOptions({ gfm: true, breaks: true });

  // ── Load & render report ──
  try {
    const r = await fetch('./report.md');
    if (!r.ok) throw new Error(r.status);
    const md = await r.text();
    render(md);
  } catch (e) {
    document.getElementById('content').innerHTML =
      `<p class="error-msg">加载报告失败 (${e.message})</p>`;
  }

  // ──────────────────── helpers ────────────────────

  function fmtDate(s) {
    const d = new Date(s + 'T00:00:00');
    return `${s}  星期${WEEKDAYS[d.getDay()]}`;
  }

  /** resolve path relative to current page */
  function resolve(rel) {
    const base = location.pathname.replace(/[^/]*$/, '');
    const url = new URL(rel, location.origin + base);
    return url.pathname;
  }

  function setupNav(cur, list) {
    const idx = list.indexOf(cur);
    const prev = document.getElementById('prev-day');
    const next = document.getElementById('next-day');
    if (!prev || !next) return;

    if (idx > 0) {
      prev.onclick = () => (location.href = `../${list[idx - 1]}/`);
    } else {
      prev.classList.add('disabled');
      prev.disabled = true;
    }

    if (idx >= 0 && idx < list.length - 1) {
      next.onclick = () => (location.href = `../${list[idx + 1]}/`);
    } else {
      next.classList.add('disabled');
      next.disabled = true;
    }
  }

  // ──────────────────── render ────────────────────

  function render(md) {
    const sections = splitSections(md);
    const tabsEl = document.getElementById('tabs');
    const contentEl = document.getElementById('content');

    // Build tab buttons
    const allTab = mkTab('📋 总览', 0);
    tabsEl.appendChild(allTab);

    sections.forEach((sec, i) => {
      tabsEl.appendChild(mkTab(sec.icon + ' ' + sec.label, i + 1));
    });

    // State
    let active = 0;
    const fullHtml = marked.parse(md);
    const sectionHtmls = sections.map((s) => marked.parse(s.raw));

    function show(idx) {
      active = idx;
      document.querySelectorAll('.tab').forEach((t) => t.classList.remove('active'));
      document.querySelector(`.tab[data-i="${idx}"]`).classList.add('active');
      contentEl.innerHTML =
        '<div class="md">' + (idx === 0 ? fullHtml : sectionHtmls[idx - 1]) + '</div>';
      contentEl.scrollTop = 0;
      window.scrollTo(0, 0);
    }

    show(0);

    // Expose switcher
    window._switchTab = show;
  }

  function mkTab(text, idx) {
    const btn = document.createElement('button');
    btn.className = 'tab' + (idx === 0 ? ' active' : '');
    btn.textContent = text;
    btn.dataset.i = idx;
    btn.onclick = () => window._switchTab(idx);
    return btn;
  }

  function splitSections(md) {
    const lines = md.split('\n');
    const sections = [];
    let cur = null;

    for (const line of lines) {
      if (/^## [^#]/.test(line)) {
        if (cur) sections.push(cur);
        const title = line.replace(/^## +/, '').trim();
        const label = title.replace(/\p{Emoji_Presentation}|\p{Emoji}\uFE0F/gu, '').replace(/\s+/g, ' ').trim();
        const emoji = title.match(/\p{Emoji_Presentation}|\p{Emoji}\uFE0F/gu);
        cur = { title, label, icon: emoji ? emoji[0] : '📄', raw: line };
      } else if (cur) {
        cur.raw += '\n' + line;
      }
    }
    if (cur) sections.push(cur);
    return sections;
  }
})();
