<#
.SYNOPSIS
    Links the configs in this repo into place on Windows.

.DESCRIPTION
    The Windows counterpart to SetupSimLink.sh. Only configs that mean
    something on native Windows are linked: bash, fish, tmux, readline and
    KZones are Linux-side and skipped.

    Idempotent and non-destructive, like the bash version: re-running is a
    no-op, and anything already at a target path is moved into
    ~\.dotfiles-backup\<timestamp>\ rather than deleted.

    Symlinks on Windows need either an elevated shell, or Developer Mode plus
    PowerShell 7. Without either, directories fall back to junctions (which
    need no privilege) and files fall back to copies. A copy does not track
    later edits to the repo, so re-run this script after pulling.

.PARAMETER InstallProfile
    core, server or desktop. Defaults to desktop, matching InstallApps.ps1.
    Only desktop links the GUI configs (WezTerm).

.PARAMETER DryRun
    Print what would be linked and exit without touching anything.

.EXAMPLE
    .\SetupSimLink.ps1 -InstallProfile desktop
#>
[CmdletBinding()]
param(
    # Not named $Profile: that is a reserved PowerShell automatic variable.
    [ValidateSet('core', 'server', 'desktop')]
    [string]$InstallProfile = 'desktop',

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$configDir = Join-Path $PSScriptRoot 'config'
$backupDir = Join-Path $HOME ".dotfiles-backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$script:backedUp = $false
$script:copied   = @()

# Tools that honour XDG_CONFIG_HOME on Windows fall back to a per-tool default
# when it is unset, so resolve each target the same way the tool itself does.
$xdgConfig = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $null }

function Resolve-FullPath([string]$Path) {
    [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}

# Move whatever is at $Path into the backup directory, preserving its name.
function Backup-Item([string]$Path) {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    $script:backedUp = $true
    Move-Item -LiteralPath $Path -Destination $backupDir
    Write-Host "    backed up existing $(Split-Path -Leaf $Path) -> $backupDir\"
}

function Test-SameFile([string]$A, [string]$B) {
    (Get-FileHash -LiteralPath $A).Hash -eq (Get-FileHash -LiteralPath $B).Hash
}

function New-Link {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Warning "$Label`: source missing ($Source), skipping"
        return
    }
    $isDir = (Get-Item -LiteralPath $Source).PSIsContainer
    $src   = Resolve-FullPath $Source

    # -Force so hidden files and dangling links are still returned.
    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue

    if ($existing -and $existing.LinkType) {
        # Target is an array on Windows PowerShell 5.1, a string on 7.
        $current = @($existing.Target)[0]
        if ($current -and (Resolve-FullPath $current) -eq $src) {
            Write-Host "==  $Label already linked"
            return
        }
    } elseif ($existing -and -not $isDir -and -not $existing.PSIsContainer -and
              (Test-SameFile $Target $Source)) {
        # A previous run fell back to copying, and the copy is still current.
        Write-Host "==  $Label already copied (up to date)"
        $script:copied += $Label
        return
    }

    if ($DryRun) {
        $verb = if ($existing) { 'replace' } else { 'link' }
        Write-Host "..  would $verb $Label  ($Target -> $src)"
        return
    }

    if ($existing -and $existing.LinkType) {
        # A wrong or dangling link is not worth backing up. Delete() removes the
        # link itself; Remove-Item on a junction can recurse into its target.
        $existing.Delete()
    } elseif ($existing) {
        Backup-Item $Target
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null

    try {
        New-Item -ItemType SymbolicLink -Path $Target -Value $src | Out-Null
        Write-Host "->  Linked $Label"
    } catch {
        if ($isDir) {
            New-Item -ItemType Junction -Path $Target -Value $src | Out-Null
            Write-Host "->  Linked $Label (junction; no symlink privilege)"
        } else {
            Copy-Item -LiteralPath $src -Destination $Target
            Write-Host "->  Copied $Label (no symlink privilege)" -ForegroundColor Yellow
            $script:copied += $Label
        }
    }
}

Write-Host "Linking dotfiles from $PSScriptRoot (profile: $InstallProfile)"
if ($DryRun) { Write-Host '-DryRun: nothing will be changed.' }
Write-Host ''

# SSH. Windows OpenSSH reads %USERPROFILE%\.ssh\config and honours the
# Include ~/.ssh/config.local at the top, so private hosts stay out of the repo.
New-Item -ItemType Directory -Force -Path (Join-Path $HOME '.ssh') -WhatIf:$DryRun | Out-Null
New-Link "$configDir\ssh\config" (Join-Path $HOME '.ssh\config') 'SSH'

# Git and WezTerm both read $XDG_CONFIG_HOME, else ~\.config.
$configRoot = if ($xdgConfig) { $xdgConfig } else { Join-Path $HOME '.config' }

# The shared git config Includes config.local next to it for user.name/user.email.
New-Link "$configDir\git\config" (Join-Path $configRoot 'git\config') 'Git'

# Neovim: stdpath('config') is $XDG_CONFIG_HOME\nvim, else %LOCALAPPDATA%\nvim.
$nvimRoot = if ($xdgConfig) { $xdgConfig } else { $env:LOCALAPPDATA }
New-Link "$configDir\nvim" (Join-Path $nvimRoot 'nvim') 'Neovim'

# Yazi: $YAZI_CONFIG_HOME, else %APPDATA%\yazi\config.
$yaziTarget = if ($env:YAZI_CONFIG_HOME) { $env:YAZI_CONFIG_HOME } else { Join-Path $env:APPDATA 'yazi\config' }
New-Link "$configDir\yazi" $yaziTarget 'Yazi'

# GUI-only configs, gated on profile to match SetupSimLink.sh.
if ($InstallProfile -eq 'desktop') {
    # WezTerm checks <config>\wezterm\wezterm.lua before ~\.wezterm.lua.
    New-Link "$configDir\wezterm\.wezterm.lua" (Join-Path $configRoot 'wezterm\wezterm.lua') 'WezTerm'

    # Earlier versions of this script linked ~\.wezterm.lua. It is shadowed now,
    # so remove it if it is ours; leave anything else alone.
    $oldWez = Get-Item -LiteralPath (Join-Path $HOME '.wezterm.lua') -Force -ErrorAction SilentlyContinue
    if ($oldWez) {
        $ours = if ($oldWez.LinkType) {
            (Resolve-FullPath @($oldWez.Target)[0]) -eq (Resolve-FullPath "$configDir\wezterm\.wezterm.lua")
        } else {
            Test-SameFile $oldWez.FullName "$configDir\wezterm\.wezterm.lua"
        }
        if (-not $ours) {
            Write-Warning "~\.wezterm.lua is not from this repo and is now ignored by WezTerm"
        } elseif ($DryRun) {
            Write-Host '..  would remove old ~\.wezterm.lua'
        } else {
            $oldWez.Delete()
            Write-Host '->  Removed old ~\.wezterm.lua'
        }
    }
} else {
    Write-Host "..  skipping GUI configs (WezTerm) for profile '$InstallProfile'"
}

Write-Host ''
if ($script:backedUp) {
    Write-Host "Replaced files were saved to: $backupDir"
}
if ($script:copied.Count -gt 0) {
    Write-Host "Copied rather than linked: $($script:copied -join ', ')" -ForegroundColor Yellow
    Write-Host '    Enable Developer Mode and use PowerShell 7, or run elevated, to get'
    Write-Host '    real symlinks. Until then, re-run this script after pulling.'
}
if (-not (Test-Path (Join-Path $configRoot 'git\config.local'))) {
    Write-Host ''
    Write-Host 'No git identity yet. Set one with:'
    Write-Host "    git config -f `"$(Join-Path $configRoot 'git\config.local')`" user.email `"you@example.com`""
}
Write-Host 'Linking complete.'
