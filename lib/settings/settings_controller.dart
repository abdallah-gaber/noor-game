import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/noor_database.dart';
import 'settings_store.dart';

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SqliteSettingsStore(ref.watch(noorDatabaseProvider)),
);

typedef SettingsState = ({AudioPreferences preferences, bool saving});

final settingsProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
      SettingsController.new,
      retry: (count, error) => null,
    );

class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final preferences = await ref.watch(settingsStoreProvider).load();
    return (preferences: preferences, saving: false);
  }

  Future<void> savePreferences({bool? speech, bool? effects}) async {
    final current = state.requireValue;
    if (current.saving) return;

    final next = AudioPreferences(
      speech: speech ?? current.preferences.speech,
      effects: effects ?? current.preferences.effects,
    );
    state = AsyncData((preferences: current.preferences, saving: true));
    try {
      await ref.read(settingsStoreProvider).save(next);
      state = AsyncData((preferences: next, saving: false));
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
