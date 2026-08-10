#!/usr/bin/env sh
# Acquisition-manifest integrity checks for the STEP Bible external source.
#
# These checks are offline and do not require the acquired artifact to be present. They assert
# that the recorded acquisition metadata stays internally consistent, that the pinned revision and
# attribution are preserved, and that no upstream payload was committed to the repository.
#
# If the acquired artifact is present locally, its hashes are re-verified as well.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
manifest="$root/data/external/stepbible/ACQUISITION_MANIFEST.yaml"
declaration="$root/data/external/stepbible/MANIFEST.yaml"
inspection="$root/data/external/stepbible/INSPECTION.md"
fixture="$root/tests/fixtures/040-stepbible-genesis-source-fixture.sql"
pinned_commit=b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39
failures=0

check() {
    if [ "$1" = "0" ]; then
        echo "ok: $2"
    else
        echo "FAIL: $2"
        failures=$((failures + 1))
    fi
}

contains() {
    grep -qF -- "$2" "$1" && echo 0 || echo 1
}

for required in "$manifest" "$declaration" "$inspection" "$fixture"; do
    [ -f "$required" ] || { echo "FAIL: missing required file: $required"; exit 1; }
done

# The pinned revision is identical across the declaration, the acquisition manifest, the
# inspection record, and the imported fixture.
for file in "$declaration" "$manifest" "$inspection" "$fixture"; do
    check "$(contains "$file" "$pinned_commit")" "pinned commit recorded in ${file#"$root/"}"
done

# Acquisition metadata required for an auditable record.
for field in upstream_path local_artifact_path size_bytes sha256 acquired_on \
             source_locator_format file_level_license attribution_text redistribution \
             selection_reason transformation; do
    check "$(contains "$manifest" "$field:")" "acquisition manifest records $field"
done

# Attribution and license notices are preserved wherever the source is described.
for file in "$manifest" "$declaration" "$inspection" \
            "$root/data/external/stepbible/README.md" \
            "$root/data/external/stepbible/SOURCE_METADATA.md" "$fixture"; do
    check "$(contains "$file" "STEPBible.org")" "STEP Bible attribution present in ${file#"$root/"}"
    check "$(contains "$file" "Tyndale House")" "Tyndale House attribution present in ${file#"$root/"}"
done
check "$(contains "$manifest" "Please do not")" \
    "acquisition manifest preserves the file-level redistribution condition"
check "$(contains "$manifest" "not_redistributed")" \
    "acquisition manifest records the redistribution decision"

# Recorded hashes are well-formed SHA-256 digests.
bad_hashes=$(awk '/sha256:/ { if ($2 !~ /^[0-9a-f]{64}$/) print $2 }' "$manifest" | wc -l | tr -d ' ')
check "$([ "$bad_hashes" = "0" ] && echo 0 || echo 1)" "all recorded hashes are well-formed SHA-256 digests"

# Hashes recorded in the manifest match the hashes imported by the fixture.
record_sha=$(awk '/^records:/ { r = 1 } r && /sha256:/ { print $2; exit }' "$manifest")
check "$([ -n "$record_sha" ] && echo 0 || echo 1)" "acquisition manifest records the imported record hash"
check "$(contains "$fixture" "$record_sha")" "imported fixture uses the manifest record hash"

# No upstream payload is tracked in the repository.
if git -C "$root" ls-files --error-unmatch .acquired >/dev/null 2>&1; then
    check 1 "acquired artifact workspace is untracked"
else
    check 0 "acquired artifact workspace is untracked"
fi
check "$(grep -q '^\.acquired/$' "$root/.gitignore" && echo 0 || echo 1)" \
    "acquired artifact workspace is ignored by git"

tracked_payload=$(git -C "$root" ls-files -- 'data/external/stepbible' \
    | grep -Ev '(MANIFEST\.yaml|ACQUISITION_MANIFEST\.yaml|SOURCE_METADATA\.md|INSPECTION\.md|README\.md)$' \
    | wc -l | tr -d ' ')
check "$([ "$tracked_payload" = "0" ] && echo 0 || echo 1)" \
    "no upstream payload file is tracked under data/external/stepbible"

# Optional: if the artifact has been acquired locally, re-verify it against the manifest.
artifact="$root/.acquired/stepbible/TAHOT_Gen-Deu.txt"
if [ -f "$artifact" ]; then
    if STEPBIBLE_VERIFY_ONLY=1 "$root/scripts/acquisition/fetch-stepbible.sh" >/dev/null 2>&1; then
        check 0 "locally acquired artifact matches the recorded hashes"
    else
        check 1 "locally acquired artifact matches the recorded hashes"
    fi
else
    echo "skip: acquired artifact is not present locally; hash re-verification skipped"
fi

if [ "$failures" -ne 0 ]; then
    echo "STEP Bible acquisition manifest checks failed: $failures"
    exit 1
fi
echo "All STEP Bible acquisition manifest checks passed."
