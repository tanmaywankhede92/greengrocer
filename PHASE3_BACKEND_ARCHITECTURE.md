# Phase 3: Backend Architecture
## Rathod Enterprises — Billing & Credit Ledger API

---

## 3.1 Technology Stack

| Layer | Choice | Purpose |
|-------|--------|---------|
| Runtime | Node.js 20 LTS | Server-side JavaScript |
| Framework | Express.js 4.x | HTTP routing, middleware |
| Database | MongoDB 7.x | Document store for billing data |
| ODM | Mongoose 8.x | Schema validation, population |
| Auth | JWT + bcrypt | Token-based authentication |
| Validation | Joi / express-validator | Request validation |
| File Upload | Multer | Receipt/image uploads |
| Storage | Cloudinary (ready) | Image hosting |
| Docs | Swagger (swagger-jsdoc + swagger-ui-express) | API documentation |
| Logging | Winston | Structured logging |
| Environment | dotenv | Config management |
| Testing | Jest | Unit/integration tests |
| Monitoring | express-status-monitor | Health checks |

---

## 3.2 Folder Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── index.js              # Central config from env
│   │   ├── database.js           # MongoDB connection
│   │   └── swagger.js            # Swagger definition
│   │
│   ├── constants/
│   │   ├── enums.js              # App enums
│   │   ├── messages.js           # Response messages
│   │   └── httpStatus.js         # HTTP status codes
│   │
│   ├── helpers/
│   │   ├── apiResponse.js        # Standardized response builder
│   │   ├── asyncHandler.js       # Async error wrapper
│   │   ├── pagination.js         # Pagination helper
│   │   └── sequenceGenerator.js  # Bill/receipt number generation
│   │
│   ├── middlewares/
│   │   ├── authenticate.js       # JWT verification
│   │   ├── authorize.js          # Role-based access
│   │   ├── validate.js           # Joi validation middleware
│   │   ├── upload.js             # Multer configuration
│   │   ├── errorHandler.js       # Global error handler
│   │   └── rateLimiter.js        # Rate limiting
│   │
│   ├── models/
│   │   ├── User.js
│   │   ├── Customer.js
│   │   ├── Product.js
│   │   ├── DailyRate.js
│   │   ├── Bill.js
│   │   ├── BillItem.js
│   │   ├── Payment.js
│   │   ├── LedgerEntry.js
│   │   ├── BusinessSetting.js
│   │   └── AuditLog.js
│   │
│   ├── repositories/
│   │   ├── userRepository.js
│   │   ├── customerRepository.js
│   │   ├── productRepository.js
│   │   ├── rateRepository.js
│   │   ├── billRepository.js
│   │   ├── paymentRepository.js
│   │   ├── ledgerRepository.js
│   │   └── settingsRepository.js
│   │
│   ├── services/
│   │   ├── authService.js
│   │   ├── customerService.js
│   │   ├── productService.js
│   │   ├── rateService.js
│   │   ├── billService.js        # Core billing logic (replaces PG functions)
│   │   ├── paymentService.js     # Payment + ledger logic
│   │   ├── ledgerService.js
│   │   ├── dashboardService.js
│   │   ├── statementService.js
│   │   └── settingsService.js
│   │
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── customerController.js
│   │   ├── productController.js
│   │   ├── rateController.js
│   │   ├── billController.js
│   │   ├── paymentController.js
│   │   ├── ledgerController.js
│   │   ├── dashboardController.js
│   │   ├── statementController.js
│   │   └── settingsController.js
│   │
│   ├── routes/
│   │   ├── index.js              # Route aggregator
│   │   ├── authRoutes.js
│   │   ├── customerRoutes.js
│   │   ├── productRoutes.js
│   │   ├── rateRoutes.js
│   │   ├── billRoutes.js
│   │   ├── paymentRoutes.js
│   │   ├── ledgerRoutes.js
│   │   ├── dashboardRoutes.js
│   │   ├── statementRoutes.js
│   │   └── settingsRoutes.js
│   │
│   ├── validators/
│   │   ├── authValidator.js
│   │   ├── customerValidator.js
│   │   ├── productValidator.js
│   │   ├── rateValidator.js
│   │   ├── billValidator.js
│   │   ├── paymentValidator.js
│   │   └── settingsValidator.js
│   │
│   └── jobs/
│       └── index.js              # Cron jobs (future)
│
├── uploads/                      # Local uploads (Cloudinary sync)
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
│
├── app.js                        # Express app setup
├── server.js                     # Server start
├── .env.example
├── .gitignore
├── package.json
├── README.md
└── Dockerfile
```

---

## 3.3 Layered Architecture

```
┌──────────────────────────────────────────┐
│              Routes (HTTP)               │
│  Defines endpoints + middleware chain    │
└────────────────┬─────────────────────────┘
                 │
┌────────────────▼─────────────────────────┐
│           Middlewares                     │
│  authenticate → authorize → validate     │
└────────────────┬─────────────────────────┘
                 │
┌────────────────▼─────────────────────────┐
│           Controllers                    │
│  Parse request, call service, send res   │
└────────────────┬─────────────────────────┘
                 │
┌────────────────▼─────────────────────────┐
│            Services                      │
│  Business logic, orchestration           │
└────────────────┬─────────────────────────┘
                 │
┌────────────────▼─────────────────────────┐
│           Repositories                   │
│  Data access (Mongoose queries)          │
└────────────────┬─────────────────────────┘
                 │
┌────────────────▼─────────────────────────┐
│            Models (Mongoose)             │
│  Schema definitions, indexes, hooks      │
└──────────────────────────────────────────┘
```

---

## 3.4 Request Lifecycle

```
Client Request
     │
     ▼
Rate Limiter → CORS → Body Parser → Authenticate (JWT)
     │
     ▼
Authorize (role check) → Validate (Joi schema)
     │
     ▼
Controller → Service → Repository → MongoDB
     │
     ▼
Response ← Controller formats ← Service returns result
     │
     ▼
Error Handler (if any error thrown)
```

---

## 3.5 Authentication Flow

```
POST /api/auth/register
  → Validate email, password, name
  → Hash password (bcrypt, 12 rounds)
  → Create User document
  → First user = admin, rest = staff
  → Generate access token (15m) + refresh token (7d)
  → Return tokens + user profile

POST /api/auth/login
  → Find user by email
  → Compare password (bcrypt)
  → Generate tokens
  → Return tokens + user profile

POST /api/auth/refresh
  → Validate refresh token
  → Generate new access token
  → Return new tokens

POST /api/auth/logout
  → Invalidate refresh token
  → Return success

POST /api/auth/forgot-password
  → Generate reset token (15m)
  → Send email (future)

POST /api/auth/reset-password
  → Validate reset token
  → Update password
```

**Token Payload:**
```json
{
  "sub": "user_id",
  "role": "admin|staff",
  "iat": 1234567890,
  "exp": 1234567890
}
```

---

## 3.6 Business Logic Services

### BillService (replaces `create_bill` PG function)
1. Validate customer exists
2. Calculate subtotal from items
3. Fetch invoice prefix from settings
4. Generate bill number: `{PREFIX}-{YYMM}-{XXXX}`
5. Fetch previous due from ledger
6. Create Bill document
7. Create BillItem documents
8. Create ledger entry (debit)
9. If payment amount > 0:
   - Generate receipt number: `RCPT-{YYMM}-{XXXX}`
   - Create Payment document
   - Create ledger entry (credit)
10. Return bill ID

### PaymentService (replaces `create_payment` PG function)
1. Validate amount > 0
2. Generate receipt number
3. Create Payment document
4. Create ledger entry (credit)
5. Return payment ID

### CancelBillService (replaces `cancel_bill` PG function)
1. Find bill, validate not already cancelled
2. Update bill status to `cancelled`
3. Create reversal ledger entry (credit)
4. If paid_now > 0, cancel associated payment
5. Create reversal for payment (debit)

### DashboardService (replaces `useDashboard`)
1. Parallel aggregation queries using MongoDB:
   - Today's active bills (sum total, count)
   - Current month payments (sum amount)
   - Customers with due > 0 (for top outstanding)
   - Recent 6 bills (with customer lookup)
   - Recent 6 payments (with customer lookup)
   - Last 6 months bill aggregation
2. Return formatted dashboard data

### StatementService (replaces `useLedger`)
1. Fetch ledger entries for customer within date range
2. Calculate opening balance (entries before start date)
3. Compute running balance
4. Return formatted statement

---

## 3.7 API Response Format

**Success:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Validation error",
  "errors": [
    { "field": "email", "message": "Email is required" }
  ]
}
```

**Paginated:**
```json
{
  "success": true,
  "data": [ ... ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

---

## 3.8 Error Handling

Centralized error handling via middleware:

| Error Type | Status | Description |
|------------|--------|-------------|
| ValidationError | 400 | Request validation failed |
| UnauthorizedError | 401 | Invalid or expired token |
| ForbiddenError | 403 | Insufficient role |
| NotFoundError | 404 | Resource not found |
| ConflictError | 409 | Duplicate entry |
| InternalError | 500 | Unexpected server error |

---

## 3.9 Environment Variables

```env
# Server
NODE_ENV=development
PORT=5000

# MongoDB
MONGODB_URI=mongodb://localhost:27017/greengrocer

# JWT
JWT_ACCESS_SECRET=your-access-secret
JWT_REFRESH_SECRET=your-refresh-secret
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# Cloudinary (optional)
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

# App
DEFAULT_PREFIX=RE
DEFAULT_BUSINESS_NAME=Rathod Enterprises

# Logging
LOG_LEVEL=debug
```

---

## 3.10 Key Design Decisions

1. **Repository Pattern**: All MongoDB queries go through repository classes. Controllers never touch models directly.
2. **Service Layer**: Business logic lives in services. Controllers only handle HTTP concerns.
3. **Atomic Operations**: Use MongoDB transactions for bill creation (bill + items + ledger + payment).
4. **No RLS**: Since we're moving from Supabase RLS to application-level auth, authorization is enforced in middleware.
5. **Soft Deletes**: customers and products use `is_deleted` flag instead of physical deletion.
6. **Audit Trail**: All ledger entries are immutable inserts (never updated or deleted).
7. **Number Generation**: Bill numbers and receipt numbers use counters stored in a dedicated `counters` collection (atomic `findOneAndUpdate` with `$inc`).
8. **Indexes**: All query patterns have corresponding MongoDB indexes for performance.
