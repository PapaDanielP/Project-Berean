#!/usr/bin/env sh
# Reproducibly acquire and verify the pinned STEP Bible artifacts declared in
# data/external/stepbible/ACQUISITION_MANIFEST.yaml.
#
# The upstream file-level notice asks downstream users not to redistribute the data
# themselves, so the payload is never written into tracked repository paths. It is fetched
# into an untracked working directory and verified against the recorded SHA-256 hashes.
#
# Usage: scripts/acquisition/fetch-stepbible.sh [target_directory]
#        STEPBIBLE_VERIFY_ONLY=1 scripts/acquisition/fetch-stepbible.sh [target_directory]
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
manifest="$root/data/external/stepbible/ACQUISITION_MANIFEST.yaml"
[ -f "$manifest" ] || { echo "missing acquisition manifest: $manifest" >&2; exit 1; }

# Read a scalar from the manifest. Handles both `key: value` and folded `key: >-` blocks.
manifest_value() {
    awk -v key="$1" '
        {
            line = $0
            sub(/^[ \t]+/, "", line)
            if (index(line, key ":") == 1) {
                value = substr(line, length(key) + 2)
                sub(/^[ \t]+/, "", value)
                if (value == ">-" || value == ">" || value == "|") {
                    if ((getline nextline) > 0) {
                        sub(/^[ \t]+/, "", nextline)
                        sub(/[ \t]+$/, "", nextline)
                        print nextline
                    }
                } else {
                    sub(/[ \t]+$/, "", value)
                    print value
                }
                exit
            }
        }
    ' "$manifest"
}

commit=$(manifest_value pinned_commit)
url_prefix=$(manifest_value raw_url_prefix)
encoded_path=$(manifest_value url_encoded_path)
artifact_rel=$(manifest_value local_artifact_path)
artifact_sha=$(manifest_value sha256)
record_locator=$(manifest_value locator)
record_sha=$(awk '/^records:/ { in_records = 1 } in_records && /sha256:/ { print $2; exit }' "$manifest")
record_rows=$(awk '/^records:/ { in_records = 1 } in_records && /row_count:/ { print $2; exit }' "$manifest")

for required in "$commit" "$url_prefix" "$encoded_path" "$artifact_rel" "$artifact_sha" \
                "$record_locator" "$record_sha" "$record_rows"; do
    [ -n "$required" ] || { echo "acquisition manifest is missing a required field" >&2; exit 1; }
done

target_root=${1:-"$root"}
artifact="$target_root/$artifact_rel"
mkdir -p "$(dirname -- "$artifact")"

sha_of() { sha256sum "$1" | cut -d' ' -f1; }

if [ -f "$artifact" ] && [ "$(sha_of "$artifact")" = "$artifact_sha" ]; then
    echo "ok: artifact already present and hash-verified: $artifact"
elif [ "${STEPBIBLE_VERIFY_ONLY:-0}" = "1" ]; then
    echo "acquisition-pending: $artifact is absent or does not match the recorded hash" >&2
    exit 1
else
    echo "fetching pinned artifact at commit $commit"
    curl --fail --silent --show-error --location \
        --output "$artifact" "${url_prefix}${encoded_path}"
    actual=$(sha_of "$artifact")
    if [ "$actual" != "$artifact_sha" ]; then
        echo "hash mismatch for $artifact: expected $artifact_sha, got $actual" >&2
        exit 1
    fi
    echo "ok: fetched and hash-verified $artifact"
fi

# Verify the imported record subset without writing any upstream payload to disk.
record_actual=$(awk -F'\t' -v prefix="$record_locator#" \
    'index($1, prefix) == 1' "$artifact" | sha256sum | cut -d' ' -f1)
record_actual_rows=$(awk -F'\t' -v prefix="$record_locator#" \
    'index($1, prefix) == 1' "$artifact" | wc -l | tr -d ' ')

if [ "$record_actual" != "$record_sha" ]; then
    echo "record hash mismatch for $record_locator: expected $record_sha, got $record_actual" >&2
    exit 1
fi
if [ "$record_actual_rows" != "$record_rows" ]; then
    echo "record row-count mismatch for $record_locator: expected $record_rows, got $record_actual_rows" >&2
    exit 1
fi
echo "ok: source record $record_locator verified ($record_actual_rows rows, sha256 $record_sha)"
echo "attribution: Data from STEP Bible (www.STEPBible.org), based on work at Tyndale House, Cambridge, licensed CC BY 4.0."
echo "note: upstream asks that the data not be redistributed; refer others to github.com/STEPBible."
