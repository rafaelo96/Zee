#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
if [[ $# -ne 1 || "$1" != /* || "$1" != *.app || -e "$1" ]]; then
    echo "Usage: $0 /absolute/new/path/ZeeNativeCore.app" >&2
    exit 2
fi
output_app="$1"
build_root="$(mktemp -d "${TMPDIR:-/tmp}/zee-control-plane-ios.XXXXXX")"
cleanup() { if [[ -d "$build_root" ]]; then /usr/bin/trash "$build_root"; fi; }
trap cleanup EXIT INT TERM HUP

cd "$repo_root/ZeeCore"
dotnet test tests/ZeeCore.Tests --nologo
dotnet publish src/ZeeCore.Native -c Release -r iossimulator-arm64 \
    -p:PublishAotUsingRuntimePack=true -o "$build_root/core" --nologo
cd "$repo_root"
python3 Scripts/control-plane/package-apple-core.py \
    --library "$build_root/core/ZeeCore.Native.dylib" \
    --output "$build_root/frameworks/ZeeCoreABI.framework" --platform iphonesimulator
xcodebuild -project Zee.xcodeproj -scheme ZeeMobileNativeCore -configuration Debug \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath "$build_root/DerivedData" \
    ZEE_CORE_FRAMEWORK_DIR="$build_root/frameworks" CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build
mkdir -p "$(dirname "$output_app")"
ditto "$build_root/DerivedData/Build/Products/Debug-iphonesimulator/ZeeNativeCore.app" "$output_app"
codesign --verify --deep --strict "$output_app"
echo "Built iOS Simulator app $output_app"
