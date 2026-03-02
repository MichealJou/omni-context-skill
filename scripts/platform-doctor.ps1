Write-Output "Platform doctor"
Write-Output "- OS: Windows"

function Check-Cmd($Label, $Name) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) {
    Write-Output "- $Label`: OK ($($cmd.Source))"
  } else {
    Write-Output "- $Label`: MISSING"
  }
}

Check-Cmd "pwsh" "pwsh"
Check-Cmd "powershell" "powershell"
Check-Cmd "git" "git"
Check-Cmd "bash" "bash"
Check-Cmd "python" "python"
Check-Cmd "python3" "python3"
Check-Cmd "node" "node"
Check-Cmd "npm" "npm"

$bash = Get-Command bash -ErrorAction SilentlyContinue
if ($bash) {
  Write-Output "- support mode: PowerShell + Git Bash backend"
  Write-Output "- global install: PowerShell installer supported with bash backend"
} else {
  Write-Output "- support mode: INCOMPLETE"
  Write-Output "- global install: Git Bash required"
}
