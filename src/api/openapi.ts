// The OpenAPI document is derived from the implemented route surface in
// `src/app.ts`, `src/api/v1.ts`, and `src/administration/routes.ts`.
// `tests/app/openapi-coverage.test.ts` fails if a route is implemented but undocumented,
// or documented but not implemented.

type Values = Record<string, unknown>;

const READ_RESOURCES = [
  'entities', 'events', 'claims', 'evidence', 'sources', 'datasets',
  'source-records', 'citations', 'identities', 'identity-mappings'
];

const SEARCH_RESOURCES = [
  'entities', 'events', 'claims', 'propositions', 'evidence', 'sources',
  'datasets', 'source-records', 'citations', 'identities'
];

const REGISTRIES = ['predicates', 'entity-types', 'event-types', 'claim-types', 'evidence-types', 'mapping-statuses'];

const ADMIN_RESOURCES = ['corpora', 'topics', 'discoveries', 'candidates', 'jobs', 'validations', 'audits', 'exports'];

const CANDIDATE_TYPES = [
  'PERSON', 'ORGANIZATION', 'PLACE', 'EVENT', 'DOCUMENT', 'TECHNOLOGY',
  'CONCEPT', 'RELATIONSHIP', 'SOURCE_IDENTITY', 'SOURCE'
];

const jsonResponse = (description: string, schema: Values = { type: 'object' }): Values => ({
  description,
  content: { 'application/json': { schema } }
});

const errorRef = (...codes: string[]): Values =>
  Object.fromEntries(codes.map((code) => [code, { $ref: `#/components/responses/${errorResponses[code]}` }]));

const errorResponses: Record<string, string> = {
  '400': 'InvalidRequest',
  '401': 'Unauthenticated',
  '403': 'Forbidden',
  '404': 'NotFound',
  '409': 'Conflict',
  '422': 'Unprocessable',
  '500': 'InternalError',
  '501': 'NotRepresented',
  '503': 'AuthNotConfigured'
};

const body = (schema: string): Values => ({
  required: true,
  content: { 'application/json': { schema: { $ref: `#/components/schemas/${schema}` } } }
});

const requiredString = (maxLength: number, description: string): Values => ({ type: 'string', minLength: 1, maxLength, description });

const object = (properties: Values, required: string[], description: string): Values => ({
  type: 'object',
  additionalProperties: false,
  description,
  required,
  properties
});

const idempotencyHeader: Values = {
  name: 'Idempotency-Key',
  in: 'header',
  required: true,
  description: 'Stable client key. Replay with the same fingerprint returns the same job; a different fingerprint returns 409 IDEMPOTENCY_CONFLICT.',
  schema: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 }
};

const correlationHeader: Values = {
  name: 'X-Correlation-Id',
  in: 'header',
  required: false,
  description: 'Optional UUID correlating the request with persisted audit events. A UUID is generated when absent and always echoed in the response.',
  schema: { type: 'string', format: 'uuid' }
};

const correlationResponseHeader: Values = {
  'X-Correlation-Id': { schema: { type: 'string', format: 'uuid' }, description: 'Correlation identifier recorded on audit events.' }
};

const limitParameter = (description: string): Values => ({
  name: 'limit',
  in: 'query',
  required: false,
  description,
  schema: { type: 'integer', minimum: 1, maximum: 100, default: 50 }
});

const positiveIdParameter = (name: string): Values => ({
  name,
  in: 'path',
  required: true,
  schema: { type: 'integer', minimum: 1 }
});

interface WriteOperation {
  operationId: string;
  summary: string;
  description: string;
  role: string;
  status: number;
  statusDescription: string;
  schema?: string;
  parameters?: Values[];
  errors: string[];
  mutation: string;
  audit: boolean;
  epistemic: string;
  transaction?: string;
}

const writeOperation = (operation: WriteOperation): Values => ({
  tags: ['administration'],
  operationId: operation.operationId,
  summary: operation.summary,
  description: operation.description,
  security: [{ bearerAuth: [] }],
  parameters: [correlationHeader, ...(operation.parameters ?? [])],
  ...(operation.schema ? { requestBody: body(operation.schema) } : {}),
  responses: {
    [String(operation.status)]: {
      ...jsonResponse(operation.statusDescription),
      headers: correlationResponseHeader
    },
    ...errorRef(...operation.errors)
  },
  'x-berean-minimum-role': operation.role,
  'x-berean-write': true,
  'x-berean-persistence': operation.mutation,
  'x-berean-transaction': operation.transaction ?? 'Single database transaction; any failure rolls the whole request back.',
  'x-berean-audit': operation.audit ? 'Appends an immutable audit_event row inside the same transaction.' : 'None.',
  'x-berean-epistemic-boundary': operation.epistemic
});

const readOperation = (operation: {
  operationId: string;
  summary: string;
  description: string;
  parameters?: Values[];
  responseDescription: string;
  responseSchema?: Values;
  errors?: string[];
  additionalResponses?: Values;
  tag?: string;
  role?: string;
}): Values => ({
  tags: [operation.tag ?? 'read'],
  operationId: operation.operationId,
  summary: operation.summary,
  description: operation.description,
  ...(operation.role ? { security: [{ bearerAuth: [] }] } : {}),
  ...(operation.parameters ? { parameters: operation.parameters } : {}),
  responses: {
    '200': jsonResponse(operation.responseDescription, operation.responseSchema ?? { type: 'object' }),
    ...(operation.additionalResponses ?? {}),
    ...errorRef(...(operation.errors ?? ['500']))
  },
  ...(operation.role ? { 'x-berean-minimum-role': operation.role } : {}),
  'x-berean-write': false,
  'x-berean-persistence': 'None. Read routes never mutate persisted state.'
});

const errorSchema: Values = object(
  {
    error: object(
      {
        code: { type: 'string', description: 'Stable machine-readable Berean error code.' },
        message: { type: 'string' }
      },
      ['code', 'message'],
      'Error detail.'
    )
  },
  ['error'],
  'Structured error envelope used by /api/v1 routes.'
);

const legacyErrorSchema: Values = object(
  { error: { type: 'string' }, coverage_status: { type: 'string' } },
  ['error'],
  'Legacy compatibility error envelope used by the non-versioned /api routes.'
);

const errorResponse = (description: string, codes: string[]): Values => ({
  description,
  content: {
    'application/json': {
      schema: { $ref: '#/components/schemas/Error' },
      examples: Object.fromEntries(codes.map((code) => [code, { value: { error: { code, message: 'See description.' } } }]))
    }
  }
});

const document: Values = {
  openapi: '3.1.0',
  info: {
    title: 'Project Berean API',
    version: '1.1.0',
    description: [
      'A provenance-aware read and controlled administration interface over the Berean PostgreSQL schema.',
      '',
      'Berean never asserts truth. A claim is an assertion, evidence is an observation, a candidate is a lead,',
      'a proposed identity mapping is not an active reconciliation, and a derived claim is not a direct source',
      'observation. `NOT_REPRESENTED` and `NO_MATCH` report the limits of representation and are never denials.',
      '',
      'Routes under `/api/v1` are the supported contract. Non-versioned `/api/*` routes are retained for',
      'compatibility with the Explorer user interface and earlier phases and are tagged `compatibility`.'
    ].join('\n')
  },
  tags: [
    { name: 'read', description: 'Read-only knowledge, registry, provenance, and graph routes.' },
    { name: 'research', description: 'Transient, bounded, read-only research over persisted rows.' },
    { name: 'administration', description: 'Authenticated, audited, transactional workflow and authoring routes.' },
    { name: 'compatibility', description: 'Legacy non-versioned routes retained for the Explorer interface.' },
    { name: 'meta', description: 'Health, capability, schema-boundary, and documentation routes.' }
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'opaque API token',
        description: [
          'Credentials are configured out of band as SHA-256 token hashes with one of the roles',
          'READER < RESEARCHER < CONTENT_EDITOR < REVIEWER < ADMINISTRATOR < SYSTEM.',
          'When no credential is configured every administrative route fails closed with 503 AUTH_NOT_CONFIGURED.'
        ].join(' ')
      }
    },
    schemas: {
      Error: errorSchema,
      LegacyError: legacyErrorSchema,
      SearchResult: object(
        {
          type: { type: 'string', enum: ['entity', 'event', 'claim', 'proposition', 'evidence', 'source', 'dataset', 'source_record', 'citation', 'source_identity'] },
          id: { type: 'integer' },
          key: { type: 'string' },
          label: { type: ['string', 'null'] },
          detail: { type: ['string', 'null'] }
        },
        ['type', 'id', 'key'],
        'A lexical search hit. A hit is not an established claim.'
      ),
      SearchResponse: object(
        {
          query: { type: 'string' },
          resource: { type: ['string', 'null'], enum: [...SEARCH_RESOURCES, null] },
          resource_type: { type: ['string', 'null'] },
          results: { type: 'array', items: { $ref: '#/components/schemas/SearchResult' } },
          classification: { type: 'string', enum: ['MATCHED', 'NO_MATCH'] },
          limitation: { type: 'string' }
        },
        ['query', 'results', 'classification'],
        'Search response. `NO_MATCH` states that nothing persisted matched the term; it is not falsity.'
      ),
      ResearchQuery: object(
        {
          question: requiredString(1000, 'Natural-language research question.'),
          datasetIds: {
            type: 'array',
            maxItems: 100,
            items: { type: 'integer', minimum: 1 },
            description: 'Optional dataset scope. An empty or absent list searches every persisted dataset.'
          }
        },
        ['question'],
        'Transient research request. Nothing is persisted.'
      ),
      ResearchResponse: object(
        {
          question: { type: 'string' },
          interpretation: { type: 'string' },
          capability: { type: 'string', enum: ['ESTABLISHED', 'DERIVED', 'SCHOLARLY_CANDIDATE', 'UNRESOLVED', 'NOT_REPRESENTED', 'NO_MATCH'] },
          plan: { type: 'object', description: 'Query plan: classification, scope, candidate predicates, traversal shape, output constraints.' },
          results: { type: 'array', items: { type: 'object' } },
          limitation: { type: 'string' }
        },
        ['question', 'plan', 'results'],
        'Research answers are assembled only from persisted rows and registered predicates.'
      ),
      CorpusCreate: object(
        {
          key: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 },
          name: requiredString(300, 'Human-readable corpus name.'),
          description: { type: 'string', maxLength: 2000 },
          scopeNote: requiredString(4000, 'Explicit bounded scope of the corpus.')
        },
        ['key', 'name', 'scopeNote'],
        'Creates a bounded corpus workspace. A corpus is workflow coordination, never authoritative knowledge.'
      ),
      CorpusPatch: object(
        {
          name: { type: 'string', maxLength: 300 },
          description: { type: 'string', maxLength: 2000 },
          scopeNote: { type: 'string', maxLength: 4000 },
          status: { type: 'string', enum: ['DRAFT', 'ACTIVE', 'ARCHIVED'] }
        },
        [],
        'Partial corpus update. Omitted fields are preserved.'
      ),
      ResearchTopicCreate: object(
        {
          corpusId: { type: 'integer', minimum: 1 },
          key: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 },
          question: requiredString(2000, 'Research question under investigation.'),
          scopeNote: requiredString(4000, 'Explicit scope boundary for the topic.')
        },
        ['corpusId', 'key', 'question', 'scopeNote'],
        'Creates a scoped research topic inside a corpus.'
      ),
      DiscoveryRequestCreate: object(
        {
          corpusId: { type: 'integer', minimum: 1 },
          researchTopicId: { type: 'integer', minimum: 1 },
          requestKind: { type: 'string', enum: ['SOURCE_DISCOVERY', 'CANDIDATE_DISCOVERY', 'GAP_DISCOVERY'] },
          queryText: requiredString(2000, 'Discovery query text.'),
          boundedScope: requiredString(4000, 'Explicit bound on what discovery may consider.'),
          requestedTypes: { type: 'array', maxItems: 10, items: { type: 'string', enum: CANDIDATE_TYPES } }
        },
        ['corpusId', 'requestKind', 'queryText', 'boundedScope', 'requestedTypes'],
        'Queues candidate-only discovery. Discovery never produces evidence or claims.'
      ),
      DiscoveryCandidateCreate: object(
        {
          key: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 },
          type: { type: 'string', enum: CANDIDATE_TYPES },
          label: requiredString(500, 'Candidate label as encountered in the discovery source.'),
          description: { type: 'string', maxLength: 2000 },
          representationStatus: { type: 'string', enum: ['UNREVIEWED', 'REPRESENTABLE', 'NOT_REPRESENTED', 'DUPLICATE', 'EXCLUDED'] },
          obstacleClassification: { type: 'string', enum: ['QUERY', 'DATA_ENTRY', 'REGISTRY_EXPRESSIVENESS', 'DOMAIN_SCOPING_LIMITATION', 'ARCHITECTURAL_DEFICIENCY'] },
          proposedPredicate: { type: 'string', maxLength: 120, description: 'A proposal only. It never registers a predicate.' },
          discoveryLocator: requiredString(2000, 'Where the candidate was encountered. A locator is not evidence.')
        },
        ['key', 'type', 'label', 'discoveryLocator'],
        'Records a discovery candidate. A candidate is a lead, never evidence.'
      ),
      CandidateReview: object(
        {
          decision: { type: 'string', enum: ['APPROVED', 'REJECTED', 'NEEDS_SOURCE_VERIFICATION', 'NOT_REPRESENTED'] },
          rationale: requiredString(4000, 'Human rationale for the decision.')
        },
        ['decision', 'rationale'],
        'Human review of a candidate. APPROVED does not create evidence or claims.'
      ),
      SourceRegistration: object(
        {
          corpusId: { type: 'integer', minimum: 1 },
          sourceKey: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 },
          sourceName: requiredString(500, 'Source name.'),
          sourceType: { type: 'string', description: 'Registered source_type code. Unknown codes fail with 422 INTEGRITY_VIOLATION.' },
          description: { type: 'string', maxLength: 2000 },
          datasetKey: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 },
          datasetName: requiredString(500, 'Dataset name.'),
          editionLabel: { type: 'string', maxLength: 500 },
          version: { type: 'string', maxLength: 200 },
          licenseStatus: requiredString(500, 'Licence status recorded for downstream export decisions.'),
          acquisitionMethod: requiredString(500, 'How the dataset was acquired.')
        },
        ['corpusId', 'sourceKey', 'sourceName', 'sourceType', 'datasetKey', 'datasetName', 'licenseStatus', 'acquisitionMethod'],
        'Registers a source and a licensed dataset and attaches the dataset to a corpus.'
      ),
      SourceRecordCreate: object(
        {
          datasetId: { type: 'integer', minimum: 1 },
          key: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 },
          sourceLocation: requiredString(2000, 'Locator for the source record.'),
          rawContent: { type: 'string', maxLength: 10000, description: 'Optional. Requires contentHash. Absence is a storage policy, never source silence.' },
          contentHash: { type: 'string', pattern: '^[0-9a-f]{64}$' },
          revisionLabel: { type: 'string', maxLength: 200 },
          citationKey: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 },
          locator: requiredString(2000, 'Citation locator.'),
          quotedText: { type: 'string', maxLength: 10000 }
        },
        ['datasetId', 'key', 'sourceLocation', 'citationKey', 'locator'],
        'Registers a source record and its citation locator.'
      ),
      EvidenceCreate: object(
        {
          key: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 },
          sourceRecordId: { type: 'integer', minimum: 1 },
          observation: requiredString(10000, 'What the evidence observes.'),
          evidenceType: { type: 'string', enum: ['SOURCE_OBSERVATION', 'ANALYTICAL_OBSERVATION'] },
          notes: { type: 'string', maxLength: 4000 },
          citationIds: { type: 'array', minItems: 1, maxItems: 100, items: { type: 'integer', minimum: 1 } }
        },
        ['key', 'sourceRecordId', 'observation', 'evidenceType', 'citationIds'],
        'Creates cited evidence. Evidence never creates a claim, and an analytical observation is not a source observation.'
      ),
      ClaimCreate: object(
        {
          key: { type: 'string', pattern: '^[A-Za-z0-9][A-Za-z0-9_.:-]*$', maxLength: 120 },
          predicate: { type: 'string', description: 'Registered predicate code. Unregistered predicates fail with 422 INTEGRITY_VIOLATION; the API never registers predicates.' },
          subjectEntityId: { type: 'integer', minimum: 1 },
          subjectEventId: { type: 'integer', minimum: 1 },
          objectEntityId: { type: 'integer', minimum: 1 },
          objectEventId: { type: 'integer', minimum: 1 },
          objectTypedValueId: { type: 'integer', minimum: 1 },
          claimType: { type: 'string', enum: ['DIRECT_SOURCE_CLAIM', 'INTERPRETIVE_CLAIM', 'DERIVED_CLAIM'] },
          status: { type: 'string', enum: ['ACTIVE', 'UNDER_REVIEW'], default: 'UNDER_REVIEW' },
          statement: { type: 'string', maxLength: 4000, description: 'Optional display text. The proposition remains the semantic authority.' },
          notes: { type: 'string', maxLength: 4000 },
          derivationId: { type: 'integer', minimum: 1, description: 'Required for DERIVED_CLAIM and rejected otherwise.' },
          evidenceIds: { type: 'array', minItems: 1, maxItems: 100, items: { type: 'integer', minimum: 1 } },
          evidenceRelation: { type: 'string', enum: ['SUPPORTS', 'CONTRADICTS', 'QUALIFIES'], default: 'SUPPORTS' }
        },
        ['key', 'predicate', 'claimType', 'evidenceIds'],
        'Authors a registered proposition and a reviewed claim. Exactly one subject and exactly one object are required. A claim is an assertion, never truth.'
      ),
      IdentityMappingCreate: object(
        {
          sourceIdentityId: { type: 'integer', minimum: 1 },
          entityId: { type: 'integer', minimum: 1 },
          confidence: { type: 'number', minimum: 0, maximum: 1 },
          justification: requiredString(4000, 'Why the source identity may correspond to the canonical entity.'),
          notes: { type: 'string', maxLength: 4000 },
          supportingEvidenceId: { type: 'integer', minimum: 1, description: 'Must originate from the source that supplied the identity.' }
        },
        ['sourceIdentityId', 'entityId', 'confidence', 'justification', 'supportingEvidenceId'],
        'Proposes a reconciliation. The mapping is persisted as PROPOSED; PROPOSED is not ACTIVE.'
      ),
      IdentityMappingReview: object(
        {
          status: { type: 'string', enum: ['ACTIVE', 'REJECTED'] },
          rationale: requiredString(4000, 'Reviewer rationale, preserved with the mapping.')
        },
        ['status', 'rationale'],
        'Human review of a proposed mapping. Only PROPOSED rows may transition.'
      ),
      DerivationCreate: object(
        {
          method: requiredString(4000, 'How the derivation was performed.'),
          assumptions: requiredString(4000, 'Assumptions the derivation depends on.'),
          inputs: {
            type: 'array',
            minItems: 1,
            maxItems: 100,
            items: object(
              {
                claimId: { type: 'integer', minimum: 1 },
                evidenceId: { type: 'integer', minimum: 1 },
                notes: { type: 'string', maxLength: 2000 }
              },
              [],
              'Exactly one of claimId or evidenceId is required.'
            )
          }
        },
        ['method', 'assumptions', 'inputs'],
        'Records derivation metadata with explicit inputs. It never creates a derived claim.'
      ),
      IngestionJobCreate: object(
        {
          corpusId: { type: 'integer', minimum: 1 },
          sourceId: { type: 'integer', minimum: 1 },
          candidateId: { type: 'integer', minimum: 1 },
          transactionPolicy: { type: 'string', enum: ['ATOMIC', 'SAVEPOINT_PER_ITEM'], default: 'ATOMIC' },
          partialFailurePolicy: { type: 'string', enum: ['ROLLBACK_ALL', 'RETAIN_SUCCESSES'], default: 'ROLLBACK_ALL' }
        },
        [],
        'Queues controlled ingestion. Queue state is persisted; execution requires an external SYSTEM worker.'
      ),
      ValidationRunCreate: object(
        {
          corpusId: { type: 'integer', minimum: 1 },
          validationTypes: {
            type: 'array',
            minItems: 1,
            items: {
              type: 'string',
              enum: ['SCHEMA', 'PROVENANCE', 'REGISTRY', 'IDENTITY', 'CLAIM', 'EVIDENCE', 'DERIVATION', 'CORPUS', 'REPLAY', 'READ_ONLY', 'NEGATIVE_SEMANTIC']
            }
          }
        },
        ['validationTypes'],
        'Queues an immutable validation run. Validation results are append-only and are not claims.'
      ),
      ExportJobCreate: object(
        {
          corpusId: { type: 'integer', minimum: 1 },
          format: { type: 'string', enum: ['JSONL', 'CSV'] },
          includeRawContent: { type: 'boolean', default: false, description: 'Licence-aware. Raw content is withheld unless the dataset licence permits redistribution.' },
          reproducibilityNote: requiredString(4000, 'How the export may be reproduced.')
        },
        ['format', 'reproducibilityNote'],
        'Queues a licence-aware export. Execution requires an external SYSTEM worker.'
      )
    },
    responses: {
      InvalidRequest: errorResponse(
        'The request failed validation before any write occurred.',
        ['INVALID_REQUEST', 'INVALID_PROPOSITION']
      ),
      Unauthenticated: {
        ...errorResponse('No bearer credential was presented, or the credential is unknown.', ['UNAUTHENTICATED']),
        headers: { 'WWW-Authenticate': { schema: { type: 'string' }, description: 'Always `Bearer`.' } }
      },
      Forbidden: errorResponse('The authenticated role is below the minimum role for this route, or the actor does not own the job.', ['FORBIDDEN']),
      NotFound: errorResponse('The resource, registry, search filter, or administrative resource is not supported or does not exist.', ['NOT_FOUND']),
      Conflict: errorResponse(
        'A concurrency, idempotency, or state conflict prevented the write. Berean reports every conflict as 409; no partial write is committed.',
        ['STALE_VERSION', 'IDEMPOTENCY_CONFLICT', 'INVALID_MAPPING_STATE', 'INVALID_JOB_STATE', 'DUPLICATE']
      ),
      Unprocessable: errorResponse(
        'The request was well formed but violates a provenance, registry, derivation, or identity constraint.',
        [
          'DIRECT_CLAIM_REQUIRES_CITED_SOURCE_OBSERVATION', 'DERIVATION_REQUIRED', 'DERIVATION_NOT_ALLOWED',
          'DERIVATION_INPUT_REQUIRED', 'IDENTITY_EVIDENCE_SOURCE_MISMATCH', 'INTEGRITY_VIOLATION'
        ]
      ),
      NotRepresented: errorResponse(
        'The requested capability is not represented by the Berean schema. Absence of representation is not falsity.',
        ['NOT_REPRESENTED']
      ),
      AuthNotConfigured: errorResponse('No administrative credential is configured; administrative routes fail closed.', ['AUTH_NOT_CONFIGURED']),
      InternalError: {
        description: 'An unexpected error occurred. No implementation detail is disclosed.',
        content: { 'application/json': { schema: { $ref: '#/components/schemas/LegacyError' } } }
      }
    }
  },
  paths: {}
};

const paths: Values = {
  '/health': {
    get: readOperation({
      operationId: 'getHealth',
      summary: 'Report process health',
      description: 'Unauthenticated liveness probe.',
      responseDescription: 'Process health and mode.',
      tag: 'meta'
    })
  },
  '/openapi.json': {
    get: readOperation({
      operationId: 'getOpenApiDocument',
      summary: 'Return this OpenAPI document',
      description: 'Machine-readable contract for every implemented route.',
      responseDescription: 'OpenAPI 3.1 document.',
      tag: 'meta'
    })
  },
  '/api-docs': {
    get: {
      tags: ['meta'],
      operationId: 'getApiDocsPage',
      summary: 'Human-readable pointer to the OpenAPI document',
      description: 'Returns a minimal HTML page linking to /openapi.json.',
      responses: {
        '200': { description: 'HTML pointer page.', content: { 'text/html': { schema: { type: 'string' } } } }
      },
      'x-berean-write': false,
      'x-berean-persistence': 'None. Read routes never mutate persisted state.'
    }
  },
  '/api/v1/health': {
    get: readOperation({
      operationId: 'getV1Health',
      summary: 'Report versioned API health',
      description: 'Reports the API version and read-only default mode.',
      responseDescription: 'Health, api_version, and mode.',
      tag: 'meta'
    })
  },
  '/api/v1/capabilities': {
    get: readOperation({
      operationId: 'getV1Capabilities',
      summary: 'List implemented capabilities and documented limitations',
      description: 'Lists implemented capabilities and NOT_REPRESENTED limitations such as external retrieval and truth confirmation.',
      responseDescription: 'Implemented capabilities and limitations.',
      tag: 'meta'
    })
  },
  '/api/v1/schema': {
    get: readOperation({
      operationId: 'getV1SchemaBoundary',
      summary: 'Describe the authoritative schema boundary',
      description: 'Names the authoritative provenance chain, the projections, and the workflow boundary that never replaces authoritative rows.',
      responseDescription: 'Authoritative chain, projections, workflow boundary, and limitations.',
      tag: 'meta'
    })
  },
  '/api/v1/registry/{registry}': {
    get: readOperation({
      operationId: 'getV1Registry',
      summary: 'List a controlled registry',
      description: 'Registries are controlled vocabularies. They are read-only over HTTP and change only through reviewed migrations. `capabilities` is redirected (307) to /api/v1/capabilities.',
      parameters: [{ name: 'registry', in: 'path', required: true, schema: { type: 'string', enum: [...REGISTRIES, 'capabilities'] } }],
      responseDescription: 'Registry rows, capped at 100.',
      responseSchema: object({ results: { type: 'array', items: { type: 'object' } } }, ['results'], 'Registry rows.'),
      additionalResponses: {
        '307': {
          description: '`registry=capabilities` redirects to `/api/v1/capabilities`.',
          headers: { Location: { schema: { type: 'string', example: '/api/v1/capabilities' } } }
        }
      },
      errors: ['404', '500']
    })
  },
  '/api/v1/search': {
    get: readOperation({
      operationId: 'searchV1',
      summary: 'Search persisted records across every searchable type',
      description: 'Lexical search over entities, events, claims, propositions, evidence, sources, datasets, source records, citations, and source identities. Matches are search hits, not established claims.',
      parameters: [
        { name: 'q', in: 'query', required: true, schema: { type: 'string', minLength: 1, maxLength: 200 } },
        limitParameter('Maximum results, 1 to 100.')
      ],
      responseDescription: 'Search results with MATCHED or NO_MATCH classification.',
      responseSchema: { $ref: '#/components/schemas/SearchResponse' },
      errors: ['400', '500']
    })
  },
  '/api/v1/search/{resource}': {
    get: readOperation({
      operationId: 'searchV1ByResource',
      summary: 'Search a single resource type',
      description: [
        'The plural route segment is normalized explicitly to a search result type:',
        SEARCH_RESOURCES.join(', ') + '.',
        'An unknown filter returns 404 NOT_FOUND rather than silently empty results.',
        '`identity-mappings` is a supported persisted resource that keyword search does not index and returns 501 NOT_REPRESENTED.'
      ].join(' '),
      parameters: [
        { name: 'resource', in: 'path', required: true, schema: { type: 'string', enum: [...SEARCH_RESOURCES, 'identity-mappings'] } },
        { name: 'q', in: 'query', required: true, schema: { type: 'string', minLength: 1, maxLength: 200 } },
        limitParameter('Maximum results, 1 to 100.')
      ],
      responseDescription: 'Filtered search results with MATCHED or NO_MATCH classification.',
      responseSchema: { $ref: '#/components/schemas/SearchResponse' },
      errors: ['400', '404', '500', '501']
    })
  },
  '/api/v1/research': {
    post: {
      tags: ['research'],
      operationId: 'runV1Research',
      summary: 'Run a transient, read-only research query',
      description: 'Answers only from persisted rows and registered predicates. Truth or proof questions return capability NOT_REPRESENTED. Nothing is persisted and no credential is required.',
      requestBody: body('ResearchQuery'),
      responses: {
        '200': jsonResponse('Bounded research answer with plan and classification.', { $ref: '#/components/schemas/ResearchResponse' }),
        ...errorRef('400', '500')
      },
      'x-berean-write': false,
      'x-berean-persistence': 'None. The query plan and results are transient.',
      'x-berean-epistemic-boundary': 'Research classifies represented material. It never establishes truth, invents predicates, or infers unregistered relationships.'
    }
  },
  '/api/v1/research/capabilities': {
    get: readOperation({
      operationId: 'getV1ResearchCapabilities',
      summary: 'List research mode and result classifications',
      description: 'Declares the transient read-only mode and the classification vocabulary.',
      responseDescription: 'Mode and classification enumeration.',
      tag: 'research'
    })
  },
  '/api/v1/provenance/claim/{id}': {
    get: readOperation({
      operationId: 'getV1ClaimProvenance',
      summary: 'Explain the provenance of a claim',
      description: 'Traverses claim to proposition, claim evidence, evidence, citation, source record, dataset, and source. A claim that is not represented returns 404 NOT_FOUND.',
      parameters: [positiveIdParameter('id')],
      responseDescription: 'Structural provenance explanation with gap reporting.',
      errors: ['400', '404', '500']
    })
  },
  '/api/v1/graph/entity/{id}': {
    get: readOperation({
      operationId: 'getV1EntityGraph',
      summary: 'Return a bounded relationship neighborhood for an entity',
      description: 'Edges are projected from persisted claim-asserted propositions. A projected edge is not a new claim. An unknown entity returns an empty neighborhood.',
      parameters: [positiveIdParameter('id')],
      responseDescription: 'Bounded neighborhood of nodes and edges.',
      errors: ['400', '500']
    })
  },
  '/api/v1/{resource}': {
    get: readOperation({
      operationId: 'listV1Resource',
      summary: 'List a supported persisted resource',
      description: 'Lists rows for a supported resource. Results are ordered by stable key and capped at 100.',
      parameters: [
        { name: 'resource', in: 'path', required: true, schema: { type: 'string', enum: READ_RESOURCES } },
        limitParameter('Maximum rows, 1 to 100.')
      ],
      responseDescription: 'Resource rows.',
      responseSchema: object({ results: { type: 'array', items: { type: 'object' } } }, ['results'], 'Resource rows.'),
      errors: ['400', '404', '500']
    })
  },
  '/api/v1/{resource}/{id}': {
    get: readOperation({
      operationId: 'getV1Resource',
      summary: 'Get a supported persisted resource',
      description: 'Returns one row. `entities`, `events`, `claims`, and `sources` return expanded detail including related claims, evidence, and provenance; other resources return the persisted row.',
      parameters: [
        { name: 'resource', in: 'path', required: true, schema: { type: 'string', enum: READ_RESOURCES } },
        positiveIdParameter('id')
      ],
      responseDescription: 'Resource detail.',
      errors: ['400', '404', '500']
    })
  },
  '/api/v1/admin/{resource}': {
    get: readOperation({
      operationId: 'listAdministrationResource',
      summary: 'List workflow administration rows',
      description: 'Reads workflow coordination rows. Workflow rows are never authoritative knowledge, and audit rows are never evidence. An unsupported resource returns 404 NOT_FOUND without implementation detail.',
      role: 'READER',
      tag: 'administration',
      parameters: [
        { name: 'resource', in: 'path', required: true, schema: { type: 'string', enum: ADMIN_RESOURCES } },
        limitParameter('Maximum rows, 1 to 100.'),
        correlationHeader
      ],
      responseDescription: 'Workflow rows, newest first.',
      responseSchema: object({ results: { type: 'array', items: { type: 'object' } } }, ['results'], 'Workflow rows.'),
      errors: ['400', '401', '403', '404', '500', '503']
    })
  },
  '/api/v1/corpora': {
    post: writeOperation({
      operationId: 'createCorpus',
      summary: 'Create a bounded corpus workspace',
      description: 'Creates a corpus with an explicit scope note.',
      role: 'ADMINISTRATOR',
      schema: 'CorpusCreate',
      status: 201,
      statusDescription: 'The created corpus row, including its concurrency `version`.',
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts one `corpus` row.',
      audit: true,
      epistemic: 'A corpus coordinates work. It is not authoritative knowledge.'
    })
  },
  '/api/v1/corpora/{id}': {
    patch: writeOperation({
      operationId: 'updateCorpus',
      summary: 'Update a corpus using optimistic concurrency',
      description: [
        'Requires `If-Match` carrying the integer `version` returned by the previous write.',
        'Berean does not issue entity tags: `If-Match` carries an opaque version counter, and a stale or unknown version returns',
        '409 STALE_VERSION consistently with every other Berean conflict. The update and its audit row share one transaction,',
        'so a stale write commits nothing at all.'
      ].join(' '),
      role: 'ADMINISTRATOR',
      schema: 'CorpusPatch',
      status: 200,
      statusDescription: 'The updated corpus row with an incremented `version`.',
      parameters: [
        positiveIdParameter('id'),
        {
          name: 'If-Match',
          in: 'header',
          required: true,
          description: 'The integer `version` last observed for this corpus.',
          schema: { type: 'integer', minimum: 1 }
        }
      ],
      errors: ['400', '401', '403', '409', '500', '503'],
      mutation: 'Updates one `corpus` row and increments its version.',
      audit: true,
      epistemic: 'Corpus status is workflow state. ACTIVE does not mean verified knowledge.'
    })
  },
  '/api/v1/research-topics': {
    post: writeOperation({
      operationId: 'createResearchTopic',
      summary: 'Create a scoped research topic',
      description: 'Creates a research topic bound to a corpus.',
      role: 'RESEARCHER',
      schema: 'ResearchTopicCreate',
      status: 201,
      statusDescription: 'The created research topic row.',
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts one `research_topic` row.',
      audit: true,
      epistemic: 'A topic bounds inquiry. It asserts nothing.'
    })
  },
  '/api/v1/discovery-requests': {
    post: writeOperation({
      operationId: 'createDiscoveryRequest',
      summary: 'Queue candidate-only discovery',
      description: 'Persists a discovery request and its queued job. Execution requires an external SYSTEM worker; the request may remain QUEUED in this repository.',
      role: 'RESEARCHER',
      schema: 'DiscoveryRequestCreate',
      status: 202,
      statusDescription: 'The queued discovery request and job identifiers.',
      parameters: [idempotencyHeader],
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts `discovery_request` and `asynchronous_job` rows.',
      audit: true,
      epistemic: 'Discovery produces candidates only. It never produces evidence, claims, or identities.'
    })
  },
  '/api/v1/discovery-requests/{id}/candidates': {
    post: writeOperation({
      operationId: 'createDiscoveryCandidate',
      summary: 'Record a discovery candidate, never evidence',
      description: 'Records a candidate with a discovery locator. A locator is a pointer, not a source observation.',
      role: 'RESEARCHER',
      schema: 'DiscoveryCandidateCreate',
      status: 201,
      statusDescription: 'The created discovery candidate row.',
      parameters: [positiveIdParameter('id')],
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts one `discovery_candidate` row.',
      audit: true,
      epistemic: 'A candidate is a lead awaiting human review. It is never promoted automatically.'
    })
  },
  '/api/v1/candidates/{id}/review': {
    post: writeOperation({
      operationId: 'reviewDiscoveryCandidate',
      summary: 'Record a human review decision for a candidate',
      description: 'Upserts the review for a candidate. Approval records a decision only.',
      role: 'REVIEWER',
      schema: 'CandidateReview',
      status: 200,
      statusDescription: 'The recorded candidate review.',
      parameters: [positiveIdParameter('id')],
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts or updates one `candidate_review` row.',
      audit: true,
      epistemic: 'APPROVED does not create evidence, a claim, an entity, or an identity mapping.'
    })
  },
  '/api/v1/source-registrations': {
    post: writeOperation({
      operationId: 'registerSource',
      summary: 'Register a source and licensed dataset',
      description: 'Registers a source, a dataset with licence status, and the corpus attachment. Existing stable keys are reused rather than duplicated.',
      role: 'CONTENT_EDITOR',
      schema: 'SourceRegistration',
      status: 201,
      statusDescription: 'The registered source and dataset identifiers.',
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts or reuses `source`, `dataset`, and `corpus_dataset` rows.',
      audit: true,
      epistemic: 'Registering a source records availability. It does not make the source true or authoritative.'
    })
  },
  '/api/v1/source-records': {
    post: writeOperation({
      operationId: 'createSourceRecord',
      summary: 'Register a source record and citation locator',
      description: 'Registers a source record and its citation. `rawContent` is optional and requires a lowercase SHA-256 `contentHash`; withholding content is a storage policy, not source silence.',
      role: 'CONTENT_EDITOR',
      schema: 'SourceRecordCreate',
      status: 201,
      statusDescription: 'The registered source record and citation identifiers.',
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts or reuses `source_record` and `citation` rows.',
      audit: true,
      epistemic: 'A locator-only record is not source silence and not falsity.'
    })
  },
  '/api/v1/evidence': {
    post: writeOperation({
      operationId: 'createEvidence',
      summary: 'Create cited evidence without creating a claim',
      description: 'Creates evidence attached to a source record and at least one citation.',
      role: 'CONTENT_EDITOR',
      schema: 'EvidenceCreate',
      status: 201,
      statusDescription: 'The created evidence row and its citation links.',
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts `evidence` and `evidence_citation` rows.',
      audit: true,
      epistemic: 'Evidence is an observation. ANALYTICAL_OBSERVATION is not a source observation and never supports a direct claim.'
    })
  },
  '/api/v1/claims': {
    post: writeOperation({
      operationId: 'createClaim',
      summary: 'Author a registered proposition and reviewed claim',
      description: [
        'Creates the proposition, the claim, and the claim/evidence links in one transaction.',
        'A DIRECT_SOURCE_CLAIM or INTERPRETIVE_CLAIM requires cited SOURCE_OBSERVATION evidence (422 otherwise);',
        'a DERIVED_CLAIM requires a derivation with explicit inputs. Predicates must already be registered.'
      ].join(' '),
      role: 'REVIEWER',
      schema: 'ClaimCreate',
      status: 201,
      statusDescription: 'The created claim and proposition identifiers.',
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts `proposition`, `claim`, and `claim_evidence` rows.',
      audit: true,
      epistemic: 'A claim is an assertion with provenance. ACTIVE is not truth, and a competing claim is never overwritten.'
    })
  },
  '/api/v1/identity-mappings': {
    post: writeOperation({
      operationId: 'createIdentityMapping',
      summary: 'Propose a source identity to canonical entity mapping',
      description: 'Creates a PROPOSED mapping with confidence, justification, and supporting evidence from the same source.',
      role: 'CONTENT_EDITOR',
      schema: 'IdentityMappingCreate',
      status: 201,
      statusDescription: 'The proposed mapping row with status PROPOSED.',
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts one `entity_source_mapping` row with status PROPOSED.',
      audit: true,
      epistemic: 'A source identity is not a canonical entity. PROPOSED is not ACTIVE and cannot be activated by this route.'
    })
  },
  '/api/v1/identity-mappings/{id}/review': {
    post: writeOperation({
      operationId: 'reviewIdentityMapping',
      summary: 'Review a proposed identity mapping',
      description: 'Transitions a PROPOSED mapping to ACTIVE or REJECTED. Any other current status returns 409 INVALID_MAPPING_STATE.',
      role: 'REVIEWER',
      schema: 'IdentityMappingReview',
      status: 200,
      statusDescription: 'The reviewed mapping row.',
      parameters: [positiveIdParameter('id')],
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Updates one `entity_source_mapping` row and preserves the reviewer rationale.',
      audit: true,
      epistemic: 'Activation requires human review and evidence from the supplying source; justification and confidence are preserved, never erased.'
    })
  },
  '/api/v1/derivations': {
    post: writeOperation({
      operationId: 'createDerivation',
      summary: 'Record derivation metadata with explicit inputs',
      description: 'Creates derivation metadata and its claim or evidence inputs. Derived claims are authored separately through POST /api/v1/claims.',
      role: 'RESEARCHER',
      schema: 'DerivationCreate',
      status: 201,
      statusDescription: 'The created derivation and its inputs.',
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts `derivation` and `derivation_input` rows.',
      audit: true,
      epistemic: 'Derived knowledge is not a direct source observation, and a derivation never becomes a claim automatically.'
    })
  },
  '/api/v1/ingestion-jobs': {
    post: writeOperation({
      operationId: 'createIngestionJob',
      summary: 'Queue controlled ingestion',
      description: 'Persists a queued ingestion job. Execution requires an external SYSTEM worker.',
      role: 'CONTENT_EDITOR',
      schema: 'IngestionJobCreate',
      status: 202,
      statusDescription: 'The queued job. Replaying the same Idempotency-Key with the same fingerprint returns the same job.',
      parameters: [idempotencyHeader],
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts one `asynchronous_job` row with status QUEUED.',
      audit: true,
      epistemic: 'A queued job is not an ingestion outcome. Nothing is ingested by this call.'
    })
  },
  '/api/v1/validation-runs': {
    post: writeOperation({
      operationId: 'createValidationRun',
      summary: 'Queue an immutable validation run',
      description: 'Persists a queued validation run. Validation results are append-only and require an external SYSTEM worker.',
      role: 'REVIEWER',
      schema: 'ValidationRunCreate',
      status: 202,
      statusDescription: 'The queued validation run and job.',
      parameters: [idempotencyHeader],
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts `validation_run` and `asynchronous_job` rows.',
      audit: true,
      epistemic: 'A validation result is a reproducibility record, not a claim and not a truth determination.'
    })
  },
  '/api/v1/export-jobs': {
    post: writeOperation({
      operationId: 'createExportJob',
      summary: 'Queue a licence-aware export',
      description: 'Persists a queued export job. Raw content is withheld unless the dataset licence permits redistribution. Execution requires an external SYSTEM worker.',
      role: 'ADMINISTRATOR',
      schema: 'ExportJobCreate',
      status: 202,
      statusDescription: 'The queued export job.',
      parameters: [idempotencyHeader],
      errors: ['400', '401', '403', '409', '422', '500', '503'],
      mutation: 'Inserts `export_job` and `asynchronous_job` rows.',
      audit: true,
      epistemic: 'Export never relicenses a dataset and never removes provenance.'
    })
  },
  '/api/v1/jobs/{id}/cancel': {
    post: writeOperation({
      operationId: 'cancelJob',
      summary: 'Cancel a queued or running job',
      description: 'Cancels a job the actor is allowed to change. A job in a non-cancellable state returns 409 INVALID_JOB_STATE.',
      role: 'CONTENT_EDITOR',
      status: 200,
      statusDescription: 'The updated job row.',
      parameters: [positiveIdParameter('id')],
      errors: ['400', '401', '403', '409', '500', '503'],
      mutation: 'Updates one `asynchronous_job` row.',
      audit: true,
      epistemic: 'Cancelling a job changes workflow state only; no knowledge is altered.'
    })
  },
  '/api/v1/jobs/{id}/retry': {
    post: writeOperation({
      operationId: 'retryJob',
      summary: 'Requeue a failed or cancelled job',
      description: 'Requeues a FAILED or CANCELLED job and increments its attempt count. Any other state returns 409 INVALID_JOB_STATE.',
      role: 'CONTENT_EDITOR',
      status: 200,
      statusDescription: 'The requeued job row.',
      parameters: [positiveIdParameter('id')],
      errors: ['400', '401', '403', '409', '500', '503'],
      mutation: 'Updates one `asynchronous_job` row back to QUEUED.',
      audit: true,
      epistemic: 'Retrying a job changes workflow state only; no knowledge is altered.'
    })
  }
};

const compatibility = (operation: {
  path: string;
  operationId: string;
  summary: string;
  description: string;
  parameters?: Values[];
  errors?: string[];
  contentType?: string;
}): void => {
  paths[operation.path] = {
    get: {
      tags: ['compatibility'],
      operationId: operation.operationId,
      summary: operation.summary,
      description: operation.description,
      ...(operation.parameters ? { parameters: operation.parameters } : {}),
      responses: {
        '200': operation.contentType === 'text/html'
          ? { description: 'Explorer HTML shell.', content: { 'text/html': { schema: { type: 'string' } } } }
          : jsonResponse('Compatibility payload.'),
        ...Object.fromEntries((operation.errors ?? ['500']).map((code) => [
          code,
          code === '500'
            ? { $ref: '#/components/responses/InternalError' }
            : {
              description: 'Legacy error envelope: `{ "error": "message" }`.',
              content: { 'application/json': { schema: { $ref: '#/components/schemas/LegacyError' } } }
            }
        ]))
      },
      'x-berean-write': false,
      'x-berean-persistence': 'None. Read routes never mutate persisted state.'
    }
  };
};

paths['/api/research'] = {
  post: {
    tags: ['compatibility'],
    operationId: 'runCompatibilityResearch',
    summary: 'Run a transient research query (compatibility route)',
    description: 'Identical research engine to POST /api/v1/research, but errors use the legacy `{ "error": "message" }` envelope. Nothing is persisted.',
    requestBody: body('ResearchQuery'),
    responses: {
      '200': jsonResponse('Bounded research answer.', { $ref: '#/components/schemas/ResearchResponse' }),
      '400': { description: 'Legacy validation error envelope.', content: { 'application/json': { schema: { $ref: '#/components/schemas/LegacyError' } } } },
      '500': { $ref: '#/components/responses/InternalError' }
    },
    'x-berean-write': false,
    'x-berean-persistence': 'None. The query plan and results are transient.'
  }
};

compatibility({
  path: '/api/research/scope',
  operationId: 'getResearchScope',
  summary: 'List persisted sources and datasets available as research scope',
  description: 'Scope selection never creates a domain and never reconciles identities.'
});
compatibility({
  path: '/api/search',
  operationId: 'searchCompatibility',
  summary: 'Search persisted records (compatibility route)',
  description: 'Unfiltered lexical search. `/api/v1/search/{resource}` provides the normalized, filterable contract.',
  parameters: [
    { name: 'q', in: 'query', required: true, schema: { type: 'string', minLength: 1, maxLength: 200 } },
    { name: 'limit', in: 'query', required: false, schema: { type: 'integer', minimum: 1 }, description: 'Defaults to 20 and is capped at 50 on this legacy route.' }
  ],
  errors: ['400', '500']
});
compatibility({
  path: '/api/entities/{entityId}',
  operationId: 'getEntityCompatibility',
  summary: 'Get entity detail with mappings, claims, events, and related entities',
  description: 'Related entities are projected from persisted claim-asserted propositions.',
  parameters: [positiveIdParameter('entityId')],
  errors: ['400', '404', '500']
});
compatibility({
  path: '/api/claims/{claimId}',
  operationId: 'getClaimCompatibility',
  summary: 'Get claim detail with proposition, evidence, and provenance',
  description: 'A claim remains an assertion regardless of status.',
  parameters: [positiveIdParameter('claimId')],
  errors: ['400', '404', '500']
});
compatibility({
  path: '/api/propositions/{propositionId}',
  operationId: 'getPropositionCompatibility',
  summary: 'Get proposition detail with every claim that asserts it',
  description: 'Competing claims over one proposition are preserved, never merged.',
  parameters: [positiveIdParameter('propositionId')],
  errors: ['400', '404', '500']
});
compatibility({
  path: '/api/events/{eventId}',
  operationId: 'getEventCompatibility',
  summary: 'Get event detail with projected participation',
  description: 'Participation is projected from claim-asserted propositions through the `event_participation` view.',
  parameters: [positiveIdParameter('eventId')],
  errors: ['400', '404', '500']
});
compatibility({
  path: '/api/sources',
  operationId: 'listSourcesCompatibility',
  summary: 'List registered sources',
  description: 'A registered source is available material, not established truth.'
});
compatibility({
  path: '/api/sources/{sourceId}',
  operationId: 'getSourceCompatibility',
  summary: 'Get source detail with datasets and record counts',
  description: 'Source detail reports what is registered, not what is correct.',
  parameters: [positiveIdParameter('sourceId')],
  errors: ['400', '404', '500']
});
compatibility({
  path: '/api/provenance/claims/{claimId}',
  operationId: 'getClaimProvenanceCompatibility',
  summary: 'Trace the raw provenance chain of a claim (compatibility route)',
  description: [
    'Intentional compatibility difference: a claim that is not represented returns 200 with an empty `traversal`',
    'and `classification: CLAIM_NOT_REPRESENTED`, whereas GET /api/v1/provenance/claim/{id} returns 404 NOT_FOUND.',
    'The Explorer interface depends on the 200 shape; the classification field prevents the two contracts from diverging silently.'
  ].join(' '),
  parameters: [positiveIdParameter('claimId')],
  errors: ['400', '500']
});
compatibility({
  path: '/api/provenance/explain',
  operationId: 'explainProvenanceCompatibility',
  summary: 'Explain provenance for a claim or a proposition',
  description: 'Exactly one of `claim_id` or `proposition_id` is required. Gaps are reported explicitly rather than silently omitted.',
  parameters: [
    { name: 'claim_id', in: 'query', required: false, schema: { type: 'integer', minimum: 1 } },
    { name: 'proposition_id', in: 'query', required: false, schema: { type: 'integer', minimum: 1 } }
  ],
  errors: ['400', '404', '500']
});
compatibility({
  path: '/api/derivations/check-eligibility',
  operationId: 'checkDerivationEligibility',
  summary: 'Check whether a derivation satisfies its structural requirements',
  description: 'Structural eligibility only. It never creates or promotes a derived claim.',
  parameters: [{ name: 'derivation_id', in: 'query', required: true, schema: { type: 'integer', minimum: 1 } }],
  errors: ['400', '404', '500']
});
compatibility({
  path: '/api/exploration/timeline',
  operationId: 'exploreEntityTimeline',
  summary: 'Assemble a persisted timeline for one entity',
  description: 'Exactly one of `entity_id` or `entity_key` is required. An unknown entity returns 404 with `coverage_status: NO_ENTITY_FOUND`.',
  parameters: [
    { name: 'entity_id', in: 'query', required: false, schema: { type: 'integer', minimum: 1 } },
    { name: 'entity_key', in: 'query', required: false, schema: { type: 'string', minLength: 1 } }
  ],
  errors: ['400', '404', '500']
});
compatibility({
  path: '/api/genesis/coverage',
  operationId: 'getGenesisCoverage',
  summary: 'Report Genesis locator coverage',
  description: 'Coverage reports what is represented. A gap is not a denial.'
});
compatibility({
  path: '/api/dashboard/quality',
  operationId: 'getQualityDashboard',
  summary: 'Report coverage and provenance quality counts',
  description: 'Counts describe representation completeness, not correctness.'
});
compatibility({
  path: '/api/graph',
  operationId: 'getGraphCompatibility',
  summary: 'Return a bounded neighborhood for an entity or claim node',
  description: 'Edges are projected from persisted rows. A projection is not a new claim.',
  parameters: [
    { name: 'nodeType', in: 'query', required: true, schema: { type: 'string', enum: ['entity', 'claim'] } },
    { name: 'nodeId', in: 'query', required: true, schema: { type: 'integer', minimum: 1 } }
  ],
  errors: ['400', '500']
});

document.paths = paths;

document['x-berean-fallback-routes'] = [
  {
    method: 'ALL',
    path: '/api/v1/*',
    response: '501 NOT_REPRESENTED',
    description: 'After more-specific V1 routes are considered, otherwise unmatched methods and paths return 501 NOT_REPRESENTED. Generic V1 GET resource routes can instead return 404 NOT_FOUND for an unknown resource. Absence of representation is not falsity.'
  },
  {
    method: 'GET',
    path: '*',
    response: '200 text/html',
    description: 'Any other GET returns the read-only Explorer HTML shell.'
  }
];

document['x-berean-roles'] = {
  order: ['READER', 'RESEARCHER', 'CONTENT_EDITOR', 'REVIEWER', 'ADMINISTRATOR', 'SYSTEM'],
  description: 'Roles are hierarchical: a route requiring RESEARCHER also accepts CONTENT_EDITOR and above.'
};

document['x-berean-not-represented'] = [
  'Truth, proof, or falsity adjudication',
  'Arbitrary URL fetch, file read, SQL execution, or import endpoints',
  'Predicate or registry mutation over HTTP',
  'Automatic candidate to evidence promotion',
  'Automatic evidence to claim promotion',
  'Automatic PROPOSED to ACTIVE identity activation',
  'Automatic derivation to claim promotion',
  'Conflict resolution or canonicalisation endpoints'
];

export const openApiDocument = (): object => document;
