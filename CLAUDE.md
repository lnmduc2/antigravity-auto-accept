# Antigravity Auto-Accept — Project Instructions

## Harness: Antigravity Tool-Call Auto-Accept Engine

**Goal:** Eliminate all confirmation popups in the local Antigravity IDE chat during tool
calls — 100% hands-free auto-accept, fully reversible.

**Invocation Condition:** When the user asks to set up, verify, maintain, debug (e.g. after an
Antigravity update), or remove the auto-accept patch, activate the `auto-accept-orchestrator`
skill.

**Team Architecture:** Supervisor–Specialist Pool
- `reverse-engineer` — decompiles the `jetskiAgent` bundle, extracts DOM selectors and IPC logic.
- `policy-architect` — designs the `always-proceed` native policy and edits config files.
- `dom-injector` — owns `auto-accept.js` and the Floating Badge UI.
- `qa-verifier` — runs `verify.ps1` and end-to-end integrity/latency tests.

**Non-negotiable engineering constraints (learned the hard way):**
1. The **main IDE window loads `workbench.html`** — not `workbench-jetski-agent.html`. Inject into **both**.
2. The workbench CSP enforces `require-trusted-types-for 'script'` — **never** use `innerHTML`
   or any HTML-string sink in injected code; build UI with `createElement`/`textContent` only.
3. `jetskiAgent.js` in the workbench folder is a Microsoft bootstrap stub; the **real bundle**
   (where selectors live) is `out/jetskiAgent/main.js`. Verify selectors there.
4. Always keep `.bak` backups of every patched HTML; `uninstall.ps1` must restore original state.

**Change History:**

| Date | Change Summary | Target | Reason |
| --- | --- | --- | --- |
| 2026-10-30 | Harness v2 initialized (`.claude/agents`, `.claude/skills`, CLAUDE.md), Vietnamese project `fix-antigravity` | Whole project | Meet harness structural standards |
| 2026-10-30 | Patch v3: rewrote injector to be Trusted-Types safe (no `innerHTML`); inject into **both** `workbench.html` (the real chat window) and `workbench-jetski-agent.html`; install/test/uninstall scripts upgraded to multi-target | `auto-confirm.js`, `install.ps1`, `test-popup.ps1`, `uninstall.ps1` | v2 badge never appeared and popups persisted: script died on a CSP Trusted-Types violation and was injected into the wrong document |
| 2026-10-30 | v4: repackaged as public GitHub repo `antigravity-auto-accept` — full English translation, renamed `auto-accept.js` / `verify.ps1`, removed redundant docs (`HARNESS_SPEC.md`, `patch-lifecycle` skill), added LICENSE + .gitignore + migration logic in installer | Whole project | Ship a clone-and-go, agent-friendly open-source release |
