# Mobile Client (Flutter)

Android client of the Academic Assessment & Audit Management System for jury
members: sign in with CATS, see assigned projects, enter and submit scores.

## Structure

```
lib/
  main.dart                 App start, routes, session-expiry handling
  config/app_theme.dart     Colours and theme
  models/                   API data models (user, projects, criteria, scores)
  services/
    api_client.dart         JSON/HTTP client, bearer token, error mapping
    session_store.dart      Token in secure storage, server address in preferences
    auth_service.dart       Sign-in, sign-out, session restore
    jury_service.dart       Assigned projects and score entry
    app_services.dart       Makes the services available to all screens
  screens/                  Startup, login, server settings, home, evaluation
  widgets/                  Grading form, status badge
  utils/formatters.dart     Date formatting, score and URL validation
test/                       Unit and widget tests
```

## Requirements

- Flutter 3.24 or later (`flutter doctor` without Android toolchain errors)
- Android emulator or an Android phone
- The backend running (see `backend/README.md`)

## Run

```powershell
cd mobile
flutter pub get
flutter run
```

On first launch open **Server settings** on the login screen:

| Device | Server address |
|---|---|
| Android emulator | `http://10.0.2.2:3000` (default) |
| Phone on the same Wi-Fi | `http://<computer IPv4 address>:3000` (`ipconfig`) |

Use **Test connection** to check that the API and database are reachable.

For local development without CATS accounts, start the backend with
`CATS_MODE=mock` and sign in as a demo jury account (e.g. `jury.demo1`) with
the configured `CATS_MOCK_PASSWORD`.

## Security

- The session token is stored in Android Keystore-backed secure storage;
  passwords are never stored.
- When the token expires the app signs out and returns to the login screen.
- Plain HTTP is allowed only for the development server; production uses HTTPS.

## Quality checks

```powershell
dart format lib test
flutter analyze
flutter test
```

The same checks run on GitHub Actions for every pull request.
