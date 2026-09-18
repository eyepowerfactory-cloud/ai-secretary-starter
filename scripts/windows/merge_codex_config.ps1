param([Parameter(Mandatory=$true)][string]$ConfigPath,[Parameter(Mandatory=$true)][string]$TemplatePath)
# 既存の config.toml を壊さず、AI秘書用のキーが無いときだけ足す
#  - top-level キー（approval_policy / sandbox_mode）は最初のテーブルより前に置く必要があるので先頭に挿入
#  - [sandbox_workspace_write] は無ければ末尾に追記
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ConfigPath)) { Copy-Item $TemplatePath $ConfigPath; exit 0 }
$text = Get-Content -Raw -Encoding UTF8 $ConfigPath
$prepend = @()
if ($text -notmatch '(?m)^\s*approval_policy\s*=') { $prepend += 'approval_policy = "never"' }
if ($text -notmatch '(?m)^\s*sandbox_mode\s*=')    { $prepend += 'sandbox_mode = "workspace-write"' }
if ($prepend.Count -gt 0) { $text = ($prepend -join "`n") + "`n" + $text }
if ($text -notmatch '(?m)^\s*\[sandbox_workspace_write\]') {
  $text = $text.TrimEnd() + "`n`n[sandbox_workspace_write]`nnetwork_access = true`n"
}
[IO.File]::WriteAllText($ConfigPath, $text, (New-Object Text.UTF8Encoding($false)))
exit 0
