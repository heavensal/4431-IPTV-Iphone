#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
kit=Vendor/MobileVLCKit.xcframework
if [[ -f "$kit/ios-arm64_armv7_armv7s/MobileVLCKit.framework/MobileVLCKit" && -f "$kit/ios-arm64_x86_64-simulator/MobileVLCKit.framework/MobileVLCKit" ]]; then exit 0; fi
mkdir -p .build Vendor
archive=.build/MobileVLCKit-3.7.5.tar.xz
curl -fL --retry 3 https://download.videolan.org/pub/cocoapods/prod/MobileVLCKit-3.7.5-a213fd11-6de05adc.tar.xz -o "$archive"
shasum -a 256 -c Scripts/mobilevlc.sha256
stage=$(mktemp -d "$PWD/.build/vlc.XXXXXX")
tar -xf "$archive" -C "$stage"
ditto "$stage/MobileVLCKit-binary/MobileVLCKit.xcframework" "$kit"
cp "$stage/MobileVLCKit-binary/COPYING.txt" Vendor/COPYING.txt
