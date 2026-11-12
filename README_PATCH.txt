Expense Tracker targeted patch

This archive contains only changed/new files. From inside your existing expense_tracker folder, extract it so the relative paths overwrite/add files in the project. Example:

  unzip -o /path/to/expense_tracker_patch.zip -d .
  flutter pub get
  dart format lib test
  flutter analyze
  flutter test

New recurring schedules are stored in a dedicated Hive box. A schedule does not count as income/expense until it is due and the user presses Record payment. Occurrence IDs are deterministic to help prevent duplicate recording if an earlier save partially succeeded.

Release note: android/app/build.gradle.kts still signs release builds with the debug key. That is acceptable for a local test APK, but not for publishing to Google Play; configure a private release keystore before publishing. Keep signing credentials out of source control and do not share them in chat.
