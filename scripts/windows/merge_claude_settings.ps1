param(
  [Parameter(Mandatory=$true)][string]$ConfigPath,
  [Parameter(Mandatory=$true)][string]$TemplatePath
)
# 既存の ~/.claude/settings.json を壊さず、AI秘書用の設定だけを足す
#  - permissions.allow / permissions.deny は「和集合」（既存の許可・拒否は残す）
#  - permissions.defaultMode と skipDangerousModePermissionPrompt はテンプレの値で上書き
#  - それ以外のキー（env / hooks / model / enabledPlugins など）は一切触らない
#  - 既存ファイルが無い／壊れている場合はテンプレをそのまま置く
$ErrorActionPreference = 'Stop'
$tpl = Get-Content -Raw -Encoding UTF8 $TemplatePath | ConvertFrom-Json
if (-not (Test-Path $ConfigPath)) {
  Copy-Item $TemplatePath $ConfigPath
  Write-Output 'settings.json: new (copied template)'
  exit 0
}
try {
  $raw = Get-Content -Raw -Encoding UTF8 $ConfigPath
  if ([string]::IsNullOrWhiteSpace($raw)) { throw 'empty' }
  $cur = $raw | ConvertFrom-Json
} catch {
  Copy-Item $TemplatePath $ConfigPath -Force
  Write-Output 'settings.json: unreadable -> replaced with template'
  exit 0
}

function Ensure-Prop($obj, [string]$name, $default) {
  if (-not ($obj.PSObject.Properties.Name -contains $name)) {
    $obj | Add-Member -MemberType NoteProperty -Name $name -Value $default
  }
}
function Merge-List($a, $b) {
  $out = New-Object System.Collections.ArrayList
  foreach ($x in @($a) + @($b)) {
    if ($null -ne $x -and -not $out.Contains([string]$x)) { [void]$out.Add([string]$x) }
  }
  return ,$out.ToArray()
}

Ensure-Prop $cur 'permissions' ([pscustomobject]@{})
Ensure-Prop $cur.permissions 'allow' @()
Ensure-Prop $cur.permissions 'deny'  @()
$cur.permissions.allow = Merge-List $cur.permissions.allow $tpl.permissions.allow
$cur.permissions.deny  = Merge-List $cur.permissions.deny  $tpl.permissions.deny
Ensure-Prop $cur.permissions 'defaultMode' $tpl.permissions.defaultMode
$cur.permissions.defaultMode = $tpl.permissions.defaultMode
Ensure-Prop $cur 'skipDangerousModePermissionPrompt' $true
$cur.skipDangerousModePermissionPrompt = $tpl.skipDangerousModePermissionPrompt

$json = $cur | ConvertTo-Json -Depth 30
# PowerShell 5.1 の ConvertTo-Json は日本語や記号を \uXXXX にするので戻す（" と \ は触らない）
$json = [regex]::Replace($json, '\\u([0-9a-fA-F]{4})', {
  param($m)
  $code = [Convert]::ToInt32($m.Groups[1].Value, 16)
  if ($code -eq 0x22 -or $code -eq 0x5c) { return $m.Value }
  return [string][char]$code
})
[IO.File]::WriteAllText($ConfigPath, $json, (New-Object Text.UTF8Encoding($false)))
Write-Output 'settings.json: merged'
exit 0
