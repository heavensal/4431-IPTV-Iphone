#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./Scripts/fetch-vlc.sh
xcodebuild -project 4431-IPTV-Iphone.xcodeproj -scheme IPTVPhone -configuration Release -sdk iphoneos -derivedDataPath .build/device build CODE_SIGNING_ALLOWED=NO
stage=$(mktemp -d "$PWD/.build/ipa.XXXXXX")
mkdir -p "$stage/Payload" dist
ditto .build/device/Build/Products/Release-iphoneos/IPTVPhone.app "$stage/Payload/IPTVPhone.app"
(cd "$stage" && /usr/bin/zip -qry "$OLDPWD/dist/4431-IPTV-Iphone-0.0.1-unsigned.ipa" Payload)
