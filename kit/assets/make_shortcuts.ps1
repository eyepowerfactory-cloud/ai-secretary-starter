param(
  [Parameter(Mandatory=$true)][string]$AiDir,
  [Parameter(Mandatory=$true)][string]$Desktop,
  [Parameter(Mandatory=$true)][string]$SetupLine
)
# デスクトップに入口を作る
#  1) 「AI秘書 (Claude)」: Claude アプリを Code タブ + AI フォルダで直接開く (claude:// リンク) = 毎日の入口
#  2) 「AI秘書セットアップ開始」: 同じリンクに、貼り付ける1行を最初から入れた初回専用
#  3) 「AI秘書を起動 (黒い画面)」: 予備。AI フォルダで claude コマンドを立ち上げる
$ErrorActionPreference = 'Continue'
$folder = [Uri]::EscapeDataString($AiDir)
$q = [Uri]::EscapeDataString($SetupLine)

function New-UrlShortcut([string]$Path, [string]$Url) {
  $body = "[InternetShortcut]`r`nURL=$Url`r`nIconFile=$env:SystemRoot\System32\shell32.dll`r`nIconIndex=15`r`n"
  [IO.File]::WriteAllText($Path, $body, [Text.Encoding]::Unicode)
}
New-UrlShortcut (Join-Path $Desktop 'AI秘書 (Claude).url') "claude://code/new?folder=$folder"
New-UrlShortcut (Join-Path $Desktop 'AI秘書セットアップ開始.url') "claude://code/new?folder=$folder&q=$q"

$shell = New-Object -ComObject WScript.Shell
$s = $shell.CreateShortcut((Join-Path $Desktop 'AI秘書を起動 (黒い画面).lnk'))
$s.TargetPath = "$env:ComSpec"
$s.Arguments = "/k cd /d `"$AiDir`" && claude"
$s.WorkingDirectory = $AiDir
$s.Description = 'AI秘書 (Claude Code) を黒い画面で起動 (予備)'
$s.IconLocation = "$env:SystemRoot\System32\shell32.dll,15"
$s.Save()
exit 0
