#!/bin/zsh
set -euo pipefail

repository_root="${0:A:h:h}"
cd "$repository_root"

required_paths=(
  ZeeShared
  ZeeMac
  ZeeMobile
  ZeeTests
  ZeeMobileTests
  ZeeTestFixtures
  Documentation/ARCHITECTURE.md
  ZeeShared/Resources/ZeeIcon/Zee.icon
  project.yml
)

for required_path in "${required_paths[@]}"; do
  if [[ ! -e "$required_path" ]]; then
    print -u2 "Missing required Zee path: $required_path"
    exit 1
  fi
done

prototype_root="Bro""wser"
prototype_tests="${prototype_root}Tests"
prototype_ui_tests="${prototype_root}UITests"
prototype_project="${prototype_root}.xcodeproj"

if [[ -e "$prototype_root" || -e "$prototype_tests" || -e "$prototype_ui_tests" || -e "$prototype_project" ]]; then
  print -u2 "A prototype-named top-level project path still exists."
  exit 1
fi

prototype_product="cae""lura"
prototype_bundle="com.pauldavis.${prototype_root:l}"
prototype_environment="${prototype_root:u}_"
prototype_import="@testable import ${prototype_root}"

if rg -n -i \
  --glob '!Scripts/validate-identity.sh' \
  --glob '!*.xcuserstate' \
  --glob '!DerivedData/**' \
  "${prototype_product}|${prototype_bundle}|${prototype_project}|${prototype_import}" \
  .; then
  print -u2 "Prototype product identity remains in the repository."
  exit 1
fi

if rg -n \
  --glob '!Scripts/validate-identity.sh' \
  --glob '!*.xcuserstate' \
  --glob '!DerivedData/**' \
  "(^|[^[:alnum:]_])${prototype_environment}" \
  .; then
  print -u2 "Prototype launch environment remains in the repository."
  exit 1
fi

rg -q '^name: Zee$' project.yml
rg -q '^  Zee:$' project.yml
rg -q '^  ZeeMobile:$' project.yml
rg -q 'ZEE_MAC_BUNDLE_IDENTIFIER: "\$\(ZEE_BUNDLE_ID\)"$' project.yml
rg -q 'ZEE_MOBILE_BUNDLE_IDENTIFIER: "\$\(ZEE_BUNDLE_ID\)"$' project.yml
rg -q '^ZEE_PRODUCT_NAME = ' Config/Zee.xcconfig
rg -q '^ZEE_BUNDLE_ID = ' Config/Zee.xcconfig
rg -q 'PRODUCT_MODULE_NAME: Zee$' project.yml
rg -q 'PRODUCT_MODULE_NAME: ZeeMobile$' project.yml

print "Zee identity validation passed."
