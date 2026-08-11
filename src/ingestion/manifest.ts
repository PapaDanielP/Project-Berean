import { MANIFEST_COLUMNS, type ManifestColumn, type ManifestRow } from './types.js';

/**
 * Minimal deterministic RFC 4180 CSV reader. The manifest is the ingestion contract, so a
 * structural problem in the file is an error rather than a silently skipped row.
 */
const parseCsv = (text: string): string[][] => {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = '';
  let quoted = false;
  let started = false;

  const endField = (): void => {
    row.push(field);
    field = '';
    started = false;
  };
  const endRow = (): void => {
    endField();
    rows.push(row);
    row = [];
  };

  for (let index = 0; index < text.length; index += 1) {
    const character = text[index];
    if (quoted) {
      if (character === '"') {
        if (text[index + 1] === '"') {
          field += '"';
          index += 1;
        } else {
          quoted = false;
        }
      } else {
        field += character;
      }
      continue;
    }
    if (character === '"' && !started) {
      quoted = true;
      started = true;
      continue;
    }
    if (character === ',') {
      endField();
      continue;
    }
    if (character === '\r') continue;
    if (character === '\n') {
      endRow();
      continue;
    }
    field += character;
    started = true;
  }

  if (quoted) throw new Error('manifest: unterminated quoted field');
  if (field !== '' || row.length > 0) endRow();
  return rows;
};

export const parseManifest = (text: string): ManifestRow[] => {
  const rows = parseCsv(text).filter((row) => row.some((value) => value.trim() !== ''));
  if (rows.length === 0) throw new Error('manifest: file is empty');

  const header = rows[0].map((value) => value.trim());
  if (header.length !== MANIFEST_COLUMNS.length || header.some((name, index) => name !== MANIFEST_COLUMNS[index])) {
    throw new Error(`manifest: header must be exactly: ${MANIFEST_COLUMNS.join(',')}`);
  }

  return rows.slice(1).map((values, rowIndex) => {
    if (values.length !== MANIFEST_COLUMNS.length) {
      throw new Error(
        `manifest: row ${rowIndex + 2} has ${values.length} columns, expected ${MANIFEST_COLUMNS.length}`
      );
    }
    const row = {} as ManifestRow;
    MANIFEST_COLUMNS.forEach((column: ManifestColumn, index) => {
      row[column] = values[index].trim();
    });
    if (row.proposition_definition === '') row.proposition_definition = row.proposed_proposition;
    if (row.proposed_proposition === '') row.proposed_proposition = row.proposition_definition;
    if (row.predicate_code === '') row.predicate_code = row.predicate;
    if (row.predicate === '') row.predicate = row.predicate_code;
    if (row.claim_key === '' && row.candidate_key !== '') row.claim_key = `CLAIM_${row.candidate_key}`;
    if (row.claim_type_code === '' && row.review_status === 'PROPOSED_AUTO_ACCEPT') {
      row.claim_type_code = 'DIRECT_SOURCE_CLAIM';
    }
    if (row.acceptance_tier === '') {
      if (row.review_status === 'PROPOSED_AUTO_ACCEPT') row.acceptance_tier = 'AUTO_ADMISSIBLE';
      else if (row.review_status === 'REQUIRES_REVIEW') row.acceptance_tier = 'REQUIRES_HUMAN_REVIEW';
      else if (row.review_status === 'EXCLUDED') row.acceptance_tier = 'EXCLUDED';
    }
    if (row.acceptance_basis === '') {
      row.acceptance_basis =
        row.review_status === 'PROPOSED_AUTO_ACCEPT'
          ? 'Explicit source assertion with registered vocabulary and deterministic no-interpretation mapping.'
          : row.review_notes || row.exclusion_reason;
    }
    return row;
  });
};
