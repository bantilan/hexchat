#!/usr/bin/env bash
set -euo pipefail

APP="osx/HexChat.app"

if [[ ! -d "$APP" ]]; then
  echo "Missing $APP. Build the bundle first." >&2
  exit 1
fi

python3 - <<'PY'
import os, subprocess
app='osx/HexChat.app'
old_prefix='@executable_path/../Resources/Cellar/libxcb/1.17.0/lib/'
new_prefix='@executable_path/../Resources/opt/libxcb/lib/'
changed=0
for root, dirs, files in os.walk(app):
    for f in files:
        path=os.path.join(root,f)
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
            if line.startswith(old_prefix):
                old=line.split(' ',1)[0]
                new=old.replace(old_prefix, new_prefix, 1)
                subprocess.check_call(['install_name_tool','-change',old,new,path])
                changed+=1
print('changed',changed)
PY

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

printf 'Bundle fixup complete for %s\n' "$APP"
