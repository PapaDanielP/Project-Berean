import { createHash } from 'node:crypto';
import type { AuthenticatedActor } from '../auth.js';
import { AdministrationRepository } from './repository.js';

type Values = Record<string, unknown>;

export class AdministrationError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string
  ) {
    super(message);
  }
}

const text = (value: unknown, field: string, max = 1000): string => {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max) {
    throw new AdministrationError(400, 'INVALID_REQUEST', `${field} must be a non-empty string of at most ${max} characters.`);
  }
  return value.trim();
};

const optionalText = (value: unknown, field: string, max = 2000): string | undefined =>
  value === undefined || value === null ? undefined : text(value, field, max);

const identifier = (value: unknown, field: string): number => {
  if (typeof value !== 'number' || !Number.isSafeInteger(value) || value <= 0) {
    throw new AdministrationError(400, 'INVALID_REQUEST', `${field} must be a positive integer.`);
  }
  return value;
};

const oneOf = <T extends string>(value: unknown, field: string, allowed: readonly T[]): T => {
  if (typeof value !== 'string' || !allowed.includes(value as T)) {
    throw new AdministrationError(400, 'INVALID_REQUEST', `${field} must be one of: ${allowed.join(', ')}.`);
  }
  return value as T;
};

const key = (value: unknown, field: string): string => {
  const result = text(value, field, 120);
  if (!/^[A-Za-z0-9][A-Za-z0-9_.:-]*$/.test(result)) {
    throw new AdministrationError(400, 'INVALID_REQUEST', `${field} contains unsupported characters.`);
  }
  return result;
};

const idempotencyKey = (value: unknown): string => key(value, 'Idempotency-Key');
const fingerprint = (value: Values): string =>
  createHash('sha256').update(JSON.stringify(value)).digest('hex');

export class AdministrationService {
  constructor(private readonly repository: AdministrationRepository) {}

  createCorpus(body: Values, actor: AuthenticatedActor, correlationId: string) {
    return this.repository.createCorpus({
      key: key(body.key, 'key'),
      name: text(body.name, 'name', 300),
      description: optionalText(body.description, 'description'),
      scopeNote: text(body.scopeNote, 'scopeNote', 4000)
    }, actor, correlationId);
  }

  updateCorpus(id: number, version: number, body: Values, actor: AuthenticatedActor, correlationId: string) {
    return this.repository.updateCorpus(id, version, {
      name: optionalText(body.name, 'name', 300),
      description: optionalText(body.description, 'description'),
      scopeNote: optionalText(body.scopeNote, 'scopeNote', 4000),
      status: body.status === undefined ? undefined : oneOf(body.status, 'status', ['DRAFT', 'ACTIVE', 'ARCHIVED'] as const)
    }, actor, correlationId);
  }

  createTopic(body: Values, actor: AuthenticatedActor, correlationId: string) {
    return this.repository.createTopic({
      corpusId: identifier(body.corpusId, 'corpusId'),
      key: key(body.key, 'key'),
      question: text(body.question, 'question', 2000),
      scopeNote: text(body.scopeNote, 'scopeNote', 4000)
    }, actor, correlationId);
  }

  createDiscovery(body: Values, requestIdempotencyKey: unknown, actor: AuthenticatedActor, correlationId: string) {
    const requestedTypes = body.requestedTypes;
    if (!Array.isArray(requestedTypes) || requestedTypes.length > 10) {
      throw new AdministrationError(400, 'INVALID_REQUEST', 'requestedTypes must be an array of at most 10 values.');
    }
    const request: Values = {
      corpusId: identifier(body.corpusId, 'corpusId'),
      researchTopicId: body.researchTopicId === undefined ? undefined : identifier(body.researchTopicId, 'researchTopicId'),
      requestKind: oneOf(body.requestKind, 'requestKind', ['SOURCE_DISCOVERY', 'CANDIDATE_DISCOVERY', 'GAP_DISCOVERY'] as const),
      queryText: text(body.queryText, 'queryText', 2000),
      boundedScope: text(body.boundedScope, 'boundedScope', 4000),
      requestedTypes: requestedTypes.map((value, index) => oneOf(value, `requestedTypes[${index}]`, [
        'PERSON', 'ORGANIZATION', 'PLACE', 'EVENT', 'DOCUMENT', 'TECHNOLOGY',
        'CONCEPT', 'RELATIONSHIP', 'SOURCE_IDENTITY', 'SOURCE'
      ] as const)),
      idempotencyKey: idempotencyKey(requestIdempotencyKey)
    };
    request.requestFingerprint = fingerprint(request);
    return this.repository.createDiscovery(request, actor, correlationId);
  }

  addCandidate(requestId: number, body: Values, actor: AuthenticatedActor, correlationId: string) {
    return this.repository.addCandidate(requestId, {
      key: key(body.key, 'key'),
      type: oneOf(body.type, 'type', [
        'PERSON', 'ORGANIZATION', 'PLACE', 'EVENT', 'DOCUMENT', 'TECHNOLOGY',
        'CONCEPT', 'RELATIONSHIP', 'SOURCE_IDENTITY', 'SOURCE'
      ] as const),
      label: text(body.label, 'label', 500),
      description: optionalText(body.description, 'description'),
      representationStatus: body.representationStatus === undefined ? undefined : oneOf(
        body.representationStatus, 'representationStatus',
        ['UNREVIEWED', 'REPRESENTABLE', 'NOT_REPRESENTED', 'DUPLICATE', 'EXCLUDED'] as const
      ),
      obstacleClassification: body.obstacleClassification === undefined ? undefined : oneOf(
        body.obstacleClassification, 'obstacleClassification',
        ['QUERY', 'DATA_ENTRY', 'REGISTRY_EXPRESSIVENESS', 'DOMAIN_SCOPING_LIMITATION', 'ARCHITECTURAL_DEFICIENCY'] as const
      ),
      proposedPredicate: optionalText(body.proposedPredicate, 'proposedPredicate', 120),
      discoveryLocator: text(body.discoveryLocator, 'discoveryLocator', 2000)
    }, actor, correlationId);
  }

  reviewCandidate(candidateId: number, body: Values, actor: AuthenticatedActor, correlationId: string) {
    return this.repository.reviewCandidate(candidateId, {
      decision: oneOf(body.decision, 'decision', ['APPROVED', 'REJECTED', 'NEEDS_SOURCE_VERIFICATION', 'NOT_REPRESENTED'] as const),
      rationale: text(body.rationale, 'rationale', 4000)
    }, actor, correlationId);
  }

  registerSource(body: Values, actor: AuthenticatedActor, correlationId: string) {
    return this.repository.registerSource({
      corpusId: identifier(body.corpusId, 'corpusId'),
      sourceKey: key(body.sourceKey, 'sourceKey'),
      sourceName: text(body.sourceName, 'sourceName', 500),
      sourceType: key(body.sourceType, 'sourceType'),
      description: optionalText(body.description, 'description'),
      datasetKey: key(body.datasetKey, 'datasetKey'),
      datasetName: text(body.datasetName, 'datasetName', 500),
      editionLabel: optionalText(body.editionLabel, 'editionLabel', 500),
      version: optionalText(body.version, 'version', 200),
      licenseStatus: text(body.licenseStatus, 'licenseStatus', 500),
      acquisitionMethod: text(body.acquisitionMethod, 'acquisitionMethod', 500)
    }, actor, correlationId);
  }

  createSourceRecord(body: Values, actor: AuthenticatedActor, correlationId: string) {
    const rawContent = optionalText(body.rawContent, 'rawContent', 10000);
    const contentHash = body.contentHash === undefined ? undefined : text(body.contentHash, 'contentHash', 64);
    if (rawContent && (!contentHash || !/^[0-9a-f]{64}$/.test(contentHash))) {
      throw new AdministrationError(400, 'INVALID_REQUEST', 'rawContent requires a lowercase SHA-256 contentHash.');
    }
    return this.repository.createSourceRecord({
      datasetId: identifier(body.datasetId, 'datasetId'),
      key: key(body.key, 'key'),
      sourceLocation: text(body.sourceLocation, 'sourceLocation', 2000),
      rawContent,
      contentHash,
      revisionLabel: optionalText(body.revisionLabel, 'revisionLabel', 200),
      citationKey: key(body.citationKey, 'citationKey'),
      locator: text(body.locator, 'locator', 2000),
      quotedText: optionalText(body.quotedText, 'quotedText', 10000)
    }, actor, correlationId);
  }

  createEvidence(body: Values, actor: AuthenticatedActor, correlationId: string) {
    if (!Array.isArray(body.citationIds) || body.citationIds.length < 1 || body.citationIds.length > 100) {
      throw new AdministrationError(400, 'INVALID_REQUEST', 'citationIds must contain 1 to 100 identifiers.');
    }
    return this.repository.createEvidence({
      key: key(body.key, 'key'),
      sourceRecordId: identifier(body.sourceRecordId, 'sourceRecordId'),
      observation: text(body.observation, 'observation', 10000),
      evidenceType: oneOf(body.evidenceType, 'evidenceType', ['SOURCE_OBSERVATION', 'ANALYTICAL_OBSERVATION'] as const),
      notes: optionalText(body.notes, 'notes', 4000),
      citationIds: body.citationIds.map((value, index) => identifier(value, `citationIds[${index}]`))
    }, actor, correlationId);
  }

  createClaim(body: Values, actor: AuthenticatedActor, correlationId: string) {
    if (!Array.isArray(body.evidenceIds) || body.evidenceIds.length < 1 || body.evidenceIds.length > 100) {
      throw new AdministrationError(400, 'INVALID_REQUEST', 'evidenceIds must contain 1 to 100 identifiers.');
    }

    const subjectEntityId = body.subjectEntityId === undefined ? undefined : identifier(body.subjectEntityId, 'subjectEntityId');
    const subjectEventId = body.subjectEventId === undefined ? undefined : identifier(body.subjectEventId, 'subjectEventId');
    const objectEntityId = body.objectEntityId === undefined ? undefined : identifier(body.objectEntityId, 'objectEntityId');
    const objectEventId = body.objectEventId === undefined ? undefined : identifier(body.objectEventId, 'objectEventId');
    const objectTypedValueId = body.objectTypedValueId === undefined ? undefined : identifier(body.objectTypedValueId, 'objectTypedValueId');
    if (Number(subjectEntityId !== undefined) + Number(subjectEventId !== undefined) !== 1 ||
        Number(objectEntityId !== undefined) + Number(objectEventId !== undefined) + Number(objectTypedValueId !== undefined) !== 1) {
      throw new AdministrationError(400, 'INVALID_PROPOSITION', 'Exactly one subject and one object are required.');
    }
    const claimType = oneOf(body.claimType, 'claimType', ['DIRECT_SOURCE_CLAIM', 'INTERPRETIVE_CLAIM', 'DERIVED_CLAIM'] as const);
    const derivationId = body.derivationId === undefined ? undefined : identifier(body.derivationId, 'derivationId');
    if (claimType === 'DERIVED_CLAIM' && derivationId === undefined) {
      throw new AdministrationError(422, 'DERIVATION_REQUIRED', 'A derived claim requires a derivation with explicit inputs.');
    }
    if (claimType !== 'DERIVED_CLAIM' && derivationId !== undefined) {
      throw new AdministrationError(422, 'DERIVATION_NOT_ALLOWED', 'A non-derived claim cannot reference a derivation.');
    }
    return this.repository.createClaim({
      key: key(body.key, 'key'),
      predicate: key(body.predicate, 'predicate'),
      subjectEntityId, subjectEventId, objectEntityId, objectEventId, objectTypedValueId,
      claimType,
      status: body.status === undefined ? 'UNDER_REVIEW' : oneOf(body.status, 'status', ['ACTIVE', 'UNDER_REVIEW'] as const),
      statement: optionalText(body.statement, 'statement', 4000),
      notes: optionalText(body.notes, 'notes', 4000),
      derivationId,
      evidenceIds: body.evidenceIds.map((value, index) => identifier(value, `evidenceIds[${index}]`)),
      evidenceRelation: body.evidenceRelation === undefined ? 'SUPPORTS' : oneOf(
        body.evidenceRelation, 'evidenceRelation', ['SUPPORTS', 'CONTRADICTS', 'QUALIFIES'] as const
      )
    }, actor, correlationId);
  }

  createIdentityMapping(body: Values, actor: AuthenticatedActor, correlationId: string) {
    if (typeof body.confidence !== 'number' || body.confidence < 0 || body.confidence > 1) {
      throw new AdministrationError(400, 'INVALID_REQUEST', 'confidence must be a number between 0 and 1.');
    }
    return this.repository.createIdentityMapping({
      sourceIdentityId: identifier(body.sourceIdentityId, 'sourceIdentityId'),
      entityId: identifier(body.entityId, 'entityId'),
      confidence: body.confidence,
      justification: text(body.justification, 'justification', 4000),
      notes: optionalText(body.notes, 'notes', 4000),
      supportingEvidenceId: identifier(body.supportingEvidenceId, 'supportingEvidenceId')
    }, actor, correlationId);
  }

  reviewIdentityMapping(mappingId: number, body: Values, actor: AuthenticatedActor, correlationId: string) {
    return this.repository.reviewIdentityMapping(mappingId, {
      status: oneOf(body.status, 'status', ['ACTIVE', 'REJECTED'] as const),
      rationale: text(body.rationale, 'rationale', 4000)
    }, actor, correlationId);
  }

  createDerivation(body: Values, actor: AuthenticatedActor, correlationId: string) {
    if (!Array.isArray(body.inputs) || body.inputs.length < 1 || body.inputs.length > 100) {
      throw new AdministrationError(400, 'INVALID_REQUEST', 'inputs must contain 1 to 100 claim or evidence references.');
    }
    const inputs = body.inputs.map((raw, index) => {
      if (!raw || typeof raw !== 'object') {
        throw new AdministrationError(400, 'INVALID_REQUEST', `inputs[${index}] must be an object.`);
      }
      const entry = raw as Values;
      const claimId = entry.claimId === undefined ? undefined : identifier(entry.claimId, `inputs[${index}].claimId`);
      const evidenceId = entry.evidenceId === undefined ? undefined : identifier(entry.evidenceId, `inputs[${index}].evidenceId`);
      if (Number(claimId !== undefined) + Number(evidenceId !== undefined) !== 1) {
        throw new AdministrationError(400, 'INVALID_REQUEST', `inputs[${index}] must contain exactly one claimId or evidenceId.`);
      }
      return { claimId, evidenceId, notes: optionalText(entry.notes, `inputs[${index}].notes`, 2000) };
    });
    return this.repository.createDerivation({
      method: text(body.method, 'method', 4000),
      assumptions: text(body.assumptions, 'assumptions', 4000),
      inputs
    }, actor, correlationId);
  }

  createJob(type: 'INGESTION' | 'VALIDATION' | 'EXPORT', body: Values, header: unknown, actor: AuthenticatedActor, correlationId: string) {
    const common: Values = {
      idempotencyKey: idempotencyKey(header),
      corpusId: body.corpusId === undefined ? undefined : identifier(body.corpusId, 'corpusId')
    };
    if (type === 'INGESTION') Object.assign(common, {
      sourceId: body.sourceId === undefined ? undefined : identifier(body.sourceId, 'sourceId'),
      candidateId: body.candidateId === undefined ? undefined : identifier(body.candidateId, 'candidateId'),
      transactionPolicy: body.transactionPolicy === undefined ? 'ATOMIC' : oneOf(body.transactionPolicy, 'transactionPolicy', ['ATOMIC', 'SAVEPOINT_PER_ITEM'] as const),
      partialFailurePolicy: body.partialFailurePolicy === undefined ? 'ROLLBACK_ALL' : oneOf(body.partialFailurePolicy, 'partialFailurePolicy', ['ROLLBACK_ALL', 'RETAIN_SUCCESSES'] as const)
    });
    if (type === 'VALIDATION') {
      if (!Array.isArray(body.validationTypes) || body.validationTypes.length < 1) {
        throw new AdministrationError(400, 'INVALID_REQUEST', 'validationTypes must not be empty.');
      }
      common.validationTypes = body.validationTypes.map((value, index) => oneOf(value, `validationTypes[${index}]`, [
        'SCHEMA', 'PROVENANCE', 'REGISTRY', 'IDENTITY', 'CLAIM', 'EVIDENCE',
        'DERIVATION', 'CORPUS', 'REPLAY', 'READ_ONLY', 'NEGATIVE_SEMANTIC'
      ] as const));
    }
    if (type === 'EXPORT') {
      const supportedFields = new Set(['corpusId', 'format', 'includeRawContent', 'reproducibilityNote']);
      if (Object.keys(body).some((field) => !supportedFields.has(field))) {
        throw new AdministrationError(400, 'INVALID_REQUEST', 'Export requests accept only the documented bounded fields and never accept paths or destinations.');
      }
      if (body.includeRawContent !== undefined && typeof body.includeRawContent !== 'boolean') {
        throw new AdministrationError(400, 'INVALID_REQUEST', 'includeRawContent must be a boolean.');
      }
      Object.assign(common, {
        corpusId: identifier(body.corpusId, 'corpusId'),
        format: oneOf(body.format, 'format', ['JSONL', 'CSV'] as const),
        includeRawContent: body.includeRawContent === true,
        reproducibilityNote: text(body.reproducibilityNote, 'reproducibilityNote', 4000)
      });
    }
    common.requestFingerprint = fingerprint(common);
    return this.repository.createJob(type, common, actor, correlationId);
  }
}
