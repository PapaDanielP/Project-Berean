import { createApp } from './app.js';

const port = Number.parseInt(process.env.PORT ?? '3000', 10);
const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required');
}

const app = createApp(databaseUrl);
app.listen(port, () => {
  process.stdout.write(`Berean read-only explorer listening on :${port}\n`);
});
