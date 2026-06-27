# ───────────────────────────────────────────────────────────────────────────
# ALDIAFAH backend — multi-stage production image
# Build context: apps/backend
# ───────────────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim AS base
ENV PNPM_HOME=/usr/local/bin
RUN corepack enable && corepack prepare pnpm@9 --activate
WORKDIR /app

# ── Build: install all deps, compile TypeScript ───────────────────────────────
FROM base AS builder
COPY package.json ./
COPY prisma ./prisma
RUN pnpm install --no-frozen-lockfile
COPY . .
RUN pnpm build

# ── Runtime ──────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim AS runner
ENV NODE_ENV=production
WORKDIR /app
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@9 --activate

# Install PROD deps (prisma CLI is in dependencies) then generate the Prisma
# client inside the final image so the correct engine binary is produced.
COPY package.json ./
COPY prisma ./prisma
RUN pnpm install --prod --no-frozen-lockfile && pnpm prisma generate

RUN mkdir -p /app/uploads
COPY --from=builder /app/dist ./dist

# Run pending migrations then boot the API.
EXPOSE 3000
CMD ["sh", "-c", "pnpm prisma migrate deploy && pnpm prisma:seed && node dist/main.js"]
