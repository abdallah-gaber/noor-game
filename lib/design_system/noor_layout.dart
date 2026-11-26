import 'package:flutter/material.dart';

enum NoorWidth {
  compact,
  medium,
  expanded;

  static NoorWidth of(double width) => switch (width) {
    < 600 => compact,
    < 840 => medium,
    _ => expanded,
  };

  double get gutter => switch (this) {
    compact => 20,
    medium => 32,
    expanded => 40,
  };
}

class NoorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoorAppBar(this.title, {super.key});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class NoorPage extends StatelessWidget {
  const NoorPage({super.key, required this.child, this.maxWidth = 1120});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = NoorWidth.of(constraints.maxWidth).gutter;
          return SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(gutter, 16, gutter, 32),
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SizedBox(width: double.infinity, child: child),
              ),
            ),
          );
        },
      ),
    );
  }
}
