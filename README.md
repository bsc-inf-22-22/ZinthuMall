# Kachipapa Store

Malawi's online marketplace for fashion and home essentials. Customers browse, add to cart and check out with Airtel Money, TNM Mpamba or cash on delivery. The store owner manages products, stock and orders from the admin dashboard.

Design reference: <https://kachipapa-store.netlify.app/>

| Folder | What it is | Tech |
|---|---|---|
| [`app/`](app/) | Customer storefront and admin dashboard (web + Android) | Flutter, Riverpod |
| [`backend/`](backend/) | REST API | NestJS, TypeORM, PostgreSQL |

## Run it locally

You need Node 20+, Flutter 3.24+ and either Docker or a local PostgreSQL.

**1. Start the API**

```bash
docker compose up --build          # Postgres + API on http://localhost:3000/api
```

Or without Docker:

```bash
cd backend
cp .env.example .env               # set DATABASE_URL to your local Postgres
npm install
npm run start:dev
```

Database tables are created automatically on startup (migrations in `backend/src/migrations`).

**2. Start the app**

```bash
cd app
flutter pub get
flutter run -d chrome              # web, talks to http://localhost:3000/api
flutter run                        # Android emulator, talks to http://10.0.2.2:3000/api
```

**3. Create the store admin**

Long-press the **Kachipapa Store** logo on the home page (or open `/#/admin/register`), then register with the **setup key** (`ADMIN_SETUP_KEY`, `local-setup-key` in docker-compose). Only one admin account can be created.

## Deploy

### Backend → Render

1. Push this repo to GitHub.
2. Render dashboard → **New → Blueprint** → select the repo. `render.yaml` creates the `kachipapa-api` web service and the `kachipapa-db` database.
3. In the service's **Environment** tab, set:
   - `CORS_ORIGINS`: the storefront URL, e.g. `https://kachipapa-store.netlify.app`
   - `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` (free account at cloudinary.com, used for product photos)
4. Copy the generated `ADMIN_SETUP_KEY`; you need it once to create the admin account.
5. Check `https://<your-service>.onrender.com/api/health` returns `{"status":"ok"}`.

> The blueprint uses Render's **free** plans for testing. Before real customers use it, switch the database and web service to paid plans: free databases expire and free services sleep when idle.

Railway works too: create a PostgreSQL service and a service from `backend/` (it has a Dockerfile), then set the same variables. Railway's `DATABASE_URL` needs `DB_SSL=true` if you use the public connection URL.

### Web storefront → Netlify

```bash
cd app
flutter build web --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com/api
```

Then drag `app/build/web` onto Netlify (**Sites → Add new site → Deploy manually**), or deploy with `netlify deploy --prod --dir build/web`. Add the Netlify URL to `CORS_ORIGINS` on the backend.

### Android app

1. Create an upload key once (keep it safe; you can't update the Play Store app without it):
   ```bash
   keytool -genkey -v -keystore ~/kachipapa-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `app/android/key.properties` (never commit it):
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/home/you/kachipapa-upload.jks
   ```
3. Build:
   ```bash
   cd app
   flutter build appbundle --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com/api   # Play Store
   flutter build apk --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com/api         # direct install
   ```

The Android application ID is `com.kachipapa.store`.

## How the pieces fit

```
Flutter app (web / Android)
        │  HTTPS, JSON, Bearer token
        ▼
NestJS API  ── /api/products, /api/orders, /api/customer/…, /api/admin/…
        │
        ▼
PostgreSQL   products · orders · customers · inventory_transactions · reviews · wishlist_items · notifications · settings · admin
```

- **Checkout** sends only product IDs, quantities and sizes. The API looks up prices, applies the delivery fee from store settings, reserves stock in a database transaction and notifies the admin.
- **Payments**: orders start as `pending`. The admin confirms Airtel Money / Mpamba payments in **Orders → Record Payment** with the transaction ID. (Automatic Pachangu payment integration is not built yet.)
- **Stock** changes are logged in `inventory_transactions`; cancelling an order puts its items back in stock.
- **Customers** can check out as guests; logged-in customers get order history, a saved wishlist, a default address and reviews. Anyone can track an order with its number and phone.

See [`backend/README.md`](backend/README.md) for the full API list.
