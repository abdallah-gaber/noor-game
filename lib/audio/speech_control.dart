import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';
import 'speech_service.dart';

class SpeechControl extends ConsumerStatefulWidget {
  const SpeechControl({
    super.key,
    required this.text,
    this.showVoiceSetup = false,
  });

  final String text;
  final bool showVoiceSetup;

  @override
  ConsumerState<SpeechControl> createState() => _SpeechControlState();
}

class _SpeechControlState extends ConsumerState<SpeechControl> {
  late final AppLifecycleListener _lifecycle;
  SpeechService? _speaking;
  Object? _request;
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onInactive: _stop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) == false) _cancel();
  }

  @override
  void didUpdateWidget(SpeechControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _cancel();
      _unavailable = false;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _cancel();
    super.dispose();
  }

  void _cancel() {
    final speaking = _speaking;
    _speaking = null;
    _request = null;
    if (speaking != null) unawaited(speaking.stop());
  }

  void _stop() {
    if (mounted && _speaking != null) setState(_cancel);
  }

  Future<void> _toggle() async {
    if (_speaking != null) {
      _stop();
      return;
    }
    final service = ref.read(speechServiceProvider);
    final request = Object();
    setState(() {
      _speaking = service;
      _request = request;
      _unavailable = false;
    });
    final read = await service.read(widget.text);
    if (!mounted || _request != request) return;
    setState(() {
      _speaking = null;
      _request = null;
      _unavailable = !read;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        ref.watch(settingsProvider).asData?.value.preferences.speech ?? false;
    ref.listen(settingsProvider, (previous, next) {
      if (next.asData?.value.preferences.speech != true) _stop();
    });
    final reading = _speaking != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: enabled ? _toggle : null,
          icon: Icon(reading ? Icons.stop_rounded : Icons.volume_up_rounded),
          label: Text(
            reading
                ? 'أوقف القراءة'
                : enabled
                ? 'استمع'
                : 'القراءة متوقّفة',
          ),
        ),
        if (enabled && _unavailable)
          Semantics(
            liveRegion: true,
            child: Text(
              widget.showVoiceSetup
                  ? 'تعذّرت القراءة. افتح إعدادات تحويل النص إلى كلام في الجهاز وثبّت صوتًا عربيًا للاستخدام بلا إنترنت.'
                  : 'الصوت غير متاح. اقرأ النص هنا.',
            ),
          ),
      ],
    );
  }
}
