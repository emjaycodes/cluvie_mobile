# cluvie_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment Configuration

API base URL is compile-time driven via `--dart-define` (see `lib/core/api/api_client.dart`).

| Target | Command |
|---|---|
| Local (iOS simulator / desktop) | `flutter run --dart-define=API_BASE_URL=http://localhost:5000/api` |
| Android emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api` |
| Physical device (same LAN) | `flutter run --dart-define=API_BASE_URL=http://<lan-ip>:5000/api` |
| QA / Prod | `flutter build apk --dart-define=API_BASE_URL=https://api.cluvie.com/api` |

Default (no flag): `http://localhost:5000/api`

Optional `.env` support: copy `.env.example` to `.env` and set `API_BASE_URL` / `ENV`. `.env` is gitignored — never commit it. The compile-time `--dart-define` takes precedence per OPERATIONS.md §2.3.
