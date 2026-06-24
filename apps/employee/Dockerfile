# ───────────────────────────────────────────────────────────────────────────
# ALDIAFAH employee dashboard — Next.js standalone multi-stage image
# Build context: monorepo root (because it depends on packages/shared)
#   docker build -f apps/employee/Dockerfile -t aldiafa-employee .
# ───────────────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim AS base
RUN corepack enable && corepack prepare pnpm@9 --activate
WORKDIR /app

# ── Install workspace deps (employee + shared) ───────────────────────────────
FROM base AS deps
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY packages/shared/package.json ./packages/shared/package.json
COPY apps/employee/package.json ./apps/employee/package.json
RUN pnpm install --no-frozen-lockfile --filter @aldiafa/employee...

# ── Build ────────────────────────────────────────────────────────────────────
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/packages/shared/node_modules ./packages/shared/node_modules
COPY --from=deps /app/apps/employee/node_modules ./apps/employee/node_modules
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY packages ./packages
COPY apps/employee ./apps/employee
# NEXT_PUBLIC_* values are inlined at build time.
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
RUN pnpm --filter @aldiafa/employee build

# ── Runtime (minimal standalone server) ──────────────────────────────────────
FROM node:20-bookworm-slim AS runner
ENV NODE_ENV=production
ENV PORT=3200
ENV HOSTNAME=0.0.0.0
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs

COPY --from=build /app/apps/employee/.next/standalone ./
COPY --from=build /app/apps/employee/.next/static ./apps/employee/.next/static
COPY --from=build /app/apps/employee/public ./apps/employee/public

USER nextjs
EXPOSE 3200
CMD ["node", "apps/employee/server.js"]
