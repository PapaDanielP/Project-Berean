const searchInput = document.getElementById('searchInput');
const searchButton = document.getElementById('searchButton');
const searchResults = document.getElementById('searchResults');
const detail = document.getElementById('detail');
const expandGraph = document.getElementById('expandGraph');
const resetGraph = document.getElementById('resetGraph');
const graphText = document.getElementById('graphText');
const relationFilter = document.getElementById('relationFilter');

let selected = null;
let graphEdges = [];

const safeText = (value) => (value === null || value === undefined ? '' : String(value));

const renderJson = (obj) => {
  detail.innerHTML = '';
  const pre = document.createElement('pre');
  pre.textContent = JSON.stringify(obj, null, 2);
  detail.appendChild(pre);
};

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
