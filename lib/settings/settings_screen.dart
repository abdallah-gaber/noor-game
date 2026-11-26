import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/noor_layout.dart';
import '../design_system/noor_theme.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    Future<void> update({bool? speech, bool? effects}) async {
      try {
        await ref
            .read(settingsProvider.notifier)
            .savePreferences(speech: speech, effects: effects);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ الإعدادات. حاول مرة أخرى.')),
        );
      }
    }

    return Scaffold(
      appBar: const NoorAppBar('الإعدادات'),
      body: NoorPage(
        maxWidth: 560,
        child: settings.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(
            child: CircularProgressIndicator(semanticsLabel: 'جارٍ التحميل'),
          ),
          error: (error, stackTrace) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تعذّر فتح الإعدادات.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(settingsProvider),
                child: const Text('حاول مرة أخرى'),
              ),
            ],
          ),
          data: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الصوت',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text('تحتاج القراءة إلى صوت عربي متاح دون إنترنت.'),
              const SizedBox(height: 18),
              Material(
                color: paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('القراءة الصوتية'),
                        value: state.preferences.speech,
                        onChanged: state.saving
                            ? null
                            : (value) => update(speech: value),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                      const Divider(indent: 20, endIndent: 20, height: 1),
                      SwitchListTile(
                        title: const Text('المؤثّرات الصوتية'),
                        subtitle: const Text('للمراحل القادمة'),
                        value: state.preferences.effects,
                        onChanged: state.saving
                            ? null
                            : (value) => update(effects: value),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
