param(
  [string]$SkillDest = "$HOME/.codex/skills/omni-context",
  [string]$BinDir = "$HOME/.local/bin",
  [switch]$KeepPath
)

$targets = @(
  (Join-Path $BinDir "omni.cmd"),
  (Join-Path $BinDir "omni-context.cmd"),
  (Join-Path $BinDir "omni.ps1"),
  (Join-Path $BinDir "omni-context.ps1")
)

foreach ($target in $targets) {
  if (Test-Path $target) {
    Remove-Item -Force $target
  }
}

if (Test-Path $SkillDest) {
  Remove-Item -Recurse -Force $SkillDest
}

if (-not $KeepPath) {
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath) {
    $parts = $userPath -split ';' | Where-Object { $_ -and $_ -ne $BinDir }
    [Environment]::SetEnvironmentVariable("Path", ($parts -join ';'), "User")
    Write-Output "- Removed PATH update for $BinDir"
  }
} else {
  Write-Output "- Kept PATH configuration"
}

Write-Output "Uninstalled OmniContext global launchers"
Write-Output "- Removed skill: $SkillDest"
Write-Output "- Removed commands from $BinDir"
