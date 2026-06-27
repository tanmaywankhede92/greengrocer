# Greengrocer Backend

Node.js + Express + MongoDB backend for the Mandi Bill Buddy wholesale billing system.

---

## Quick Start

```bash
npm install
npm run dev          # Development (nodemon)
npm start            # Production
```

Server starts on `http://localhost:5000`.

---

## Folder Structure

```
src/
├── config/          # database.js (Mongoose), index.js (env)
├── helpers/         # apiResponse, asyncHandler, pagination, sequenceGenerator
├── middlewares/      # authenticate, authorize, validate, errorHandler, rateLimiter
├── models/          # 11 Mongoose schemas (User, Customer, Product, DailyRate, Bill, BillItem, Payment, LedgerEntry, BusinessSetting, AuditLog, Counter)
├── validators/      # express-validator rulesets (auth, customer, product, rate, bill, payment, settings)
├── repositories/    # Data access layer (9 repos)
├── services/        # Business logic (10 services)
├── controllers/     # Request handlers (10 controllers)
├── routes/          # Route → controller (10 route files + index.js aggregator)
├── app.js           # Express app setup
└── server.js        # Entry point
```

---

## Environment (.env)

| Variable | Required | Default |
|----------|----------|---------|
| PORT | No | 5000 |
| NODE_ENV | No | development |
| MONGODB_URI | **Yes** | — |
| JWT_SECRET | **Yes** | — |
| JWT_REFRESH_SECRET | **Yes** | — |
| JWT_EXPIRY | No | 15m |
| JWT_REFRESH_EXPIRY | No | 7d |
| CORS_ORIGIN | No | * |

---

## API Endpoints

| Module | Endpoints |
|--------|-----------|
| Auth | POST /api/v1/auth/register, login, refresh, logout · GET /me |
| Dashboard | GET /api/v1/dashboard |
| Customers | CRUD /api/v1/customers (soft delete) |
| Products | CRUD /api/v1/products + PATCH /toggle |
| Rates | GET+PUT /api/v1/rates · GET /history/:id |
| Bills | CRUD /api/v1/bills + POST /:id/cancel |
| Payments | GET+POST /api/v1/payments |
| Ledger | GET /api/v1/ledger/:customerId |
| Statements | GET /api/v1/statements/:customerId |
| Settings | GET+PUT /api/v1/settings (PUT = admin) |
| Health | GET /health |

Full details: [../API_REFERENCE.md](../API_REFERENCE.md)

---

## Database

MongoDB (greengrocer DB) with 11 collections. Optimized indexes on billNumber, receiptNumber, email, mobile, and compound indexes for query patterns.

---

## Architecture

**Layered:** Routes → Validators → Controllers → Services → Repositories → Models

**Key patterns:**
- Async handlers wrapped with `asyncHandler` (no try/catch in controllers)
- Atomic bill creation using MongoDB transactions (session)
- Atomic invoice numbering using `findOneAndUpdate` + `$inc` on Counter collection
- Aggregation pipeline for running balances and dashboard stats
- Soft deletes via `isDeleted` flag / `status: cancelled`

---

## Dependencies

- **express** — HTTP framework
- **mongoose** — MongoDB ODM
- **jsonwebtoken** — JWT auth
- **bcryptjs** — Password hashing
- **express-validator** — Input validation
- **winston** — Logging
- **helmet** — Security headers
- **cors** — CORS middleware
- **dotenv** — Environment variables
- **rate-limiter-flexible** — Rate limiting
