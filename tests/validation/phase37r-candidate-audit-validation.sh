#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"

python3 - "$root" <<'PY'
import csv
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
candidate_path = root / "data/candidates/phase37r-worlds-columbian-exposition-candidates.csv"
source_path = root / "data/candidates/phase37r-worlds-columbian-exposition-source-review.csv"

with candidate_path.open(newline="", encoding="utf-8") as handle:
    candidates = list(csv.DictReader(handle))
with source_path.open(newline="", encoding="utf-8") as handle:
    sources = list(csv.DictReader(handle))

assert len(candidates) == 33, f"phase37r: expected 33 candidates, found {len(candidates)}"
assert sum(row["selection_status"] == "SELECTED" for row in candidates) == 20
assert sum(row["selection_status"] == "EXCLUDED" for row in candidates) == 13
required_categories = {"PERSON", "ORGANIZATION", "EVENT", "EXHIBIT", "TECHNOLOGY", "RELATIONSHIP"}
assert {row["candidate_category"] for row in candidates} == required_categories
assert all(row["rationale"] for row in candidates)
assert all(row["discovery_source_references"] for row in candidates)
assert all(row["verification_status"] for row in candidates)

roles = {row["source_role"] for row in sources}
assert len(sources) == 8
assert "DISCOVERY_ONLY" in roles
assert "PRIMARY_OFFICIAL" in roles
assert "PRIMARY_CONTEMPORARY_TECHNICAL" in roles
assert "PRIMARY_CONTEMPORARY_TRADE" in roles
assert sum(role == "SCHOLARLY_INTERPRETATION" for role in roles) == 1
assert all(row["access_date"] == "2026-08-11" for row in sources)

for key in ("P37R_PERSON_TESLA", "P37R_PERSON_WESTINGHOUSE"):
    row = next(candidate for candidate in candidates if candidate["candidate_key"] == key)
    assert row["discovery_source_references"]
    assert row["verification_source_references"]
tesla = next(candidate for candidate in candidates if candidate["candidate_key"] == "P37R_PERSON_TESLA")
westinghouse = next(candidate for candidate in candidates if candidate["candidate_key"] == "P37R_PERSON_WESTINGHOUSE")
assert tesla["selection_status"] == "SELECTED" and tesla["verification_status"].startswith("VERIFIED")
assert westinghouse["selection_status"] == "EXCLUDED"
assert westinghouse["verification_status"] == "REQUIRES_PAGE_VERIFICATION"

implementation = "\n".join(
    path.read_text(encoding="utf-8")
    for path in (
        root / "tests/fixtures/145-phase37r-worlds-columbian-exposition-expanded-population-fixture.sql",
        root / "tests/validation/phase37r-worlds-columbian-exposition-population-validation.sql",
    )
)
assert not re.search(r"\b(?:IF|CASE)\b[^\n]*(?:TESLA|WESTINGHOUSE)", implementation, re.IGNORECASE), \
    "phase37r: person-specific selection branch found"

print("ok: Phase 37R candidate audit has 33 discovered, 20 selected, 13 excluded candidates across all required categories")
print("ok: Tesla and Westinghouse carry ordinary discovery and verification fields; their differing dispositions follow verification status, not selection branches")
PY
