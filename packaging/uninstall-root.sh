#!/bin/sh
set -eu

/bin/rm -rf -- \
    /Library/Audio/Plug-Ins/VST3/Circulate.vst3 \
    /Library/Audio/Plug-Ins/Components/Circulate.component

/usr/sbin/pkgutil --forget com.gulldsp.circulate.pkg >/dev/null 2>&1 || true
/usr/bin/killall -q AudioComponentRegistrar 2>/dev/null || true
exit 0
