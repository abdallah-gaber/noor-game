# ADR 001 — Local settings and progress storage

Accepted for SPEC-001. Use sqflite on Android and iOS. It uses the platform SQLite library and runs I/O off the UI thread. SQLite provides atomic writes and schema versioning. Shared preferences fit toggles but document weaker durability and would introduce another store once learning progress needs transactions. [sqflite](https://pub.dev/packages/sqflite) · [shared_preferences](https://pub.dev/packages/shared_preferences)

Schema 1 stores two Boolean preferences in one app-private, single-profile row. Each update writes both values atomically. Riverpod exposes load state and settings writes; the UI waits for the commit before presenting a new value. Keep future progress in dedicated tables keyed by stable IDs. Add an explicit upgrade for each future schema version. Disable Android app backup for the local-only pilot and review the iOS backup policy before storing child progress. The foundation stores only the two toggles.
