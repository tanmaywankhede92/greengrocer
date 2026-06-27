# Phase 2: Flutter Architecture
## Rathod Enterprises — Billing & Credit Ledger

---

## 2.1 Technology Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | Flutter (latest stable) | Cross-platform: Android, iOS, tablets, web |
| State Management | Riverpod 2.x | Compile-safe, testable, no BuildContext dependency |
| Routing | Go Router v14 | Declarative, deep linking, redirect guards |
| Architecture | Clean Architecture (feature-first) | Separation of concerns, testability |
| HTTP | Dio | Interceptors, retry, logging |
| Local Storage | flutter_secure_storage | JWT tokens |
| Printing | printing | PDF generation + print |
| Charts | fl_chart | Comparable to Recharts |
| Date/Time | intl | Locale-aware formatting (en-IN) |
| Theme | Material 3 | Dynamic theming, dark mode |

---

## 2.2 Folder Structure

```
frontend/
├── android/
├── ios/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app.dart                           # MaterialApp + GoRouter
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart            # API URLs, env vars
│   │   │   └── routes.dart                # Route constants
│   │   ├── constants/
│   │   │   ├── app_constants.dart         # App-wide constants
│   │   │   └── api_constants.dart         # API endpoint paths
│   │   ├── theme/
│   │   │   ├── app_theme.dart             # Light + dark theme
│   │   │   ├── app_colors.dart            # Color palette
│   │   │   ├── app_typography.dart        # Text styles
│   │   │   └── app_dimensions.dart        # Spacing, radius
│   │   ├── utils/
│   │   │   ├── format.dart                # INR, date, quantity formatting
│   │   │   ├── validators.dart            # Form validation
│   │   │   └── extensions.dart            # Dart extension methods
│   │   ├── network/
│   │   │   ├── dio_client.dart            # Dio singleton + interceptors
│   │   │   ├── api_exceptions.dart        # Custom exceptions
│   │   │   └── api_response.dart          # Generic response wrapper
│   │   ├── services/
│   │   │   ├── print_service.dart         # Print invoices/statements
│   │   │   ├── document_service.dart      # Build HTML for print
│   │   │   ├── share_service.dart         # WhatsApp sharing
│   │   │   └── storage_service.dart       # Secure storage
│   │   └── widgets/
│   │       ├── app_shell.dart             # Sidebar + scaffold
│   │       ├── page_container.dart        # Max-width wrapper
│   │       ├── page_header.dart           # Title + subtitle + actions
│   │       ├── empty_state.dart           # Empty state placeholder
│   │       ├── due_badge.dart             # Due amount badge
│   │       ├── stat_card.dart             # Dashboard stat card
│   │       ├── loading_skeleton.dart      # Skeleton loader
│   │       ├── responsive_grid.dart       # Adaptive grid layout
│   │       ├── search_field.dart          # Reusable search input
│   │       └── confirmation_dialog.dart   # Reusable confirm dialog
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   ├── providers/
│   │   │   │   ├── auth_provider.dart       # Auth state notifier
│   │   │   │   └── auth_state.dart          # AuthState sealed class
│   │   │   ├── screens/
│   │   │   │   ├── splash_screen.dart
│   │   │   │   └── auth_screen.dart
│   │   │   └── widgets/
│   │   │       └── auth_mode_toggle.dart
│   │   │
│   │   ├── dashboard/
│   │   │   ├── models/
│   │   │   │   ├── dashboard_data.dart
│   │   │   │   └── sales_series.dart
│   │   │   ├── repositories/
│   │   │   │   └── dashboard_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── dashboard_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── dashboard_screen.dart
│   │   │   └── widgets/
│   │   │       ├── dashboard_stat_grid.dart
│   │   │       ├── sales_area_chart.dart
│   │   │       ├── top_outstanding_list.dart
│   │   │       ├── recent_bills_list.dart
│   │   │       └── recent_payments_list.dart
│   │   │
│   │   ├── billing/
│   │   │   ├── models/
│   │   │   │   ├── bill_model.dart
│   │   │   │   ├── bill_item_model.dart
│   │   │   │   └── new_bill_request.dart
│   │   │   ├── repositories/
│   │   │   │   └── billing_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── billing_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── billing_screen.dart
│   │   │   └── widgets/
│   │   │       ├── customer_picker.dart
│   │   │       ├── quick_add_customer.dart
│   │   │       ├── product_picker.dart
│   │   │       ├── bill_line_item.dart
│   │   │       ├── bill_summary_card.dart
│   │   │       └── bill_success_dialog.dart
│   │   │
│   │   ├── bills/
│   │   │   ├── models/
│   │   │   │   ├── bill_detail.dart
│   │   │   │   └── bill_filter.dart
│   │   │   ├── repositories/
│   │   │   │   └── bills_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── bills_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── bills_screen.dart
│   │   │   └── widgets/
│   │   │       ├── bill_list_tile.dart
│   │   │       ├── bill_filter_bar.dart
│   │   │       ├── bill_detail_dialog.dart
│   │   │       └── cancel_bill_dialog.dart
│   │   │
│   │   ├── customers/
│   │   │   ├── models/
│   │   │   │   └── customer_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── customer_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── customer_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── customers_screen.dart
│   │   │   │   └── customer_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── customer_card.dart
│   │   │       ├── customer_form_dialog.dart
│   │   │       ├── customer_quick_summary.dart
│   │   │       └── ledger_table.dart
│   │   │
│   │   ├── products/
│   │   │   ├── models/
│   │   │   │   └── product_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── product_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── product_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── products_screen.dart
│   │   │   └── widgets/
│   │   │       ├── product_card.dart
│   │   │       ├── product_form_dialog.dart
│   │   │       └── product_toggle.dart
│   │   │
│   │   ├── rates/
│   │   │   ├── models/
│   │   │   │   ├── daily_rate_model.dart
│   │   │   │   └── rate_history_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── rate_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── rate_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── rates_screen.dart
│   │   │   └── widgets/
│   │   │       ├── rate_card.dart
│   │   │       ├── rate_input.dart
│   │   │       └── rate_history_dialog.dart
│   │   │
│   │   ├── payments/
│   │   │   ├── models/
│   │   │   │   └── payment_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── payment_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── payment_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── payments_screen.dart
│   │   │   └── widgets/
│   │   │       ├── payment_dialog.dart
│   │   │       ├── customer_picker_dialog.dart
│   │   │       └── receipt_print.dart
│   │   │
│   │   ├── ledger/
│   │   │   ├── models/
│   │   │   │   └── ledger_entry_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── ledger_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── ledger_provider.dart
│   │   │   └── widgets/
│   │   │       └── ledger_table.dart
│   │   │
│   │   ├── statements/
│   │   │   ├── models/
│   │   │   │   └── statement_data.dart
│   │   │   ├── repositories/
│   │   │   │   └── statement_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── statement_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── statements_screen.dart
│   │   │   └── widgets/
│   │   │       ├── customer_selector.dart
│   │   │       ├── period_picker.dart
│   │   │       └── statement_table.dart
│   │   │
│   │   └── settings/
│   │       ├── models/
│   │       │   └── business_settings.dart
│   │       ├── repositories/
│   │       │   └── settings_repository.dart
│   │       ├── providers/
│   │       │   └── settings_provider.dart
│   │       ├── screens/
│   │       │   └── settings_screen.dart
│   │       └── widgets/
│   │           └── settings_form.dart
│   │
│   └── l10n/                              # Localization (future)
│       ├── app_en.arb
│       └── app_hi.arb                     # Hindi support
│
├── assets/
│   ├── fonts/
│   │   └── PlusJakartaSans-*.ttf
│   ├── images/
│   │   └── logo.png
│   └── icons/
│
├── test/
│   ├── core/
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── billing/
│   │   └── ...
│   └── helpers/
│
├── pubspec.yaml
├── analysis_options.yaml
└── .env
```

---

## 2.3 Go Router Configuration

```
/                  → SplashScreen (redirects to /dashboard or /auth)
/auth              → AuthScreen
/dashboard         → DashboardScreen (auth required)
/billing           → BillingScreen (auth required)
/bills             → BillsScreen (auth required)
/customers         → CustomersScreen (auth required)
/customers/:id     → CustomerDetailScreen (auth required)
/products          → ProductsScreen (auth required)
/rates             → RatesScreen (auth required)
/payments          → PaymentsScreen (auth required)
/statements        → StatementsScreen (auth required)
/settings          → SettingsScreen (auth required, admin for edit)
```

Redirect guard: `ShellRoute` with `redirect` that checks `AuthProvider` state. If `unauthenticated`, redirect to `/auth`.

---

## 2.4 State Management Architecture (Riverpod)

```
                    ┌──────────────────┐
                    │   Widget Layer   │
                    │  (Screens/Pages) │
                    └────────┬─────────┘
                             │ watch/read
                    ┌────────▼─────────┐
                    │   Providers      │
                    │ (StateNotifier  │
                    │  /Future/Stream)│
                    └────────┬─────────┘
                             │ call
                    ┌────────▼─────────┐
                    │  Repositories    │
                    │ (Data access)    │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  Dio Client      │
                    │  (API calls)     │
                    └────────┬─────────┘
                             │ HTTP
                    ┌────────▼─────────┐
                    │   Node.js API    │
                    └──────────────────┘
```

**Provider Patterns:**
- `authProvider` → `StateNotifier<AuthState>` (authenticated/unauthenticated/loading)
- `dashboardProvider` → `FutureProvider<DashboardData>`
- `customersProvider` → `FutureProvider<List<Customer>>` with family for search
- `customerDetailProvider` → `FutureProvider.family<CustomerDetail, String>`
- `billsProvider` → `FutureProvider<List<Bill>>` with family for filters
- `billDetailProvider` → `FutureProvider.family<BillDetail, String>`
- `productsProvider` → `FutureProvider<List<Product>>`
- `ratesProvider` → `FutureProvider<Map<String, DailyRate>>` with family for date
- `paymentsProvider` → `FutureProvider<List<Payment>>` with family for customerId
- `ledgerProvider` → `FutureProvider.family<List<LedgerEntry>, LedgerParams>`
- `settingsProvider` → `FutureProvider<BusinessSettings>`

---

## 2.5 Theme Architecture (Material 3)

**Color Scheme (Light):**
- Primary: Green (#2F7A4D) — from existing `--primary`
- Secondary: Light green tint (#E8F5E9) — from existing `--secondary`
- Error: Red (#B3261E) — from existing `--destructive`
- Tertiary: Amber (#F59E0B) — from existing `--warning`
- Surface: Off-white (#F8F9F6) — from existing `--background`
- Surface Container: White — from existing `--card`
- On Surface: Dark green (#1A2E22) — from existing `--foreground`

**Color Scheme (Dark):**
- Primary: Lighter green (#4CAF50)
- Surface: Dark (#1A2E22)
- On Surface: Off-white

**Typography:**
- Font Family: Plus Jakarta Sans
- Headlines: w700, size 24-32
- Titles: w600, size 16-20
- Body: w400, size 13-15
- Labels: w500, size 11-13
- Tabular numbers for currency

**Shadows:**
- Soft: elevation 1-2 with custom offset
- Card: elevation 3-4

**Shape:**
- Small: 8px
- Medium: 12px (default)
- Large: 16px
- Extra Large: 20px

---

## 2.6 Responsive Design Strategy

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Phone | < 600px | Single column, bottom nav |
| Tablet (fold) | 600-840px | Two column, sidebar |
| Tablet (landscape) | 840-1024px | Sidebar + two/three columns |
| Desktop | > 1024px | Sidebar + flexible grid |

**LayoutBuilder + Breakpoints** used throughout:
- `AppShell`: sidebar shown inline on tablet+, drawer on phone
- `Dashboard`: 1 col phone → 2 col tablet → 3 col desktop
- `Billing`: stacked on phone → side-by-side on tablet+
- `Customers`: 1 col phone → 2 col tablet → 3 col desktop
- Tables: horizontal scroll on phone, full width on tablet+

---

## 2.7 Dependency Injection

All providers are created at the app level via Riverpod's `ProviderScope`. Each repository is created as a `Provider` that depends on `dioClientProvider`. This allows easy testing by overriding any provider.

```
final dioClientProvider = Provider<Dio>((ref) => createDioClient());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(dioClientProvider)));
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref.watch(authRepositoryProvider)));
```

---

## 2.8 Feature Module Template

Each feature follows this structure:
1. **Model**: Freezed data classes with JSON serialization
2. **Repository**: Data access layer (API calls via Dio, parsing responses)
3. **Provider**: Riverpod provider (FutureProvider or StateNotifierProvider)
4. **Screen**: Full-page widget using Go Router
5. **Widgets**: Reusable sub-widgets for the screen

---

## 2.9 Key Architectural Decisions

1. **No `BuildContext` in providers** — Riverpod avoids this antipattern
2. **Repositories return domain models** — raw JSON never leaks to UI
3. **Dio interceptors** — one for auth token injection, one for error mapping
4. **All API calls go through repository layer** — no direct Dio calls in widgets
5. **Loading/error/data states** — handled via Riverpod's AsyncValue
6. **Secure storage** — JWT tokens stored via flutter_secure_storage
7. **Print service** — uses `printing` package for native print/PDF
8. **Form validation** — formz package or manual validators matching Zod schemas
