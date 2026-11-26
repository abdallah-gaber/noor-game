import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final speechServiceProvider = Provider<SpeechService>(
  (ref) => const PlatformSpeech(),
);

abstract interface class SpeechService {
  Future<bool> read(String text);
  Future<void> stop();
}

class PlatformSpeech implements SpeechService {
  const PlatformSpeech();

  static const channel = MethodChannel('dev.noor.noor/speech');

  @override
  Future<bool> read(String text) async {
    try {
      return await channel
              .invokeMethod<bool>('read', text)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  unawaited(stop());
                  return false;
                },
              ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // The platform has no engine to stop.
    } on PlatformException {
      // The native engine may already have closed.
    }
  }
}
