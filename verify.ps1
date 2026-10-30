# verify.ps1
# Checks the installation state of Antigravity Auto-Accept (read-only).
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     Antigravity Auto-Accept - Installation Check         " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

$workbenchDir = "$env:LOCALAPPDATA\Programs\Antigravity IDE\resources\app\out\vs\code\electron-browser\workbench"
$scriptDest = Join-Path $workbenchDir "auto-accept.js"
$targets = @(
    (Join-Path $workbenchDir "workbench.html"),
    (Join-Path $workbenchDir "workbench-jetski-agent.html")
)
$failures = 0

# 1. Injector script deployed and Trusted-Types safe
Write-Host "1. auto-accept.js deployed in workbench folder : " -NoNewline
if (Test-Path $scriptDest) {
    if ((Get-Content -Path $scriptDest -Raw) -notmatch "\.innerHTML\s*=") {
        Write-Host "[PASS]" -ForegroundColor Green
    } else {
        Write-Host "[FAIL - legacy/unsafe version, re-run install.ps1]" -ForegroundColor Red; $failures++
    }
} else {
    Write-Host "[FAIL - missing, run install.ps1]" -ForegroundColor Red; $failures++
}

# 2. Script tag injected into every target HTML
foreach ($targetHtml in $targets) {
    $name = Split-Path $targetHtml -Leaf
    Write-Host "2. Script tag present in $name :" -NoNewline
    $htmlContent = if (Test-Path $targetHtml) { Get-Content -Path $targetHtml -Raw } else { "" }
    if ($htmlContent -match "auto-accept\.js") {
        Write-Host "  [PASS]" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL - run install.ps1]" -ForegroundColor Red; $failures++
    }
}

# 3. Native policy keys
Write-Host "3. always-proceed policy keys in settings.json  : " -NoNewline
$settingsPath = "$env:APPDATA\Antigravity IDE\User\settings.json"
if ((Test-Path $settingsPath) -and ((Get-Content -Path $settingsPath -Raw) -match "cascadeAutoExecutionPolicy")) {
    Write-Host "[PASS]" -ForegroundColor Green
} else {
    Write-Host "[WARN - keys missing, UI layer still covers this]" -ForegroundColor Yellow
}

Write-Host ""
if ($failures -eq 0) {
    Write-Host "STATUS: INSTALLED AND READY." -ForegroundColor Green
    Write-Host "If Antigravity is open: Ctrl+Shift+P -> Reload Window." -ForegroundColor Cyan
    Write-Host "The green 'Auto-Accept: ON' badge should then appear bottom-right." -ForegroundColor Cyan
} else {
    Write-Host "STATUS: NOT FULLY INSTALLED. Run: .\install.ps1" -ForegroundColor Yellow
}
