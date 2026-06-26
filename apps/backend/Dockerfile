# ───────────────────────────────────────────────────────────────────────────
# ALDIAFAH backend — multi-stage production image
# Build context: apps/backend
# ───────────────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim AS base
ENV PNPM_HOME=/usr/local/bin
RUN corepack enable && corepack prepare pnpm@9 --activate
WORKDIR /app

# ── Build (all deps + prisma generate + compile + prune to prod) ─────────────
FROM base AS builder
COPY package.json ./
COPY prisma ./prisma
# Install all deps (including prisma CLI from devDependencies)
RUN pnpm install --no-frozen-lockfile
COPY . .
# Generate Prisma client, compile TypeScript, then strip dev packages in-place
RUN pnpm prisma generate && pnpm build && pnpm prune --prod

# ── Runtime ──────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim AS runner
ENV NODE_ENV=production
WORKDIR /app
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@9 --activate

# node_modules already pruned to prod + contains generated .prisma client
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
COPY --from=builder /app/prisma ./prisma

# Run pending migrations then boot the API.
EXPOSE 3000
CMD ["sh", "-c", "pnpm prisma migrate deploy && node dist/main.js"]
