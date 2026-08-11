const searchInput = document.getElementById('searchInput');
const searchButton = document.getElementById('searchButton');
const searchResults = document.getElementById('searchResults');
const detail = document.getElementById('detail');
const expandGraph = document.getElementById('expandGraph');
const resetGraph = document.getElementById('resetGraph');
const graphText = document.getElementById('graphText');
const relationFilter = document.getElementById('relationFilter');
const researchQuestion = document.getElementById('researchQuestion');
const researchButton = document.getElementById('researchButton');
const researchResults = document.getElementById('researchResults');
const scopeOptions = document.getElementById('scopeOptions');
const scopeCount = document.getElementById('scopeCount');

let selected = null;
let graphEdges = [];

const safeText = (value) => (value === null || value === undefined ? '' : String(value));

const renderJson = (obj) => {
  detail.innerHTML = '';
  const pre = document.createElement('pre');
  pre.textContent = JSON.stringify(obj, null, 2);
  detail.appendChild(pre);
};

const selectedDatasetIds = () => Array.from(scopeOptions.querySelectorAll('input:checked')).map((input) => Number(input.value));

const loadScope = async () => {
  const response = await fetch('/api/research/scope');
  if (!response.ok) return;
  const payload = await response.json();
  scopeOptions.innerHTML = '';
  for (const dataset of payload.datasets ?? []) {
    const label = document.createElement('label');
    const input = document.createElement('input');
    input.type = 'checkbox';
    input.value = dataset.dataset_id;
    input.checked = true;
    input.addEventListener('change', () => {
      scopeCount.textContent = `(${selectedDatasetIds().length} datasets selected)`;
    });
    label.append(input, ` ${safeText(dataset.source_name)} — ${safeText(dataset.name)} (${safeText(dataset.claim_count)} claims)`);
    scopeOptions.append(label, document.createElement('br'));
  }
  scopeCount.textContent = `(${selectedDatasetIds().length} datasets selected)`;
};

researchButton.addEventListener('click', async () => {
  const question = researchQuestion.value.trim();
  if (!question) return;
  researchResults.textContent = 'Researching persisted Berean data…';
  const response = await fetch('/api/research', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ question, datasetIds: selectedDatasetIds() })
  });
  const payload = await response.json();
  researchResults.innerHTML = '';
  const heading = document.createElement('h3');
  heading.textContent = `${safeText(payload.capability)} — ${safeText(payload.interpretation ?? payload.error)}`;
  researchResults.appendChild(heading);
  if (payload.plan) {
    const plan = document.createElement('details');
    const summary = document.createElement('summary');
    summary.textContent = 'Normalized query plan';
    const pre = document.createElement('pre');
    pre.textContent = JSON.stringify(payload.plan, null, 2);
    plan.append(summary, pre);
    researchResults.appendChild(plan);
  }
  for (const result of payload.results ?? []) {
    const item = document.createElement('article');
    item.className = 'research-result';
    item.textContent = `${safeText(result.classification)} · ${safeText(result.claim_key)} · ${safeText(result.predicate)} · ${safeText(result.source_name)} / ${safeText(result.dataset_name)}`;
    researchResults.appendChild(item);
  }
  if (payload.limitation) {
    const limitation = document.createElement('p');
    limitation.textContent = payload.limitation;
    researchResults.appendChild(limitation);
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

const loadData = async (path) => {
  const response = await fetch(path);
  if (!response.ok) {
    renderJson({ error: `Request failed (${response.status})`, path });
    return;
  }
  renderJson(await response.json());
};

searchButton.addEventListener('click', async () => {
  const q = searchInput.value.trim();
  if (!q) return;
  const response = await fetch(`/api/search?q=${encodeURIComponent(q)}&limit=25`);
  const payload = await response.json();
  searchResults.innerHTML = '';

  for (const result of payload.results ?? []) {
    const item = document.createElement('li');
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = `${safeText(result.type)} • ${safeText(result.key)} • ${safeText(result.label)}`;
    button.addEventListener('click', async () => {
      selected = result;
      const path = detailPathForResult(result);
      if (!path) {
        renderJson({ selected: result, message: 'No dedicated endpoint for this type yet.' });
        return;
      }
      await loadData(path);
    });
    item.appendChild(button);
    searchResults.appendChild(item);
  }
});

for (const button of document.querySelectorAll('button[data-load]')) {
  button.addEventListener('click', async () => {
    if (button.dataset.load === 'dashboard') await loadData('/api/dashboard/quality');
    if (button.dataset.load === 'genesis') await loadData('/api/genesis/coverage');
    if (button.dataset.load === 'sources') await loadData('/api/sources');
  });
}

expandGraph.addEventListener('click', async () => {
  if (!selected || !['entity', 'claim'].includes(selected.type)) {
    renderJson({ message: 'Select an entity or claim from search results first.' });
    return;
  }
  const response = await fetch(`/api/graph?nodeType=${encodeURIComponent(selected.type)}&nodeId=${selected.id}`);
  const payload = await response.json();
  graphEdges = payload.edges ?? [];

  const filter = relationFilter.value.trim().toLowerCase();
  graphText.innerHTML = '';
  for (const edge of graphEdges) {
    if (filter && !safeText(edge.relation).toLowerCase().includes(filter)) continue;
    const li = document.createElement('li');
    li.textContent = `${safeText(edge.source)} --${safeText(edge.relation)}--> ${safeText(edge.target)}`;
    graphText.appendChild(li);
  }

  renderJson(payload);
});

relationFilter.addEventListener('input', () => {
  graphText.innerHTML = '';
  const filter = relationFilter.value.trim().toLowerCase();
  for (const edge of graphEdges) {
    if (filter && !safeText(edge.relation).toLowerCase().includes(filter)) continue;
    const li = document.createElement('li');
    li.textContent = `${safeText(edge.source)} --${safeText(edge.relation)}--> ${safeText(edge.target)}`;
    graphText.appendChild(li);
  }
});

resetGraph.addEventListener('click', () => {
  graphEdges = [];
  graphText.innerHTML = '';
});

loadScope();
