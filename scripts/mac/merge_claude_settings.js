// osascript -l JavaScript merge_settings.js <settings.json> <template.json>
// 既存の ~/.claude/settings.json を壊さず、AI秘書用の設定だけを足す（Windows 版 merge_settings.ps1 と同じ規則）
//  - permissions.allow / deny は和集合（既存の許可・拒否は残す）
//  - permissions.defaultMode と skipDangerousModePermissionPrompt はテンプレの値で上書き
//  - それ以外のキー（env / hooks / model / enabledPlugins など）は一切触らない
//  - 既存ファイルが壊れている場合はテンプレをそのまま置く
// macOS 標準の JavaScriptCore だけで動く（python / node 不要）
ObjC.import('Foundation');

function readFile(p) {
  var s = $.NSString.stringWithContentsOfFileEncodingError($(p), $.NSUTF8StringEncoding, null);
  return s.isNil() ? null : ObjC.unwrap(s);
}
function writeFile(p, s) {
  $(s).writeToFileAtomicallyEncodingError($(p), true, $.NSUTF8StringEncoding, null);
}
function union(a, b) {
  var out = [];
  [].concat(a || [], b || []).forEach(function (x) {
    if (x !== null && x !== undefined && out.indexOf(x) < 0) out.push(x);
  });
  return out;
}

function run(argv) {
  var cfgPath = argv[0], tplPath = argv[1];
  var tpl = JSON.parse(readFile(tplPath));
  var raw = readFile(cfgPath);
  var cur = null;
  if (raw !== null && raw.trim() !== '') {
    try { cur = JSON.parse(raw); } catch (e) { cur = null; }
  } else if (raw === null) {
    cur = {};
  }
  if (cur === null || typeof cur !== 'object' || Array.isArray(cur)) {
    writeFile(cfgPath, JSON.stringify(tpl, null, 2) + '\n');
    return 'settings.json: unreadable -> replaced with template';
  }
  if (!cur.permissions || typeof cur.permissions !== 'object') cur.permissions = {};
  cur.permissions.allow = union(cur.permissions.allow, tpl.permissions.allow);
  cur.permissions.deny = union(cur.permissions.deny, tpl.permissions.deny);
  cur.permissions.defaultMode = tpl.permissions.defaultMode;
  cur.skipDangerousModePermissionPrompt = tpl.skipDangerousModePermissionPrompt;
  writeFile(cfgPath, JSON.stringify(cur, null, 2) + '\n');
  return 'settings.json: merged';
}
