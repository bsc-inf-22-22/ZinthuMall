<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

<p align="center">Kachipapa Store — Admin Backend API built with NestJS</p>

---

## Description

REST API for the Kachipapa Store admin dashboard. Handles admin authentication, product management, order management and analytics.

---

## 1. Database Setup

### Install PostgreSQL
Download and install PostgreSQL from https://www.postgresql.org/download/

### Create the database
Open pgAdmin or psql and run:
```sql
CREATE DATABASE "Admin";
```

### Configure environment variables
Create a `.env` file in the root of the project:

.env configurations
DB_HOST=localhost

DB_PORT=5432

DB_USER=postgres

DB_PASS=your_postgres_password

DB_NAME=Admin
JWT_SECRET=

cloudinary for storing images
CLOUDINARY_CLOUD_NAME=your_cloud_name

CLOUDINARY_API_KEY=your_api_key

CLOUDINARY_API_SECRET=your_api_secret

> Tables are created automatically on first run via TypeORM `synchronize: true`.

---

## 2. Running the Server

### Install dependencies
```bash
$ npm install
```

### Development
```bash
$ npm run start:dev
```

### Production
```bash
$ npm run build
$ npm run start:prod
```

Server runs on `http://localhost:3000`

---

## 3. All Routes

### Auth
| Method | Route | Protection | Description |
|--------|-------|------------|-------------|
| POST | `/api/admin/auth/register` | Public | Register admin (one-time only) |
| POST | `/api/admin/auth/login` | Public | Login and get JWT token |
| PATCH | `/api/admin/auth/password` | JWT | Change admin password |

### Products
| Method | Route | Protection | Description |
|--------|-------|------------|-------------|
| POST | `/api/products` | JWT | Create new product |
| GET | `/api/products` | Public | Get all products |
| GET | `/api/products/:id` | Public | Get single product |
| GET | `/api/products/search?q=` | Public | Search products |
| GET | `/api/products/category/:category` | Public | Filter by category |
| PATCH | `/api/products/:id` | JWT | Update product |
| DELETE | `/api/products/:id` | JWT | Delete product |

### Orders (Admin View)
| Method | Route | Protection | Description |
|--------|-------|------------|-------------|
| GET | `/api/admin/orders` | JWT | Get all orders |
| GET | `/api/admin/orders/stats` | JWT | Get order statistics |
| GET | `/api/admin/orders/status/:status` | JWT | Filter orders by status |
| GET | `/api/admin/orders/:id` | JWT | Get single order |
| PATCH | `/api/admin/orders/:id/status` | JWT | Update order status |

### Analytics
| Method | Route | Protection | Description |
|--------|-------|------------|-------------|
| GET | `/api/admin/analytics/summary` | JWT | Dashboard summary cards |
| GET | `/api/admin/analytics/revenue` | JWT | Revenue chart (last 7 days) |
| GET | `/api/admin/analytics/top-products` | JWT | Top 5 best selling products |

---

## 4. Response JSON

### Auth

**POST `/api/admin/auth/register`**
```json
{
  "message": "Admin registered successfully"
}
```

**POST `/api/admin/auth/login`**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**PATCH `/api/admin/auth/password`**
```json
{
  "message": "Password updated successfully"
}
```

---

### Products

**GET `/api/products`**
```json
{
  "id": 1,
  "name": "Classic Oxford Shirt",
  "category": "Men's Clothing",
  "price": "4500.00",
  "stock": 50,
  "discount": 10,
  "description": "A classic oxford shirt",
  "sizes": ["S", "M", "L"],
  "imageUrl": "https://res.cloudinary.com/djbknbnqe/image/upload/v1/kachipapa/products/sample.jpg",
  "createdAt": "2026-06-10T22:29:47.704Z",
  "updatedAt": "2026-06-10T22:29:47.704Z"
}
```

**GET `/api/products/search?q=shirt`**
```json
[
  {
    "id": 1,
    "name": "Classic Oxford Shirt",
    "category": "Men's Clothing",
    "price": "4500.00",
    "stock": 50,
    "discount": 10,
    "description": "A classic oxford shirt",
    "sizes": ["S", "M", "L"],
    "imageUrl": "https://res.cloudinary.com/djbknbnqe/image/upload/v1/kachipapa/products/sample.jpg",
    "createdAt": "2026-06-10T22:29:47.704Z",
    "updatedAt": "2026-06-10T22:29:47.704Z"
  }
]
```

---

### Orders

**GET `/api/admin/orders`**
```json
[
  {
    "id": 1,
    "customerName": "Chisomo Banda",
    "customerEmail": "chisomo@gmail.com",
    "customerPhone": "0881234567",
    "deliveryAddress": "Area 47",
    "deliveryCity": "Lilongwe",
    "totalAmount": "4500.00",
    "status": "processing",
    "paymentStatus": "paid",
    "paymentMethod": "airtel_money",
    "transactionId": "TXN001",
    "items": [
      {
        "productId": 1,
        "productName": "Classic Oxford Shirt",
        "productImage": "https://res.cloudinary.com/...",
        "price": 4500,
        "quantity": 1,
        "size": "M"
      }
    ],
    "createdAt": "2026-06-10T22:29:47.704Z",
    "updatedAt": "2026-06-10T22:29:47.704Z"
  }
]
```

**GET `/api/admin/orders/stats`**
```json
{
  "total": 38,
  "pending": 10,
  "processing": 15,
  "shipped": 8,
  "delivered": 5,
  "totalRevenue": 247000
}
```

**PATCH `/api/admin/orders/:id/status`**
```json
{
  "id": 1,
  "status": "shipped",
  "updatedAt": "2026-06-10T22:29:47.704Z"
}
```

---

### Analytics

**GET `/api/admin/analytics/summary`**
```json
{
  "totalRevenue": 247000,
  "revenueGrowth": 18,
  "ordersToday": 38,
  "ordersTodayGrowth": 5,
  "productsListed": 124,
  "productsAddedThisWeek": 6
}
```

**GET `/api/admin/analytics/revenue`**
```json
[
  { "date": "2026-06-04", "revenue": 32000 },
  { "date": "2026-06-05", "revenue": 45000 },
  { "date": "2026-06-06", "revenue": 28000 },
  { "date": "2026-06-07", "revenue": 51000 },
  { "date": "2026-06-08", "revenue": 38000 },
  { "date": "2026-06-09", "revenue": 42000 },
  { "date": "2026-06-10", "revenue": 11000 }
]
```

**GET `/api/admin/analytics/top-products`**
```json
[
  {
    "productId": 1,
    "productName": "Classic Oxford Shirt",
    "totalSold": 45,
    "totalRevenue": 202500
  }
]
```

---

## Error Responses

```json
{ "statusCode": 400, "message": ["field is required"], "error": "Bad Request" }
{ "statusCode": 401, "message": "Unauthorized" }
{ "statusCode": 404, "message": "Product #5 not found", "error": "Not Found" }
{ "statusCode": 409, "message": "Admin already registered", "error": "Conflict" }
```

---

## Docker

```bash
# Run with docker
docker-compose up --build

# Run only admin backend and database
docker-compose up admin-backend postgres
```

---

## Support

- NestJS Documentation - https://docs.nestjs.com
- License - [MIT](https://github.com/nestjs/nest/blob/master/LICENSE)