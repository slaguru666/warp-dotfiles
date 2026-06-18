<#
.SYNOPSIS
    Symlinks Warp configuration files from this dotfiles repo into the
    locations Warp reads on Windows.

.DESCRIPTION
    For each managed entry, the script:
      * Ensures the target's parent directory exists.
      * If a real file/dir already lives at the target, backs it up to
        "<target>.bak-<timestamp>" (unless -Force is used, which deletes it).
      * Replaces an existing symlink at the target.
      * Creates a new symlink target -> repo source.

    Creating symlinks on Windows requires either:
      * Developer Mode enabled (Settings > Privacy & security > For developers), or
      * Running this script from an elevated (Administrator) PowerShell.

.PARAMETER DataRoot
    Override the Warp "data" root (where tab_configs, themes, and
    keybindings.yaml live). Defaults to %APPDATA%\warp\Warp\data.
    Useful for testing or non-standard installs.

.PARAMETER ConfigRoot
    Override the Warp "config" root (where settings.toml lives).
    Defaults to %LOCALAPPDATA%\warp\Warp\config.

.PARAMETER DryRun
    Print what would happen without making changes.

.PARAMETER Force
    Delete existing real targets instead of backing them up.

.EXAMPLE
    pwsh -ExecutionPolicy Bypass -File .\install.ps1
    pwsh -File .\install.ps1 -DryRun
    pwsh -File .\install.ps1 -DataRoot C:\tmp\data -ConfigRoot C:\tmp\config -DryRun
#>
[CmdletBinding()]
param(
    [string]$DataRoot   = (Join-Path $env:APPDATA      'warp\Warp\data'),
    [string]$ConfigRoot = (Join-Path $env:LOCALAPPDATA 'warp\Warp\config'),
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

# Warp config roots. APPDATA = Roaming (data), LOCALAPPDATA = Local (config).
# Both are overridable via the -DataRoot / -ConfigRoot parameters above.

# Managed entries: Source is relative to the repo, Target is absolute.
# Type is 'File' or 'Directory' (controls how the symlink is created).
$Entries = @(
    @{ Source = 'warp\data\tab_configs'; Target = (Join-Path $DataRoot 'tab_configs');     Type = 'Directory' }
    @{ Source = 'warp\data\themes';      Target = (Join-Path $DataRoot 'themes');          Type = 'Directory' }
    @{ Source = 'warp\data\keybindings.yaml'; Target = (Join-Path $DataRoot 'keybindings.yaml'); Type = 'File' }
    @{ Source = 'warp\config\settings.toml';  Target = (Join-Path $ConfigRoot 'settings.toml');  Type = 'File' }
)

function Test-SymlinkCapability {
    # Admin always works.
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return $true
    }
    # Otherwise check Developer Mode.
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    try {
        $val = (Get-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -ErrorAction Stop).AllowDevelopmentWithoutDevLicense
        return ($val -eq 1)
    } catch {
        return $false
    }
}

function Backup-Target {
    param([string]$Path)
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$Path.bak-$stamp"
    Write-Host "  backing up existing target -> $backup" -ForegroundColor Yellow
    if (-not $DryRun) { Move-Item -LiteralPath $Path -Destination $backup -Force }
}

Write-Host "Warp dotfiles installer" -ForegroundColor Cyan
Write-Host "  repo:        $RepoRoot"
Write-Host "  data root:   $DataRoot"
Write-Host "  config root: $ConfigRoot"
if ($DryRun) { Write-Host "  MODE: DryRun (no changes)" -ForegroundColor Magenta }
Write-Host ""

if (-not (Test-SymlinkCapability)) {
    Write-Warning @"
Symlink creation may fail. Enable Developer Mode
(Settings > Privacy & security > For developers > Developer Mode)
or re-run this script from an elevated (Administrator) PowerShell.
"@
}

foreach ($entry in $Entries) {
    $source = Join-Path $RepoRoot $entry.Source
    $target = $entry.Target

    Write-Host ("-> {0}" -f $entry.Source) -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Host "  skip: source does not exist in repo ($source)" -ForegroundColor DarkGray
        continue
    }

    # Ensure parent dir of target exists.
    $parent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $parent)) {
        Write-Host "  creating parent dir: $parent"
        if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    }

    # Handle anything already at the target.
    if (Test-Path -LiteralPath $target) {
        $item = Get-Item -LiteralPath $target -Force
        $isLink = $item.LinkType -eq 'SymbolicLink' -or [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
        if ($isLink) {
            Write-Host "  removing existing symlink"
            if (-not $DryRun) { (Get-Item -LiteralPath $target -Force).Delete() }
        }
        elseif ($Force) {
            Write-Host "  removing existing target (-Force)" -ForegroundColor Yellow
            if (-not $DryRun) { Remove-Item -LiteralPath $target -Recurse -Force }
        }
        else {
            Backup-Target -Path $target
        }
    }

    Write-Host "  linking $target -> $source" -ForegroundColor Green
    if (-not $DryRun) {
        New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
