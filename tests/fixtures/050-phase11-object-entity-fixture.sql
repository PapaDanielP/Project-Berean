-- Phase 11 bounded object/artifact entity fixture: Ark of the Covenant.
--
-- This is a validation-only canonical Entity. No source record, citation, evidence, or claim is
-- created for it in this repository: the Ark of the Covenant narrative (Exodus onward) falls
-- outside the Genesis 1-11 dataset this repository populates, and no source material for it has
-- been acquired or inspected here. Its only purpose is to demonstrate, alongside the source-backed
-- `noahs_ark` entity already added to the Genesis 1-11 fixture, that two canonical Entity records
-- which share the generic term "ark" remain distinct, that no source identity/claim/evidence for
-- one can attach to the other, and that this repository does not fabricate source-backed content
-- to fill the gap.
--
-- This fixture extends the Genesis 1-11 fixture in place and does not truncate it.
BEGIN;

INSERT INTO entity (entity_key, entity_type_code, canonical_name, description) VALUES
    ('ark_of_covenant', 'OBJECT', 'Ark of the Covenant',
     'Validation-only canonical entity. No Genesis 1-11 source record, citation, evidence, or '
     || 'claim is populated for this entity in this repository; no source text is acquired, '
     || 'inspected, or fabricated for it here. Present only to demonstrate entity distinctness '
     || 'from noahs_ark and evidence isolation between the two "ark" entities.');

COMMIT;
