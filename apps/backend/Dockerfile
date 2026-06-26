# ───────────────────────────────────────────────────────────────────────────
# ALDIAFAH backend — multi-stage production image
# Build context: apps/backend
# ───────────────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim AS base
ENV PNPM_HOME=/usr/local/bin
RUN corepack enable && corepack prepare pnpm@9 --activate
WORKDIR /app

# ── Dependencies (with dev deps for the build) ──────────────────────────────
FROM base AS deps
COPY package.json ./
RUN pnpm install --no-frozen-lockfile

# ── Build ───────────────────────────────────────────────────────────────────
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm prisma generate && pnpm build

# ── Production dependencies + Prisma client ──────────────────────────────────
FROM base AS prod-deps
COPY package.json ./
COPY prisma ./prisma
RUN pnpm install --prod --no-frozen-lockfile && pnpm prisma generate

# ── Runtime ──────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim AS runner
ENV NODE_ENV=production
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@9 --activate

COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
COPY prisma ./prisma

# Run pending migrations then boot the API.
EXPOSE 3000
CMD ["sh", "-c", "pnpm prisma migrate deploy && node dist/main.js"]
