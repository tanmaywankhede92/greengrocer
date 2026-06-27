# Rathod Enterprises — Complete API Reference

Base URL: `http://localhost:5000/api/v1`

**Headers (authenticated requests):**
```
Authorization: Bearer <accessToken>
Content-Type: application/json
Accept: application/json
```

---

## 📦 Module 1: Authentication

### 1.1 Register

Creates a new user account. The very first user to register becomes `admin`, all subsequent users become `staff`.

**Endpoint:** `POST /api/v1/auth/register`

**Rate Limit:** 10 requests per 15 minutes

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePass123",
  "fullName": "Suresh Rathod"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Account created successfully",
  "data": {
    "user": {
      "id": "6a3f90ac3e589d5466488ede",
      "email": "user@example.com",
      "fullName": "Suresh Rathod",
      "role": "admin"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Response (409 — Email exists):**
```json
{
  "success": false,
  "message": "An account with this email already exists"
}
```

**Error Response (400 — Validation):**
```json
{
  "success": false,
  "message": "Validation error",
  "errors": [
    { "field": "email", "message": "Enter a valid email" },
    { "field": "password", "message": "Password must be at least 6 characters" }
  ]
}
```

---

### 1.2 Login

Authenticate with email and password.

**Endpoint:** `POST /api/v1/auth/login`

**Rate Limit:** 10 requests per 15 minutes

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePass123"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "6a3f90ac3e589d5466488ede",
      "email": "user@example.com",
      "fullName": "Suresh Rathod",
      "role": "admin"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

---

### 1.3 Refresh Token

Exchange a valid refresh token for new access + refresh tokens.

**Endpoint:** `POST /api/v1/auth/refresh`

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Invalid or expired refresh token"
}
```

---

### 1.4 Logout

Invalidate the current refresh token.

**Endpoint:** `POST /api/v1/auth/logout`

**Headers:** `Authorization: Bearer <accessToken>`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### 1.5 Get Profile

Get the currently authenticated user's profile.

**Endpoint:** `GET /api/v1/auth/me`

**Headers:** `Authorization: Bearer <accessToken>`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": "6a3f90ac3e589d5466488ede",
    "email": "user@example.com",
    "fullName": "Suresh Rathod",
    "role": "admin",
    "createdAt": "2026-06-27T08:58:08.362Z"
  }
}
```

---

## 📊 Module 2: Dashboard

### 2.1 Get Dashboard

Get the main dashboard overview data.

**Endpoint:** `GET /api/v1/dashboard`

**Headers:** `Authorization: Bearer <accessToken>`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "todayRevenue": 45000,
    "todayOrders": 12,
    "monthlyCollection": 285000,
    "outstanding": 320000,
    "totalCustomers": 45,
    "pendingCustomers": 28,
    "topCustomers": [
      {
        "id": "6a3f90ac3e589d5466488ede",
        "name": "Rajesh Patel",
        "mobile": "9876543210",
        "currentDue": 45000
      }
    ],
    "recentBills": [
      {
        "id": "6a3f90ac3e589d5466488ede",
        "billNumber": "RE-2506-0001",
        "billDate": "2025-06-20T00:00:00.000Z",
        "total": 5000,
        "status": "active",
        "customer": {
          "name": "Rajesh Patel"
        }
      }
    ],
    "recentPayments": [
      {
        "id": "6a3f90ac3e589d5466488ede",
        "receiptNumber": "RCPT-2506-0001",
        "amount": 10000,
        "mode": "cash",
        "paymentDate": "2025-06-20T00:00:00.000Z",
        "customer": {
          "name": "Rajesh Patel"
        },
        "isCancelled": false
      }
    ],
    "salesSeries": [
      { "month": "Jan", "sales": 125000 },
      { "month": "Feb", "sales": 142000 },
      { "month": "Mar", "sales": 138000 },
      { "month": "Apr", "sales": 165000 },
      { "month": "May", "sales": 152000 },
      { "month": "Jun", "sales": 45000 }
    ]
  }
}
```

---

## 👥 Module 3: Customers

### 3.1 List Customers

Get paginated list of customers with search.

**Endpoint:** `GET /api/v1/customers`

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| search | string | — | Search by name or mobile |
| page | number | 1 | Page number |
| limit | number | 20 | Items per page (max 100) |
| sort | string | name | Sort field |
| order | string | asc | Sort order: asc or desc |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "_id": "6a3f90ac3e589d5466488ede",
      "name": "Rajesh Patel",
      "mobile": "9876543210",
      "address": "Mandi Road, Pune",
      "gstNumber": "27ABCDE1234F1Z5",
      "openingBalance": 0,
      "notes": "",
      "isDeleted": false,
      "createdBy": "6a3f90ac3e589d5466488ede",
      "createdAt": "2026-06-27T08:58:08.362Z",
      "updatedAt": "2026-06-27T08:58:08.362Z",
      "currentDue": 45000,
      "billCount": 15,
      "lastBillDate": "2025-06-18T00:00:00.000Z",
      "lastPaymentDate": "2025-06-15T00:00:00.000Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

---

### 3.2 Get Customer

Get a single customer by ID with current due.

**Endpoint:** `GET /api/v1/customers/:id`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "_id": "6a3f90ac3e589d5466488ede",
    "name": "Rajesh Patel",
    "mobile": "9876543210",
    "address": "Mandi Road, Pune",
    "gstNumber": "27ABCDE1234F1Z5",
    "openingBalance": 0,
    "notes": "",
    "isDeleted": false,
    "createdBy": "6a3f90ac3e589d5466488ede",
    "createdAt": "2026-06-27T08:58:08.362Z",
    "updatedAt": "2026-06-27T08:58:08.362Z",
    "currentDue": 45000
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Customer not found"
}
```

---

### 3.3 Create Customer

**Endpoint:** `POST /api/v1/customers`

**Request Body:**
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

**Success Response (201):**
```json
{
  "success": true,
  "message": "Customer created successfully",
  "data": {
    "id": "6a3f90ac3e589d5466488ede"
  }
}
```

**Error Response (409 — Duplicate mobile):**
```json
{
  "success": false,
  "message": "Mobile number already exists"
}
```

---

### 3.4 Update Customer

**Endpoint:** `PUT /api/v1/customers/:id`

**Request Body (all fields optional, at least one required):**
```json
{
  "name": "Rajesh Patel Updated",
  "mobile": "9876543211",
  "address": "New Address",
  "gstNumber": "27ABCDE1234F1Z5",
  "notes": "Regular customer"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Customer updated successfully"
}
```

---

### 3.5 Delete Customer (Soft Delete)

**Endpoint:** `DELETE /api/v1/customers/:id`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Customer removed successfully"
}
```

---

## 📦 Module 4: Products

### 4.1 List Products

**Endpoint:** `GET /api/v1/products`

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| activeOnly | boolean | false | Only show active products |
| search | string | — | Search by name |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "_id": "6a3f90ac3e589d5466488ede",
      "name": "Potato",
      "unit": "kg",
      "isActive": true,
      "isDeleted": false,
      "createdAt": "2026-06-27T08:58:08.362Z",
      "updatedAt": "2026-06-27T08:58:08.362Z"
    }
  ]
}
```

---

### 4.2 Create Product

**Endpoint:** `POST /api/v1/products`

**Request Body:**
```json
{
  "name": "Potato",
  "unit": "kg"
}
```

**Unit Values:** `kg`, `pcs`, `bundle`, `box`, `dozen`, `quintal`, `bag`, `crate`

**Success Response (201):**
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "id": "6a3f90ac3e589d5466488ede"
  }
}
```

---

### 4.3 Update Product

**Endpoint:** `PUT /api/v1/products/:id`

**Request Body:**
```json
{
  "name": "Potato (New)",
  "unit": "quintal"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Product updated successfully"
}
```

---

### 4.4 Toggle Product Active Status

**Endpoint:** `PATCH /api/v1/products/:id/toggle`

**Request Body:**
```json
{
  "isActive": false
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Product updated"
}
```

---

## 💰 Module 5: Daily Rates

### 5.1 Get Rates by Date

**Endpoint:** `GET /api/v1/rates`

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| date | string | today | Date in YYYY-MM-DD format |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "6a3f90ac3e589d5466488ede": {
      "id": "6a3f90ac3e589d5466488ede",
      "rate": 30,
      "rateDate": "2026-06-27T00:00:00.000Z"
    }
  }
}
```

The response is a map keyed by product ID for easy lookup on the frontend.

---

### 5.2 Upsert Rate

Create or update a rate for a product on a specific date.

**Endpoint:** `PUT /api/v1/rates`

**Request Body:**
```json
{
  "productId": "6a3f90ac3e589d5466488ede",
  "rate": 35,
  "rateDate": "2026-06-27"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Rate saved successfully"
}
```

---

### 5.3 Get Rate History

**Endpoint:** `GET /api/v1/rates/history/:productId`

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| limit | number | 60 | Number of historical entries |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "_id": "6a3f90ac3e589d5466488ede",
      "productId": "6a3f90ac3e589d5466488ede",
      "rate": 35,
      "rateDate": "2026-06-27T00:00:00.000Z",
      "createdBy": "6a3f90ac3e589d5466488ede",
      "createdAt": "2026-06-27T08:58:08.362Z",
      "updatedAt": "2026-06-27T08:58:08.362Z"
    }
  ]
}
```

---

## 🧾 Module 6: Bills

### 6.1 List Bills

**Endpoint:** `GET /api/v1/bills`

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| search | string | — | Search by bill number |
| status | string | — | all, active, or cancelled |
| from | string | — | Start date YYYY-MM-DD |
| to | string | — | End date YYYY-MM-DD |
| page | number | 1 | Page number |
| limit | number | 50 | Items per page (max 100) |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": "6a3f90ac3e589d5466488ede",
      "billNumber": "RE-2506-0001",
      "customerId": "6a3f90ac3e589d5466488ede",
      "customer": {
        "_id": "6a3f90ac3e589d5466488ede",
        "name": "Rajesh Patel",
        "mobile": "9876543210"
      },
      "billDate": "2025-06-20T00:00:00.000Z",
      "subtotal": 5200,
      "discount": 200,
      "total": 5000,
      "paidNow": 5000,
      "newDue": 15000,
      "paymentType": "cash",
      "notes": "",
      "status": "active",
      "createdAt": "2026-06-27T08:58:08.362Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 50,
    "total": 100,
    "totalPages": 2,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

---

### 6.2 Get Bill Detail

Get a single bill with all line items.

**Endpoint:** `GET /api/v1/bills/:id`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "bill": {
      "_id": "6a3f90ac3e589d5466488ede",
      "billNumber": "RE-2506-0001",
      "customerId": {
        "_id": "6a3f90ac3e589d5466488ede",
        "name": "Rajesh Patel",
        "mobile": "9876543210",
        "address": "Mandi Road, Pune",
        "gstNumber": "27ABCDE1234F1Z5"
      },
      "billDate": "2025-06-20T00:00:00.000Z",
      "subtotal": 5200,
      "discount": 200,
      "total": 5000,
      "previousDue": 15000,
      "paidNow": 5000,
      "newDue": 15000,
      "paymentType": "cash",
      "notes": "",
      "status": "active",
      "createdBy": "6a3f90ac3e589d5466488ede",
      "createdAt": "2026-06-27T08:58:08.362Z",
      "updatedAt": "2026-06-27T08:58:08.362Z",
      "id": "6a3f90ac3e589d5466488ede",
      "customer": {
        "_id": "6a3f90ac3e589d5466488ede",
        "name": "Rajesh Patel",
        "mobile": "9876543210",
        "address": "Mandi Road, Pune",
        "gstNumber": "27ABCDE1234F1Z5"
      }
    },
    "items": [
      {
        "_id": "6a3f90ac3e589d5466488ede",
        "billId": "6a3f90ac3e589d5466488ede",
        "productId": "6a3f90ac3e589d5466488ede",
        "productName": "Potato",
        "unit": "kg",
        "quantity": 100,
        "defaultRate": 30,
        "appliedRate": 32,
        "amount": 3200,
        "createdAt": "2026-06-27T08:58:08.362Z",
        "id": "6a3f90ac3e589d5466488ede"
      }
    ]
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Bill not found"
}
```

---

### 6.3 Create Bill (Atomic)

Creates bill + line items + ledger entry + optional payment atomically in a transaction.

**Endpoint:** `POST /api/v1/bills`

**Request Body:**
```json
{
  "customerId": "6a3f90ac3e589d5466488ede",
  "billDate": "2026-06-27",
  "items": [
    {
      "productId": "6a3f90ac3e589d5466488ede",
      "productName": "Potato",
      "unit": "kg",
      "quantity": 100,
      "defaultRate": 30,
      "appliedRate": 32
    },
    {
      "productName": "Custom Item",
      "unit": "pcs",
      "quantity": 5,
      "appliedRate": 50
    }
  ],
  "discount": 200,
  "notes": "Bill for weekly supply",
  "paymentAmount": 5000,
  "paymentMode": "cash"
}
```

**Fields:**
| Field | Required | Description |
|-------|----------|-------------|
| customerId | ✅ | Valid customer ID |
| billDate | ✅ | Date in YYYY-MM-DD format |
| items[].productId | ❌ | Product reference (null for custom items) |
| items[].productName | ✅ | Product name (snapshot) |
| items[].unit | ✅ | One of: kg, pcs, bundle, box, dozen, quintal, bag, crate |
| items[].quantity | ✅ | Positive number |
| items[].defaultRate | ❌ | Today's rate (default: 0) |
| items[].appliedRate | ✅ | Actual rate applied |
| discount | ❌ | Discount amount (default: 0) |
| notes | ❌ | Optional notes |
| paymentAmount | ❌ | Amount paid now (default: 0) |
| paymentMode | ❌ | If paymentAmount > 0: cash, upi, bank_transfer, cheque |

**Success Response (201):**
```json
{
  "success": true,
  "message": "Bill generated successfully",
  "data": {
    "id": "6a3f90ac3e589d5466488ede"
  }
}
```

**Error Response (400 — No items):**
```json
{
  "success": false,
  "message": "Validation error",
  "errors": [
    { "field": "items", "message": "At least one item is required" }
  ]
}
```

---

### 6.4 Cancel Bill

Cancels a bill — marks as cancelled, reverses ledger entry, and cancels associated payment.

**Endpoint:** `POST /api/v1/bills/:id/cancel`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Bill cancelled successfully"
}
```

**Error Response (400 — Already cancelled):**
```json
{
  "success": false,
  "message": "Bill is already cancelled"
}
```

---

## 💳 Module 7: Payments

### 7.1 List Payments

**Endpoint:** `GET /api/v1/payments`

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| customerId | string | — | Filter by customer |
| page | number | 1 | Page number |
| limit | number | 50 | Items per page |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "_id": "6a3f90ac3e589d5466488ede",
      "receiptNumber": "RCPT-2506-0001",
      "customerId": {
        "_id": "6a3f90ac3e589d5466488ede",
        "name": "Rajesh Patel",
        "mobile": "9876543210"
      },
      "amount": 10000,
      "mode": "cash",
      "reference": "UPI ref 12345",
      "notes": "",
      "paymentDate": "2025-06-20T00:00:00.000Z",
      "isCancelled": false,
      "createdBy": "6a3f90ac3e589d5466488ede",
      "createdAt": "2026-06-27T08:58:08.362Z",
      "updatedAt": "2026-06-27T08:58:08.362Z",
      "id": "6a3f90ac3e589d5466488ede",
      "customer": {
        "_id": "6a3f90ac3e589d5466488ede",
        "name": "Rajesh Patel",
        "mobile": "9876543210"
      }
    }
  ],
  "meta": {
    "page": 1,
    "limit": 50,
    "total": 50,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPreviousPage": false
  }
}
```

---

### 7.2 Create Payment (Standalone)

Record a standalone payment not linked to a bill.

**Endpoint:** `POST /api/v1/payments`

**Request Body:**
```json
{
  "customerId": "6a3f90ac3e589d5466488ede",
  "amount": 10000,
  "mode": "cash",
  "reference": "UPI ref 12345",
  "notes": "Payment for outstanding",
  "paymentDate": "2026-06-27"
}
```

**Fields:**
| Field | Required | Description |
|-------|----------|-------------|
| customerId | ✅ | Valid customer ID |
| amount | ✅ | Positive number |
| mode | ❌ | cash, upi, bank_transfer, cheque (default: cash) |
| reference | ❌ | Transaction reference |
| notes | ❌ | Optional notes |
| paymentDate | ✅ | Date in YYYY-MM-DD format |

**Success Response (201):**
```json
{
  "success": true,
  "message": "Payment recorded successfully",
  "data": {
    "id": "6a3f90ac3e589d5466488ede"
  }
}
```

---

## 📒 Module 8: Ledger

### 8.1 Get Customer Ledger

**Endpoint:** `GET /api/v1/ledger/:customerId`

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| from | string | — | Start date YYYY-MM-DD |
| to | string | — | End date YYYY-MM-DD |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": "6a3f90ac3e589d5466488ede",
      "customerId": "6a3f90ac3e589d5466488ede",
      "entryType": "opening_balance",
      "entryDate": "2026-06-27T00:00:00.000Z",
      "description": "Opening balance",
      "debit": 0,
      "credit": 0,
      "createdAt": "2026-06-27T08:58:08.362Z"
    },
    {
      "id": "6a3f90ac3e589d5466488ede",
      "customerId": "6a3f90ac3e589d5466488ede",
      "entryType": "bill",
      "entryDate": "2026-06-27T00:00:00.000Z",
      "description": "Bill RE-2506-0001",
      "debit": 5000,
      "credit": 0,
      "createdAt": "2026-06-27T08:58:08.362Z"
    },
    {
      "id": "6a3f90ac3e589d5466488ede",
      "customerId": "6a3f90ac3e589d5466488ede",
      "entryType": "payment",
      "entryDate": "2026-06-27T00:00:00.000Z",
      "description": "Payment RCPT-2506-0001",
      "debit": 0,
      "credit": 5000,
      "createdAt": "2026-06-27T08:58:08.362Z"
    },
    {
      "id": "6a3f90ac3e589d5466488ede",
      "customerId": "6a3f90ac3e589d5466488ede",
      "entryType": "adjustment",
      "entryDate": "2026-06-27T00:00:00.000Z",
      "description": "Cancelled bill RE-2506-0001",
      "debit": 0,
      "credit": 5000,
      "createdAt": "2026-06-27T08:58:08.362Z"
    }
  ]
}
```

**Entry Types:**
| Type | Meaning | Debit | Credit |
|------|---------|-------|--------|
| opening_balance | Initial balance | Amount owed | Amount advanced |
| bill | New bill | Bill total | — |
| payment | Payment received | — | Amount paid |
| adjustment | Reversal | Reverses credit | Reverses debit |

---

## 📋 Module 9: Statements

### 9.1 Get Customer Statement

**Endpoint:** `GET /api/v1/statements/:customerId`

**Query Parameters:**
| Param | Required | Description |
|-------|----------|-------------|
| from | ✅ | Start date YYYY-MM-DD |
| to | ✅ | End date YYYY-MM-DD |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "customer": {
      "name": "Rajesh Patel",
      "mobile": "9876543210"
    },
    "period": {
      "from": "2026-06-01",
      "to": "2026-06-27"
    },
    "openingBalance": 10000,
    "closingBalance": 15000,
    "totalDebit": 10000,
    "totalCredit": 5000,
    "rows": [
      {
        "date": "2026-06-15T00:00:00.000Z",
        "type": "bill",
        "description": "Bill RE-2506-0001",
        "debit": 10000,
        "credit": 0,
        "balance": 20000
      },
      {
        "date": "2026-06-20T00:00:00.000Z",
        "type": "payment",
        "description": "Payment RCPT-2506-0001",
        "debit": 0,
        "credit": 5000,
        "balance": 15000
      }
    ]
  }
}
```

---

## ⚙️ Module 10: Settings

### 10.1 Get Settings

**Endpoint:** `GET /api/v1/settings`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "_id": "6a3f90ac3e589d5466488ede",
    "businessName": "Rathod Enterprises",
    "tagline": "Vegetable & Fruit Wholesale Supplier",
    "address": "Main Mandi Yard, Pune",
    "phone": "+91-9876543210",
    "gstNumber": "27ABCDE1234F1Z5",
    "invoicePrefix": "RE",
    "footerNote": "Thank you for your business!",
    "createdAt": "2026-06-27T08:58:08.362Z",
    "updatedAt": "2026-06-27T08:58:08.362Z"
  }
}
```

---

### 10.2 Update Settings

**Admin only.** Requires role = "admin".

**Endpoint:** `PUT /api/v1/settings`

**Request Body (all fields optional, at least one required):**
```json
{
  "businessName": "Rathod Enterprises",
  "tagline": "Premium Vegetable & Fruit Wholesale Supplier",
  "address": "Main Mandi Yard, Phase 2, Pune",
  "phone": "+91-9876543210",
  "gstNumber": "27ABCDE1234F1Z5",
  "invoicePrefix": "RE",
  "footerNote": "Thank you for your continued business!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Settings updated successfully"
}
```

**Error Response (403 — Not admin):**
```json
{
  "success": false,
  "message": "You do not have permission to perform this action"
}
```

---

## 🔐 Module 11: Health

### 11.1 Health Check

**Endpoint:** `GET /health`

**No authentication required.**

**Success Response (200):**
```json
{
  "success": true,
  "message": "Greengrocer API is running",
  "environment": "development",
  "timestamp": "2026-06-27T08:58:12.694Z"
}
```

---

## 📐 Common Error Response Format

All error responses follow this structure:

```json
{
  "success": false,
  "message": "Human-readable error message",
  "errors": [
    { "field": "fieldName", "message": "Validation error for this field" }
  ]
}
```

### HTTP Status Code Reference

| Code | Meaning | When |
|------|---------|------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 400 | Bad Request | Validation failed, missing fields |
| 401 | Unauthorized | Missing/invalid/expired token |
| 403 | Forbidden | Insufficient role permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate email, mobile, etc. |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |

---

## 🔄 Authentication Flow Summary

```
┌─────────┐         ┌──────────┐         ┌──────────┐
│ Flutter  │ 1. POST │  Node.js │ 2. JWT  │  MongoDB │
│  App     │──/auth──▶│   API   │◀────────▶│          │
│          │  /login │          │         │          │
│  Store   │         │          │         │          │
│  tokens  │ 3. Use  │          │         │          │
│  securely│──Bearer─▶│ Verify  │         │          │
│          │  Token  │  Token   │         │          │
└─────────┘         └──────────┘         └──────────┘
```

1. User registers or logs in → receives `accessToken` (15 min) + `refreshToken` (7 days)
2. All subsequent requests include `Authorization: Bearer <accessToken>`
3. When access token expires, use `/auth/refresh` to get new tokens
4. On logout, the refresh token is invalidated server-side
