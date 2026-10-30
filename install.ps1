# install.ps1
# One-click installer for Antigravity Auto-Accept (Windows)
# Injects auto-accept.js into BOTH workbench HTML documents and applies
# the native always-proceed policy. Idempotent and safe to re-run after an
# Antigravity update. Also migrates old "auto-confirm.js" patches.
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     Antigravity Auto-Accept Installer                    " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

$workbenchDir = "$env:LOCALAPPDATA\Programs\Antigravity IDE\resources\app\out\vs\code\electron-browser\workbench"
$targets = @(
    (Join-Path $workbenchDir "workbench.html"),               # Main window (renders the agent chat)
    (Join-Path $workbenchDir "workbench-jetski-agent.html")   # Secondary jetski agent page
)
$scriptSource = Join-Path $PSScriptRoot "auto-accept.js"
$scriptDest   = Join-Path $workbenchDir "auto-accept.js"

if (-not (Test-Path $workbenchDir)) {
    Write-Error "Antigravity IDE not found at: $workbenchDir"
    exit 1
}

# [1/4] Deploy the injector script
Write-Host "[1/4] Copying auto-accept.js into the workbench folder..." -ForegroundColor Green
Copy-Item -Path $scriptSource -Destination $scriptDest -Force

# [2/4] Migrate away any legacy auto-confirm.js patch (old name)
$legacyDest = Join-Path $workbenchDir "auto-confirm.js"
$htmlAll = @()
foreach ($targetHtml in $targets) {
    if (Test-Path $targetHtml) { $htmlAll += ,@($targetHtml, (Get-Content -Path $targetHtml -Raw)) }
}
if ((Test-Path $legacyDest) -or ($htmlAll | Where-Object { $_[1] -match "auto-confirm\.js" })) {
    Write-Host "[2/4] Migrating legacy 'auto-confirm' patch to 'auto-accept'..." -ForegroundColor Green
    if (Test-Path $legacyDest) { Remove-Item -Path $legacyDest -Force }
} else {
    Write-Host "[2/4] No legacy patch to migrate." -ForegroundColor Gray
}

# [3/4] Inject the script tag into every target HTML
Write-Host "[3/4] Injecting script tag into workbench HTML documents..." -ForegroundColor Green
foreach ($pair in $htmlAll) {
    $targetHtml = $pair[0]
    $name = Split-Path $targetHtml -Leaf

    # Backup untouched original once, before the first modification.
    $backupHtml = "$targetHtml.bak"
    if (-not (Test-Path $backupHtml)) {
        Copy-Item -Path $targetHtml -Destination $backupHtml -Force
        Write-Host "      -> Created backup: $name.bak" -ForegroundColor Gray
    }

    $htmlContent = $pair[1]

    # Replace legacy tag if present.
    $legacyTagPattern = '<!-- Antigravity Auto-Confirm Injector -->\s*<script src="\./auto-confirm\.js"></script>'
    $newTagText = "<!-- Antigravity Auto-Accept Injector -->`n" + '<script src="./auto-accept.js"></script>'
    $htmlContent = $htmlContent -replace $legacyTagPattern, $newTagText

    if ($htmlContent -notmatch "auto-accept\.js") {
        $htmlContent = $htmlContent -replace "(</body>)", "`n<!-- Antigravity Auto-Accept Injector -->`n<script src=`"./auto-accept.js`"></script>`n`$1"
        Write-Host "      -> [OK] Injected into $name" -ForegroundColor Green
    } elseif ($htmlContent -notmatch "auto-confirm\.js") {
        Write-Host "      -> [OK] $name already up to date." -ForegroundColor Gray
    }
    Set-Content -Path $targetHtml -Value $htmlContent -Encoding UTF8
}

# [4/4] Native policy: always-proceed keys in user settings
Write-Host "[4/4] Applying native always-proceed policy to user settings..." -ForegroundColor Green
$settingsPath = "$env:APPDATA\Antigravity IDE\User\settings.json"
if (Test-Path $settingsPath) {
    try {
        $raw = Get-Content -Path $settingsPath -Raw
        if ($raw -notmatch "cascadeAutoExecutionPolicy") {
            $snippet = ",`r`n  `"antigravity.cascadeAutoExecutionPolicy`": `"always-proceed`",`r`n  `"antigravity.terminalAutoExecutionPolicy`": `"always-proceed`",`r`n  `"antigravity.artifactReviewMode`": `"always-proceed`"`r`n}"
            $raw = $raw -replace "\}\s*$", $snippet
            Set-Content -Path $settingsPath -Value $raw -Encoding UTF8
            Write-Host "      -> [OK] settings.json updated." -ForegroundColor Green
        } else {
            Write-Host "      -> [OK] Policy keys already present." -ForegroundColor Gray
        }
    } catch {
        Write-Warning "Could not update settings.json automatically. The UI auto-accept layer still works."
    }
} else {
    Write-Warning "settings.json not found (is Antigravity IDE opened at least once?). UI layer still works."
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " SUCCESS! Auto-Accept is installed." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Activate it now:" -ForegroundColor Yellow
Write-Host "  1. Switch to the Antigravity IDE window."
Write-Host "  2. Press Ctrl + Shift + P  ->  'Reload Window'  ->  Enter."
Write-Host "  3. Look for the green badge: Auto-Accept: ON (bottom-right)."
