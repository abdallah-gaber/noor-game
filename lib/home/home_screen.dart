import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/noor_layout.dart';
import '../design_system/noor_theme.dart';
import 'noor_lantern.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.showPreview});

  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NoorAppBar('نور'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = MediaQuery.paddingOf(context);
          final width = NoorWidth.of(constraints.maxWidth - insets.horizontal);
          final settings = _HomeActions(showPreview: showPreview);

          return NoorPage(
            maxWidth: width == NoorWidth.expanded ? 1040 : 620,
            child: width == NoorWidth.expanded
                ? Row(
                    key: const ValueKey(NoorWidth.expanded),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 3, child: _WelcomePanel()),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: settings),
                    ],
                  )
                : Column(
                    key: ValueKey(width),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _WelcomePanel(),
                      const SizedBox(height: 16),
                      settings,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _WelcomePanel extends StatefulWidget {
  const _WelcomePanel();

  @override
  State<_WelcomePanel> createState() => _WelcomePanelState();
}

class _WelcomePanelState extends State<_WelcomePanel>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  bool _happy = false;

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _greet() {
    setState(() => _happy = true);
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.reset();
    } else {
      _motion.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final lantern = NoorLantern(happy: _happy);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            reduceMotion
                ? lantern
                : AnimatedBuilder(
                    animation: _motion,
                    child: lantern,
                    builder: (context, child) {
                      final phase = _motion.value;
                      final lift = phase * (1 - phase) * 24;
                      return Transform.translate(
                        offset: Offset(0, -lift),
                        child: child,
                      );
                    },
                  ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                'أهلًا! أنا نور',
                textAlign: TextAlign.center,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _greet, child: const Text('أهلًا يا نور!')),
          ],
        ),
      ),
    );
  }
}

class _HomeActions extends StatelessWidget {
  const _HomeActions({required this.showPreview});

  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: outline),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsetsDirectional.fromSTEB(18, 8, 16, 8),
            leading: const CircleAvatar(
              backgroundColor: sage,
              foregroundColor: ink,
              child: Icon(Icons.tune_rounded),
            ),
            title: const Text(
              'الإعدادات',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
            onTap: () => context.push('/settings'),
          ),
        ),
        if (showPreview)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => context.push('/preview'),
              child: const Text('معاينة المطوّر'),
            ),
          ),
      ],
    );
  }
}
