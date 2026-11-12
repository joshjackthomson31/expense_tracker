# Expense Tracker release verification

Recorded: 2026-10-30. App version: 1.0.0+1.

## Toolchain

- Flutter 3.47.2 stable, framework revision d3b14c8769.
- Dart 3.13.2.
- Xcode 27.1, build 27A9275 (previous diagnostic).

## Android artifacts

Artifacts built on 2026-10-30 include the Home footer and narrow-form dropdown fixes.

| Artifact | Location | Size (bytes) | SHA-256 |
|---|---|---:|---|
| APK | `build/app/outputs/flutter-apk/app-release.apk` | 53482802 | `a4bf60da2115872d41144118b3383287bcbb9549edb3a35682532212354ee9ba` |
| AAB | `build/app/outputs/bundle/release/app-release.aab` | 51901460 | `66a35a0accd5dd45aaec2338eba9927dd2148d098d1b9123fc8b3d45e74e8b18` |

Recompute these hashes after any rebuild.

## Verified results

- Latest automated run: Flutter analysis clean; all 38 tests passed.
- Release APK and AAB builds succeeded.
- Earlier Android release regression covered transaction add/edit/delete,
  budget integration, analytics, recurring create/pause/resume/record/delete,
  Settings navigation, and force-stop/relaunch persistence.
- Latest APK installed successfully using `adb -s emulator-5554 install -r`.
  No uninstall, storage clearing, or simulator reset was used.
- Latest Android smoke test: Home footer visually inspected; Add and Edit forms
  opened, Entertainment category selected, temporary expense saved at INR 10
  and edited to INR 20. Temporary expense subsequently deleted.
- Original test records survived both the APK update and a full process restart:
  INR 5,000 income, INR 250 expense, INR 4,750 balance; Food budget INR 4,000,
  spent INR 250, remaining INR 3,750.
- 320px form behavior is covered by widget tests; the Android smoke test used
  the emulator's existing screen size, not a forced 320px configuration.

## iOS: pending final interactive regression

Existing iPhone 17 device: `FA3B1D73-2B7A-4F73-ABEB-EEC7999E0002`.
Do not erase the device or uninstall the app between persistence checks.

Build/launch and Home footer screenshot inspection passed previously. These
results do not establish interactive correctness or saved-data persistence.

| Check | Expected verification | Status |
|---|---|---|
| Home | No overlapping controls; content scrolls clear of footer | Screenshot verified; scrolling pending |
| Transactions | Add, edit, delete; verify totals | Pending |
| Budgets | Spent and remaining follow transaction changes | Pending |
| Analytics | Totals, categories, charts, reporting periods | Pending |
| Recurring | Create, pause, resume, record, delete; no duplicate occurrence | Pending |
| Settings | Open existing destination and navigate back | Pending |
| Persistence | Create records, terminate and relaunch without reinstall; verify records | Pending |
| Layout/keyboard | No overflow; fields and Save reachable with keyboard open | Pending |

## Limitations and signing

- Graphical Simulator application was not found in the selected Xcode installation.
  CLI tools/runtimes work; organization-approved installation repair is pending.
  No Xcode repair, runtime reinstall, or environment reconfiguration was performed.
- iOS interactive regression and persistence remain open until actually exercised.
- iOS signed distribution has not been attempted and is deferred until an
  authorized Apple Developer Team is available. Simulator testing does not
  require distribution signing.
- Existing Settings version text is maintained manually and must stay aligned
  with the Flutter version for future releases.
- Earlier Android builds emitted non-blocking Java native-access/SDK XML warnings.

## Remaining milestones

1. IT restores the graphical Simulator.
2. Complete the iOS checklist on the existing device, retaining app data.
3. Update this record with actual outcomes; do not infer passes from launches.
4. Handle signed iOS distribution separately when authorized.
