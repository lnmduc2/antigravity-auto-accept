# Antigravity Auto-Accept

**Stop Antigravity IDE from asking "Are you sure?" every time its AI agent runs a command.**
This patch clicks the confirm button for you — instantly and automatically, on your own machine.

---

## ✅ What you get

- **No more popups** — terminal commands, file access and tool calls are accepted automatically
- **A small green badge** in the bottom-right corner shows it's working — click it to pause anytime
- **Safe & reversible** — no admin rights needed, no extensions installed, one step to undo everything

---

## 🚀 Setup — let your AI agent do it (recommended)

1. **Clone this repo** and open the folder in your AI coding workspace (Claude Code, etc.)
2. **Tell the agent:** `Set up auto-accept for Antigravity`
3. When it's done, go to Antigravity and press **`Ctrl + Shift + P`** → type **`Reload Window`** → Enter

You should see **🟢 Auto-Accept: ON** in the corner. That's it — you're done.

## 🛠️ Setup — manual (Windows, ~10 seconds)

Open PowerShell in this folder and run:

```powershell
.\install.ps1
```

Then Reload Window in Antigravity (as above).

| Task | Command |
|---|---|
| Check everything is installed correctly | `.\verify.ps1` |
| Pause auto-accept temporarily | Click the green badge → `⚪ PAUSED` |
| Remove the patch, restore Antigravity to original | `.\uninstall.ps1` |

---

## 🔍 How it works (only if you're curious)

Antigravity confirms risky actions using **two layers**, and this patch answers both:

1. **Native settings** — flips Antigravity's own policy keys (`terminal / cascade / artifact review`) to `always-proceed`, so most confirmations are never generated.
2. **UI safety net** — a tiny script (`auto-accept.js`) loaded into the IDE window auto-clicks any confirmation button that still appears, in under 1 second. It **never** clicks Cancel, Skip, or Deny.

> **Why does Windows pop up so much in the first place?**
> Antigravity's terminal sandbox only exists on Linux/macOS. On Windows every command
> runs "unsandboxed", so the IDE demands a human OK for each one — this patch supplies that OK automatically.

---

## 🧯 Something broke?

- Most likely cause: a **Google update** changed the IDE's UI structure.
- Tell your agent: `The Antigravity update broke the patch, debug it` — this repo ships with a
  built-in maintenance harness (`.claude/agents` + `.claude/skills`) that knows exactly where to look
  (`out/jetskiAgent/main.js`, DOM `data-testid` selectors, CSP rules) and how to fix it.
- Or simply run `.\uninstall.ps1` then `.\install.ps1` to start fresh.

## 📌 Requirements

- **Windows** with Antigravity IDE installed (patches per-user files in `%LOCALAPPDATA%` only)
