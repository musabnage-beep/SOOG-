# ALDIAFAH — Deploy with NO domain (Render)

This is the **zero-domain** launch path. Render gives every service a free
`*.onrender.com` subdomain with **real HTTPS**, so you get valid TLS (which the
mobile app and Apple require) without buying a domain. Postgres is free too.

Everything is described by [`render.yaml`](../render.yaml) at the repo root —
Render reads it as a **Blueprint** and creates all 4 resources in one shot:

| Resource        | Render name      | URL                                    |
|-----------------|------------------|----------------------------------------|
| PostgreSQL      | `aldiafa-db`     | (internal)                             |
| API (NestJS)    | `aldiafa-api`    | `https://aldiafa-api.onrender.com`     |
| Admin dashboard | `aldiafa-admin`  | `https://aldiafa-admin.onrender.com`   |
| Staff dashboard | `aldiafa-staff`  | `https://aldiafa-staff.onrender.com`   |

> If any name is already taken, Render appends a random suffix. If that happens,
> update `CORS_ORIGINS` (api) and `NEXT_PUBLIC_API_URL` (both dashboards) to the
> real URLs in the Render dashboard, then redeploy.

---

## 1. Push the repo to GitHub
The repo is already at `https://github.com/musabnage-beep/SOOG-.git`, branch `main`.
Make sure `render.yaml` is committed and pushed.

## 2. Create the Blueprint on Render
1. Sign up at <https://render.com> (free, use the GitHub login).
2. **New → Blueprint**.
3. Connect the GitHub repo `SOOG-` and pick branch `main`.
4. Render detects `render.yaml` and lists the 4 resources. Click **Apply**.
5. When prompted for the `SEED_ADMIN_PASSWORD` (it is marked `sync: false`,
   i.e. you must type it), enter a strong password — this is the admin login.

Render now builds the API + both dashboards from their Dockerfiles and
provisions Postgres. First build takes a few minutes.

## 3. Seed the database (once)
The API runs `prisma migrate deploy` automatically on every boot. The one-time
seed (admin user, 3 roles, 17 permissions, 18 categories, settings, delivery
zones) must be run once:

- Open the `aldiafa-api` service → **Shell** tab → run:
  ```bash
  pnpm prisma:seed
  ```
  > Render's Shell is a paid feature. On the free plan instead temporarily set
  > the API service **Start Command** (Settings → Docker Command) to
  > `pnpm prisma migrate deploy && pnpm prisma:seed && node dist/main.js`,
  > deploy once, then revert it to the default so it doesn't reseed every boot.

## 4. Verify
- `https://aldiafa-api.onrender.com/api/health` → `{ "status": "ok" }`
- `https://aldiafa-api.onrender.com/api/docs` → Swagger UI
- `https://aldiafa-admin.onrender.com` → admin login (sign in with
  `admin@aldiafah.com` + the password from step 2)
- `https://aldiafa-staff.onrender.com` → staff login

## 5. Point the mobile app at the API
The Flutter app is COD-only and just needs the API base URL at build time:
```bash
flutter build apk   --dart-define=API_BASE_URL=https://aldiafa-api.onrender.com/api
flutter build ipa   --dart-define=API_BASE_URL=https://aldiafa-api.onrender.com/api
```

---

## Free-tier notes (important)
- **Free web services sleep** after ~15 min idle and cold-start on the next
  request (a few seconds). Fine for testing / a soft launch.
- **Free Postgres expires after ~30 days** and the instance is small. For a real
  launch, upgrade the DB (and ideally the API) to a paid instance, or move to the
  AWS path in [`AWS_DEPLOYMENT.md`](./AWS_DEPLOYMENT.md). The app code is identical.
- **Persistent uploads:** the free plan has an ephemeral filesystem, so
  `STORAGE_PROVIDER=local` uploads are lost on redeploy/restart. For durable
  product images switch to S3: set `STORAGE_PROVIDER=s3` + `AWS_REGION`,
  `S3_BUCKET`, `S3_PUBLIC_BASE_URL`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
  in the `aldiafa-api` env vars.

## Turning on real integrations later
All providers default to dev/no-op adapters so the platform boots with zero keys.
Flip any of these in the `aldiafa-api` service env vars when you have accounts:

| Feature   | Env to change                          | Extra keys needed                                  |
|-----------|----------------------------------------|----------------------------------------------------|
| Payments  | `PAYMENT_PROVIDER=moyasar`             | `MOYASAR_SECRET_KEY`, `MOYASAR_WEBHOOK_SECRET`     |
| SMS / OTP | `SMS_PROVIDER=unifonic` (or `twilio`)  | `SMS_API_KEY`, `SMS_SENDER_ID`                     |
| Push      | `PUSH_PROVIDER=fcm`                     | `FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY`     |
| Email     | `MAIL_PROVIDER=ses`                     | AWS creds + `MAIL_FROM`, `SES_REGION`              |
| Maps      | `MAPS_PROVIDER=google`                  | `GOOGLE_MAPS_API_KEY`                              |

After enabling Moyasar, register the webhook in the Moyasar dashboard at
`https://aldiafa-api.onrender.com/api/payments/webhook` with the same secret as
`MOYASAR_WEBHOOK_SECRET`.

## Privacy Policy & Support URL (also free, no domain)
Apple/Google require a Privacy Policy URL and a Support URL. Without a domain you
can host both free on **GitHub Pages** (enable Pages on this repo → a `docs/`
folder) or a public **Notion** page. Use those URLs in App Store / Play Console.
