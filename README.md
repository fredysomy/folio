# Folio

A personal portfolio tracker for **Mutual Funds** and **Stocks**, built with Flutter. Import your holdings via Excel, track live NAV and prices, and get daily summary notifications — all stored locally on your device.

## Features

- **Mutual Fund tracking** — import holdings from CAS/Excel, live NAV via MF API
- **Stock tracking** — import stock holdings, live prices via API key
- **Net worth overview** — combined MF + stock value, invested vs current, P&L
- **Day change** — daily gain/loss tracked from net worth history
- **Daily notifications** — scheduled background summary of your portfolio
- **API key management** — add/remove stock data API keys
- **Offline-first** — all data stored locally with SQLite, no account needed
- **Pure black dark UI** — Material 3 with black background

## Screenshots

> Coming soon

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.1`
- Android device or emulator (API 21+)

### Run locally

```bash
flutter pub get
flutter run
```

### Build release APK

```bash
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Import Format

### Mutual Funds (Excel)
| Column | Description |
|--------|-------------|
| Scheme Name | Full name of the MF scheme |
| Units | Number of units held |
| Invested Value | Total amount invested |

### Stocks (Excel)
| Column | Description |
|--------|-------------|
| Company Name | Stock name / ticker |
| Quantity | Number of shares |
| Avg Buy Price | Average buy price per share |

## Tech Stack

| Layer | Package |
|-------|---------|
| State management | `provider` |
| Local database | `sqflite` |
| Notifications | `flutter_local_notifications` |
| Background tasks | `workmanager` |
| File import | `file_picker` + `excel` |
| HTTP | `http` |
| Timezone | `timezone` + `flutter_timezone` |

## Releases

See the [Releases](../../releases) page for the latest APK download.

## License

MIT
