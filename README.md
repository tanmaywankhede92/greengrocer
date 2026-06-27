# 🥦 Greengrocer — Mandi Bill Buddy

> **Production-grade wholesale vegetable & fruit billing system**  
> Flutter (tablet-first) + Node.js/Express + MongoDB

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Reference](#api-reference)
- [Database Design](#database-design)
- [Key Features](#key-features)
- [Business Flow](#business-flow)
- [Security](#security)
- [Development](#development)

---

## 🎯 Overview

Mandi Bill Buddy is a wholesale vegetable & fruit billing system originally built with TypeScript/React/Supabase. This repo is a **full production-grade rebuild** using:

- **Frontend:** Flutter (Riverpod, Go Router, Material 3) — tablet-first responsive design
- **Backend:** Node.js, Express, MongoDB/Mongoose — layered architecture

The system manages daily market rates, generates bills for wholesale customers, tracks ledger/payments, and provides dashboard analytics — all tailored for Indian mandi (wholesale market) workflows.

---

## 🏗 Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Tablet)                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │   Auth    │ │   Bill   │ │   Rate   │ │ Dashboard│  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│         │           │            │            │         │
│         └───────────┴────────────┴────────────┘         │
│                        │ HTTP/JSON                      │
│                   (Dio Client)                          │
└────────────────────────┬────────────────────────────────┘
                         │
                  JWT Bearer Token
                         │
┌────────────────────────▼────────────────────────────────┐
│               Node.js/Express Backend                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │   Routes  │▶│  Valid.  │▶│  Contr.  │▶│ Services │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│                                                   │     │
│                                              ┌────▼──┐ │
│                                              │  Repo  │ │
│                                              └───┬───┘ │
│                                                  │     │
└──────────────────────────────────────────────────┼─────┘
                                                   │
                                          Mongoose ODM
                                                   │
┌──────────────────────────────────────────────────▼───────┐
│                   MongoDB Atlas (greengrocer)             │
│  11 Collections: users, customers, products, daily_rates, │
│  bills, bill_items, payments, ledger_entries,             │
│  business_settings, audit_logs, counters                  │
└──────────────────────────────────────────────────────────┘
```

### Layered Backend Pattern

```
src/
├── config/          # DB connection, app config
├── helpers/         # Sequence generator, API response, pagination
├── middlewares/      # Auth, authorize, validate, error handler, rate limiter
├── models/          # Mongoose schemas + indexes
├── validators/      # Express-validator rulesets
├── repositories/    # Data access layer (queries)
├── services/        # Business logic layer
├── controllers/     # Request/response handling
└── routes/          # Route definitions → controllers
```

---

## 🧰 Tech Stack

### Frontend (Flutter)

| Component | Choice |
|-----------|--------|
| State Management | Riverpod 2.x |
| Routing | Go Router |
| HTTP Client | Dio |
| Charts | fl_chart |
| PDF/Print | printing |
| Secure Storage | flutter_secure_storage |
| UI Framework | Material 3 (M3) |
| Theme | Dark mode, custom color scheme |
| Platform | Tablet-first, responsive breakpoints |

### Backend (Node.js)

| Component | Choice |
|-----------|--------|
| Runtime | Node.js 18+ |
| Framework | Express 4.x |
| Database | MongoDB 7+ (Atlas) |
| ODM | Mongoose 8.x |
| Auth | JWT (jsonwebtoken) + bcrypt |
| Validation | express-validator |
| Logging | Winston |
| Security | helmet, cors, rate-limiter-flexible |

### Database (MongoDB)

- **11 collections** with optimized indexes
- **Atomic transactions** for bill generation (session-based)
- **Decimal128** ready for monetary values
- **Aggregation pipeline** for running balances, dashboard stats

---

## 📁 Project Structure

```
greengrocer/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   ├── database.js        # Mongoose connection with pooling
│   │   │   └── index.js           # Environment config
│   │   ├── helpers/
│   │   │   ├── apiResponse.js     # Standardized response builder
│   │   │   ├── asyncHandler.js    # Async error wrapper
│   │   │   ├── pagination.js      # Pagination helper
│   │   │   └── sequenceGenerator.js # Atomic counter via findOneAndUpdate
│   │   ├── middlewares/
│   │   │   ├── authenticate.js    # JWT Bearer token verification
│   │   │   ├── authorize.js       # Role-based access control
│   │   │   ├── errorHandler.js    # Global error handler
│   │   │   ├── rateLimiter.js     # Rate limiting (auth vs general)
│   │   │   └── validate.js        # Validation middleware wrapper
│   │   ├── models/
│   │   │   ├── User.js
│   │   │   ├── Customer.js
│   │   │   ├── Product.js
│   │   │   ├── DailyRate.js
│   │   │   ├── Bill.js
│   │   │   ├── BillItem.js
│   │   │   ├── Payment.js
│   │   │   ├── LedgerEntry.js
│   │   │   ├── BusinessSetting.js
│   │   │   ├── AuditLog.js
│   │   │   └── Counter.js
│   │   ├── validators/
│   │   │   ├── auth.validator.js
│   │   │   ├── customer.validator.js
│   │   │   ├── product.validator.js
│   │   │   ├── rate.validator.js
│   │   │   ├── bill.validator.js
│   │   │   └── payment.validator.js
│   │   ├── repositories/
│   │   │   ├── userRepository.js
│   │   │   ├── customerRepository.js
│   │   │   ├── productRepository.js
│   │   │   ├── rateRepository.js
│   │   │   ├── billRepository.js
│   │   │   ├── billItemRepository.js
│   │   │   ├── paymentRepository.js
│   │   │   ├── ledgerRepository.js
│   │   │   └── settingsRepository.js
│   │   ├── services/
│   │   │   ├── authService.js
│   │   │   ├── customerService.js
│   │   │   ├── productService.js
│   │   │   ├── rateService.js
│   │   │   ├── billService.js       # Core atomic billing logic
│   │   │   ├── paymentService.js
│   │   │   ├── ledgerService.js
│   │   │   ├── dashboardService.js   # Parallel aggregations
│   │   │   ├── statementService.js   # Running balance calc
│   │   │   └── settingsService.js
│   │   ├── controllers/
│   │   │   ├── authController.js
│   │   │   ├── dashboardController.js
│   │   │   ├── customerController.js
│   │   │   ├── productController.js
│   │   │   ├── rateController.js
│   │   │   ├── billController.js
│   │   │   ├── paymentController.js
│   │   │   ├── ledgerController.js
│   │   │   ├── statementController.js
│   │   │   └── settingsController.js
│   │   ├── routes/
│   │   │   ├── index.js             # Route aggregator
│   │   │   ├── auth.routes.js
│   │   │   ├── dashboard.routes.js
│   │   │   ├── customer.routes.js
│   │   │   ├── product.routes.js
│   │   │   ├── rate.routes.js
│   │   │   ├── bill.routes.js
│   │   │   ├── payment.routes.js
│   │   │   ├── ledger.routes.js
│   │   │   ├── statement.routes.js
│   │   │   └── settings.routes.js
│   │   ├── app.js                   # Express app setup
│   │   └── server.js                # Server entrypoint
│   ├── seeds/
│   │   └── seedProducts.js          # 20 product seeds
│   ├── .env                         # Environment variables
│   └── package.json
├── PHASE2_FLUTTER_ARCHITECTURE.md
├── PHASE3_BACKEND_ARCHITECTURE.md
├── PHASE4_DATABASE_DESIGN.md
├── PHASE5_API_DOCUMENTATION.md
├── API_REFERENCE.md                 # Complete API reference
└── README.md                        # This file
```

---

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- MongoDB 7+ (Atlas or local)
- Flutter SDK 3.22+ (for frontend)

### Backend Setup

```bash
# 1. Navigate to backend
cd backend

# 2. Install dependencies
npm install

# 3. Create .env file
cat > .env << EOF
PORT=5000
NODE_ENV=development
MONGODB_URI=mongodb+srv://yt-backend:sLyQSeJMcWVvpcxG@yt-project-backend.azjkpke.mongodb.net/greengrocer
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-in-production
JWT_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d
CORS_ORIGIN=*
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=100
AUTH_RATE_LIMIT_MAX=10
EOF

# 4. Start server
npm run dev
```

The server starts on `http://localhost:5000`. Health check: `GET /health`

### Frontend Setup (Flutter)

```bash
# 1. Create Flutter project
flutter create --org com.greengrocer --project-name greengrocer .

# 2. Copy generated source files into lib/
# (Dart source files generated separately)

# 3. Install dependencies
flutter pub get

# 4. Run on tablet
flutter run -d chrome                # Web
flutter run -d android-tablet        # Android tablet
```

---

## 📖 API Reference

Complete API reference with all request/response bodies: **[API_REFERENCE.md](./API_REFERENCE.md)**

### Endpoint Summary

| Module | Method | Endpoint | Auth | Description |
|--------|--------|----------|------|-------------|
| **Auth** | POST | `/api/v1/auth/register` | No | Register new user |
| | POST | `/api/v1/auth/login` | No | Login |
| | POST | `/api/v1/auth/refresh` | No | Refresh tokens |
| | POST | `/api/v1/auth/logout` | Yes | Logout |
| | GET | `/api/v1/auth/me` | Yes | Get profile |
| **Dashboard** | GET | `/api/v1/dashboard` | Yes | Main dashboard data |
| **Customers** | GET | `/api/v1/customers` | Yes | List (paginated + search) |
| | GET | `/api/v1/customers/:id` | Yes | Get single |
| | POST | `/api/v1/customers` | Yes | Create |
| | PUT | `/api/v1/customers/:id` | Yes | Update |
| | DELETE | `/api/v1/customers/:id` | Yes | Soft delete |
| **Products** | GET | `/api/v1/products` | Yes | List |
| | POST | `/api/v1/products` | Yes | Create |
| | PUT | `/api/v1/products/:id` | Yes | Update |
| | PATCH | `/api/v1/products/:id/toggle` | Yes | Toggle active |
| **Rates** | GET | `/api/v1/rates` | Yes | Get rates by date |
| | PUT | `/api/v1/rates` | Yes | Upsert rate |
| | GET | `/api/v1/rates/history/:productId` | Yes | Rate history |
| **Bills** | GET | `/api/v1/bills` | Yes | List (paginated + filters) |
| | GET | `/api/v1/bills/:id` | Yes | Get with items |
| | POST | `/api/v1/bills` | Yes | Create (atomic) |
| | POST | `/api/v1/bills/:id/cancel` | Yes | Cancel |
| **Payments** | GET | `/api/v1/payments` | Yes | List |
| | POST | `/api/v1/payments` | Yes | Create standalone |
| **Ledger** | GET | `/api/v1/ledger/:customerId` | Yes | Customer ledger |
| **Statements** | GET | `/api/v1/statements/:customerId` | Yes | Running balance |
| **Settings** | GET | `/api/v1/settings` | Yes | Get settings |
| | PUT | `/api/v1/settings` | Admin | Update settings |
| **Health** | GET | `/health` | No | Server health |

> **26 total endpoints** across 11 modules

---

## 🗄 Database Design

11 collections with carefully designed indexes:

| Collection | Key Fields | Indexes |
|------------|-----------|---------|
| `users` | email, password, role | email (unique) |
| `customers` | name, mobile, openingBalance | name, mobile (unique) |
| `products` | name, unit, isActive | name (unique) |
| `daily_rates` | productId, rateDate, rate | {productId+rateDate} (unique) |
| `bills` | billNumber, customerId, status | billNumber (unique), customerId+status |
| `bill_items` | billId, productId | billId |
| `payments` | receiptNumber, customerId | receiptNumber (unique) |
| `ledger_entries` | customerId, entryDate | customerId+entryDate |
| `business_settings` | businessName | singleton |
| `audit_logs` | action, resource, userId | createdAt |
| `counters` | key | key (unique) |

[Bold] Bills and stock items are separate collections. [Bold] Monetary values use Number (float64). [Bold] All deletes are soft (isDeleted flag or status=cancelled).

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **Atomic Billing** | Bill + line items + ledger + payment in single MongoDB transaction |
| **Daily Rates** | Set product rates per day; auto-applied when creating bills |
| **Live Dashboard** | Today's revenue, orders, outstanding, top customers, sales chart |
| **Running Balances** | Real-time currentDue computed via aggregation |
| **PDF/Print** | Customer statements and bills printable |
| **Ledger** | Immutable audit trail — every debit/credit is permanent |
| **Soft Deletes** | Customers, products safely removed without data loss |
| **Invoice Series** | Auto-generated bill/receipt numbers via atomic counter |
| **Role-Based Access** | Admin (full) vs Staff (billing only) |
| **JWT Auth** | Access + refresh token rotation with secure storage |
| **Rate Limiting** | Auth endpoints: 10/15min; General: 100/15min |
| **Validation** | Server-side field validation on all inputs |

---

## 🔄 Business Flow

```
┌──────────────┐
│ Set Daily    │  ← Staff sets today's rates per product
│   Rates      │
└──────┬───────┘
       │
       ▼
┌──────────────┐     ┌────────────────┐     ┌──────────────┐
│ Create Bill  │────▶│ Line Items     │────▶│ Auto-apply   │
│ (select      │     │ (product x qty │     │ today's rate │
│  customer)   │     │  x rate)       │     │ (can override)│
└──────┬───────┘     └────────────────┘     └──────────────┘
       │
       ▼
┌────────────────────────────────────────────────────┐
│ Atomic Transaction:                                 │
│  1. Create Bill document (status=active)            │
│  2. Create BillItem documents (line items)          │
│  3. Add LedgerEntry (debit = bill total)            │
│  4. Add LedgerEntry (credit = payment, if any)      │
│  5. Create Payment record (if paid now)             │
│  6. Update customer balance via aggregation         │
└────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Dashboard    │    │ Ledger       │    │ Statements   │
│ (revenue,    │    │ (immutable   │    │ (running     │
│  orders,     │    │  audit trail)│    │  balance)    │
│  chart)      │    └──────────────┘    └──────────────┘
└──────────────┘
```

---

## 🔒 Security

| Measure | Implementation |
|---------|---------------|
| **Password Hashing** | bcrypt (12 salt rounds) |
| **JWT Auth** | Bearer token, 15min expiry |
| **Refresh Token Rotation** | 7-day refresh, invalidated on use |
| **Rate Limiting** | Auth: 10/15min, General: 100/15min |
| **Input Validation** | express-validator on all endpoints |
| **CORS** | Configurable origin whitelist |
| **Helmet** | Security headers (XSS, clickjack, etc.) |
| **Role Check** | Middleware enforces admin vs staff |
| **Token Storage** | flutter_secure_storage (encrypted) |
| **Mongo Injection** | Mongoose sanitization, parameterized queries |

---

## 🛠 Development

### Commands

```bash
# Backend
npm run dev           # Development with nodemon
npm start             # Production start
npm run seed          # Run seed scripts

# Testing API
curl http://localhost:5000/health
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Server port | 5000 |
| NODE_ENV | Environment | development |
| MONGODB_URI | MongoDB connection string | — |
| JWT_SECRET | Access token signing key | — |
| JWT_REFRESH_SECRET | Refresh token signing key | — |
| JWT_EXPIRY | Access token TTL | 15m |
| JWT_REFRESH_EXPIRY | Refresh token TTL | 7d |
| CORS_ORIGIN | Allowed origins | * |
| RATE_LIMIT_WINDOW | Rate limit window (ms) | 900000 |
| RATE_LIMIT_MAX | Max requests per window | 100 |
| AUTH_RATE_LIMIT_MAX | Auth max requests | 10 |

---

## 📄 License

Private — Internal business use

---

## 👥 Team

Built with ❤️ for Mandi traders. Contributions welcome.
