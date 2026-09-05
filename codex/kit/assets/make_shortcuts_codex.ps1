param(
  [Parameter(Mandatory=$true)][string]$AiDir,
  [Parameter(Mandatory=$true)][string]$Desktop
)
# 「AI秘書を起動 (Codex)」: 作業フォルダ AI で codex を立ち上げる (毎日の入口)
$ErrorActionPreference = 'Stop'
$shell = New-Object -ComObject WScript.Shell
$s = $shell.CreateShortcut((Join-Path $Desktop 'AI秘書を起動 (Codex).lnk'))
$s.TargetPath = "$env:ComSpec"
$s.Arguments = "/k cd /d `"$AiDir`" && codex"
$s.WorkingDirectory = $AiDir
$s.Description = 'AI秘書 (Codex) を起動'
$s.IconLocation = "$env:SystemRoot\System32\shell32.dll,15"
$s.Save()
exit 0
