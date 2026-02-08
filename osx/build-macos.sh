#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
BUNDLE_ROOT="$ROOT/osx"
PREFIX="$BUNDLE_ROOT/prefix"
BUNDLER_DIR="$BUNDLE_ROOT/gtk-mac-bundler-0.7.4"
BUNDLE_SPEC="$BUNDLE_ROOT/hexchat.bundle"
APP="$BUNDLE_ROOT/HexChat.app"

if [[ ! -d "$BUNDLER_DIR" ]]; then
  echo "Missing gtk-mac-bundler at $BUNDLER_DIR" >&2
  exit 1
fi

# 1) Configure + build
meson setup build --reconfigure \
  --prefix="$PREFIX" \
  -Dgtk-frontend=true \
  -Dtext-frontend=false \
  -Dwith-lua=false \
  -Dwith-perl=false \
  -Dwith-python=false

ninja -C build
ninja -C build install

# 2) Bundle
rm -rf "$BUNDLE_ROOT/.HexChat.app" "$APP"
python3 - <<PY
import sys
sys.path.insert(0, "$BUNDLER_DIR")
from bundler import main
main.main(["$BUNDLE_SPEC"])
PY

if [[ ! -d "$APP" ]]; then
  echo "Bundle step did not create $APP" >&2
  exit 1
fi

# 3) Remove duplicate Cellar copies (avoid class/type collisions)
rm -rf "$APP/Contents/Resources/Cellar"

# 4) Fix install_name references from Cellar -> opt
python3 - <<'PY'
import os, subprocess
app='osx/HexChat.app'
replacements = {
    '@executable_path/../Resources/Cellar/pango/1.57.0_1/lib/': '@executable_path/../Resources/opt/pango/lib/',
    '@executable_path/../Resources/Cellar/gtk+/2.24.33_2/lib/': '@executable_path/../Resources/opt/gtk+/lib/',
    '@executable_path/../Resources/Cellar/glib/2.86.3/lib/': '@executable_path/../Resources/opt/glib/lib/',
    '@executable_path/../Resources/Cellar/openssl@3/3.6.0/lib/': '@executable_path/../Resources/opt/openssl@3/lib/',
    '@executable_path/../Resources/Cellar/libxcb/1.17.0/lib/': '@executable_path/../Resources/opt/libxcb/lib/',
}
changed = 0
for root, dirs, files in os.walk(app):
    for f in files:
        path=os.path.join(root, f)
        try:
            out=subprocess.check_output(['file', path], text=True)
        except Exception:
            continue
        if 'Mach-O' not in out:
            continue
        try:
            o=subprocess.check_output(['otool','-L',path], text=True)
        except Exception:
            continue
        for line in o.splitlines():
            line=line.strip()
            for old_prefix, new_prefix in replacements.items():
                if line.startswith(old_prefix):
                    old=line.split(' ',1)[0]
                    new=old.replace(old_prefix, new_prefix, 1)
                    subprocess.check_call(['install_name_tool','-change',old,new,path])
                    changed+=1
print('install_name changes', changed)
PY

# 5) Re-sign all Mach-O files and the app bundle (ad-hoc)
python3 - <<'PY'
import os, subprocess
app='osx/HexChat.app'
for root, dirs, files in os.walk(app):
    for f in files:
        path=os.path.join(root,f)
        try:
            out=subprocess.check_output(['file', path], text=True)
        except Exception:
            continue
        if 'Mach-O' not in out:
            continue
        subprocess.check_call(['codesign','--force','--sign','-',path])
subprocess.check_call(['codesign','--force','--deep','--sign','-',app])
PY

# Explicit app-level signing (per request)
codesign --force --deep --sign - "$APP"

echo "Build complete: $APP"
