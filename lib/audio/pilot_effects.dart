import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';
import 'speech_service.dart';

enum PilotEffect { tap, correct, retry, complete }

final pilotEffectsProvider = Provider<PilotEffects>((ref) => PilotEffects(ref));

class PilotEffects {
  PilotEffects(this._ref);

  final Ref _ref;

  void play(PilotEffect effect) {
    if (_ref.read(settingsProvider).asData?.value.preferences.effects != true) {
      return;
    }
    unawaited(_play(effect));
  }

  Future<void> _play(PilotEffect effect) async {
    try {
      await PlatformSpeech.channel.invokeMethod<void>('effect', effect.name);
    } on MissingPluginException {
      // The pilot effect backend is Android-only.
    } on PlatformException {
      // Audio is optional and must not block play.
    }
  }
}
