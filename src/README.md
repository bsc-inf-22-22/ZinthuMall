# Kachipapa Store — Backend Setup

## Quick Start (Everyone on the team)

### Step 1 — Install Docker
- **Ubuntu/Linux:** `sudo apt install docker.io docker-compose -y`
- **Windows:** Download Docker Desktop from https://docker.com
- **Mac:** Download Docker Desktop from https://docker.com

### Step 2 — Clone the repo
```bash
git clone https://github.com/bsc-inf-22-22/ZinthuMall.git
cd ZinthuMall
```

### Step 3 — Run everything
```bash
docker-compose up --build
```

Wait for these messages:
```
kachipapa_postgres   | database system is ready to accept connections
kachipapa_admin      | Kachipapa Admin API running on http://localhost:3000/api
kachipapa_inventory  | ZinthuMall Inventory API running on http://localhost:3001
```

### Step 4 — Test it works
Open your browser:
- http://localhost:3000/api → Admin Backend ✅
- http://localhost:3001 → Inventory Service ✅

### Step 5 — Register the admin (first time only!)
```bash
curl -X POST http://localhost:3000/api/admin/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@kachipapa.mw","password":"Admin@1234"}'
```

### Step 6 — Run Flutter app
```bash
cd your-flutter-project
flutter run -d chrome
```

Long press the KachipapaStore logo → Admin Login → use the credentials above.

## API Endpoints

### Auth
| Method | URL | Description |
|--------|-----|-------------|
| POST | /api/admin/auth/register | Register admin (once only) |
| POST | /api/admin/auth/login | Login → returns JWT token |

### Products
| Method | URL | Auth |
|--------|-----|------|
| GET | /api/products | No |
| GET | /api/products/:id | No |
| GET | /api/products/category/:cat | No |
| POST | /api/products | Yes (JWT) |
| PATCH | /api/products/:id | Yes (JWT) |
| DELETE | /api/products/:id | Yes (JWT) |

### Inventory
| Method | URL | Description |
|--------|-----|-------------|
| GET | /inventory | All products with stock |
| GET | /inventory/low-stock | Products with < 5 units |
| POST | /inventory/add-stock | Add stock |
| POST | /inventory/reduce-stock | Reduce stock |

## Stop the backend
```bash
docker-compose down
```

## Fresh start (wipe database)
```bash
docker-compose down -v
docker-compose up --build
```
