# BPCL POS Backend

Node.js + PostgreSQL backend that matches the Flutter app API in `lib/form.dart`.

## Setup (Local)
1) Install deps:

```bash
npm install
```

2) Initialize schema + seed data:

```bash
npm run db:init
```

3) Start server:

```bash
npm run dev
```

## Render Deploy
This repo includes `render.yaml` to provision the web service + Postgres.
After deploy, run:

```bash
node src/init.js
```

## Environment
Copy `.env.example` to `.env` if you want to override defaults.
