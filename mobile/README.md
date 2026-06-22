# ФИНКИ Распоред — Mobile (Flutter)

Native iOS/Android client for the FINKI Scheduler. Talks to the **existing**
Spring Boot backend (`/api`) — no backend changes.

## Phase 1 (built so far)
- Login (`/api/auth/login`) with JWT stored in the device keychain/keystore.
- Timetable: class list grouped by day, filter sheet (year, programme, day, type,
  professor, subject, room), and one-tap **+ Додај / ✓ Додадено** to your schedule.
- Bottom tabs (Консултации, Испити, Мој Распоред, Карта are placeholders for later phases).

## Run it

1. Make sure the backend is up (from the repo root): `docker compose up -d`
2. Get packages: `cd mobile && flutter pub get`
3. Run:
   - iOS simulator (reaches localhost automatically): `flutter run`
   - Android emulator (uses host loopback automatically): `flutter run`
   - Physical phone — pass your computer's LAN IP:
     `flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8080/api`
     (find it with `ipconfig getifaddr en0` on macOS)

## Notes
- Cleartext HTTP to the local backend is enabled for development (iOS
  NSAllowsLocalNetworking, Android usesCleartextTraffic). Use HTTPS for release.
- Stack: Flutter · Riverpod · go_router · dio · flutter_secure_storage · google_fonts.
