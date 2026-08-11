const byId = (id) => document.getElementById(id);
const searchForm = byId('searchForm');
const searchInput = byId('searchInput');
const searchButton = byId('searchButton');
const searchResults = byId('searchResults');
const searchStatus = byId('searchStatus');
const detail = byId('detail');
const expandGraph = byId('expandGraph');
const resetGraph = byId('resetGraph');
const loadMoreGraph = byId('loadMoreGraph');
const graphText = byId('graphText');
const relationFilter = byId('relationFilter');
const researchForm = byId('researchForm');
const researchQuestion = byId('researchQuestion');
const researchButton = byId('researchButton');
const researchStatus = byId('researchStatus');
const researchResults = byId('researchResults');
const scopeOptions = byId('scopeOptions');
const scopeCount = byId('scopeCount');
const scopeFilter = byId('scopeFilter');
const scopeEmpty = byId('scopeEmpty');
const selectAllScopes = byId('selectAllScopes');
const clearScopes = byId('clearScopes');

const GRAPH_PAGE_SIZE = 25;
const scopeState = { datasets: [], selected: new Set() };
let selected = null;
let graphEdges = [];
let shownGraphEdges = GRAPH_PAGE_SIZE;
let searchController;
let researchController;

const safeText = (value) => (value === null || value === undefined ? '' : String(value));
const humanize = (value) => safeText(value).replaceAll('_', ' ').toLowerCase().replace(/^\w/, (letter) => letter.toUpperCase());

const element = (tag, options = {}) => {
  const node = document.createElement(tag);
  if (options.className) node.className = options.className;
  if (options.text !== undefined) node.textContent = safeText(options.text);
  return node;
};

const appendDefinition = (list, term, value) => {
  if (value === null || value === undefined || value === '') return;
  list.append(element('dt', { text: term }), element('dd', { text: value }));
};

const definitionList = (entries) => {
  const list = element('dl', { className: 'metadata' });
  for (const [term, value] of entries) appendDefinition(list, term, value);
  return list;
};

const setBusy = (button, busy, busyText) => {
  button.disabled = busy;
  if (busy) {
    button.dataset.label = button.textContent;
    button.textContent = busyText;
  } else if (button.dataset.label) {
    button.textContent = button.dataset.label;
  }
};

const fetchJson = async (url, options = {}) => {
  const response = await fetch(url, options);
  let payload;
  try {
    payload = await response.json();
  } catch {
    throw new Error(`Request failed (${response.status})`);
  }
  if (!response.ok) throw new Error(safeText(payload.error) || `Request failed (${response.status})`);
  return payload;
};

const renderMessage = (container, message, kind = 'empty') => {
  container.innerHTML = '';
  container.append(element('p', { className: kind, text: message }));
};

const capabilityDescription = {
  ESTABLISHED: 'Represented by persisted direct claims. A represented claim is not automatically truth.',
  DERIVED: 'Derived through persisted graph structure and explicit derivation metadata.',
  SCHOLARLY_CANDIDATE: 'A represented scholarly interpretation; no candidate is promoted to truth.',
  UNRESOLVED: 'Represented material remains under review or unresolved.',
  NOT_REPRESENTED: 'The requested conclusion is outside the represented query capability.',
  NO_MATCH: 'No matching represented claims were found in the active scope.'
};

const badge = (status, prefix = '') => {
  const value = safeText(status) || 'UNRESOLVED';
  return element('span', {
    className: `badge badge-${value.toLowerCase().replaceAll('_', '-')}`,
    text: `${prefix}${humanize(value)}`
  });
};

const saveScope = () => {
  try {
    sessionStorage.setItem('berean-scope', JSON.stringify(Array.from(scopeState.selected)));
  } catch {
    // Session persistence is optional; scope remains available in memory.
  }
};

const updateScopeSummary = () => {
  const selected = scopeState.datasets.filter((dataset) => scopeState.selected.has(Number(dataset.dataset_id)));
  const claims = selected.reduce((sum, dataset) => sum + Number(dataset.claim_count || 0), 0);
  scopeCount.textContent = `${selected.length} of ${scopeState.datasets.length} datasets · ${claims} linked claims`;
  researchButton.disabled = selected.length === 0;
};

const renderScopes = () => {
  const filter = scopeFilter.value.trim().toLowerCase();
  scopeOptions.innerHTML = '';
  const visible = scopeState.datasets.filter((dataset) =>
    `${safeText(dataset.source_name)} ${safeText(dataset.name)} ${safeText(dataset.dataset_key)}`.toLowerCase().includes(filter)
  );
  for (const dataset of visible) {
    const id = Number(dataset.dataset_id);
    const label = element('label', { className: 'scope-option' });
    const input = document.createElement('input');
    input.type = 'checkbox';
    input.value = safeText(id);
    input.checked = scopeState.selected.has(id);
    input.addEventListener('change', () => {
      if (input.checked) scopeState.selected.add(id);
      else scopeState.selected.delete(id);
      saveScope();
      updateScopeSummary();
    });
    const copy = element('span');
    copy.append(
      element('strong', { text: `${safeText(dataset.source_name)} — ${safeText(dataset.name)}` }),
      element('small', { text: `${safeText(dataset.source_record_count)} records · ${safeText(dataset.evidence_count)} evidence · ${safeText(dataset.claim_count)} claims` })
    );
    label.append(input, copy);
    scopeOptions.append(label);
  }
  scopeEmpty.hidden = visible.length > 0;
  updateScopeSummary();
};

const loadScope = async () => {
  try {
    const payload = await fetchJson('/api/research/scope');
    scopeState.datasets = payload.datasets ?? [];
    let saved = null;
    try {
      saved = JSON.parse(sessionStorage.getItem('berean-scope'));
    } catch {
      saved = null;
    }
    const validIds = new Set(scopeState.datasets.map((dataset) => Number(dataset.dataset_id)));
    const savedIds = Array.isArray(saved) ? saved.map(Number).filter((id) => validIds.has(id)) : [];
    scopeState.selected = new Set(Array.isArray(saved) ? savedIds : validIds);
    scopeOptions.setAttribute('aria-busy', 'false');
    renderScopes();
  } catch {
    scopeOptions.setAttribute('aria-busy', 'false');
    renderMessage(scopeOptions, 'Persisted research scopes could not be loaded.', 'error');
    scopeCount.textContent = 'Unavailable';
    researchButton.disabled = true;
  }
};

scopeFilter.addEventListener('input', renderScopes);
selectAllScopes.addEventListener('click', () => {
  scopeState.selected = new Set(scopeState.datasets.map((dataset) => Number(dataset.dataset_id)));
  saveScope();
  renderScopes();
});
clearScopes.addEventListener('click', () => {
  scopeState.selected.clear();
  saveScope();
  renderScopes();
  researchStatus.textContent = 'No scope selected. Select at least one persisted dataset to research.';
});

const resultCard = (result) => {
  const classification = safeText(result.classification);
  const article = element('article', { className: `result-card state-${classification.toLowerCase().replaceAll('_', '-')}` });
  article.setAttribute('aria-label', `${humanize(classification)} claim ${safeText(result.claim_key)}`);
  const heading = element('h4', { text: safeText(result.rendered_proposition) || safeText(result.claim_key) });
  const state = badge(classification);
  const metadata = definitionList([
    ['Claim', result.claim_key],
    ['Predicate', result.predicate],
    ['Claim status', result.claim_status_code],
    ['Evidence relation', result.evidence_relation_type_code],
    ['Source', result.source_name],
    ['Dataset', result.dataset_name]
  ]);
  if (result.statement) {
    metadata.append(element('dt', { text: 'Display label' }), element('dd', { text: result.statement }));
  }
  const inspect = element('button', { text: 'Inspect claim, evidence, and provenance' });
  inspect.type = 'button';
  inspect.addEventListener('click', async () => {
    selected = { type: 'claim', id: Number(result.claim_id), label: result.claim_key };
    await loadDetail(`/api/claims/${result.claim_id}`, 'claim');
    detail.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });
  article.append(state, heading, metadata, inspect);
  return article;
};

const addResearchSection = (title, description, results) => {
  if (!results.length) return;
  const section = element('section', { className: 'response-section' });
  const heading = element('h3', { text: `${title} (${results.length})` });
  section.append(heading);
  if (description) section.append(element('p', { className: 'muted', text: description }));
  for (const result of results) section.append(resultCard(result));
  researchResults.append(section);
};

const renderResearch = (payload) => {
  researchResults.innerHTML = '';
  const answer = element('section', { className: 'response-section answer' });
  const heading = element('h3', { text: 'Answer' });
  const status = badge(payload.capability, 'Capability: ');
  answer.append(heading, status, element('p', { text: payload.interpretation }));
  const description = capabilityDescription[payload.capability];
  if (description) answer.append(element('p', { className: 'muted', text: description }));
  if (payload.limitation) answer.append(element('p', { className: 'limitation', text: payload.limitation }));
  researchResults.append(answer);

  const results = payload.results ?? [];
  addResearchSection(
    'What Berean Establishes',
    'Directly source-backed claims. These are represented assertions, not declarations of truth.',
    results.filter((result) => result.classification === 'DIRECTLY_SUPPORTED')
  );
  addResearchSection(
    'Derived Relationships',
    'Distinct from direct source observations and backed by persisted derivation structure.',
    results.filter((result) => result.classification === 'DERIVED_FROM_PERSISTED_GRAPH')
  );
  addResearchSection(
    'Scholarly Interpretations',
    'Competing interpretations coexist; no candidate is selected or promoted.',
    results.filter((result) => result.classification === 'SCHOLARLY_CANDIDATE')
  );
  addResearchSection(
    'Unresolved',
    'Status and uncertainty are preserved exactly as represented.',
    results.filter((result) => result.classification === 'UNRESOLVED')
  );
  addResearchSection(
    'Evidence',
    'Contradicting and qualifying evidence retains its stored ClaimEvidence relation and is not presented as support.',
    results.filter((result) => result.classification === 'EVIDENCE_CONTRADICTS' || result.classification === 'EVIDENCE_QUALIFIES')
  );

  const sources = new Map();
  for (const result of results) {
    if (result.source_key) sources.set(result.source_key, `${safeText(result.source_name)} — ${safeText(result.dataset_name)}`);
  }
  if (sources.size) {
    const section = element('section', { className: 'response-section' });
    section.append(element('h3', { text: `Sources (${sources.size})` }));
    const list = element('ul');
    for (const source of sources.values()) list.append(element('li', { text: source }));
    section.append(list);
    researchResults.append(section);
  }

  if (payload.plan) {
    const plan = element('details', { className: 'query-plan' });
    const summary = element('summary', { text: 'Query plan and safeguards' });
    const planList = definitionList([
      ['Classification', payload.plan.classification],
      ['Traversal shape', payload.plan.traversal_shape],
      ['Traversal', payload.plan.traversal],
      ['Provenance requirement', payload.plan.provenance_requirement],
      ['Registered predicates', (payload.plan.candidate_predicates ?? []).join(', ') || 'None'],
      ['Output constraints', (payload.plan.output_constraints ?? []).join(', ')],
      ['Dataset identifiers', (payload.plan.scope?.dataset_ids ?? []).join(', ') || 'All persisted datasets']
    ]);
    plan.append(summary, planList);
    researchResults.append(plan);
  }
};

researchForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const question = researchQuestion.value.trim();
  if (!question) return;
  if (!scopeState.selected.size) {
    researchStatus.textContent = 'No scope selected. Select at least one persisted dataset to research.';
    scopeOptions.closest('details').open = true;
    scopeOptions.closest('details').scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    return;
  }
  researchController?.abort();
  researchController = new AbortController();
  setBusy(researchButton, true, 'Researching…');
  researchStatus.textContent = 'Researching persisted Berean data…';
  const allSelected = scopeState.selected.size === scopeState.datasets.length;
  try {
    const payload = await fetchJson('/api/research', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ question, datasetIds: allSelected ? [] : Array.from(scopeState.selected) }),
      signal: researchController.signal
    });
    renderResearch(payload);
    researchStatus.textContent = `${humanize(payload.capability)}. ${(payload.results ?? []).length} bounded results.`;
  } catch (error) {
    if (error.name !== 'AbortError') {
      renderMessage(researchResults, 'Research could not be completed. Please revise the question or try again.', 'error');
      researchStatus.textContent = 'Research request failed.';
    }
  } finally {
    setBusy(researchButton, false);
  }
});

const detailPathForResult = (result) => {
  switch (result.type) {
    case 'entity': return `/api/entities/${result.id}`;
    case 'claim': return `/api/claims/${result.id}`;
    case 'proposition': return `/api/propositions/${result.id}`;
    case 'event': return `/api/events/${result.id}`;
    case 'source': return `/api/sources/${result.id}`;
    default: return null;
  }
};

const renderRecords = (title, records, fields) => {
  if (!records?.length) return null;
  const section = element('section', { className: 'detail-section' });
  section.append(element('h3', { text: `${title} (${records.length})` }));
  for (const record of records) {
    const card = element('article', { className: 'compact-card' });
    card.append(definitionList(fields.map(([label, key]) => [label, record[key]])));
    section.append(card);
  }
  return section;
};

const renderClaimDetail = (payload) => {
  const claim = payload.claim;
  detail.innerHTML = '';
  detail.append(
    element('h3', { text: safeText(claim.claim_key) }),
    badge(claim.claim_status_code),
    definitionList([
      ['Claim type', claim.claim_type_code],
      ['Display label', claim.statement],
      ['Authoritative proposition', claim.rendered_proposition]
    ])
  );
  const proposition = renderRecords('Authoritative proposition', payload.proposition ? [payload.proposition] : [], [
    ['Predicate', 'predicate'],
    ['Subject entity', 'subject_entity_name'],
    ['Subject event', 'subject_event_key'],
    ['Object entity', 'object_entity_name'],
    ['Object event', 'object_event_key'],
    ['Value type', 'value_type_code'],
    ['Text value', 'text_value'],
    ['Numeric value', 'numeric_value'],
    ['Date value', 'date_value'],
    ['Duration', 'duration_value']
  ]);
  const evidence = renderRecords('Evidence', payload.evidence, [
    ['Classification', 'evidence_type_code'],
    ['Claim relation', 'relation_type_code'],
    ['Observation', 'observation'],
    ['Citation', 'locator'],
    ['Source record', 'source_record_key'],
    ['Dataset', 'dataset_name'],
    ['Source', 'source_name']
  ]);
  const derivation = renderRecords('Derivation', payload.derivation ? [payload.derivation] : [], [
    ['Method', 'method'],
    ['Assumptions', 'assumptions']
  ]);
  const unresolved = renderRecords('Related or competing claims', payload.claimRelations, [
    ['Relation', 'relation_type_code'],
    ['Claim', 'claim_key'],
    ['Related claim', 'related_claim_key'],
    ['Notes', 'notes']
  ]);
  for (const section of [proposition, derivation, evidence, unresolved]) if (section) detail.append(section);
  const provenanceButton = element('button', { text: 'Trace full provenance flow' });
  provenanceButton.type = 'button';
  provenanceButton.addEventListener('click', async () => {
    setBusy(provenanceButton, true, 'Tracing…');
    try {
      const provenance = await fetchJson(`/api/provenance/claims/${claim.claim_id}`);
      renderProvenance(provenance);
    } catch {
      detail.append(element('p', { className: 'error', text: 'Provenance could not be loaded.' }));
    } finally {
      setBusy(provenanceButton, false);
    }
  });
  detail.append(provenanceButton);
};

const renderProvenance = (payload) => {
  const section = element('section', { className: 'detail-section provenance-flow' });
  section.append(element('h3', { text: 'Provenance' }));
  const traversal = payload.traversal ?? [];
  if (!traversal.length) {
    section.append(element('p', { className: 'empty', text: 'No source-backed provenance chain is represented for this claim.' }));
  }
  for (const row of traversal) {
    const flow = element('ol', { className: 'flow' });
    for (const [label, value] of [
      ['Claim', row.claim_key],
      [`Evidence (${safeText(row.relation_type_code)})`, row.evidence_key],
      ['Citation', row.locator],
      ['Source record', row.source_record_key],
      ['Dataset', row.dataset_name],
      ['Source', row.source_name]
    ]) {
      if (value) flow.append(element('li', { text: `${label}: ${safeText(value)}` }));
    }
    section.append(flow);
  }
  detail.append(section);
};

const renderEntityDetail = (payload) => {
  detail.innerHTML = '';
  detail.append(
    element('h3', { text: payload.entity.canonical_name }),
    definitionList([
      ['Entity key', payload.entity.entity_key],
      ['Entity type', payload.entity.entity_type_code],
      ['Description', payload.entity.description]
    ])
  );
  const mappings = renderRecords('Source identities and reconciliation', payload.sourceMappings, [
    ['Source identity', 'display_name'],
    ['Mapping status', 'mapping_status_code'],
    ['Justification', 'justification'],
    ['Stored confidence', 'confidence'],
    ['Source', 'source_name']
  ]);
  const events = renderRecords('Events', payload.events, [
    ['Event', 'event_key'],
    ['Event type', 'event_type_code'],
    ['Projected role', 'role_code'],
    ['Asserting claim', 'asserting_claim_id']
  ]);
  const claims = renderRecords('Claims', payload.claims, [
    ['Claim', 'claim_key'],
    ['Claim type', 'claim_type_code'],
    ['Status', 'claim_status_code'],
    ['Display label', 'statement']
  ]);
  for (const section of [mappings, events, claims]) if (section) detail.append(section);
};

const renderEventDetail = (payload) => {
  detail.innerHTML = '';
  detail.append(
    element('h3', { text: payload.event.event_key }),
    definitionList([
      ['Event type', payload.event.event_type_code],
      ['Description', payload.event.description]
    ])
  );
  const participation = renderRecords('Claim-asserted participation', payload.participation, [
    ['Entity', 'canonical_name'],
    ['Role', 'role_code'],
    ['Asserting claim', 'claim_key'],
    ['Claim type', 'claim_type_code']
  ]);
  const claims = renderRecords('Claims', payload.claims, [
    ['Claim', 'claim_key'],
    ['Claim type', 'claim_type_code'],
    ['Status', 'claim_status_code'],
    ['Display label', 'statement']
  ]);
  for (const section of [participation, claims]) if (section) detail.append(section);
};

const renderSourceDetail = (payload) => {
  detail.innerHTML = '';
  detail.append(
    element('h3', { text: payload.source.name }),
    definitionList([
      ['Source key', payload.source.source_key],
      ['Source type', payload.source.source_type_code],
      ['Description', payload.source.description]
    ])
  );
  const datasets = renderRecords('Datasets', payload.datasets, [
    ['Dataset', 'name'],
    ['Dataset key', 'dataset_key'],
    ['Edition', 'edition_label'],
    ['Version', 'version'],
    ['License status', 'license_status'],
    ['Source records', 'source_record_count']
  ]);
  const records = renderRecords('Source records (bounded)', payload.sourceRecords, [
    ['Record', 'source_record_key'],
    ['Location', 'source_location'],
    ['Revision', 'revision_label']
  ]);
  for (const section of [datasets, records]) if (section) detail.append(section);
};

const renderGenericDetail = (payload) => {
  detail.innerHTML = '';
  const pre = element('pre', { text: JSON.stringify(payload, null, 2) });
  detail.append(pre);
};

const loadDetail = async (path, type) => {
  renderMessage(detail, 'Loading represented detail…', 'loading');
  try {
    const payload = await fetchJson(path);
    if (type === 'claim') renderClaimDetail(payload);
    else if (type === 'entity') renderEntityDetail(payload);
    else if (type === 'event') renderEventDetail(payload);
    else if (type === 'source') renderSourceDetail(payload);
    else renderGenericDetail(payload);
  } catch {
    renderMessage(detail, 'This represented detail could not be loaded.', 'error');
  }
};

searchForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const query = searchInput.value.trim();
  if (!query) return;
  searchController?.abort();
  searchController = new AbortController();
  setBusy(searchButton, true, 'Searching…');
  searchStatus.textContent = 'Searching represented records…';
  try {
    const payload = await fetchJson(`/api/search?q=${encodeURIComponent(query)}&limit=25`, { signal: searchController.signal });
    searchResults.innerHTML = '';
    for (const result of payload.results ?? []) {
      const item = element('li');
      const button = element('button', { className: 'search-hit' });
      button.type = 'button';
      button.append(badge('MATCHED'), element('span', { text: `${humanize(result.type)} · ${safeText(result.key)} · ${safeText(result.label)}` }));
      button.addEventListener('click', async () => {
        selected = result;
        const path = detailPathForResult(result);
        if (!path) {
          renderGenericDetail({ selected: result, limitation: 'No dedicated bounded detail endpoint exists for this record type.' });
          return;
        }
        await loadDetail(path, result.type);
      });
      item.append(button);
      searchResults.append(item);
    }
    const count = (payload.results ?? []).length;
    searchStatus.textContent = count ? `${count} matched records. Matches are not established claims.` : 'No represented records matched this keyword.';
    if (!count) renderMessage(searchResults, 'No represented records matched this keyword.');
  } catch (error) {
    if (error.name !== 'AbortError') {
      renderMessage(searchResults, 'Keyword search could not be completed.', 'error');
      searchStatus.textContent = 'Search request failed.';
    }
  } finally {
    setBusy(searchButton, false);
  }
});

for (const button of document.querySelectorAll('button[data-load]')) {
  button.addEventListener('click', async () => {
    const paths = {
      dashboard: '/api/dashboard/quality',
      genesis: '/api/genesis/coverage',
      sources: '/api/sources'
    };
    await loadDetail(paths[button.dataset.load], 'generic');
  });
}

const visibleGraphEdges = () => {
  const filter = relationFilter.value.trim().toLowerCase();
  return graphEdges.filter((edge) => !filter || safeText(edge.relation).toLowerCase().includes(filter));
};

const renderGraph = () => {
  graphText.innerHTML = '';
  const filtered = visibleGraphEdges();
  for (const edge of filtered.slice(0, shownGraphEdges)) {
    graphText.append(element('li', { text: `${safeText(edge.source)} —${safeText(edge.relation)}→ ${safeText(edge.target)}` }));
  }
  loadMoreGraph.hidden = filtered.length <= shownGraphEdges;
  if (!filtered.length && graphEdges.length) graphText.append(element('li', { className: 'empty', text: 'No relationships match this filter.' }));
};

expandGraph.addEventListener('click', async () => {
  if (!selected || !['entity', 'claim'].includes(selected.type)) {
    renderMessage(graphText, 'Select an entity or claim from matched records or research results first.');
    return;
  }
  setBusy(expandGraph, true, 'Expanding…');
  try {
    const payload = await fetchJson(`/api/graph?nodeType=${encodeURIComponent(selected.type)}&nodeId=${selected.id}`);
    graphEdges = payload.edges ?? [];
    shownGraphEdges = GRAPH_PAGE_SIZE;
    renderGraph();
    if (!graphEdges.length) renderMessage(graphText, 'No represented relationships are available for this node.');
  } catch {
    renderMessage(graphText, 'The bounded graph neighborhood could not be loaded.', 'error');
  } finally {
    setBusy(expandGraph, false);
  }
});

relationFilter.addEventListener('input', () => {
  shownGraphEdges = GRAPH_PAGE_SIZE;
  renderGraph();
});
loadMoreGraph.addEventListener('click', () => {
  shownGraphEdges += GRAPH_PAGE_SIZE;
  renderGraph();
});
resetGraph.addEventListener('click', () => {
  graphEdges = [];
  shownGraphEdges = GRAPH_PAGE_SIZE;
  graphText.innerHTML = '';
  loadMoreGraph.hidden = true;
});

loadScope();
