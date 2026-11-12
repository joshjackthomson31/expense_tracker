# expense_tracker
<<<<<<< HEAD

A new Flutter project.

## Home layout

The Home add action keeps its button styling in a reserved footer above the
main navigation. The dashboard scrolls separately so the button cannot cover
the empty state or recent transactions. On shorter screens, scroll to view the
complete empty-state card.

## Transaction form layout

Category and payment-method dropdowns fit the available field width, including
320px screens. Narrow-screen regression tests cover income/expense add and edit,
prefilled values, validation, and reaching Save with keyboard insets:

```sh
flutter test test/add_transaction_screen_test.dart test/widget_test.dart
```

## Analytics

The Analytics screen supports Today, Week, and Month, with month/year selection
in Month mode. Summary cards stack on narrow screens or with larger text.
Bar charts can scroll horizontally on narrow screens to keep their labels readable;
the category chart scales to the available width. Empty periods display a message
while keeping the reporting-period controls available.

Run the Analytics layout and period-selection tests with:

```sh
flutter test test/analytics_screen_test.dart
```

## Recurring schedules and Settings

Recurring schedules are managed from Settings > Recurring Transactions, separately
from the one-time transaction form. The schedule editor groups frequency, anchor
date, and due-date previews together. Previews use the existing recurrence helper;
they do not record transactions or advance a schedule. Pause/resume, recording,
catch-up, editing, and deletion retain their existing behavior.

Settings displays the fixed INR preference, local-storage information, and app
information. Its version label is currently `1.0.0 (build 1)`; keep it aligned with
`pubspec.yaml` when preparing a new release. No theme or currency controls were
added.

Run the recurring and Settings presentation tests with:

```sh
flutter test test/recurring_ui_test.dart
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
This is an app to track our daily expenses.
>>>>>>> origin/main
