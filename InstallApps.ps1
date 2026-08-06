<#
.SYNOPSIS
    Installs packages from apps/app_list.csv on Windows via winget.

.DESCRIPTION
    The Windows counterpart to InstallApps.sh. Both read the same CSV, so the
    package list has a single source of truth.

    Profiles are cumulative: server includes core, desktop includes both.

.PARAMETER InstallProfile
    core, server or desktop. Defaults to desktop, since Windows here is a
    workstation rather than a headless host.

.PARAMETER DryRun
    Print what would be installed and exit.

.EXAMPLE
    .\InstallApps.ps1 -InstallProfile desktop
#>
[CmdletBinding()]
param(
    # Not named $Profile: that is a reserved PowerShell automatic variable.
    [ValidateSet('core', 'server', 'desktop')]
    [string]$InstallProfile = 'desktop',

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$csvPath = Join-Path $PSScriptRoot 'apps/app_list.csv'
if (-not (Test-Path $csvPath)) {
    throw "Cannot find $csvPath"
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store.'
}

$rows = Import-Csv -Path $csvPath

# Cumulative profile selection.
$wanted = switch ($InstallProfile) {
    'core'    { $rows | Where-Object { $_.Core -eq '1' } }
    'server'  { $rows | Where-Object { $_.Core -eq '1' -or $_.Server -eq '1' } }
    'desktop' { $rows | Where-Object { $_.Core -eq '1' -or $_.Server -eq '1' -or $_.Desktop -eq '1' } }
}

$installable = $wanted | Where-Object { $_.Winget -and $_.Winget -ne '-' }
$skipped     = $wanted | Where-Object { -not $_.Winget -or $_.Winget -eq '-' }

Write-Host "Profile:    $InstallProfile"
Write-Host "Candidates: $($installable.Count)"
Write-Host ''

if ($skipped) {
    Write-Host 'No winget id defined, skipping:' -ForegroundColor Yellow
    $skipped | ForEach-Object { Write-Host "  - $($_.ApplicationName)" }
    Write-Host ''
}

if (-not $installable) {
    Write-Host 'Nothing to install.'
    return
}

foreach ($app in $installable) {
    Write-Host "$($app.ApplicationName)  [$($app.Winget)]"
}
Write-Host ''

if ($DryRun) {
    Write-Host '-DryRun: nothing was installed.'
    return
}

$failed = @()
foreach ($app in $installable) {
    Write-Host "==> Installing $($app.ApplicationName)..." -ForegroundColor Cyan
    winget install --id $app.Winget --exact `
        --accept-package-agreements --accept-source-agreements `
        --disable-interactivity

    # 0 = installed, -1978335189 = no applicable upgrade (already current).
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        Write-Warning "$($app.ApplicationName) failed with exit code $LASTEXITCODE"
        $failed += $app.ApplicationName
    }
}

Write-Host ''
if ($failed.Count -gt 0) {
    Write-Host "Finished with failures: $($failed -join ', ')" -ForegroundColor Yellow
} else {
    Write-Host "Install complete for profile '$InstallProfile'." -ForegroundColor Green
}
