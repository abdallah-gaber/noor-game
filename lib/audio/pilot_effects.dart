import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';
import 'speech_service.dart';

enum PilotEffect { tap, correct, retry, complete }

enum AdventureEffect { pickup, place, splash, wipe, retry, finish, reveal }

final pilotEffectsProvider = Provider<PilotEffects>((ref) {
  final effects = PilotEffects(ref);
  ref.listen(settingsProvider, (before, after) {
    if (before?.asData?.value.preferences.effects == true &&
        after.asData?.value.preferences.effects == false) {
      unawaited(effects._invoke('stopEffects'));
    }
  });
  return effects;
});

class PilotEffects {
  PilotEffects(this._ref);

  final Ref _ref;

  void play(PilotEffect effect) => _play(effect.name);

  void playAdventure(AdventureEffect effect) => _play('wudu_${effect.name}');

  void _play(String name) {
    if (_ref.read(settingsProvider).asData?.value.preferences.effects == true) {
      unawaited(_invoke('effect', name));
    }
  }

  Future<void> _invoke(String method, [String? name]) async {
    try {
      await PlatformSpeech.channel.invokeMethod<void>(method, name);
    } on MissingPluginException {
      // This platform has no effects player.
    } on PlatformException {
      // Audio is optional and must not block play.
    }
  }
}
