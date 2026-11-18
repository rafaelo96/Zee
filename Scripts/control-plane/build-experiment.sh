#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
if [[ $# -ne 1 || "$1" != /* || "$1" != *.app || -e "$1" ]]; then
    echo "Usage: $0 /absolute/new/path/ZeeNativeCore.app" >&2
    exit 2
fi
output_app="$1"
build_root="$(mktemp -d "${TMPDIR:-/tmp}/zee-control-plane.XXXXXX")"
cleanup() { if [[ -d "$build_root" ]]; then /usr/bin/trash "$build_root"; fi; }
trap cleanup EXIT INT TERM HUP

cd "$repo_root/ZeeCore"
dotnet test tests/ZeeCore.Tests --nologo
dotnet publish src/ZeeCore.Native -c Release -r osx-arm64 -o "$build_root/core" --nologo
cd "$repo_root"
clang -std=c11 -Wall -Wextra -Werror -I ZeeContracts/include \
    ZeeContracts/tests/native_abi.c "$build_root/core/ZeeCore.Native.dylib" \
    -Wl,-rpath,"$build_root/core" -o "$build_root/native-abi"
"$build_root/native-abi"
clang++ -std=c++20 -Wall -Wextra -Werror -Wconversion -I ZeeContracts/include \
    ZeeContracts/tests/engine_abi.cc "$build_root/core/ZeeCore.Native.dylib" \
    -Wl,-rpath,"$build_root/core" -o "$build_root/engine-abi"
"$build_root/engine-abi"
xcodebuild -project Zee.xcodeproj -scheme ZeeNativeCore -configuration Debug \
    -destination 'platform=macOS' -derivedDataPath "$build_root/DerivedData" \
    ZEE_CORE_LIBRARY_DIR="$build_root/core" CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build
mkdir -p "$(dirname "$output_app")"
ditto "$build_root/DerivedData/Build/Products/Debug/ZeeNativeCore.app" "$output_app"
codesign --verify --deep --strict "$output_app"
echo "Built $output_app"
