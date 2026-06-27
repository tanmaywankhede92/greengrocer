# Phase 4: MongoDB Database Design
## Rathod Enterprises — Billing & Credit Ledger

---

## 4.1 Collection: `users`

```javascript
{
  _id: ObjectId,
  email: String,               // unique, indexed, required
  password: String,             // bcrypt hashed, required
  fullName: String,             // required
  role: String,                 // enum: "admin" | "staff", default: "staff"
  isActive: Boolean,            // default: true
  refreshToken: String,         // nullable, for JWT refresh
  resetPasswordToken: String,   // nullable
  resetPasswordExpires: Date,   // nullable
  lastLoginAt: Date,
  createdBy: ObjectId,          // ref: users (who created this user)
  createdAt: Date,              // auto
  updatedAt: Date               // auto
}

// Indexes
{ email: 1 }                    // unique
{ role: 1 }
{ isActive: 1 }
```

---

## 4.2 Collection: `customers`

```javascript
{
  _id: ObjectId,
  name: String,                 // required, trimmed, max 120
  mobile: String,               // required, indexed, unique (when not deleted)
  address: String,              // default: ""
  gstNumber: String,            // default: ""
  openingBalance: Number,       // default: 0, Decimal128
  notes: String,                // default: ""
  isDeleted: Boolean,           // default: false, soft delete
  createdBy: ObjectId,          // ref: users
  createdAt: Date,
  updatedAt: Date
}

// Indexes
{ mobile: 1, isDeleted: 1 }     // partial unique filter
{ name: 1 }
{ isDeleted: 1 }
{ name: "text", mobile: "text" } // text search
```

---

## 4.3 Collection: `products`

```javascript
{
  _id: ObjectId,
  name: String,                 // required, trimmed, max 80
  unit: String,                 // enum: "kg" | "pcs" | "bundle" | "box" | "dozen" | "quintal" | "bag" | "crate"
  isActive: Boolean,            // default: true
  isDeleted: Boolean,           // default: false
  createdAt: Date,
  updatedAt: Date
}

// Indexes
{ name: 1, isDeleted: 1 }       // unique compound
{ isActive: 1 }
{ isDeleted: 1 }
{ name: "text" }
```

---

## 4.4 Collection: `daily_rates`

```javascript
{
  _id: ObjectId,
  productId: ObjectId,          // ref: products, required
  rate: Number,                 // Decimal128, required
  rateDate: Date,               // date only (YYYY-MM-DD), required
  createdBy: ObjectId,          // ref: users
  createdAt: Date,
  updatedAt: Date
}

// Indexes
{ productId: 1, rateDate: 1 }   // unique compound
{ rateDate: 1 }
{ productId: 1 }
```

---

## 4.5 Collection: `bills`

```javascript
{
  _id: ObjectId,
  billNumber: String,           // unique, e.g. "RE-2506-0001"
  customerId: ObjectId,         // ref: customers, required
  billDate: Date,               // date only, required
  subtotal: Number,             // Decimal128
  discount: Number,             // Decimal128, default: 0
  total: Number,                // Decimal128
  previousDue: Number,          // Decimal128
  paidNow: Number,              // Decimal128, default: 0
  newDue: Number,               // Decimal128
  paymentType: String,          // "cash" | "partial" | "credit"
  notes: String,                // default: ""
  status: String,               // enum: "active" | "cancelled", default: "active"
  createdBy: ObjectId,          // ref: users
  createdAt: Date,
  updatedAt: Date
}

// Indexes
{ billNumber: 1 }               // unique
{ customerId: 1, createdAt: -1 }
{ billDate: 1 }
{ status: 1 }
{ customerId: 1, status: 1 }
{ billNumber: "text" }
```

---

## 4.6 Collection: `bill_items`

```javascript
{
  _id: ObjectId,
  billId: ObjectId,             // ref: bills, required
  productId: ObjectId,          // ref: products, nullable
  productName: String,          // required (snapshot at billing time)
  unit: String,                 // enum: product_unit
  quantity: Number,             // Decimal128
  defaultRate: Number,          // Decimal128, default: 0
  appliedRate: Number,          // Decimal128, required
  amount: Number,               // Decimal128 (qty * appliedRate)
  createdAt: Date
}

// Indexes
{ billId: 1 }
{ productId: 1 }
```

---

## 4.7 Collection: `payments`

```javascript
{
  _id: ObjectId,
  receiptNumber: String,        // unique, e.g. "RCPT-2506-0001"
  customerId: ObjectId,         // ref: customers, required
  amount: Number,               // Decimal128, required
  mode: String,                 // enum: "cash" | "upi" | "bank_transfer" | "cheque"
  reference: String,            // default: "" (txn ID, cheque no)
  notes: String,                // default: ""
  paymentDate: Date,            // date only
  billId: ObjectId,             // ref: bills (nullable — payment linked to bill or standalone)
  isCancelled: Boolean,         // default: false
  createdBy: ObjectId,          // ref: users
  createdAt: Date,
  updatedAt: Date
}

// Indexes
{ receiptNumber: 1 }            // unique
{ customerId: 1, createdAt: -1 }
{ paymentDate: 1 }
{ billId: 1 }
{ isCancelled: 1 }
```

---

## 4.8 Collection: `ledger_entries`

```javascript
{
  _id: ObjectId,
  customerId: ObjectId,         // ref: customers, required
  entryType: String,            // enum: "opening_balance" | "bill" | "payment" | "adjustment"
  entryDate: Date,              // date only
  description: String,          // e.g. "Bill RE-2506-0001"
  debit: Number,                // Decimal128, default: 0 (amount customer owes)
  credit: Number,               // Decimal128, default: 0 (amount paid)
  referenceId: ObjectId,        // polymorphic ref (billId or paymentId)
  createdBy: ObjectId,          // ref: users
  createdAt: Date               // immutable — never updated
}

// Indexes
{ customerId: 1, entryDate: 1, createdAt: 1 }
{ customerId: 1, entryDate: -1 }
{ entryType: 1 }
{ referenceId: 1 }
```

---

## 4.9 Collection: `business_settings`

```javascript
{
  _id: ObjectId,
  businessName: String,         // default: "Rathod Enterprises"
  tagline: String,              // default: "Vegetable & Fruit Wholesale Supplier"
  address: String,              // default: ""
  phone: String,                // default: ""
  gstNumber: String,            // default: ""
  invoicePrefix: String,        // default: "RE"
  footerNote: String,           // default: "Thank you for your business!"
  createdAt: Date,
  updatedAt: Date
}
// Singleton — only one document exists
```

---

## 4.10 Collection: `audit_logs`

```javascript
{
  _id: ObjectId,
  userId: ObjectId,             // ref: users
  action: String,               // e.g. "CREATE_BILL" | "CANCEL_BILL" | "CREATE_PAYMENT"
  resource: String,             // e.g. "bill" | "payment" | "customer"
  resourceId: ObjectId,         // the affected document ID
  details: Mixed,               // any additional context
  ipAddress: String,
  createdAt: Date
}

// Indexes
{ userId: 1, createdAt: -1 }
{ resource: 1, resourceId: 1 }
{ action: 1 }
{ createdAt: -1 }
```

---

## 4.11 Collection: `counters`

```javascript
{
  _id: String,                  // "bill_number" | "receipt_number"
  seq: Number,                  // current sequence value
  prefix: String,               // optional prefix
  yearMonth: String             // "YYMM" for reset logic
}

// Atomic increment via findOneAndUpdate with $inc
```

---

## 4.12 Entity Relationship Diagram

```
users ──── creates ────> customers
users ──── creates ────> bills
users ──── creates ────> payments
users ──── creates ────> daily_rates
users ──── creates ────> ledger_entries

customers ──< bills
customers ──< payments
customers ──< ledger_entries

bills ──< bill_items
bills ────> payments (optional, via billId)
bills ────> ledger_entries (via referenceId)

products ──< daily_rates
products ──< bill_items
```

---

## 4.13 Design Decisions

1. **Decimal128 for monetary values**: Using MongoDB's Decimal128 via Mongoose to avoid floating-point rounding errors in financial calculations. All amounts are stored with 2 decimal precision.

2. **Text indexes for search**: Customers and products have text indexes for efficient search queries matching the current `ilike` behavior.

3. **Counter collection**: Instead of PostgreSQL sequences, we use a dedicated `counters` collection with `findOneAndUpdate` + `$inc` for atomic bill/receipt number generation.

4. **Immutable ledger**: Ledger entries are never updated or deleted — only inserted. This ensures a complete audit trail. Reversals are new entries with type `adjustment`.

5. **Snapshot pattern**: `bill_items.productName` stores the product name at billing time so historical bills remain correct even if products are renamed.

6. **Soft deletes**: Customers and products use `isDeleted` flag. Queries filter `isDeleted: false` by default.

7. **Date-only fields**: `billDate`, `paymentDate`, `rateDate`, `entryDate` are stored as Date objects at midnight (00:00:00 UTC). The application sends YYYY-MM-DD strings.

8. **No cascading deletes**: Since we use soft deletes and immutable ledgers, no cascade is needed. References remain valid.

9. **Index coverage**: Every query pattern in the existing application has a corresponding MongoDB index for performance.
