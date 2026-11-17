<div align="center">

<img src="web/icons/Icon-192.png" alt="Expense Tracker icon" width="96" height="96">

# Expense Tracker

**Know where your money goes, one transaction at a time.**

A personal income, expense, and budget tracker built with Flutter.
Available as an Android app and a home-screen web app on iPhone.

[Try the web app](https://expense-calculator-tracker.netlify.app/) ·
[Getting started](#getting-started) ·
[Deployment](#deployment) ·
[Data and privacy](#data-and-privacy)

**Flutter** · **Riverpod** · **Hive** · **Material 3**

</div>

---

## At a glance

| Feature | What you can do |
| --- | --- |
| Monthly dashboard | See the current month's income, expenses, and balance, plus recent transactions |
| Transactions | Add, edit, delete, search, filter by income/expense, and sort records |
| Budgets | Track spending, remaining amounts, progress, and over-budget states |
| Analytics | Explore daily, weekly, monthly, and all-time summaries with charts and breakdowns |
| Recurring schedules | Manage daily, weekly, monthly, and yearly schedules; pause, resume, and record due occurrences |
| In-app reminders | See active schedules starting two days before they are due, including overdue items |
| Appearance | Choose System, Light, or Dark mode; the preference is saved locally |
| Local storage | Keep transactions, budgets, and schedules on the device or browser |

**Currency:** Indian Rupee (INR). Currency conversion and multi-currency support
are not included.

## How reporting works

### Home

The dashboard totals cover the **current calendar month**:

```text
Monthly balance = monthly income - monthly expenses
```

This is a period's net amount, not a bank-account balance carried forward from
previous months. The recent-transactions list is not restricted to the month.

### Analytics

| Period | Scope |
| --- | --- |
| Today | Transactions dated today |
| Week | The selected Monday-to-Sunday week, with synchronized totals, category pie chart, payment-method breakdown, and daily bars |
| Month | The selected month and year, with monthly totals, breakdowns, and a monthly spending trend |
| All time | Totals and breakdowns across all saved transactions, plus a monthly spending trend |

In **Week** mode:

- The chart uses **Mon, Tue, Wed, Thu, Fri, Sat, Sun** labels and a visible date range.
- Use **Previous week**, **Next week**, or **This week** to navigate.
- Next week is disabled when viewing the current week.
- Empty weeks keep the navigation available.

**The selected transaction date determines the reporting period**, not when you
entered the record. An expense entered today but dated last Wednesday appears in
last Wednesday's totals and bar.

The Transactions tab has its own search, type filter, and sort controls; it does
not automatically follow the Analytics period.

### Recurring payments

Manage schedules under **Settings > Recurring Transactions**. Recording a due
occurrence creates a transaction and advances the schedule. Catch-up records
overdue occurrences.

Home reminders show up to three active schedules due within two days or already
overdue, with a count for additional schedules. Tap the card to manage them.

> These are **in-app reminders**, not phone notifications. The app does not send
> push notifications or automatically make payments.

## Platform status

| Platform | Distribution and testing |
| --- | --- |
| Android | Release APK and AAB builds available locally; earlier release smoke testing passed |
| Web / iPhone home-screen app | Static web build hosted on Netlify; install through Safari's Add to Home Screen |
| Native iOS | Simulator build and launch previously verified; full native regression and signed distribution remain separate |

The latest UI and reporting changes have automated coverage. Recheck the deployed
web app and installed APK after each update; a successful build alone does not
verify device behavior.

The hosted site is deployed manually and may not match the latest source commit.

## Getting started

### Prerequisites

- Git.
- Flutter with Dart compatible with the constraint in [pubspec.yaml](pubspec.yaml).
  The project was developed with **Flutter 3.47.2 / Dart 3.13.2**.
- For web development: a supported browser, such as Chrome.
- For Android: Android SDK, an emulator or device, and a compatible Java toolchain.
- For native iOS: macOS, a complete Xcode installation, an iOS simulator runtime,
  and CocoaPods where required by Flutter's tooling.

### Clone and install dependencies

```bash
git clone https://github.com/joshjackthomson31/expense_tracker.git
cd expense_tracker
flutter doctor -v
flutter pub get
```

### Run in a browser

```bash
flutter run -d chrome
```

### Run on an Android device or iOS simulator

```bash
flutter devices
flutter run -d <device-id>
```

Use the device ID shown on **your machine**. Simulator IDs are not portable
between Macs. iOS simulator testing does not require Apple distribution signing.

> **Android signing on a fresh clone:** the current Gradle configuration expects
> a local release-signing configuration, including `android/key.properties` and
> its referenced keystore. These files are intentionally excluded from Git.
> Obtain them securely from the project owner before running Android Gradle
> builds. Never commit keystores, signing passwords, or other credentials.

## Testing

Run static analysis and the full test suite:

```bash
flutter analyze
flutter test
```

The latest local verification passed **54 tests**. Coverage includes:

- Transaction calculations, form validation, and add/edit flows.
- Backdated expenses and weekday chart placement.
- Monthly Home totals and historical Analytics periods.
- Synchronized weekly summaries, pie charts, and bar charts.
- Week navigation, year boundaries, and daylight-saving transitions.
- Budget updates and recurring transaction behavior.
- Theme switching and Settings information dialogs.
- Narrow-screen layouts, larger text, and keyboard accessibility.

For focused reporting and date checks:

```bash
flutter test test/analytics_screen_test.dart \
  test/weekly_spending_test.dart \
  test/add_transaction_screen_test.dart
```

## Deployment

### Web: Netlify

Build the production bundle:

```bash
flutter build web --release
```

In your existing Netlify site's **Deploys** page, upload the entire
**`build/web/`** folder.

> **Do not upload the source `web/` folder.** It contains the page template and
> icons, but not the compiled app. The uploaded folder must include
> `index.html`, `flutter_bootstrap.js`, `main.dart.js`, `assets/`, and `canvaskit/`.

To use it on an iPhone:

1. Open the deployed HTTPS link in Safari.
2. Choose **Share > Add to Home Screen > Add**.
3. Launch the app from its home-screen icon.
4. Verify transactions, reports, theme selection, and data after closing and reopening.

Rebuild and redeploy to the **same site URL** for updates. Reopen or refresh the
app to load the new version. Do not clear website data as an update step: that
can delete saved records. Offline startup and automatic update behavior should
not be assumed without testing the deployed build.

### Android: APK and App Bundle

With release signing configured locally:

```bash
flutter build apk --release
flutter build appbundle --release
```

| Artifact | Output |
| --- | --- |
| APK: direct installation | `build/app/outputs/flutter-apk/app-release.apk` |
| AAB: store submission | `build/app/outputs/bundle/release/app-release.aab` |

Install the APK as an update on a connected device:

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

If `adb` is not on your PATH, use the executable in your Android SDK's
`platform-tools` directory.

Updates preserve app data only when the installed package and signing
certificate are compatible. Older test installs may use a different package
name. If installation reports a signing or version conflict, **stop rather than
uninstalling** when you need to preserve data.

### Native iOS

Run on an available simulator using `flutter run -d <simulator-id>`.
Native distribution to other users requires an appropriate Apple signing and
distribution setup; it is not the same as the free hosted web app.

## Data and privacy

- Native apps use **Hive local storage**; the web app uses **IndexedDB**.
- Each device/browser has separate data. Android data does not sync to the
  iPhone web app or another installation.
- There is **no cloud sync, account login, or in-app backup/export**.
- Clearing app/browser storage, uninstalling an app, or browser storage eviction
  can remove records. Do not use the app as the only copy of critical financial data.
- A different website origin has a different storage area. Keep the same hosting
  URL if you want to continue accessing existing browser records.
- Static hosting serves app files; the app has no backend for uploading expense
  records. Hosting providers may still process normal web request metadata.
- **Data & Storage**, **About Expense Tracker**, and **Version** in Settings open
  information dialogs; they do not manage, export, or delete data.

## Project structure

```text
lib/
  main.dart        App startup, storage initialization, and themes
  models/          Transactions, budgets, schedules, and reporting types
  providers/       Riverpod state and repository wiring
  repositories/    Storage interfaces and Hive implementations
  screens/         Home, Transactions, Analytics, Budgets, and Settings
  utils/           Calculations, date filters, search, and recurrence helpers
  widgets/         Shared cards, charts, and transaction UI
test/              Unit, widget, and integration-style tests
web/               Source page template, manifest, and web icons
android/           Native Android configuration
ios/               Native iOS configuration
```

## Release notes for maintainers

- Current version: **1.0.0+1**, defined in [pubspec.yaml](pubspec.yaml).
- Android application ID and iOS bundle ID: **`com.jack.expensetracker`**.
- The Settings version label is currently hard-coded; update it alongside the
  package version when preparing a release.
- Build outputs are ignored by Git. Pushing source does **not** deploy Netlify
  or replace APKs shared through Drive.
- Keep signing material outside version control and share it only through a
  secure channel.
- For previous release evidence and pending checks, see
  [Release verification](RELEASE-VERIFICATION.md). Its historical checksums apply
  only to the builds recorded there, not necessarily the latest local artifacts.
