# uninstall.ps1
# Removes the Auto-Accept patch and restores Antigravity IDE to its original state.
# Note: native policy keys in settings.json are intentionally left untouched
# (harmless "always-proceed" values); remove them from IDE settings if desired.
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     Antigravity Auto-Accept Uninstaller                  " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

$workbenchDir = "$env:LOCALAPPDATA\Programs\Antigravity IDE\resources\app\out\vs\code\electron-browser\workbench"
$targets = @(
    (Join-Path $workbenchDir "workbench.html"),
    (Join-Path $workbenchDir "workbench-jetski-agent.html")
)

foreach ($targetHtml in $targets) {
    $name = Split-Path $targetHtml -Leaf
    if (-not (Test-Path $targetHtml)) { continue }
    $backupHtml = "$targetHtml.bak"

    if (Test-Path $backupHtml) {
        Write-Host "[Restore] $name <- $name.bak" -ForegroundColor Green
        Copy-Item -Path $backupHtml -Destination $targetHtml -Force
        Remove-Item -Path $backupHtml -Force
    } else {
        Write-Host "[Strip]   Removing injected tags from $name (no backup found)..." -ForegroundColor Yellow
        $content = Get-Content -Path $targetHtml -Raw
        $content = $content -replace "`r?`n?<!-- Antigravity Auto-(Accept|Confirm) Injector -->\s*<script src=`"\./auto-(accept|confirm)\.js`"></script>`r?`n?", "`n"
        Set-Content -Path $targetHtml -Value $content -Encoding UTF8
    }
}

foreach ($jsName in @("auto-accept.js", "auto-confirm.js")) {
    $jsPath = Join-Path $workbenchDir $jsName
    if (Test-Path $jsPath) {
        Write-Host "[Remove]  Deleted $jsName from workbench." -ForegroundColor Green
        Remove-Item -Path $jsPath -Force
    }
}

Write-Host ""
Write-Host "[DONE] Patch fully removed. Press Ctrl+Shift+P -> 'Reload Window' in Antigravity to apply." -ForegroundColor Green
