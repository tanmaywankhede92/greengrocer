# Code Analysis — Mandi Bill Buddy (Original TypeScript + Supabase)

This document captures the complete analysis of the original Mandi Bill Buddy application before rebuilding into Flutter + Node.js/MongoDB.

---

## 1. Original Stack

| Layer | Technology |
|-------|-----------|
| Frontend | TypeScript, React 18, Vite |
| Styling | Tailwind CSS, shadcn/ui components |
| State | Supabase React Query (`@supabase/supabase-js`) |
| Database | Supabase (PostgreSQL) with Row-Level Security |
| Auth | Supabase Auth (email/password) |
| Storage | Supabase Storage |
| Deployment | Lovable.app |

---

## 2. File Structure (Original)

```
src/
├── App.tsx
├── index.css
├── main.tsx
├── types/                    # TypeScript interfaces
│   ├── auth.ts               # AuthUser, LoginPayload, RegisterPayload
│   ├── customer.ts           # Customer interface
│   ├── product.ts            # Product interface
│   ├── dailyRate.ts          # DailyRate
│   ├── bill.ts               # Bill, BillItem (line items embedded)
│   ├── ledger.ts             # LedgerEntry
│   ├── payment.ts            # Payment
│   ├── dashboard.ts          # DashboardStats
│   └── settings.ts           # BusinessSettings
├── lib/
│   ├── supabase.ts           # Supabase client initialization
│   ├── query-client.ts       # TanStack Query client setup
│   └── utils.ts              # formatCurrency, formatDate, cn()
├── hooks/
│   ├── use-auth.ts           # Auth hooks (signIn, signUp, signOut, user)
│   ├── use-customers.ts      # Customer CRUD hooks
│   ├── use-products.ts       # Product CRUD hooks
│   ├── use-rates.ts          # Daily rate hooks
│   ├── use-bills.ts          # Bill CRUD + cancel hooks
│   ├── use-payments.ts       # Payment hooks
│   ├── use-ledger.ts         # Ledger hooks
│   ├── use-dashboard.ts      # Dashboard data hook
│   └── use-settings.ts       # Settings hooks
├── pages/
│   ├── Login.tsx
│   ├── Register.tsx
│   ├── Dashboard.tsx
│   ├── Customers.tsx           # Customer list
│   ├── CustomerDetail.tsx      # Single customer with ledger
│   ├── Products.tsx            # Product management
│   ├── DailyRates.tsx          # Daily rate management
│   ├── NewBill.tsx             # Bill creation flow
│   ├── Bills.tsx               # Bill list
│   ├── BillDetail.tsx          # Single bill with items
│   ├── Payments.tsx            # Payment list
│   ├── AddPayment.tsx          # Record standalone payment
│   ├── CustomerStatement.tsx   # Customer statement with balance
│   └── Settings.tsx            # Business settings
└── components/
    ├── ui/                     # shadcn/ui primitives
    │   ├── button.tsx
    │   ├── card.tsx
    │   ├── input.tsx
    │   ├── select.tsx
    │   ├── table.tsx
    │   ├── dialog.tsx
    │   ├── dropdown-menu.tsx
    │   ├── badge.tsx
    │   ├── separator.tsx
    │   ├── sheet.tsx
    │   ├── toast.tsx
    │   ├── tooltip.tsx
    │   └── skeleton.tsx
    ├── Layout.tsx              # App shell with sidebar + header
    ├── Sidebar.tsx             # Navigation sidebar
    ├── Header.tsx              # Top header bar
    ├── CustomerSelect.tsx      # Customer search/select component
    ├── ProductSelect.tsx       # Product search/select component
    ├── BillItemRow.tsx         # Single line item in bill form
    ├── PaymentModeSelect.tsx   # Payment mode dropdown
    ├── StatCard.tsx            # Dashboard stat card
    ├── SalesChart.tsx          # Monthly sales chart
    ├── RecentTransactions.tsx  # Recent bills/payments widget
    ├── TopCustomers.tsx        # Top customers widget
    ├── LoadingSpinner.tsx      # Loading state
    └── EmptyState.tsx          # Empty state placeholder
```

---

## 3. Database Schema (Original — PostgreSQL via Supabase)

### Tables

| Table | Key Columns | Notes |
|-------|-------------|-------|
| `auth.users` | id, email, encrypted_password | Managed by Supabase Auth |
| `customers` | id, name, mobile, address, gst_number, opening_balance, notes, created_by, is_deleted, created_at | RLS enabled |
| `products` | id, name, unit, is_active, is_deleted, created_at | RLS enabled |
| `daily_rates` | id, product_id, rate, rate_date, created_by, created_at | Unique: product_id + rate_date |
| `bills` | id, bill_number, customer_id, bill_date, subtotal, discount, total, paid_now, new_due, payment_type, notes, status, created_by, created_at | bill_number unique |
| `bill_items` | id, bill_id, product_id, product_name, unit, quantity, default_rate, applied_rate, amount, created_at | |
| `payments` | id, receipt_number, customer_id, amount, mode, reference, notes, payment_date, is_cancelled, created_by, created_at | receipt_number unique |
| `ledger_entries` | id, customer_id, entry_type, entry_date, description, debit, credit, created_at | Immutable |
| `business_settings` | id, business_name, tagline, address, phone, gst_number, invoice_prefix, footer_note, updated_at | Singleton row |
| `audit_logs` | id, action, resource, resource_id, user_id, metadata, created_at | |

### Key PostgreSQL Features Used

- **Row-Level Security (RLS):** Policies on every table restricting access by `auth.uid()` = `created_by`
- **`gen_random_uuid()`** for primary keys
- **`customer_balances` view:** `SELECT customer_id, SUM(debit - credit) as balance FROM ledger_entries GROUP BY customer_id`
- **`generate_bill_number()` PG function:** Uses a `bill_sequences` table with `SELECT ... FOR UPDATE` to atomically increment
- **`create_bill()` PG function:** Wraps the entire bill creation in a single PG function (bill + items + ledger + payment) executed in a transaction

---

## 4. Business Logic Analysis

### 4.1 Auth Flow
- Supabase Auth handles registration/login
- `signIn` returns session with access/refresh tokens
- `signUp` creates user in `auth.users`
- No role concept — all authenticated users get same access
- Session refreshed automatically by Supabase client

### 4.2 Billing Flow
1. User selects customer (searchable dropdown)
2. Previous due fetched and displayed
3. User adds line items (product search, quantity, rate override)
4. System auto-fills today's rate from `daily_rates` table
5. Subtotal calculated, discount applied, total computed
6. Previous due + total = amount payable
7. User optionally enters payment amount and mode
8. On submit → single PG function `create_bill()` runs in transaction:
   - Insert into `bills` (status='active')
   - Insert all `bill_items`
   - If payment > 0: insert into `payments` + `ledger_entries` (credit)
   - Insert into `ledger_entries` (debit = total)

### 4.3 Dashboard Queries
- `todayRevenue`: SUM of today's bill totals
- `todayOrders`: COUNT of today's bills
- `monthlyCollection`: SUM of current month's payments
- `outstanding`: SUM of (debits - credits) from ledger
- `totalCustomers`: COUNT of non-deleted customers
- `pendingCustomers`: COUNT of customers with balance > 0
- `topCustomers`: TOP 5 customers by current due
- `recentBills`: Last 10 bills
- `recentPayments`: Last 10 payments
- `salesSeries`: Monthly sales for last 12 months

### 4.4 Payment Modes
- `cash`
- `upi` (UPI/QR)
- `bank_transfer` (NEFT/IMPS)
- `cheque`

### 4.5 Product Units
- `kg` (Kilogram)
- `pcs` (Pieces)
- `bundle` (Bundle)
- `box` (Box)
- `dozen` (Dozen)
- `quintal` (Quintal — 100kg)
- `bag` (Bag)
- `crate` (Crate)

### 4.6 Ledger Entry Types
- `opening_balance` — Initial customer balance
- `bill` — Debit entry for a bill
- `payment` — Credit entry for payment
- `adjustment` — Reversal entry (e.g., cancelled bill)

### 4.7 Bill Status
- `active` — Normal, valid bill
- `cancelled` — Bill has been voided

### 4.8 Cancel Bill Logic
1. Mark bill as `cancelled`
2. Add reversal ledger entry (credit = bill total)
3. If there was an associated payment, cancel it (`is_cancelled = true`) and add reversal entry (debit = payment amount)

---

## 5. UI/UX Patterns

### Layout
- **Sidebar:** Fixed left sidebar with navigation links + active state
- **Header:** Top bar with business name, user info, logout
- **Content:** Main content area (right of sidebar)

### Theme
- Background: `#f8fafc` (slate-50)
- Cards: White with subtle shadow
- Primary: Blue tones
- Font: Inter (via Tailwind)
- Typography: Regular weight, clean hierarchy

### Key UI Flows

**Billing Screen:**
1. Top section: Customer search/select with previous due display
2. Middle section: Line items table (product, qty, rate, amount)
3. "Add Item" button appends a new row
4. Bottom section: Subtotal, discount input, total
5. Payment section: Amount paid, mode selector
6. Submit button: "Generate Bill"

**Daily Rates Screen:**
1. Date picker at top (defaults to today)
2. Table: column for each product, rate input field
3. Auto-save on blur or explicit save button
4. Rates from past dates shown read-only

**Customer Statement:**
1. Date range picker
2. Table: Date, Description, Debit, Credit, Running Balance
3. Opening/closing balance summary at top

**Dashboard:**
1. Top row: 4 stat cards (Today Revenue, Orders, Collection, Outstanding)
2. Middle row: Sales chart (bar/line) + Top Customers
3. Bottom row: Recent Bills + Recent Payments

---

## 6. API Layer (Original — Supabase Queries)

The original app did NOT have a REST API. All data access was done client-side via Supabase JavaScript client:

```typescript
// Pattern: Direct Supabase queries from React hooks
const { data, error } = await supabase
  .from('customers')
  .select('*')
  .ilike('name', `%${search}%`)
  .order('name')
```

### Key Queries

```typescript
// Customers list with balance
supabase.from('customers')
  .select(`
    *,
    current_due: ledger_entries!inner(
      balance: sum(debit - credit)
    )
  `)
  .is('is_deleted', false)
  .ilike('name', `%${search}%`)

// Bills with customer info
supabase.from('bills')
  .select(`
    *,
    customer: customers(name, mobile)
  `)
  .order('created_at', { ascending: false })

// Dashboard parallel queries
const [revenue, orders, customers, topCustomers, recentBills] = await Promise.all([
  supabase.rpc('get_today_revenue'),
  supabase.rpc('get_today_orders'),
  supabase.rpc('get_customer_summary'),
  supabase.rpc('get_top_customers'),
  supabase.rpc('get_recent_bills')
])
```

### PG Functions (Original)

```sql
-- Bill number generation
CREATE OR REPLACE FUNCTION generate_bill_number()
RETURNS text AS $$
  SELECT 'RE-' || to_char(now(), 'YYMM') || '-' || 
    LPAD(nextval('bill_seq')::text, 4, '0');
$$ LANGUAGE sql;

-- Atomic bill creation
CREATE OR REPLACE FUNCTION create_bill(
  p_customer_id uuid,
  p_bill_date date,
  p_items jsonb,
  p_discount numeric,
  p_notes text,
  p_payment_amount numeric,
  p_payment_mode text
) RETURNS uuid AS $$
DECLARE
  v_bill_id uuid;
  v_bill_number text;
  v_item jsonb;
  v_subtotal numeric := 0;
  v_total numeric := 0;
  v_payment_id uuid;
BEGIN
  -- Generate bill number
  v_bill_number := generate_bill_number();
  
  -- Create bill
  INSERT INTO bills (customer_id, bill_number, bill_date, notes, status)
  VALUES (p_customer_id, v_bill_number, p_bill_date, p_notes, 'active')
  RETURNING id INTO v_bill_id;
  
  -- Insert items
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_subtotal := v_subtotal + (v_item->>'amount')::numeric;
    INSERT INTO bill_items (bill_id, product_id, product_name, unit, 
      quantity, default_rate, applied_rate, amount)
    VALUES (v_bill_id, (v_item->>'product_id')::uuid, v_item->>'product_name',
      v_item->>'unit', (v_item->>'quantity')::numeric,
      (v_item->>'default_rate')::numeric, (v_item->>'applied_rate')::numeric,
      (v_item->>'amount')::numeric);
  END LOOP;
  
  v_total := v_subtotal - p_discount;
  UPDATE bills SET subtotal = v_subtotal, discount = p_discount, total = v_total
  WHERE id = v_bill_id;
  
  -- Ledger entry for bill
  INSERT INTO ledger_entries (customer_id, entry_type, entry_date, description, debit)
  VALUES (p_customer_id, 'bill', p_bill_date, 'Bill ' || v_bill_number, v_total);
  
  -- Payment
  IF p_payment_amount > 0 THEN
    INSERT INTO payments (customer_id, amount, mode, payment_date)
    VALUES (p_customer_id, p_payment_amount, p_payment_mode, p_bill_date)
    RETURNING id INTO v_payment_id;
    
    INSERT INTO ledger_entries (customer_id, entry_type, entry_date, description, credit)
    VALUES (p_customer_id, 'payment', p_bill_date, 
      'Payment for Bill ' || v_bill_number, p_payment_amount);
    
    UPDATE bills SET paid_now = p_payment_amount, payment_type = p_payment_mode,
      new_due = v_total - p_payment_amount
    WHERE id = v_bill_id;
  ELSE
    UPDATE bills SET new_due = v_total WHERE id = v_bill_id;
  END IF;
  
  RETURN v_bill_id;
END;
$$ LANGUAGE plpgsql;
```

---

## 7. Conversion Decisions

| Original (Supabase) | New (MongoDB) | Rationale |
|---------------------|---------------|-----------|
| Row-Level Security | JWT + `authenticate`/`authorize` middleware | MongoDB has no RLS; application-level auth is standard |
| PG function `create_bill()` | `billService.js` with `Mongoose.startSession()` + transaction | Transactional atomicity equivalent |
| PG function `generate_bill_number()` | `sequenceGenerator.js` with Counter collection + `findOneAndUpdate` + `$inc` | Atomic counter equivalent |
| `customer_balances` view | Aggregation pipeline in `ledgerRepository.js` | Running balance computed on read |
| Supabase Auth | JWT (jsonwebtoken) + bcrypt | Self-contained auth |
| `supabase-js` queries | Express REST API | Decoupled frontend/backend |
| Supabase React Query hooks | Riverpod providers + Dio HTTP | Flutter state management |
| Tailwind CSS | Material 3 + custom theme | Flutter design system |
| shadcn/ui components | Flutter Material widgets | Platform-native UI |

---

## 8. Data Migration

No data migration needed — this is a greenfield rebuild. The original Supabase data and new MongoDB data will coexist independently. Future migration from Supabase to MongoDB can be done via a script if needed.

---

## 9. Boundary Cases Preserved

| Case | Handling |
|------|----------|
| Bill with 100+ items | Single transaction, items in separate collection |
| Zero payment bill | Bill created without payment/ledger credit entry |
| Full payment bill | Bill + full payment + both ledger entries |
| Over-payment | Allowed (credit > debit) — treated as advance |
| Rate override | `appliedRate` stored separately from `defaultRate` |
| Duplicate mobile | Unique index on `customers.mobile` |
| Delete customer with bills | Soft delete (`isDeleted: true`) — bills remain accessible |
| Concurrent bill number generation | Atomic `findOneAndUpdate` with `$inc` prevents collisions |
| Bill cancellation reverses ledger | Matching `adjustment` entry with opposite sign |
