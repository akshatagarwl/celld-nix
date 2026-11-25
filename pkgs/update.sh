#!/usr/bin/env bash
# Bump pkgs/sources.json to the latest (or given) denoland/celld release.
# Usage: nix run .#update [-- VERSION]   (run from the repository root)
set -euo pipefail

sources=pkgs/sources.json
[[ -f $sources ]] || {
  echo "run from the repository root ($sources not found)" >&2
  exit 1
}

version=${1:-}
if [[ -z $version ]]; then
  version=$(curl -fsSL https://api.github.com/repos/denoland/celld/releases/latest | jq -r .tag_name)
fi
version=${version#v}

current=$(jq -r .version "$sources")
if [[ $version == "$current" ]]; then
  echo "celld is already at $version"
  exit 0
fi

base="https://github.com/denoland/celld/releases/download/v$version"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
jq --arg v "$version" '.version = $v' "$sources" > "$tmp"

for key in $(jq -r '.assets | keys[]' "$sources"); do
  name=$(jq -r --arg k "$key" '.assets[$k].name' "$sources")
  hash=$(nix store prefetch-file --json "$base/$name" | jq -r .hash)
  echo "$key: $name $hash"
  jq --arg k "$key" --arg h "$hash" '.assets[$k].hash = $h' "$tmp" > "$tmp.next"
  mv "$tmp.next" "$tmp"
done

cp "$tmp" "$sources"
echo "celld $current -> $version"
