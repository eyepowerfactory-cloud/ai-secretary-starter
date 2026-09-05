param(
  [Parameter(Mandatory=$true)][string]$AiDir,
  [Parameter(Mandatory=$true)][string]$Desktop
)
# デスクトップにショートカットを作る
#  1) 「AI秘書 (Codex)」: Codex デスクトップアプリ (Store アプリ) を開く = 毎日の入口
#  2) 「AI秘書を起動 (Codex・黒い画面)」: 予備。作業フォルダ AI で codex コマンドを立ち上げる
$ErrorActionPreference = 'Continue'
$shell = New-Object -ComObject WScript.Shell

$made = $false
try {
  $pkg = Get-AppxPackage | Where-Object { $_.Name -like '*Codex*' -and ($_.Publisher -like '*OpenAI*' -or $_.Name -like '*OpenAI*') } | Select-Object -First 1
  if ($pkg) {
    $appId = ((Get-AppxPackageManifest $pkg).Package.Applications.Application | Select-Object -First 1).Id
    $s = $shell.CreateShortcut((Join-Path $Desktop 'AI秘書 (Codex).lnk'))
    $s.TargetPath = "$env:SystemRoot\explorer.exe"
    $s.Arguments = "shell:AppsFolder\$($pkg.PackageFamilyName)!$appId"
    $s.Description = 'AI秘書 (Codex アプリ) を開く'
    $s.Save()
    $made = $true
  }
} catch { }
if (-not $made) {
  # アプリが見つからないときは `codex app` (アプリを開く/無ければインストーラーを開く)
  $s = $shell.CreateShortcut((Join-Path $Desktop 'AI秘書 (Codex).lnk'))
  $s.TargetPath = "$env:ComSpec"
  $s.Arguments = '/c codex app'
  $s.WorkingDirectory = $AiDir
  $s.Description = 'AI秘書 (Codex アプリ) を開く'
  $s.Save()
}

$s2 = $shell.CreateShortcut((Join-Path $Desktop 'AI秘書を起動 (Codex・黒い画面).lnk'))
$s2.TargetPath = "$env:ComSpec"
$s2.Arguments = "/k cd /d `"$AiDir`" && codex"
$s2.WorkingDirectory = $AiDir
$s2.Description = 'AI秘書 (Codex) を黒い画面で起動 (予備)'
$s2.IconLocation = "$env:SystemRoot\System32\shell32.dll,15"
$s2.Save()
exit 0
