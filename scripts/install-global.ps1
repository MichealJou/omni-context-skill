param(
  [string]$SkillDest = "$HOME/.codex/skills/omni-context",
  [string]$BinDir = "$HOME/.local/bin",
  [switch]$Force,
  [switch]$SkipPathUpdate
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallSkill = Join-Path $ScriptDir "install-skill.sh"

function Resolve-BashPath {
  $candidate = Get-Command bash -ErrorAction SilentlyContinue
  if ($candidate) {
    return $candidate.Source
  }

  $fallbacks = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files\Git\usr\bin\bash.exe",
    "$HOME\scoop\apps\git\current\bin\bash.exe",
    "$HOME\scoop\apps\git\current\usr\bin\bash.exe"
  )

  foreach ($path in $fallbacks) {
    if (Test-Path $path) {
      return $path
    }
  }

  return $null
}

$BashPath = Resolve-BashPath
if (-not $BashPath) {
  Write-Error "Git Bash or another bash runtime is required on Windows. Install Git for Windows first."
  exit 1
}

if ($Force -and (Test-Path $SkillDest)) {
  Remove-Item -Recurse -Force $SkillDest
}

if (-not (Test-Path $SkillDest)) {
  & $BashPath $InstallSkill $SkillDest | Out-Null
}

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

$cmdLauncher = @"
@echo off
"$BashPath" "$SkillDest/scripts/omni-context" %*
"@

$psLauncher = @"
#!/usr/bin/env pwsh
& "$BashPath" "$SkillDest/scripts/omni-context" @args
"@

Set-Content -Path (Join-Path $BinDir "omni.cmd") -Value $cmdLauncher -Encoding ASCII
Set-Content -Path (Join-Path $BinDir "omni-context.cmd") -Value $cmdLauncher -Encoding ASCII
Set-Content -Path (Join-Path $BinDir "omni.ps1") -Value $psLauncher -Encoding ASCII
Set-Content -Path (Join-Path $BinDir "omni-context.ps1") -Value $psLauncher -Encoding ASCII

if (-not $SkipPathUpdate) {
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not $userPath) { $userPath = "" }
  $parts = $userPath -split ';' | Where-Object { $_ -ne "" }
  if ($parts -notcontains $BinDir) {
    $newPath = @($parts + $BinDir) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Output "- Added PATH update to user environment"
  } else {
    Write-Output "- PATH already contains $BinDir"
  }
} else {
  Write-Output "- Skipped PATH update"
}

Write-Output "Installed OmniContext global launchers"
Write-Output "- Skill: $SkillDest"
Write-Output "- Bash: $BashPath"
Write-Output "- Commands: $BinDir/omni(.cmd|.ps1), $BinDir/omni-context(.cmd|.ps1)"
