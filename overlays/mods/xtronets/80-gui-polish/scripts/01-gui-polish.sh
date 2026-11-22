#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-PackageHomePage: https://github.com/paxx12-snapmaker-u1/SnapmakerU1-Extended-Firmware
# SPDX-FileCopyrightText: Copyright (c) 2026 @xtronets
#
# Polish language for the stock Snapmaker touchscreen GUI.
#
# The stock GUI (/usr/bin/gui) reads its texts from JSON files, but the list
# of languages and their menu names are compiled into the binary. Polish
# therefore takes over the Turkish slot (tr-TR):
#   1. the tr-TR UI and error-message JSON files are replaced with Polish,
#   2. the menu label "Türkçe" in /usr/bin/gui is changed to "Polski".
# The label lives in a fixed-size, NUL-padded slot, so the binary layout does
# not change. The build fails if the label is not found exactly once.

set -eo pipefail

if [[ -z "$CREATE_FIRMWARE" ]]; then
  echo "Error: This script should be run within the create_firmware.sh environment."
  exit 1
fi

CUR_DIR="$(realpath "$(dirname "$0")")"
FILES_DIR="$CUR_DIR/../files"
RES_DIR="$ROOTFS_DIR/home/lava/resource"
GUI_BIN="$ROOTFS_DIR/usr/bin/gui"

install_as() {
  local src="$1" dst="$2"
  if [[ ! -f "$dst" ]]; then
    echo "!! Expected stock file $dst not found, refusing to continue."
    exit 1
  fi
  # Keep owner and mode of the stock file
  install -m "$(stat -c '%a' "$dst")" -o "$(stat -c '%u' "$dst")" -g "$(stat -c '%g' "$dst")" "$src" "$dst"
  echo "[+] Installed $(basename "$src") as ${dst#"$ROOTFS_DIR"}"
}

echo ">> Comparing the Polish translation with this firmware's English texts..."
python3 - "$CUR_DIR/../i18n/source" "$RES_DIR" <<'EOF'
import json, sys
src, res = sys.argv[1], sys.argv[2]
pairs = (("en-GB.json", "locales/en-GB.json"), ("exception_en-GB.json", "text/exception_en-GB.json"))
stale = 0
for snap, stock in pairs:
    old = json.load(open(f"{src}/{snap}", encoding="utf-8"))
    new = json.load(open(f"{res}/{stock}", encoding="utf-8"))
    n = sum(1 for k in new if old.get(k) != new[k]) + sum(1 for k in old if k not in new)
    if n:
        print(f"!! WARNING: {stock}: {n} text(s) changed since the translation was made.")
        stale += n
if stale:
    print("!! Missing texts fall back to English. Update with: i18n/i18n.py extract/update/apply (see i18n/README.md)")
else:
    print("[+] Translation is up to date with this firmware")
EOF

install_as "$FILES_DIR/pl.json" "$RES_DIR/locales/tr-TR.json"
install_as "$FILES_DIR/exception_pl.json" "$RES_DIR/text/exception_tr-TR.json"

echo ">> Renaming the Turkish menu entry to Polski in /usr/bin/gui..."
python3 - "$GUI_BIN" <<'EOF'
import sys

path = sys.argv[1]
old = "Türkçe".encode() + b"\0"
new = "Polski".encode()
new += b"\0" * (len(old) - len(new))

data = open(path, "rb").read()
count = data.count(old)
if count != 1:
    sys.exit(f"!! Expected exactly one 'Türkçe' label in {path}, found {count}")

with open(path, "r+b") as f:
    f.seek(data.index(old))
    f.write(new)
print("[+] Patched language label at offset", hex(data.index(old)))
EOF
