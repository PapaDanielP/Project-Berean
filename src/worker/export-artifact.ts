import { constants } from 'node:fs';
import fs from 'node:fs/promises';
import path from 'node:path';
import { createHash, randomUUID } from 'node:crypto';

export const EXPORT_CONTENT_TYPE = 'application/x-ndjson';
export const EXPORT_FORMAT_VERSION = 'berean.claim-evidence.v1';
const LOCATOR_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.jsonl$/;

export class ExportArtifactError extends Error {
  constructor(readonly code: string) {
    super(code);
    this.name = 'ExportArtifactError';
  }
}

const configuredRoot = async (configuredDirectory: string | undefined, create: boolean): Promise<string> => {
  if (!configuredDirectory) throw new ExportArtifactError('EXPORT_ARTIFACT_DIR_MISSING');
  if (!path.isAbsolute(configuredDirectory)) throw new ExportArtifactError('EXPORT_ARTIFACT_DIR_INVALID');
  const resolved = path.resolve(configuredDirectory);
  try {
    if (create) await fs.mkdir(resolved, { recursive: true, mode: 0o700 });
    const [stat, real] = await Promise.all([fs.lstat(resolved), fs.realpath(resolved)]);
    if (!stat.isDirectory() || stat.isSymbolicLink() || real !== resolved) {
      throw new ExportArtifactError('EXPORT_ARTIFACT_DIR_INVALID');
    }
    return resolved;
  } catch (error) {
    if (error instanceof ExportArtifactError) throw error;
    throw new ExportArtifactError('EXPORT_ARTIFACT_DIR_INVALID');
  }
};

const artifactPath = (root: string, locator: string): string => {
  if (!LOCATOR_PATTERN.test(locator)) throw new ExportArtifactError('EXPORT_ARTIFACT_LOCATOR_INVALID');
  const resolved = path.resolve(root, locator);
  if (path.dirname(resolved) !== root) throw new ExportArtifactError('EXPORT_ARTIFACT_LOCATOR_INVALID');
  return resolved;
};

export interface ExportArtifactRecord {
  artifactKey: string;
  exportJobId: number;
  contentType: string;
  formatVersion: string;
  byteLength: number;
  sha256: string;
  relativeLocator: string;
}

export interface PreparedExportArtifact {
  record: ExportArtifactRecord;
  discard: () => Promise<void>;
}

export const writeExportArtifact = async (
  configuredDirectory: string | undefined,
  exportJobId: number,
  bytes: Buffer
): Promise<PreparedExportArtifact> => {
  const root = await configuredRoot(configuredDirectory, true);
  const artifactKey = randomUUID();
  const relativeLocator = `${artifactKey}.jsonl`;
  const finalPath = artifactPath(root, relativeLocator);
  const temporaryPath = path.resolve(root, `.tmp-${randomUUID()}`);
  const sha256 = createHash('sha256').update(bytes).digest('hex');
  let handle: fs.FileHandle | undefined;
  try {
    handle = await fs.open(temporaryPath, constants.O_CREAT | constants.O_EXCL | constants.O_WRONLY | constants.O_NOFOLLOW, 0o600);
    await handle.writeFile(bytes);
    await handle.sync();
    await handle.close();
    handle = undefined;
  } catch {
    await handle?.close().catch(() => undefined);
    await fs.unlink(temporaryPath).catch(() => undefined);
    throw new ExportArtifactError('EXPORT_ARTIFACT_WRITE_FAILED');
  }
  let renamed = false;
  try {
    await fs.lstat(finalPath).then(
      () => { throw new ExportArtifactError('EXPORT_ARTIFACT_RENAME_FAILED'); },
      (error: NodeJS.ErrnoException) => {
        if (error.code !== 'ENOENT') throw error;
      }
    );
    await fs.rename(temporaryPath, finalPath);
    renamed = true;
    const directory = await fs.open(root, constants.O_RDONLY);
    await directory.sync();
    await directory.close();
  } catch {
    await fs.unlink(temporaryPath).catch(() => undefined);
    if (renamed) await fs.unlink(finalPath).catch(() => undefined);
    throw new ExportArtifactError('EXPORT_ARTIFACT_RENAME_FAILED');
  }
  return {
    record: {
      artifactKey,
      exportJobId,
      contentType: EXPORT_CONTENT_TYPE,
      formatVersion: EXPORT_FORMAT_VERSION,
      byteLength: bytes.byteLength,
      sha256,
      relativeLocator
    },
    discard: () => fs.unlink(finalPath).catch(() => undefined)
  };
};

export const readExportArtifact = async (
  configuredDirectory: string | undefined,
  locator: string,
  expectedLength: number,
  expectedSha256: string
): Promise<Buffer> => {
  const root = await configuredRoot(configuredDirectory, false);
  const resolved = artifactPath(root, locator);
  try {
    const handle = await fs.open(resolved, constants.O_RDONLY | constants.O_NOFOLLOW);
    const stat = await handle.stat();
    if (!stat.isFile() || stat.size !== expectedLength) {
      await handle.close();
      throw new ExportArtifactError('EXPORT_ARTIFACT_UNAVAILABLE');
    }
    const bytes = await handle.readFile();
    await handle.close();
    if (createHash('sha256').update(bytes).digest('hex') !== expectedSha256) {
      throw new ExportArtifactError('EXPORT_ARTIFACT_UNAVAILABLE');
    }
    return bytes;
  } catch (error) {
    if (error instanceof ExportArtifactError) throw error;
    throw new ExportArtifactError('EXPORT_ARTIFACT_UNAVAILABLE');
  }
};
