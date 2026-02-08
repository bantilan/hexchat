# HexChat

HexChat is an IRC client for Windows and UNIX-like operating systems.  
This build is dedicated to the latest Apple Silicon version of macOS.
See [IRCHelp.org](http://irchelp.org) for information about IRC in general.  
For more information on HexChat please read our [documentation](https://hexchat.readthedocs.org/en/latest/index.html):
- [Downloads](http://hexchat.github.io/downloads.html)
- [FAQ](https://hexchat.readthedocs.org/en/latest/faq.html)
- [Changelog](https://hexchat.readthedocs.org/en/latest/changelog.html)
- [Python API](https://hexchat.readthedocs.org/en/latest/script_python.html)
- [Perl API](https://hexchat.readthedocs.org/en/latest/script_perl.html)

---

**Apple Silicon macOS Bundle**
- Added a macOS app bundle workflow using gtk-mac-bundler with Homebrew prefixes.
- Updated the bundle manifest to use Homebrew `opt` paths and `.dylib` plugin extension.
- Fixed the macOS launcher script locale handling and app name resolution.
- Made post-install scripts resilient when icon/desktop tools are missing.
- Ensured OpenSSL headers are included in the common dependency set for builds.
- Patched gtk-mac-bundler to run on Python 3 and to handle translations cleanly.
- Removed duplicate GTK/GLib/Pango `Cellar` copies from the bundle to avoid class/type collisions.
- Rewrote install-name references from `Cellar` to `opt` for GTK, Pango, GLib, OpenSSL, and libxcb.
- Re-signed all Mach-O binaries and the app bundle after install-name fixes.

**Build macOS Bundle**
Run the one-step build script from the repo root:
```bash
osx/build-macos.sh
```

<sub>
X-Chat ("xchat") Copyright (c) 1998-2010 By Peter Zelezny.  
HexChat ("hexchat") Copyright (c) 2009-2014 By Berke Viktor.
</sub>

<sub>
This program is released under the GPL v2 with the additional exemption
that compiling, linking, and/or using OpenSSL is allowed. You may
provide binary packages linked to the OpenSSL libraries, provided that
all other requirements of the GPL are met.
See file COPYING for details.
</sub>
