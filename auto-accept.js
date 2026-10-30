/**
 * Antigravity Auto-Accept Injector (Trusted-Types safe)
 *
 * Automatically detects and accepts tool-call / command confirmation popups
 * inside the Antigravity IDE agent chat.
 *
 * IMPORTANT constraints baked into this file:
 * - The workbench CSP enforces `require-trusted-types-for 'script'`, so assigning
 *   HTML strings to innerHTML throws a TypeError and would kill the script at
 *   bootstrap. All UI is therefore built with createElement/textContent only.
 * - This file is loaded via <script src="./auto-accept.js"> from BOTH
 *   workbench.html (main window - the one that actually renders the chat)
 *   and workbench-jetski-agent.html.
 */
(function () {
  'use strict';

  if (window.__antigravityAutoAcceptInstalled) {
    console.log('[Antigravity Auto-Accept] Already initialized.');
    return;
  }
  window.__antigravityAutoAcceptInstalled = true;

  var isEnabled = true;
  var clickHistory = new Map();
  var CLICK_COOLDOWN_MS = 500;
  var MAX_RETRY_PER_ELEMENT = 3;

  console.log('[Antigravity Auto-Accept] Initialized (Trusted-Types safe mode).');

  // ---- Status badge (pure DOM construction, zero HTML-string sinks) ----
  var DOT_STYLE_ON = 'width:7px;height:7px;border-radius:50%;background:#10b981;box-shadow:0 0 6px #10b981;';
  var DOT_STYLE_OFF = 'width:7px;height:7px;border-radius:50%;background:#94a3b8;box-shadow:none;';

  var badgeEl = null;
  var badgeDot = null;
  var badgeLabel = null;

  function setBadgeState(on) {
    if (!badgeEl) return;
    if (on) {
      badgeEl.style.color = '#10b981';
      badgeEl.style.borderColor = 'rgba(16, 185, 129, 0.4)';
      badgeDot.style.cssText = DOT_STYLE_ON;
      badgeLabel.nodeValue = ' Auto-Accept: ON';
    } else {
      badgeEl.style.color = '#94a3b8';
      badgeEl.style.borderColor = 'rgba(148, 163, 184, 0.3)';
      badgeDot.style.cssText = DOT_STYLE_OFF;
      badgeLabel.nodeValue = ' Auto-Accept: PAUSED';
    }
  }

  function createBadge() {
    if (document.getElementById('antigravity-auto-accept-badge')) return;

    badgeEl = document.createElement('div');
    badgeEl.id = 'antigravity-auto-accept-badge';
    badgeEl.style.cssText = [
      'position:fixed', 'bottom:12px', 'right:16px', 'z-index:999999',
      'background:rgba(18, 24, 38, 0.9)', 'backdrop-filter:blur(8px)',
      'border:1px solid rgba(16, 185, 129, 0.4)', 'border-radius:20px',
      'padding:4px 12px',
      "font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif",
      'font-size:11px', 'font-weight:500', 'color:#10b981',
      'display:flex', 'align-items:center', 'gap:6px',
      'cursor:pointer', 'user-select:none',
      'box-shadow:0 4px 12px rgba(0, 0, 0, 0.3)', 'transition:all 0.2s ease'
    ].join(';');
    badgeEl.title = 'Click to toggle Auto-Accept ON/OFF';

    badgeDot = document.createElement('span');
    badgeDot.style.cssText = DOT_STYLE_ON;
    badgeLabel = document.createTextNode(' Auto-Accept: ON');

    badgeEl.appendChild(badgeDot);
    badgeEl.appendChild(badgeLabel);

    badgeEl.addEventListener('click', function () {
      isEnabled = !isEnabled;
      setBadgeState(isEnabled);
      console.log('[Antigravity Auto-Accept] Toggled ' + (isEnabled ? 'ON' : 'PAUSED'));
    });

    document.body.appendChild(badgeEl);
  }

  // ---- Auto-click engine ----
  function canClick(el) {
    if (!el || el.disabled || el.getAttribute('aria-disabled') === 'true') return false;
    var now = Date.now();
    var stats = clickHistory.get(el) || { count: 0, lastTime: 0 };
    if (now - stats.lastTime < CLICK_COOLDOWN_MS) return false;
    if (stats.count >= MAX_RETRY_PER_ELEMENT) return false;
    return true;
  }

  function recordClick(el) {
    var stats = clickHistory.get(el) || { count: 0, lastTime: 0 };
    clickHistory.set(el, { count: stats.count + 1, lastTime: Date.now() });
  }

  function attemptAutoAccept() {
    if (!isEnabled) return;

    // 1. Primary target: Antigravity's official interaction Continue button.
    var continueBtn = document.querySelector('button[data-testid="interaction-continue-button"]');
    if (continueBtn && canClick(continueBtn)) {
      recordClick(continueBtn);
      console.log('[Antigravity Auto-Accept] Auto-accepted tool call: ' +
        (continueBtn.textContent || '').replace(/\s+/g, ' ').trim());
      continueBtn.click();
      return;
    }

    // 2. Fallback: any modal button labelled as an acceptance action.
    var buttons = document.querySelectorAll('button');
    for (var i = 0; i < buttons.length; i++) {
      var btn = buttons[i];
      if (!canClick(btn)) continue;

      var testId = btn.getAttribute('data-testid') || '';
      if (testId === 'interaction-skip-button') continue; // Never click Skip.

      var text = (btn.textContent || '').toLowerCase().trim();

      // Hard guard: never deny-side buttons.
      if (text.indexOf('cancel') !== -1 || text.indexOf('reject') !== -1 ||
          text.indexOf('skip') !== -1 || text.indexOf('deny') !== -1 || text === 'no') {
        continue;
      }

      // Match Antigravity's canonical acceptance labels.
      if (
        text.indexOf('yes, allow') === 0 ||
        text.indexOf('yes, and always') === 0 ||
        text === 'submit' ||
        text === 'continue' ||
        text === 'allow' ||
        text === 'always allow' ||
        text === 'run' ||
        text === 'execute' ||
        text === 'approve' ||
        testId.indexOf('confirm') !== -1 ||
        testId.indexOf('accept') !== -1
      ) {
        recordClick(btn);
        console.log('[Antigravity Auto-Accept] Clicked acceptance button: "' +
          (btn.textContent || '').trim() + '"');
        btn.click();
        return;
      }
    }
  }

  // Prune stale click-history entries every 4 seconds.
  setInterval(function () {
    var now = Date.now();
    clickHistory.forEach(function (stats, el) {
      if (!document.body || !document.body.contains(el) || now - stats.lastTime > 5000) {
        clickHistory.delete(el);
      }
    });
  }, 4000);

  // ---- Bootstrap (a broken badge must never kill the engine) ----
  function init() {
    try {
      createBadge();
    } catch (err) {
      console.warn('[Antigravity Auto-Accept] Badge creation failed (engine still running):', err);
    }
    var observer = new MutationObserver(function () {
      attemptAutoAccept();
    });
    observer.observe(document.body, { childList: true, subtree: true });
    setInterval(attemptAutoAccept, 300);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
