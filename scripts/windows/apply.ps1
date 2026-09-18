param(
  [Parameter(Mandatory=$true)][ValidateSet('claude','codex')][string]$Agent,
  [string]$AiDir = '',
  [string]$DesktopDir = '',   # テスト用。通常は空（Windows に本当のデスクトップの場所を聞く）
  [switch]$CheckOnly
)
# AI秘書の土台を配置して点検する（Windows）
#   セットアップ指示書（setup-claude.md / setup-codex.md）から Claude Code / Codex が実行する。人が直接叩く想定ではない。
#   - 何度実行しても同じ結果になる（既にあるファイルは上書きしない。設定はマージ）
#   - 最後に点検表を AI フォルダの SETUP_CHECK.md に書き、画面にも出す
#   - -CheckOnly なら何も変更せず点検だけ
# 使い方: powershell -NoProfile -ExecutionPolicy Bypass -File <kit>\scripts\windows\apply.ps1 -Agent claude
$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) } catch { }

$Kit = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # scripts\windows -> リポのルート
$Starter = Join-Path $Kit 'starter'
$Desktop = if ($DesktopDir) { $DesktopDir } else { [Environment]::GetFolderPath('Desktop') }   # OneDrive にリダイレクトされていても本当の場所を返す
if ([string]::IsNullOrWhiteSpace($Desktop)) { $Desktop = Join-Path $env:USERPROFILE 'Desktop' }
if ([string]::IsNullOrWhiteSpace($AiDir)) { $AiDir = Join-Path $Desktop 'AI' }
$HomeDir = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($HomeDir)) { $HomeDir = [Environment]::GetFolderPath('UserProfile') }
$Skills = @('morning-briefing','meeting-notes','doc-draft','learn')

if ($Agent -eq 'claude') {
  $AgentDir  = Join-Path $HomeDir '.claude'
  $SkillDir  = Join-Path $AgentDir 'skills'
  $CfgPath   = Join-Path $AgentDir 'settings.json'
  $TplPath   = Join-Path $Kit 'config\claude-settings.json'
  $Rules     = 'CLAUDE.md'
} else {
  $AgentDir  = Join-Path $HomeDir '.codex'
  $SkillDir  = Join-Path (Join-Path $HomeDir '.agents') 'skills'
  $CfgPath   = Join-Path $AgentDir 'config.toml'
  $TplPath   = Join-Path $Kit 'config\codex-config.toml'
  $Rules     = 'AGENTS.md'
}
$log = New-Object System.Collections.ArrayList
function Note([string]$s) { [void]$log.Add($s); Write-Output $s }

Note "kit      : $Kit"
Note "desktop  : $Desktop"
Note "ai folder: $AiDir"
if ($Desktop -match 'OneDrive') { Note 'note     : desktop is inside OneDrive' }

if (-not $CheckOnly) {
  # 1) AI フォルダと秘書の中身（既にあるものは残す）
  New-Item -ItemType Directory -Force -Path (Join-Path $AiDir 'memory') | Out-Null
  $files = @($Rules, 'tasks.md', 'SKILL_CATALOG.md', 'memory\README.md', 'memory\condition.md')
  foreach ($f in $files) {
    $dst = Join-Path $AiDir $f
    if (-not (Test-Path $dst)) { Copy-Item (Join-Path $Starter $f) $dst; Note "copied   : $f" } else { Note "kept     : $f" }
  }

  # 2) スキル4つ（既にあるものは残す）
  New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null
  foreach ($s in $Skills) {
    $dst = Join-Path $SkillDir $s
    if (-not (Test-Path (Join-Path $dst 'SKILL.md'))) {
      Copy-Item -Recurse -Force (Join-Path $Starter "skills\$s") $SkillDir
      Note "skill    : installed $s"
    } else { Note "skill    : kept $s" }
  }

  # 3) 許可を求めない設定（退避してからマージ。既存の設定は消さない）
  New-Item -ItemType Directory -Force -Path $AgentDir | Out-Null
  if (Test-Path $CfgPath) { Copy-Item $CfgPath "$CfgPath.backup" -Force; Note "backup   : $CfgPath.backup" }
  $merge = if ($Agent -eq 'claude') { 'merge_claude_settings.ps1' } else { 'merge_codex_config.ps1' }
  try {
    $out = & (Join-Path $PSScriptRoot $merge) -ConfigPath $CfgPath -TemplatePath $TplPath 2>&1
    Note "settings : merged $out"
  } catch { Note "settings : FAILED $($_.Exception.Message)" }

  # 4) デスクトップの入口
  if ($Agent -eq 'claude') {
    # 毎日の入口: Claude アプリを Code タブ + AI フォルダで開くリンク（COM に頼らないので先に作る）
    try {
      $url = 'claude://code/new?folder=' + [Uri]::EscapeDataString($AiDir)
      $body = "[InternetShortcut]`r`nURL=$url`r`nIconFile=$env:SystemRoot\System32\shell32.dll`r`nIconIndex=15`r`n"
      [IO.File]::WriteAllText((Join-Path $Desktop 'AI秘書 (Claude).url'), $body, [Text.Encoding]::Unicode)
    } catch { Note "shortcut : FAILED url $($_.Exception.Message)" }
  }
  try {
    $shell = New-Object -ComObject WScript.Shell
    if ($Agent -eq 'claude') {
      $lnk = $shell.CreateShortcut((Join-Path $Desktop 'AI秘書を起動 (黒い画面).lnk'))
      $lnk.TargetPath = "$env:ComSpec"; $lnk.Arguments = "/k cd /d `"$AiDir`" && claude"
    } else {
      $made = $false
      try {
        $pkg = Get-AppxPackage | Where-Object { $_.Name -like '*Codex*' -and ($_.Publisher -like '*OpenAI*' -or $_.Name -like '*OpenAI*') } | Select-Object -First 1
        if ($pkg) {
          $appId = ((Get-AppxPackageManifest $pkg).Package.Applications.Application | Select-Object -First 1).Id
          $app = $shell.CreateShortcut((Join-Path $Desktop 'AI秘書 (Codex).lnk'))
          $app.TargetPath = "$env:SystemRoot\explorer.exe"; $app.Arguments = "shell:AppsFolder\$($pkg.PackageFamilyName)!$appId"
          $app.Save(); $made = $true
        }
      } catch { }
      if (-not $made) { Note 'shortcut : Codex app not found (terminal shortcut only)' }
      $lnk = $shell.CreateShortcut((Join-Path $Desktop 'AI秘書を起動 (Codex・黒い画面).lnk'))
      $lnk.TargetPath = "$env:ComSpec"; $lnk.Arguments = "/k cd /d `"$AiDir`" && codex"
    }
    $lnk.WorkingDirectory = $AiDir
    $lnk.IconLocation = "$env:SystemRoot\System32\shell32.dll,15"
    $lnk.Save()
    Note 'shortcut : created'
  } catch { Note "shortcut : FAILED $($_.Exception.Message)" }
}

# 5) 点検表
$rows = New-Object System.Collections.ArrayList
function Row([string]$name, [bool]$ok, [string]$detail) {
  [void]$rows.Add([pscustomobject]@{ Name = $name; Ok = $ok; Detail = $detail })
}
function Ver([string]$cmd) {
  try { $v = (& $cmd --version 2>$null | Select-Object -First 1); if ($v) { return [string]$v } } catch { }
  return ''
}
$git = Ver 'git'
Row 'Git' ($git -ne '') $git
$cli = Ver $Agent
Row ($(if ($Agent -eq 'claude') { 'Claude Code (コマンド版)' } else { 'Codex (コマンド版)' })) ($cli -ne '') $cli
Row 'AI フォルダ' (Test-Path $AiDir) $AiDir
foreach ($f in @($Rules, 'tasks.md', 'SKILL_CATALOG.md', 'memory\condition.md')) { Row "  $f" (Test-Path (Join-Path $AiDir $f)) '' }
foreach ($s in $Skills) { Row "スキル $s" (Test-Path (Join-Path $SkillDir "$s\SKILL.md")) '' }
$permOk = $false; $permDetail = 'not found'
if (Test-Path $CfgPath) {
  $raw = Get-Content -Raw -Encoding UTF8 $CfgPath
  if ($Agent -eq 'claude') {
    try { $j = $raw | ConvertFrom-Json; $permDetail = "defaultMode=$($j.permissions.defaultMode)"; $permOk = ($j.permissions.defaultMode -eq 'bypassPermissions') } catch { $permDetail = 'settings.json is broken' }
  } else {
    $ap = [regex]::Match($raw, '(?m)^\s*approval_policy\s*=\s*"([^"]+)"').Groups[1].Value
    $sb = [regex]::Match($raw, '(?m)^\s*sandbox_mode\s*=\s*"([^"]+)"').Groups[1].Value
    $permDetail = "approval_policy=$ap sandbox_mode=$sb"; $permOk = ($ap -eq 'never')
  }
}
Row '許可を求めない設定' $permOk $permDetail
$sc = if ($Agent -eq 'claude') { 'AI秘書 (Claude).url' } else { 'AI秘書を起動 (Codex・黒い画面).lnk' }
Row 'デスクトップの入口' (Test-Path (Join-Path $Desktop $sc)) $sc

$ng = @($rows | Where-Object { -not $_.Ok }).Count
$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine("# セットアップ点検表（$Agent / Windows）")
[void]$md.AppendLine('')
[void]$md.AppendLine("- 日時: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$md.AppendLine("- デスクトップ: $Desktop")
[void]$md.AppendLine('')
[void]$md.AppendLine('| 項目 | 結果 | 詳細 |')
[void]$md.AppendLine('|---|---|---|')
foreach ($r in $rows) { [void]$md.AppendLine("| $($r.Name) | $(if ($r.Ok) { 'OK' } else { 'NG' }) | $($r.Detail) |") }
[void]$md.AppendLine('')
[void]$md.AppendLine($(if ($ng -eq 0) { '結果: すべて OK' } else { "結果: NG が $ng 件" }))
if (Test-Path $AiDir) { [IO.File]::WriteAllText((Join-Path $AiDir 'SETUP_CHECK.md'), $md.ToString(), (New-Object Text.UTF8Encoding($false))) }

Write-Output ''
foreach ($r in $rows) { Write-Output ("[{0}] {1}  {2}" -f $(if ($r.Ok) { 'OK' } else { 'NG' }), $r.Name, $r.Detail) }
Write-Output ("RESULT: {0}" -f $(if ($ng -eq 0) { 'ALL_OK' } else { "NG=$ng" }))
exit 0
