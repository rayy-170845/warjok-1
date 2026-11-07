# Warjok POS

Point of Sale (POS) web app built with **Next.js 16 (App Router)**, **React 19**, **TypeScript**, **Tailwind CSS v4/shadcn**, **Drizzle ORM**, and **Neon Postgres + Neon Auth**.

## Stack
- App: Next.js 16, React 19, TypeScript (strict), path alias `@/*` → `src/*`
- Package manager/runtime: **Bun** (lockfile `bun.lock`)
- Styling/UI: Tailwind CSS v4, shadcn/ui (`src/components/ui`)
- Lint/format: oxlint (`bun lint`), ESLint config for Next
- Database: Drizzle ORM + `pg` (schemas in `src/server/db/schema`, migrations in `drizzle/`)
- Auth: `@neon/auth` (server + middleware), route protection via `src/proxy.ts`

## Prerequisites
- Bun 1.3+ (project uses Bun scripts)
- A Neon project with Postgres and Neon Auth enabled

## Setup
1. Install dependencies:
   ```bash
   bun install
   ```
2. Copy env template and fill values (local only, do not commit `.env`):
   ```bash
   cp .env.example .env
   ```
3. Start the dev server:
   ```bash
   bun dev
   ```
   Open [http://localhost:3000](http://localhost:3000).

## Environment Variables
Set locally in `.env` and in Vercel **Project Settings → Environment Variables** (Production/Preview as needed). Do **not** use `NEXT_PUBLIC_` for server secrets.

| Variable | Where | Required | Notes |
|---|---|---:|---|
| `NODE_ENV` | server | yes | `development` / `production` |
| `NEXT_PUBLIC_APP_URL` | client | yes | e.g. `http://localhost:3000` or deployed URL |
| `DATABASE_URL` | server | yes | Neon Postgres connection string |
| `NEON_AUTH_BASE_URL` | server | yes | Neon Auth base URL |
| `NEON_AUTH_JWKS_URL` | server | yes | Neon Auth JWKS URL |
| `NEON_AUTH_COOKIE_SECRET` | server | yes | **Create your own random secret** (not from Neon dashboard), e.g. `openssl rand -base64 32` or `bun -e "console.log(require('crypto').randomBytes(32).toString('base64'))"` |
| `NEXT_PUBLIC_NEON_AUTH_URL` | client | yes | Neon Auth public URL |
| `DATABASE_URL_UNPOOLED` | server | optional | Not used by current app code |
| `NEON_BRANCH`, `PORT`, `VITE_APP_NAME`, `FREEMIUS_*` | — | no | Not used by current app code / optional |

## Scripts
```bash
bun dev          # Next dev server
bun build        # Production build
bun start        # Start production server
bun lint         # oxlint
bun run typecheck # tsc --noEmit
bun test         # bun test
bun run test:integration # database integration tests (dedicated test database only)

bun db:generate  # drizzle-kit generate
bun db:migrate   # drizzle-kit migrate
bun db:push      # drizzle-kit push
bun db:seed      # seed business/demo data
bun db:studio    # drizzle-kit studio
```

Database integration tests are skipped unless `WARJOK_TEST_DATABASE_URL` points
to a dedicated test database that is different from `DATABASE_URL`. Apply the
schema and seed that test database before running `bun run test:integration`.
Never point integration tests at production; they create and remove test rows.

## Database & Auth Notes
- Drizzle schema lives in `src/server/db/schema/` and outputs migrations to `drizzle/`. Review migrations before applying to shared/production databases.
- Neon Auth tables (`neon_auth`) are managed by Neon — avoid modifying them via app migrations.
- RBAC/profile data is stored in app tables (e.g. `core.UserProfiles`, `core.Roles`). After a DB reset, ensure required roles/permissions are seeded and user profiles are re-established on login as needed.
- When the default business or store is missing, an owner is redirected to `/setup`. The setup form creates only the business, store, and minimal settings after explicit submission; it does not create sample categories or products.
- `bun run db:seed` creates sample business data. Do not run it against production unless you explicitly intend to populate that database.

## Deploy (Vercel)
1. Push to the connected branch (e.g. `master`).
2. Configure all required Environment Variables in Vercel.
3. Set `NEON_AUTH_COOKIE_SECRET` to a strong random value (same key name; rotate carefully — existing sessions may be invalidated).
4. Deploy. If the build fails on typecheck, ensure test files aren’t included in production TS checks and route files export valid route modules.

## Project Layout (high level)
- `src/app/` — App Router routes (dashboard, profile, auth, API)
- `src/components/` — shared UI/components
- `src/features/` — feature modules
- `src/server/` — auth, db, repositories/services/business logic
- `src/lib/`, `src/hooks/`, `src/stores/`, `src/shared/`, `src/types/`
