# ALDIAFAH — AWS Deployment Guide

This guide deploys the full platform (API + Postgres + Admin + Employee dashboards
behind nginx) to AWS. Two paths are described:

- **Path A — Single EC2 host** (fastest, all containers on one box). Matches
  `infra/docker-compose.prod.yml` and the `Deploy` GitHub Action.
- **Path B — Managed services** (RDS + S3 + SES + ALB) for production scale.

```
                       ┌────────────────────────────────────────────┐
   Route 53 (DNS)      │                  EC2 host                   │
   api.   ───────────► │  nginx :80/:443                             │
   admin. ───────────► │   ├─► api      (NestJS)    :3000            │
   staff. ───────────► │   ├─► admin    (Next.js)   :3100            │
                       │   └─► employee (Next.js)   :3200            │
                       │  postgres :5432  (Path A)  ──► RDS (Path B) │
                       │  uploads volume  (Path A)  ──► S3  (Path B) │
                       └────────────────────────────────────────────┘
```

---

## 0. Prerequisites

- A registered domain in **Route 53** (or any DNS provider).
- AWS account with permission to create EC2, RDS, S3, SES, IAM.
- The three external integrations are optional at launch (dev adapters run without them):
  Google Maps API key, Firebase FCM service account, AWS SES (email).

---

## Path A — Single EC2 host

### 1. Launch EC2
- AMI: Ubuntu 22.04 LTS, type: `t3.small` (min) / `t3.medium` (comfortable).
- Storage: 30 GB gp3.
- Security group inbound: `22` (your IP), `80`, `443` (anywhere).
- Allocate an **Elastic IP** and associate it.

### 2. DNS (Route 53)
Create A records pointing at the Elastic IP:
```
api.aldiafah.example    → <elastic-ip>
admin.aldiafah.example  → <elastic-ip>
staff.aldiafah.example  → <elastic-ip>
```

### 3. Install Docker on the host
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER   # re-login after this
```

### 4. Clone & configure
```bash
sudo mkdir -p /opt/aldiafa && sudo chown $USER /opt/aldiafa
git clone https://github.com/musabnage-beep/SOOG-.git /opt/aldiafa
cd /opt/aldiafa
cp infra/.env.example infra/.env
nano infra/.env   # set DB password, JWT secrets, CORS_ORIGINS, public API URLs
```

Generate strong secrets:
```bash
openssl rand -hex 24   # use for JWT_ACCESS_SECRET and JWT_REFRESH_SECRET
```

### 5. First boot
```bash
docker compose -f infra/docker-compose.prod.yml --env-file infra/.env up -d --build
docker compose -f infra/docker-compose.prod.yml logs -f api   # watch migrate + boot
```
The API runs `prisma migrate deploy` on start. To seed the admin + 18 categories:
```bash
docker compose -f infra/docker-compose.prod.yml exec api pnpm prisma:seed
```

### 6. TLS (Let's Encrypt)
```bash
# issue certs (repeat per subdomain, or use -d for all three)
docker run --rm \
  -v /opt/aldiafa/infra/certbot/conf:/etc/letsencrypt \
  -v /opt/aldiafa/infra/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d api.aldiafah.example -d admin.aldiafah.example -d staff.aldiafah.example \
  --email you@example.com --agree-tos --no-eff-email
```
Then uncomment the `443` server blocks + the http→https redirect in
`infra/nginx/conf.d/aldiafa.conf` and reload:
```bash
docker compose -f infra/docker-compose.prod.yml exec nginx nginx -s reload
```
Add a cron/systemd timer to run `certbot renew` + nginx reload monthly.

### 7. Continuous deploy (GitHub Actions)
Set repo secrets: `DEPLOY_HOST`, `DEPLOY_USER` (`ubuntu`), `DEPLOY_SSH_KEY`,
`DEPLOY_PATH` (`/opt/aldiafa`). Pushing a `v*` tag (or running the **Deploy**
workflow manually) SSHes in, pulls, and `up -d --build`.

---

## Path B — Managed services (production scale)

Swap single-host pieces for managed AWS services:

| Concern        | Path A (single host)        | Path B (managed)                         |
|----------------|-----------------------------|------------------------------------------|
| Database       | `postgres` container        | **RDS for PostgreSQL** (Multi-AZ)        |
| File uploads   | `uploads` docker volume     | **S3 bucket** (`STORAGE_PROVIDER=s3`)    |
| Email          | dev adapter                 | **SES** (`MAIL_PROVIDER=ses`)            |
| TLS + routing  | nginx + certbot             | **ACM cert + Application Load Balancer** |
| Static/CDN     | nginx                       | **CloudFront** in front of the ALB       |
| Logs/metrics   | `docker logs`               | **CloudWatch** (awslogs log driver)      |

### RDS
1. Create a PostgreSQL 16 instance, same VPC/SG as EC2, port 5432 open only to the
   EC2 security group.
2. Remove the `postgres` service from the compose file (or just don't use it).
3. Point `DATABASE_URL` in `infra/.env` at the RDS endpoint:
   `postgresql://USER:PASS@<rds-endpoint>:5432/aldiafa?schema=public&sslmode=require`

### S3 (uploads)
1. Create bucket `aldiafa-uploads` (block public access; serve via CloudFront/presigned URLs).
2. Create an IAM user/role with `s3:PutObject/GetObject/DeleteObject` on that bucket.
3. In `infra/.env`: `STORAGE_PROVIDER=s3`, `AWS_REGION`, `S3_BUCKET`,
   `S3_PUBLIC_BASE_URL` (CloudFront/bucket URL used to build public image links),
   `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (prefer an instance role over keys).

### SES (email)
1. Verify your domain + DKIM in SES, request production access (out of sandbox).
2. `MAIL_PROVIDER=ses` + the same AWS creds/region.

### Payments (Moyasar)
Card payments (mada / Apple Pay / Visa / Mastercard) go through Moyasar. The
default `PAYMENT_PROVIDER=console` is a no-op dev adapter — switch to `moyasar`
for real charges. Cash-on-delivery (COD) works regardless of this setting.
1. Create a Moyasar account and grab the **secret API key** from the dashboard.
2. In `infra/.env`:
   ```
   PAYMENT_PROVIDER=moyasar
   MOYASAR_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxx
   MOYASAR_WEBHOOK_SECRET=<a strong random token you choose>
   PAYMENT_CALLBACK_URL=https://api.aldiafah.example/api/payments/callback
   ```
3. In the Moyasar dashboard → **Webhooks**, register:
   `https://api.aldiafah.example/api/payments/webhook` and set its shared secret
   to the same value as `MOYASAR_WEBHOOK_SECRET`. The backend rejects any webhook
   whose `secret_token` does not match, and re-queries Moyasar before marking an
   order paid (it never trusts the callback query string).

### ALB + ACM + CloudFront
- Request an ACM certificate for `*.aldiafah.example` (in the ALB's region; for
  CloudFront use `us-east-1`).
- ALB target groups → EC2/ECS tasks on `:3000/:3100/:3200`, host-based routing rules
  mirroring the nginx vhosts. In this setup nginx can be dropped.
- Optionally put CloudFront in front for global caching of dashboard assets.

---

## Operations

**Backups (Path A):**
```bash
docker compose -f infra/docker-compose.prod.yml exec postgres \
  pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > backup-$(date +%F).sql.gz
```
Schedule daily via cron; copy dumps to S3 (`aws s3 cp`). On RDS use automated
snapshots + PITR.

**Restore:**
```bash
gunzip -c backup-YYYY-MM-DD.sql.gz | \
  docker compose -f infra/docker-compose.prod.yml exec -T postgres \
  psql -U "$POSTGRES_USER" "$POSTGRES_DB"
```

**Disaster recovery:** images are reproducible from git (`up -d --build`); the only
stateful pieces are the database and uploads. Keep daily DB dumps + S3 versioning,
and the platform can be rebuilt on a fresh host in minutes by re-running steps 3–6.

**Health:** API exposes `/api/health`. Wire ALB/Route53 health checks to it.

**Logs:** `docker compose -f infra/docker-compose.prod.yml logs -f <service>`; on
managed setups use the `awslogs` driver → CloudWatch.
