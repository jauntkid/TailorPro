# Godarzi — Pending Features & Roadmap

## Current Feature Summary

- **Auth**: Email/password + Google Sign-In, user-scoped Firestore data
- **Customers**: CRUD with soft-delete, phone/email/address, measurement templates
- **Orders**: Multi-item orders, configurable measurements, status workflow, due dates, reference images, urgent flag
- **Payments**: Advance + multiple payments (Cash/UPI/Card/Bank/Cheque), balance tracking
- **Invoices**: PDF generation with shop branding, share via system sheet
- **WhatsApp**: Status updates, payment links, delivery reminders, custom messages
- **Notifications**: Local push for orders due today (every 3 hours check)
- **Analytics**: Revenue/orders by day charts, top customers, custom date range
- **Settings**: Shop details, garment types + default prices, measurement fields, unit toggle, theme toggle
- **Search**: Global search across orders & customers

---

## P0 — Critical (Before Release)

| # | Feature | Status |
|---|---------|--------|
| 1 | **Release signing** | ❌ Using debug signing. Need keystore + key.properties for Play Store. |
| 2 | **Firestore security rules** | ❌ Need rules restricting `users/{uid}/**` to authenticated owner. |
| 3 | **Firebase Storage rules** | ❌ Need read/write rules scoped to user. |
| 4 | **Crash reporting** | ❌ Add Firebase Crashlytics. |
| 5 | **Error handling** | ⚠️ Data service uses debugPrint. Need user-facing error toasts. |
| 6 | **Input validation** | ⚠️ Harden phone/email/amount validation. |

## P1 — High Priority (Shortly After Launch)

| # | Feature | Status |
|---|---------|--------|
| 7 | **Data backup / export** | ❌ Export customers, orders, financials to CSV. |
| 8 | **Trash / restore UI** | ❌ Soft-delete exists but no UI to view or restore deleted items. |
| 9 | **Image upload to cloud** | ❌ Reference images stored as local paths. Need Firebase Storage upload. |
| 10 | **Pagination / lazy loading** | ❌ All data loaded into memory. Won't scale past ~1000 orders. |
| 11 | **Real-time Firestore listeners** | ❌ Data loaded once at init. Multi-device edits don't sync. |
| 12 | **Privacy policy & terms** | ❌ Required for Play Store / App Store. |

## P2 — Medium Priority (Post-Launch)

| # | Feature | Status |
|---|---------|--------|
| 13 | **Multi-language / i18n** | ❌ English only. Hindi/regional languages for Indian market. |
| 14 | **Financial reports** | ❌ Monthly/yearly revenue, GST summaries, outstanding balances. |
| 15 | **Customer order tracking** | ❌ Web link for customers to check order status. |
| 16 | **SMS notifications** | ❌ Fallback for customers without WhatsApp. |
| 17 | **Calendar view** | ❌ Visual due date calendar for workload planning. |
| 18 | **Staff / multi-user** | ❌ Roles (tailor, assistant), staff management. |
| 19 | **Barcode / QR labels** | ❌ Print QR labels for physical garment tracking. |
| 20 | **Measurement history** | ❌ Track changes in customer measurements over time. |
| 21 | **Automated reminders** | ❌ Auto-send WhatsApp when order overdue or payment due. |
| 22 | **Unit tests** | ❌ No test coverage for services or models. |
| 23 | **CI/CD pipeline** | ❌ No automated testing/build pipeline. |

## P3 — Nice to Have

| # | Feature | Status |
|---|---------|--------|
| 24 | **Offline indicators** | ❌ Show connectivity status to user. |
| 25 | **Receipt printing** | ❌ Bluetooth thermal printer support. |
| 26 | **Customer loyalty / discounts** | ❌ Discount system, loyalty points. |
| 27 | **Accessibility** | ❌ Semantic labels, screen reader support. |
| 28 | **Deep linking** | ❌ Open specific order from notification. |
| 29 | **App update prompts** | ❌ Version check and update reminders. |

---

## Files to Clean Up

These legacy files are not imported by the active app and can be safely deleted:

### Models
- `lib/models/enhanced_customer.dart`
- `lib/models/enhanced_order.dart`
- `lib/models/enhanced_product.dart`

### Screens
- `lib/screens/enhanced_home_screen.dart`
- `lib/screens/orders/new_order_screen.dart`
- `lib/screens/orders/orders_tracking_screen.dart`
- `lib/screens/customers/customers_list_screen.dart`
- `lib/screens/products/products_list_screen.dart`

### Providers
- `lib/providers/firebase_auth_provider.dart`
- `lib/providers/theme_provider.dart`

### Other
- `lib/core/` (entire directory — old router)
- `lib/widgets/user_profile_header.dart`
- `lib/assets/logo2.png`

### Unused main_*.dart variants
- `lib/main_final.dart`
- `lib/main_firebase_real.dart`
- `lib/main_firebase.dart`
- `lib/main_new.dart`
- `lib/main_simple.dart`
- `lib/main_step2.dart`
- `lib/main_step3.dart`
