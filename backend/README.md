# Kachipapa Store API

NestJS + TypeORM + PostgreSQL. All routes are under `/api`.

## Scripts

```bash
npm run start:dev                      # watch mode
npm run build && npm run start:prod    # production
npm run lint
npm run test:e2e                       # needs TEST_DATABASE_URL (database is wiped!)

# After changing an entity, create a migration and commit it:
npm run migration:generate -- src/migrations/DescribeTheChange
```

Pending migrations run automatically on startup (`DB_RUN_MIGRATIONS=false` to disable).

## Environment

See [`.env.example`](.env.example). In production the app refuses to start without `JWT_SECRET` (32+ chars), a database URL and `ADMIN_SETUP_KEY`.

## Endpoints

🔓 public · 👤 customer token · 🔑 admin token

| Method | Path | |
|---|---|---|
| GET | `/health` | 🔓 health check |
| **Products** | | |
| GET | `/products` · `/products/:id` · `/products/category/:category` · `/products/search?q=` | 🔓 |
| POST, PATCH | `/products`, `/products/:id` (multipart; optional `image` file) | 🔑 |
| DELETE | `/products/:id` | 🔑 |
| **Customers** | | |
| POST | `/customer/auth/register` · `/customer/auth/login` → `{access_token, customer}` | 🔓 |
| GET, PATCH | `/customer/profile` | 👤 |
| **Orders** | | |
| POST | `/orders` (guest or 👤) `{customerName, customerEmail?, customerPhone, deliveryAddress, deliveryCity, paymentMethod, items:[{productId, quantity, size?}]}` | 🔓 |
| GET | `/orders/mine` · `/orders/mine/:id` | 👤 |
| GET | `/orders/track/:id?phone=` | 🔓 |
| GET | `/admin/orders?status=` · `/admin/orders/stats` · `/admin/orders/:id` | 🔑 |
| PATCH | `/admin/orders/:id/status` `{status}` (cancelling restocks) | 🔑 |
| PATCH | `/admin/orders/:id/payment` `{paymentStatus, transactionId?}` | 🔑 |
| **Wishlist** | | |
| GET · POST · DELETE | `/wishlist` · `/wishlist/:productId` | 👤 |
| **Reviews** | | |
| GET | `/reviews/product/:id` · `/reviews/product/:id/summary` | 🔓 |
| GET, POST | `/reviews/mine`, `/reviews` `{productId, rating, comment?}` | 👤 |
| GET, DELETE | `/admin/reviews` · `/admin/reviews/stats` · `/admin/reviews/:id` | 🔑 |
| **Inventory** | | |
| GET | `/inventory` · `/inventory/low-stock` · `/inventory/out-of-stock` · `/inventory/history/:productId` | 🔑 |
| POST | `/inventory/add-stock` · `/inventory/reduce-stock` `{productId, quantity, notes?}` | 🔑 |
| **Admin** | | |
| POST | `/admin/auth/register` (header `X-Setup-Key`, first admin only) · `/admin/auth/login` | 🔓 |
| PATCH | `/admin/auth/password` | 🔑 |
| GET, PATCH | `/admin/notifications…` · `/admin/analytics/summary\|revenue\|top-products` | 🔑 |
| GET | `/settings` (delivery fee, free-delivery threshold, store contacts) | 🔓 |
| PATCH | `/admin/settings` | 🔑 |

Login, registration and checkout are rate-limited per IP.
