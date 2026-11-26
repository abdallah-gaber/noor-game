import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../content/curriculum.dart';
import '../design_system/noor_layout.dart';
import '../design_system/noor_theme.dart';
import '../worlds/world_art.dart';
import 'noor_lantern.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.showPreview});

  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width -
        MediaQuery.paddingOf(context).horizontal;
    final columns = NoorWidth.of(width) == NoorWidth.compact ? 1 : 2;
    return Scaffold(
      appBar: NoorAppBar(
        'نور',
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            style: IconButton.styleFrom(minimumSize: const Size.square(48)),
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: NoorPage(
        maxWidth: 1060,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _WelcomePanel(),
            const SizedBox(height: 22),
            Semantics(
              header: true,
              child: Text(
                'اختر عالمًا',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 14.0;
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * gap) / columns;
                return Wrap(
                  key: ValueKey('world-columns-$columns'),
                  runSpacing: gap,
                  spacing: gap,
                  children: [
                    for (final world in WorldId.values)
                      SizedBox(width: cardWidth, child: _WorldTile(world)),
                  ],
                );
              },
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
        ),
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final lantern = Center(
      child: SizedBox.square(dimension: 120, child: NoorLantern(happy: _happy)),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF174A41),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(22, 16, 14, 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'أهلًا! أنا نور',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFF6D9),
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _greet,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFDB8A),
                      foregroundColor: ink,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'أهلًا يا نور!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: reduceMotion
                  ? lantern
                  : AnimatedBuilder(
                      animation: _motion,
                      child: lantern,
                      builder: (context, child) {
                        final phase = _motion.value;
                        return Transform.translate(
                          offset: Offset(0, -phase * (1 - phase) * 24),
                          child: child,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldTile extends StatelessWidget {
  const _WorldTile(this.world);

  final WorldId world;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: world.wash,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/worlds/${world.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 112, child: WorldArt(world)),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        world.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: world.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
                      color: world.ink,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
