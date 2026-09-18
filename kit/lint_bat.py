#!/usr/bin/env python3
"""BAT の括弧検査（ビルド前ゲート）。
cmd は if/for/else の ( … ) ブロックを丸ごと解釈してから実行するため、
ブロック内の echo に ^ で逃がしていない ) があると、そこでブロックが閉じて
「。 は予期されていません」で BAT が即終了する（2026-09-18 廣田さん実機で発覚）。
使い方: python3 lint_bat.py a.bat b.bat …  → 問題があれば exit 1
"""
import sys,re
def check(f):
    src=open(f,'rb').read().decode('utf-8','replace').replace('\r\n','\n').split('\n')
    depth=0; bad=[]
    for i,l in enumerate(src,1):
        s=l.strip()
        if not s or re.match(r'(?i)(rem\b|::|:[A-Za-z])',s): continue
        q=False; j=0; t=s
        while j<len(t):
            c=t[j]
            if c=='^': j+=2; continue
            if c=='"': q=not q
            elif not q and c=='(':
                # opens block only at line start, or after if/for/else/do keywords (approx: any '(' at end-of-line or followed by space-less command)
                if re.search(r'(?i)(^|\b(do|else)|\)\s*|^if\b.*|^for\b.*)\s*$',t[:j]) or j==0:
                    depth+=1
            elif not q and c==')' and depth>0:
                depth-=1
                rest=t[j+1:].strip()
                if rest and not re.match(r'(?i)(else\b|>|>>|do\b|2>|&|\|)',rest):
                    bad.append((i,s))
            j+=1
    return bad,depth
ng=0
for f in sys.argv[1:]:
    bad,d=check(f)
    ng+= bool(bad) or d!=0
    print(f, "OK" if not bad and d==0 else f"NG depth={d}")
    for i,s in bad: print("  ",i,s)
sys.exit(1 if ng else 0)
