#!/bin/zsh
# Regenerates the contract codecs and models from the C# contract records, the
# core's ZeeCore.Contracts namespace: the core's ContractCodec, the two Swift
# files under ZeeShared/Infrastructure/Core/Generated,
# ZeeContracts/include/zee_contracts.h and the C++ engine codec
# ZeeContracts/include/zee_engine_contract.h. Pass --check to verify that
# they are current without writing anything.
set -euo pipefail

repository_root="${0:A:h:h:h}"
dotnet run --project "$repository_root/ZeeCore/tools/ZeeCore.Generator" --nologo -- --root "$repository_root" "$@"
