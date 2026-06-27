# Phase 5: REST API Documentation
## Rathod Enterprises — Billing & Credit Ledger

Base URL: `http://localhost:5000/api/v1`

---

## 5.1 Authentication Endpoints

### POST `/api/v1/auth/register`
Create a new user account. First user = admin, subsequent = staff.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePass123",
  "fullName": "Suresh Rathod"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Account created successfully",
  "data": {
    "user": { "id": "...", "email": "...", "fullName": "...", "role": "admin" },
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

### POST `/api/v1/auth/login`
Authenticate with email and password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePass123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": { "id": "...", "email": "...", "fullName": "...", "role": "admin" },
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

### POST `/api/v1/auth/refresh`
Exchange a valid refresh token for new tokens.

**Request:**
```json
{
  "refreshToken": "eyJ..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

### POST `/api/v1/auth/logout`
Invalidate current refresh token. Requires auth.

**Headers:** `Authorization: Bearer <accessToken>`

**Response (200):**
```json
{ "success": true, "message": "Logged out successfully" }
```

### GET `/api/v1/auth/me`
Get current user profile. Requires auth.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "email": "...",
    "fullName": "...",
    "role": "admin",
    "createdAt": "2025-06-20T..."
  }
}
```

---

## 5.2 Dashboard Endpoints

### GET `/api/v1/dashboard`
Get dashboard overview data. Requires auth.

**Query params:** none

**Response (200):**
```json
{
  "success": true,
  "data": {
    "todayRevenue": 45000,
    "todayOrders": 12,
    "monthlyCollection": 285000,
    "outstanding": 320000,
    "totalCustomers": 45,
    "pendingCustomers": 28,
    "topCustomers": [
      { "id": "...", "name": "Rajesh Patel", "mobile": "9876543210", "currentDue": 45000 }
    ],
    "recentBills": [
      {
        "id": "...",
        "billNumber": "RE-2506-0001",
        "billDate": "2025-06-20",
        "total": 5000,
        "status": "active",
        "customer": { "name": "Rajesh Patel" }
      }
    ],
    "recentPayments": [
      {
        "id": "...",
        "receiptNumber": "RCPT-2506-0001",
        "amount": 10000,
        "mode": "cash",
        "paymentDate": "2025-06-20",
        "customer": { "name": "Rajesh Patel" }
      }
    ],
    "salesSeries": [
      { "month": "Jan", "sales": 125000 },
      { "month": "Feb", "sales": 142000 }
    ]
  }
}
```

---

## 5.3 Customer Endpoints

### GET `/api/v1/customers`
List customers with search and pagination. Requires auth.

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| search | string | Search by name or mobile |
| page | number | Page number (default: 1) |
| limit | number | Items per page (default: 20) |
| sort | string | Sort field (default: "name") |
| order | string | "asc" or "desc" (default: "asc") |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "name": "Rajesh Patel",
      "mobile": "9876543210",
      "address": "Mandi Road, Pune",
      "gstNumber": "27ABCDE1234F1Z5",
      "openingBalance": 0,
      "currentDue": 45000,
      "billCount": 15,
      "lastBillDate": "2025-06-18",
      "lastPaymentDate": "2025-06-15",
      "notes": "",
      "createdAt": "..."
    }
  ],
  "meta": { "page": 1, "limit": 20, "total": 45, "totalPages": 3 }
}
```

### GET `/api/v1/customers/:id`
Get single customer with full details. Requires auth.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "name": "Rajesh Patel",
    "mobile": "9876543210",
    "address": "Mandi Road, Pune",
    "gstNumber": "27ABCDE1234F1Z5",
    "openingBalance": 0,
    "currentDue": 45000,
    "billCount": 15,
    "lastBillDate": "2025-06-18",
    "lastPaymentDate": "2025-06-15",
    "notes": "",
    "createdAt": "..."
  }
}
```

### POST `/api/v1/customers`
Create a new customer. Requires auth.

**Request:**
```json
{
  "name": "Rajesh Patel",
  "mobile": "9876543210",
  "address": "Mandi Road, Pune",
  "gstNumber": "27ABCDE1234F1Z5",
  "openingBalance": 0,
  "notes": ""
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Customer created successfully",
  "data": { "id": "..." }
}
```

### PUT `/api/v1/customers/:id`
Update customer details. Requires auth.

**Request:** (same fields as POST, all optional except name)

**Response (200):**
```json
{
  "success": true,
  "message": "Customer updated successfully"
}
```

### DELETE `/api/v1/customers/:id`
Soft delete a customer. Requires auth.

**Response (200):**
```json
{
  "success": true,
  "message": "Customer removed"
}
```

---

## 5.4 Product Endpoints

### GET `/api/v1/products`
List products. Requires auth.

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| activeOnly | boolean | Only active products (default: false) |
| search | string | Search by name |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "name": "Potato",
      "unit": "kg",
      "isActive": true,
      "createdAt": "..."
    }
  ]
}
```

### POST `/api/v1/products`
Create a product. Requires auth.

**Request:**
```json
{
  "name": "Potato",
  "unit": "kg"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": { "id": "..." }
}
```

### PUT `/api/v1/products/:id`
Update product. Requires auth.

**Request:** (name, unit, or isActive)

**Response (200):**
```json
{
  "success": true,
  "message": "Product updated successfully"
}
```

### PATCH `/api/v1/products/:id/toggle`
Toggle product active status. Requires auth.

**Request:**
```json
{
  "isActive": false
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Product updated"
}
```

---

## 5.5 Daily Rate Endpoints

### GET `/api/v1/rates`
Get rates for a specific date. Requires auth.

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| date | string | Date YYYY-MM-DD (default: today) |

**Response (200):**
```json
{
  "success": true,
  "data": {
    "productId1": { "id": "...", "rate": 30, "rateDate": "2025-06-20" },
    "productId2": { "id": "...", "rate": 45, "rateDate": "2025-06-20" }
  }
}
```

### PUT `/api/v1/rates`
Upsert a rate for a product on a date. Requires auth.

**Request:**
```json
{
  "productId": "...",
  "rate": 35,
  "rateDate": "2025-06-20"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Rate saved successfully"
}
```

### GET `/api/v1/rates/history/:productId`
Get rate history for a product. Requires auth.

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| limit | number | (default: 60) |

**Response (200):**
```json
{
  "success": true,
  "data": [
    { "id": "...", "rate": 30, "rateDate": "2025-06-20", "createdAt": "..." },
    { "id": "...", "rate": 28, "rateDate": "2025-06-19", "createdAt": "..." }
  ]
}
```

---

## 5.6 Bill Endpoints

### GET `/api/v1/bills`
List bills with filters. Requires auth.

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| search | string | Bill number search |
| status | string | "all", "active", "cancelled" |
| from | string | Start date YYYY-MM-DD |
| to | string | End date YYYY-MM-DD |
| page | number | (default: 1) |
| limit | number | (default: 50) |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "billNumber": "RE-2506-0001",
      "customerId": "...",
      "customer": { "name": "Rajesh Patel", "mobile": "9876543210" },
      "billDate": "2025-06-20",
      "total": 5000,
      "status": "active",
      "createdAt": "..."
    }
  ],
  "meta": { "page": 1, "limit": 50, "total": 100, "totalPages": 2 }
}
```

### GET `/api/v1/bills/:id`
Get full bill detail with items. Requires auth.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "bill": {
      "id": "...",
      "billNumber": "RE-2506-0001",
      "customerId": "...",
      "customer": { "name": "Rajesh Patel", "mobile": "9876543210", "address": "", "gstNumber": "" },
      "billDate": "2025-06-20",
      "subtotal": 5200,
      "discount": 200,
      "total": 5000,
      "previousDue": 15000,
      "paidNow": 5000,
      "newDue": 15000,
      "paymentType": "cash",
      "notes": "",
      "status": "active",
      "createdAt": "..."
    },
    "items": [
      {
        "id": "...",
        "productId": "...",
        "productName": "Potato",
        "unit": "kg",
        "quantity": 100,
        "defaultRate": 30,
        "appliedRate": 32,
        "amount": 3200
      }
    ]
  }
}
```

### POST `/api/v1/bills`
Create a new bill (atomic: bill + items + ledger + optional payment). Requires auth.

**Request:**
```json
{
  "customerId": "...",
  "billDate": "2025-06-20",
  "items": [
    {
      "productId": "...",
      "productName": "Potato",
      "unit": "kg",
      "quantity": 100,
      "defaultRate": 30,
      "appliedRate": 32
    }
  ],
  "discount": 200,
  "notes": "",
  "paymentAmount": 5000,
  "paymentMode": "cash"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Bill generated successfully",
  "data": { "id": "..." }
}
```

### POST `/api/v1/bills/:id/cancel`
Cancel a bill (reverses ledger + cancels payment). Requires auth.

**Response (200):**
```json
{
  "success": true,
  "message": "Bill cancelled successfully"
}
```

---

## 5.7 Payment Endpoints

### GET `/api/v1/payments`
List payments with filters. Requires auth.

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| customerId | string | Filter by customer |
| page | number | (default: 1) |
| limit | number | (default: 50) |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "receiptNumber": "RCPT-2506-0001",
      "customerId": "...",
      "customer": { "name": "Rajesh Patel", "mobile": "9876543210" },
      "amount": 10000,
      "mode": "cash",
      "reference": "",
      "notes": "",
      "paymentDate": "2025-06-20",
      "isCancelled": false,
      "createdAt": "..."
    }
  ],
  "meta": { ... }
}
```

### POST `/api/v1/payments`
Record a standalone payment. Requires auth.

**Request:**
```json
{
  "customerId": "...",
  "amount": 10000,
  "mode": "cash",
  "reference": "",
  "notes": "",
  "paymentDate": "2025-06-20"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Payment recorded successfully",
  "data": { "id": "..." }
}
```

---

## 5.8 Ledger Endpoints

### GET `/api/v1/ledger/:customerId`
Get ledger entries for a customer. Requires auth.

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| from | string | Start date YYYY-MM-DD |
| to | string | End date YYYY-MM-DD |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "customerId": "...",
      "entryType": "bill",
      "entryDate": "2025-06-20",
      "description": "Bill RE-2506-0001",
      "debit": 5000,
      "credit": 0,
      "balance": 20000,
      "createdAt": "..."
    }
  ]
}
```

---

## 5.9 Statement Endpoints

### GET `/api/v1/statements/:customerId`
Get customer statement for a period. Requires auth.

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| from | string | Start date YYYY-MM-DD (required) |
| to | string | End date YYYY-MM-DD (required) |

**Response (200):**
```json
{
  "success": true,
  "data": {
    "customer": { "name": "Rajesh Patel", "mobile": "9876543210" },
    "period": { "from": "2025-06-01", "to": "2025-06-20" },
    "openingBalance": 10000,
    "closingBalance": 20000,
    "totalDebit": 15000,
    "totalCredit": 5000,
    "rows": [
      {
        "date": "2025-06-20",
        "type": "bill",
        "description": "Bill RE-2506-0001",
        "debit": 5000,
        "credit": 0,
        "balance": 15000
      }
    ]
  }
}
```

---

## 5.10 Settings Endpoints

### GET `/api/v1/settings`
Get business settings. Requires auth.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "businessName": "Rathod Enterprises",
    "tagline": "Vegetable & Fruit Wholesale Supplier",
    "address": "Main Mandi Yard, Pune",
    "phone": "+91-9876543210",
    "gstNumber": "27ABCDE1234F1Z5",
    "invoicePrefix": "RE",
    "footerNote": "Thank you for your business!"
  }
}
```

### PUT `/api/v1/settings`
Update business settings. Admin only.

**Request:** (any subset of settings fields)

**Response (200):**
```json
{
  "success": true,
  "message": "Settings updated successfully"
}
```

---

## 5.11 Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK — Successful GET, PUT, PATCH |
| 201 | Created — Successful POST |
| 400 | Bad Request — Validation error |
| 401 | Unauthorized — Missing or invalid token |
| 403 | Forbidden — Insufficient role |
| 404 | Not Found — Resource doesn't exist |
| 409 | Conflict — Duplicate entry |
| 429 | Too Many Requests — Rate limit exceeded |
| 500 | Internal Server Error |

---

## 5.12 Common Headers

**Request:**
```
Authorization: Bearer <accessToken>
Content-Type: application/json
Accept: application/json
```

**Response:**
```
Content-Type: application/json
X-Request-Id: <uuid>
X-RateLimit-Remaining: 98
```

---

## 5.13 Authentication Middleware Summary

| Endpoint Group | Auth Required | Admin Only |
|----------------|:---:|:---:|
| POST /auth/register | No | No |
| POST /auth/login | No | No |
| POST /auth/refresh | No | No |
| POST /auth/logout | Yes | No |
| GET /auth/me | Yes | No |
| GET /dashboard | Yes | No |
| GET/POST /customers | Yes | No |
| PUT/DELETE /customers/:id | Yes | No |
| GET/POST /products | Yes | No |
| PUT /products/:id | Yes | No |
| PATCH /products/:id/toggle | Yes | No |
| GET/PUT /rates | Yes | No |
| GET /rates/history/:id | Yes | No |
| GET/POST /bills | Yes | No |
| GET /bills/:id | Yes | No |
| POST /bills/:id/cancel | Yes | No |
| GET /payments | Yes | No |
| POST /payments | Yes | No |
| GET /ledger/:customerId | Yes | No |
| GET /statements/:customerId | Yes | No |
| GET /settings | Yes | No |
| PUT /settings | Yes | **Yes** |
