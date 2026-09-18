#!/usr/bin/env python3
"""zip作成（UTF-8ファイル名フラグ付き・実行権限保持）。

macOSのzipコマンドは日本語ファイル名にUTF-8フラグ(EFS)を立てず、
日本語Windowsのエクスプローラーで展開すると文字化けする。
Python zipfileは非ASCII名に自動でUTF-8フラグを立てるため、これで梱包する。
"""
import os
import stat
import sys
import time
import zipfile


def main(src: str, out: str) -> None:
    src = src.rstrip("/")
    base = os.path.basename(src)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(src):
            dirs.sort()
            for name in sorted(dirs):
                p = os.path.join(root, name)
                arc = os.path.join(base, os.path.relpath(p, src)) + "/"
                zi = zipfile.ZipInfo(arc, time.localtime(os.stat(p).st_mtime)[:6])
                zi.external_attr = (0o755 << 16) | 0x10
                z.writestr(zi, b"")
            for name in sorted(files):
                p = os.path.join(root, name)
                if name == ".DS_Store":
                    continue
                arc = os.path.join(base, os.path.relpath(p, src))
                st = os.stat(p)
                zi = zipfile.ZipInfo(arc, time.localtime(st.st_mtime)[:6])
                zi.external_attr = stat.S_IMODE(st.st_mode) << 16
                zi.compress_type = zipfile.ZIP_DEFLATED
                with open(p, "rb") as f:
                    z.writestr(zi, f.read())


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
