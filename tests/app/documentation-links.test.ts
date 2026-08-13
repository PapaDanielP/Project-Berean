import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

const repositoryRoot = process.cwd();
const skippedDirectories = new Set(['.git', 'node_modules', 'dist']);

const collectMarkdownFiles = (directory: string): string[] => {
  const files: string[] = [];
  for (const entry of readdirSync(directory)) {
    if (skippedDirectories.has(entry)) continue;
    const fullPath = path.join(directory, entry);
    const stats = statSync(fullPath);
    if (stats.isDirectory()) {
      files.push(...collectMarkdownFiles(fullPath));
    } else if (entry.endsWith('.md')) {
      files.push(fullPath);
    }
  }
  return files;
};

const localLinkPattern = /(?<!!)\[[^\]]*]\(([^)\s]+)(?:\s+"[^"]*")?\)/g;
const externalLinkPattern = /^[a-z][a-z0-9+.-]*:/i;

describe('documentation repository structure', () => {
  it('keeps canonical documentation authority entry points in place', () => {
    for (const relativePath of [
      'docs/README.md',
      'docs/01-architecture/REPOSITORY_STRUCTURE.md',
      'docs/api/API_DEVELOPER_GUIDE.md',
      'docs/api/API_CAPABILITY_MATRIX.md',
      'docs/api/OPENAPI_GAP_REPORT.md',
      'docs/05-validation/VALIDATION.md',
      'docs/phases/README.md',
      'docs/04-data/README.md'
    ]) {
      expect(existsSync(path.join(repositoryRoot, relativePath)), relativePath).toBe(true);
    }
  });

  it('does not contain broken local Markdown links', () => {
    const brokenLinks: string[] = [];
    for (const file of collectMarkdownFiles(repositoryRoot)) {
      const markdown = readFileSync(file, 'utf8');
      for (const match of markdown.matchAll(localLinkPattern)) {
        const target = match[1];
        if (!target || target.startsWith('#') || externalLinkPattern.test(target)) continue;
        const targetPath = decodeURIComponent(target.split('#', 1)[0]);
        if (!targetPath) continue;
        const resolvedPath = path.resolve(path.dirname(file), targetPath);
        if (!existsSync(resolvedPath)) {
          brokenLinks.push(`${path.relative(repositoryRoot, file)} -> ${target}`);
        }
      }
    }
    expect(brokenLinks).toEqual([]);
  });
});
