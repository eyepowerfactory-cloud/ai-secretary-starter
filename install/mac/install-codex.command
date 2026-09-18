#!/bin/bash
# ダブルクリック用: 同じフォルダの install.sh を呼ぶ（初回は「右クリック → 開く」）
cd "$(dirname "$0")" && exec bash ./install.sh codex
