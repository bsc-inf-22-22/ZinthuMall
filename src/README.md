# Kachipapa Store — Flutter App

## 📁 Project Structure

```
kachipapa_store/
│
├── lib/
│   │
│   ├── main.dart                          ← App entry point
│   │
│   ├── core/                              ← Shared across all features
│   │   ├── theme/
│   │   │   └── app_theme.dart             ← Colors, fonts, spacing
│   │   ├── constants/
│   │   │   └── app_constants.dart         ← API URLs, keys, strings
│   │   └── widgets/                       ← Shared reusable widgets
│   │
│   └── features/                          ← Each screen is a "feature"
│       ├── home/
│       │   ├── data/
│       │   │   └── models/
│       │   │       └── product_model.dart ← Product data class
│       │   └── presentation/
│       │       ├── screens/
│       │       │   └── home_screen.dart   ← Homepage UI
│       │       └── widgets/
│       │           └── product_card.dart  ← Reusable product card
│       │
│       ├── product/                       ← Product detail (coming next)
│       ├── cart/                          ← Cart screen (coming next)
│       ├── checkout/                      ← Checkout + Pachangu (coming next)
│       ├── account/                       ← User account (coming next)
│       └── seller/                        ← Seller dashboard (coming next)
│
├── assets/
│   ├── fonts/                             ← PlayfairDisplay + DMSans .ttf files
│   ├── images/                            ← Logo, placeholders
│   └── icons/                             ← SVG icons
│
└── pubspec.yaml                           ← Dependencies & assets config
```

---

## 🏗️ Architecture — Feature-First Clean Architecture

We organize code by **feature** (not by type). This means all
code related to "home" lives in `features/home/`, all code for
"cart" lives in `features/cart/`, etc.

Each feature has 3 layers:

```
feature/
  data/           ← Models, API calls, local storage
  domain/         ← Business logic (coming later with Riverpod)
  presentation/   ← UI: screens and widgets
```

**Why this matters:** When the app grows to 20+ screens, you can
find everything in one place. A new developer can open `features/cart/`
and understand the entire cart feature without touching anything else.

---

## 🧠 Key Flutter Concepts Used

| Concept | Where | Why |
|---------|-------|-----|
| `StatefulWidget` | HomeScreen, ProductCard | Mutable state (countdown, wishlist toggle) |
| `StatelessWidget` | KachipapaStoreApp | No internal state needed |
| `CustomScrollView + Slivers` | HomeScreen | Performant scrolling with sticky header |
| `SliverGrid` | HomeScreen | Lazy-loading product grid |
| `AnimatedContainer` | Category circles, tabs | Smooth selection animations |
| `Timer.periodic` | Flash sale countdown | Runs code every second |
| `initState / dispose` | HomeScreen | Start timer on open, cancel on close |
| `factory fromJson` | ProductModel | Convert API JSON → Dart object |
| `copyWith` | ProductModel | Immutable updates |
| `GestureDetector` | Cards, circles | Tap detection |

---

## 🚀 How to Run

```bash
# 1. Get dependencies
flutter pub get

# 2. Add fonts to assets/fonts/ (download from Google Fonts)
#    - PlayfairDisplay-Regular.ttf
#    - PlayfairDisplay-Bold.ttf
#    - DMSans-Regular.ttf
#    - DMSans-Medium.ttf
#    - DMSans-SemiBold.ttf

# 3. Run the app
flutter run
```

---

## 🔗 Connection to NestJS Backend

The Flutter app will talk to NestJS via REST API:

```
Flutter App  →  HTTP Request  →  NestJS API  →  PostgreSQL
Flutter App  ←  JSON Response ←  NestJS API  ←  PostgreSQL
```

All API calls will go through `AppConstants.apiBaseUrl`.
Products, orders, users — all come from the NestJS server.

---

## 📦 Coming Next (in order)

1. ✅ Homepage (done)
2. 🔜 Category screen (Men, Women, Home with filters)
3. 🔜 Product detail screen
4. 🔜 Cart screen
5. 🔜 Checkout screen + Pachangu payment integration
6. 🔜 Login / Register screen
7. 🔜 Seller Dashboard screen
8. 🔜 NestJS backend setup (modules, controllers, services)
9. 🔜 PostgreSQL database schema + TypeORM entities
10. 🔜 Pachangu API integration on the backend
