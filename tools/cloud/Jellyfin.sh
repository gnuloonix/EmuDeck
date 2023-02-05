#!/usr/bin/bash

LINK="https://demo.jellyfin.org/stable"

. ./cloud.conf
"/usr/bin/flatpak" run --branch=stable --arch=x86_64 --command=${COMMAND} --file-forwarding ${FILEFORWARDING} @@u @@ --window-size=${WINDOWSIZE} --force-device-scale-factor=${DEVICESCALEFACTOR} --device-scale-factor=${DEVICESCALEFACTOR} --kiosk "${LINK}"