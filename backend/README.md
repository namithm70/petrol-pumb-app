# BPCL POS Backend

Node.js + PostgreSQL backend that matches the Flutter app API in `lib/form.dart`.

## Setup
1. Start Postgres (the repo includes `docker-compose.yml`).
2. Install deps:

```bash
npm install
```

3. Initialize schema + seed data:

```bash
npm run db:init
```

4. Start server:

```bash
npm run dev
```

The API runs on `http://localhost:3001` by default.

## Environment
Copy `.env.example` to `.env` if you want to override defaults.
