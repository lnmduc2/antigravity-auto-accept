---
name: bundle-analysis
description: "Guide for extracting and analyzing AST, selectors and tokens from the minified Antigravity IDE bundles (jetskiAgent, workbench). Use when Antigravity updates to a new version or popup data-testid attributes change."
---

# Bundle Analysis Guide

Technical reference for locating UI components inside the installed Antigravity IDE.

## Key file locations (under `%LOCALAPPDATA%\Programs\Antigravity IDE\resources\app\`)
- **Main window HTML:** `out/vs/code/electron-browser/workbench/workbench.html`
  (loads `workbench.js` → `out/vs/workbench/workbench.desktop.main.js`) — **this is the document
  that actually renders the agent chat UI.**
- **Secondary agent page HTML:** `out/vs/code/electron-browser/workbench/workbench-jetski-agent.html`
- **Real React bundle:** `out/jetskiAgent/main.js` (~14 MB minified).
  ⚠️ `jetskiAgent.js` in the workbench folder is a Microsoft bootstrap stub (~28 KB) — searching it
  for UI strings gives false negatives.
- **Settings store:** `%APPDATA%\Antigravity IDE\User\settings.json` +
  `User\globalStorage\state.vscdb` (SQLite).

## Tracing selectors
1. Search the string `interaction-continue-button` in `out/jetskiAgent/main.js` and
   `out/vs/workbench/workbench.desktop.main.js`.
2. Inspect the parent component (historically `oVt`) and the permission choice arrays
   (`ye(..., Hd.GLOBAL)`), enums (`zi`, `Tr`, `Fh`).
3. If Google renamed a `data-testid`, update the primary selector **and** the label-fallback list
   in `auto-accept.js`, then re-run `install.ps1`.

## CSP constraints when injecting
- `script-src 'self' 'unsafe-eval' blob:` → an external `.js` file placed beside the HTML loads fine.
- `require-trusted-types-for 'script'` → HTML-string sinks throw TypeError; DOM API only.
- `trusted-types` policy names are an explicit allowlist → you cannot register your own policy
  without editing the CSP meta tag (not recommended; prefer avoiding sinks entirely).
