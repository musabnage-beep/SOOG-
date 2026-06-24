# ALDIAFAH | الضيافة

Production-grade commerce & centralized order-management platform for Saudi Arabia.

## Monorepo layout

| Path             | System                              | Status        |
| ---------------- | ----------------------------------- | ------------- |
| `apps/backend`   | NestJS + Prisma + PostgreSQL API    | **Phase 1**   |
| `apps/mobile`    | Flutter customer app (iOS/Android)  | Phase 2       |
| `apps/admin`     | Next.js 15 admin dashboard          | Phase 3       |
| `apps/employee`  | Next.js 15 employee dashboard       | Phase 3       |
| `packages/shared`| Shared TS API contracts             | Phase 3       |
| `infra`          | Docker / nginx / CI / AWS infra     | Phase 4       |

## Prerequisites

- Node.js >= 20
- pnpm >= 9
- PostgreSQL 15+ (local, Docker, or AWS RDS)

## Quick start (backend)

```bash
pnpm install
cp apps/backend/.env.example apps/backend/.env   # then fill values
pnpm --filter @aldiafa/backend prisma:generate
pnpm --filter @aldiafa/backend prisma:migrate
pnpm --filter @aldiafa/backend prisma:seed
pnpm backend:dev
```

API: `http://localhost:3000` · Swagger docs: `http://localhost:3000/api/docs`

### With Docker

```bash
cd apps/backend
docker compose up --build
```

## Default seeded admin

Configured via `.env` (`SEED_ADMIN_EMAIL`, `SEED_ADMIN_PASSWORD`). Change after first login.

## Color system

Primary `#166534` · Secondary `#22C55E` · Cream `#FFF8E7` · Dark `#111827` · Gold accent `#D4AF37`
