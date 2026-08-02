# Install shared Claude Code config on Windows from PowerShell.
# Safe to re-run. Merges into any existing settings.json rather than clobbering it.
# (You can also just run ./install.sh from Git Bash instead - same result.)
$ErrorActionPreference = "Stop"

$RepoDir   = $PSScriptRoot
$ClaudeDir = Join-Path $HOME ".claude"
$Target    = Join-Path $ClaudeDir "settings.json"

if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
    Write-Warning "jq not found. The status line needs it. Install with:  winget install jqlang.jq"
}

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

$shared = Get-Content (Join-Path $RepoDir "settings.json") -Raw | ConvertFrom-Json

if (Test-Path $Target) {
    $stamp  = Get-Date -Format "yyyyMMddHHmmss"
    $backup = "$Target.backup.$stamp"
    Copy-Item $Target $backup
    Write-Host "backed up existing settings -> $backup"

    # Merge: shared repo values win, but any machine-only keys are preserved.
    $merged = Get-Content $Target -Raw | ConvertFrom-Json
    foreach ($prop in $shared.PSObject.Properties) {
        $merged | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
    }
    $merged | ConvertTo-Json -Depth 100 | Set-Content $Target -Encoding UTF8
    Write-Host "merged shared settings into $Target"
} else {
    Copy-Item (Join-Path $RepoDir "settings.json") $Target
    Write-Host "installed settings -> $Target"
}

Write-Host ""
Write-Host "Done. Status line runs from: $RepoDir\statusline.sh"
Write-Host "Restart Claude Code to pick it up."
