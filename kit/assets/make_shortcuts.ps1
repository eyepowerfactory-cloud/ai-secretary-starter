param(
  [Parameter(Mandatory=$true)][string]$AiDir,
  [Parameter(Mandatory=$true)][string]$Desktop
)
# デスクトップにショートカットを作る
#  1) 「AI秘書を起動」: 作業フォルダ AI で claude を立ち上げる (これが毎日の入口)
#  2) 「Claude」: Claude デスクトップアプリが入っていればそのショートカット
$ErrorActionPreference = 'Stop'
$shell = New-Object -ComObject WScript.Shell

$lnk = Join-Path $Desktop 'AI秘書を起動.lnk'
$s = $shell.CreateShortcut($lnk)
$s.TargetPath = "$env:ComSpec"
$s.Arguments = "/k cd /d `"$AiDir`" && claude"
$s.WorkingDirectory = $AiDir
$s.Description = 'AI秘書 (Claude Code) を起動'
$s.IconLocation = "$env:SystemRoot\System32\shell32.dll,15"
$s.Save()

$candidates = @(
  (Join-Path $env:LOCALAPPDATA 'AnthropicClaude\claude.exe'),
  (Join-Path $env:LOCALAPPDATA 'Programs\Claude\Claude.exe'),
  (Join-Path $env:ProgramFiles 'Claude\Claude.exe')
)
foreach ($exe in $candidates) {
  if (Test-Path $exe) {
    $s2 = $shell.CreateShortcut((Join-Path $Desktop 'Claude.lnk'))
    $s2.TargetPath = $exe
    $s2.WorkingDirectory = (Split-Path $exe)
    $s2.Save()
    break
  }
}
exit 0
