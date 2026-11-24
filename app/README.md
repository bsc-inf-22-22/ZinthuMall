# Kachipapa Store: Flutter app

Customer storefront and store-admin dashboard, built for **web** and **Android**.

```bash
flutter pub get
flutter run -d chrome                                   # uses http://localhost:3000/api
flutter build web --release --dart-define=API_BASE_URL=https://<api-host>/api
flutter analyze && flutter test
```

## Structure

```
lib/
├── main.dart                     routes
├── core/
│   ├── constants/                API URL, categories, cities
│   ├── providers/                Riverpod state: products, cart, customer session, wishlist
│   ├── services/api_service.dart all HTTP calls to the backend
│   ├── theme/app_theme.dart      brand colours and fonts (from the design)
│   ├── utils/format.dart         MK currency, dates, status labels
│   └── widgets/                  shared loading / error / empty states
└── features/<feature>/presentation/screens/
    home · category · product · search · cart · checkout · auth · profile
    orders · tracking · wishlist · reviews · addresses · admin
```

The store admin opens the dashboard by long-pressing the logo on the home page (or `/#/admin`).

See the [root README](../README.md) for deployment.

## App icon

`branding/app-icon-1024.png` is the source for the launcher icons (Android `mipmap-*`, web `icons/` and `favicon.png`, iOS `AppIcon`). It's a placeholder "K" monogram in the store red, set in Playfair Display (SIL Open Font License). To replace it with a real logo, swap the images, or add `flutter_launcher_icons` and point it at the new file.
