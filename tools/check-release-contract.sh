#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(tr -d '[:space:]' < "$root/VERSION")"
protocol="$(tr -d '[:space:]' < "$root/PROTOCOL_VERSION")"
firmware_version="$(sed -n 's/^#define DESK_FW_VERSION "\([0-9][0-9.]*\)"$/\1/p' "$root/firmware/notchagent_desk/config.h")"
protocol_minor="$(sed -n 's/^#define DESK_PROTOCOL_MINOR \([0-9][0-9]*\)$/\1/p' "$root/firmware/notchagent_desk/config.h")"
protocol_major="$(sed -n 's/^constexpr uint8_t kProtocolMajor = \([0-9][0-9]*\);$/\1/p' "$root/firmware/notchagent_desk/desk_protocol.h")"

[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]] || {
  echo "Invalid SemVer in VERSION: $version" >&2
  exit 1
}
[[ "$firmware_version" == "$version" ]] || {
  echo "VERSION $version does not match firmware $firmware_version" >&2
  exit 1
}
[[ "$protocol" == "$protocol_major.$protocol_minor" ]] || {
  echo "PROTOCOL_VERSION $protocol does not match firmware $protocol_major.$protocol_minor" >&2
  exit 1
}

for required in README.md CHANGELOG.md VERSIONING.md COMPATIBILITY.md SECURITY.md protocol/PROTOCOL.md; do
  [[ -s "$root/$required" ]] || { echo "Missing required contract: $required" >&2; exit 1; }
done

grep -Fq "## [$version]" "$root/CHANGELOG.md" || {
  echo "CHANGELOG.md has no release entry for $version" >&2
  exit 1
}
grep -Fq "| $version | $protocol |" "$root/COMPATIBILITY.md" || {
  echo "COMPATIBILITY.md has no row for firmware $version and protocol $protocol" >&2
  exit 1
}

if rg -n --hidden --glob '!.git/**' --glob '!tools/check-release-contract.sh' \
  '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|ANTHROPIC_AUTH_TOKEN=|OPENAI_API_KEY=)' "$root"; then
  echo "Potential secret found in repository" >&2
  exit 1
fi

echo "PASS: NotchAgent Desk $version · protocol $protocol release contract"
