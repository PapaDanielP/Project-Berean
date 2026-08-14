import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

// This suite verifies repository documentation navigability and link integrity without any
// external network access or database dependency. It protects the canonical entry points,
// the canonical API documentation location, the phase-history indexes, the repository
// placement authority, and the consolidation audit report established by the repository-wide
// documentation and structural integrity audit.

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

const read = (relativePath: string): string =>
  fs.readFileSync(path.join(repoRoot, relativePath), 'utf8');

const exists = (relativePath: string): boolean => fs.existsSync(path.join(repoRoot, relativePath));

const CANONICAL_ENTRY_POINTS = [
  'README.md',
  'docs/README.md',
  'docs/01-architecture/ARCHITECTURE.md',
  'docs/01-architecture/REPOSITORY_STRUCTURE.md',
  'docs/02-domain/DOMAIN_MODEL.md',
  'docs/03-schema/INFORMATION_SCHEMA.md',
  'docs/05-validation/VALIDATION.md',
  'docs/phases/README.md',
  'docs/04-data/README.md',
  'docs/07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md',
  'docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md'
];

const CANONICAL_API_DOCS = [
  'docs/api/API_DEVELOPER_GUIDE.md',
  'docs/api/API_CAPABILITY_MATRIX.md',
  'docs/api/API_EPISTEMIC_BOUNDARIES.md',
  'docs/api/API_LIMITATIONS.md',
  'docs/api/API_SECURITY_MODEL.md',
  'docs/api/API_WORKFLOWS.md',
  'docs/api/OPENAPI_GAP_REPORT.md',
  'docs/api/VERIFICATION_REPORT.md'
];

// Markdown files (and their directory) that were consolidated away or never existed and must
// not reappear as live links. This guards against reintroducing stale/obsolete canonical paths.
const OBSOLETE_PATH_FRAGMENTS = [
  'docs/architecture/',
  'docs/data/',
  'docs/administration/',
  'docs/ingestion/',
  'docs/research/',
  'docs/history/phases/',
  'docs/development/',
  'docs/operations/'
];

const isExternalLink = (target: string): boolean =>
  /^([a-z]+:)?\/\//i.test(target) || target.startsWith('mailto:');

const extractLocalMarkdownLinks = (content: string): string[] => {
  const links: string[] = [];
  const linkPattern = /\[[^\]]*\]\(([^)]+)\)/g;
  let match: RegExpExecArray | null;
  while ((match = linkPattern.exec(content)) !== null) {
    const target = match[1].trim();
    if (isExternalLink(target)) continue;
    const [withoutAnchor] = target.split('#');
    if (!withoutAnchor) continue; // pure in-page anchor
    links.push(withoutAnchor);
  }
  return links;
};

const collectMarkdownFiles = (dir: string): string[] => {
  const absoluteDir = path.join(repoRoot, dir);
  const entries = fs.readdirSync(absoluteDir, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    if (entry.name === 'node_modules' || entry.name.startsWith('.')) continue;
    const relativePath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectMarkdownFiles(relativePath));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      files.push(relativePath);
    }
  }
  return files;
};

describe('documentation navigation and link integrity', () => {
  it('has every canonical entry point present on disk', () => {
    for (const entryPoint of CANONICAL_ENTRY_POINTS) {
      expect(exists(entryPoint), `missing canonical entry point: ${entryPoint}`).toBe(true);
    }
  });

  it('has every canonical API document present under the single docs/api location', () => {
    for (const apiDoc of CANONICAL_API_DOCS) {
      expect(exists(apiDoc), `missing canonical API doc: ${apiDoc}`).toBe(true);
    }
  });

  it('does not define a competing API documentation directory outside docs/api', () => {
    const forbiddenDirectories = ['docs/architecture/api', 'docs/data/api', 'src/api-docs'];
    for (const dir of forbiddenDirectories) {
      expect(exists(dir), `unexpected competing API doc location: ${dir}`).toBe(false);
    }
  });

  it('links from README.md to docs/README.md, and docs/README.md to every documentation domain', () => {
    const rootReadme = read('README.md');
    expect(rootReadme).toMatch(/docs\/README\.md/);

    const docsIndex = read('docs/README.md');
    const expectedTargets = [
      '01-architecture/ARCHITECTURE.md',
      '01-architecture/REPOSITORY_STRUCTURE.md',
      '02-domain/DOMAIN_MODEL.md',
      '03-schema/INFORMATION_SCHEMA.md',
      'api/API_DEVELOPER_GUIDE.md',
      '05-validation/VALIDATION.md',
      '04-data/',
      'phases/'
    ];
    for (const target of expectedTargets) {
      expect(docsIndex, `docs/README.md does not reference ${target}`).toContain(target);
    }
  });

  it('makes docs/phases/README.md the canonical phase-history index referencing legacy and later phases', () => {
    const phasesIndex = read('docs/phases/README.md');
    expect(phasesIndex).toMatch(/04-data\//);
    expect(phasesIndex).toContain('PHASE_37R_37B_WORLD_COLUMBIAN_EXPOSITION_EXPANSION.md');
  });

  it('makes docs/01-architecture/REPOSITORY_STRUCTURE.md the canonical placement authority', () => {
    const docsIndex = read('docs/README.md');
    expect(docsIndex).toContain('REPOSITORY_STRUCTURE.md');
    const structureDoc = read('docs/01-architecture/REPOSITORY_STRUCTURE.md');
    expect(structureDoc).toMatch(/Placement rules for new contributions/i);
  });

  it('contains the consolidation audit in docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md', () => {
    const report = read('docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md');
    expect(report).toMatch(/Authority hierarchy/i);
    expect(report).toMatch(/API documentation audit/i);
  });

  it('contains the documentation governance audit in docs/07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md', () => {
    const report = read('docs/07-review/DOCUMENTATION_GOVERNANCE_AUDIT.md');
    expect(report).toMatch(/Executive summary/i);
    expect(report).toMatch(/OpenAPI/i);
  });

  it('contains no references to obsolete/superseded canonical documentation paths', () => {
    // The consolidation report itself discusses these fragments as illustrative negative
    // examples (paths that were considered and intentionally not adopted); exclude it from
    // this scan so that discussing them does not trip the guard meant for live references.
    const exemptFiles = new Set(['docs/07-review/REPOSITORY_CONSOLIDATION_REPORT.md']);
    const markdownFiles = collectMarkdownFiles('docs')
      .concat(collectMarkdownFiles('.').filter(
        (file) => !file.startsWith('docs/') && !file.includes('node_modules')
      ))
      .filter((file) => !exemptFiles.has(file));
    for (const file of markdownFiles) {
      const content = read(file);
      for (const fragment of OBSOLETE_PATH_FRAGMENTS) {
        expect(
          content.includes(fragment),
          `${file} references obsolete canonical path fragment: ${fragment}`
        ).toBe(false);
      }
    }
  });

  it('resolves every local Markdown link within docs/ to an existing file or directory', () => {
    const markdownFiles = collectMarkdownFiles('docs');
    const broken: string[] = [];
    for (const file of markdownFiles) {
      const content = read(file);
      const links = extractLocalMarkdownLinks(content);
      const fileDir = path.dirname(file);
      for (const link of links) {
        const resolved = path.normalize(path.join(fileDir, link));
        if (!exists(resolved)) {
          broken.push(`${file} -> ${link} (resolved: ${resolved})`);
        }
      }
    }
    expect(broken, `broken local Markdown links:\n${broken.join('\n')}`).toEqual([]);
  });
});
