import 'package:flutter/material.dart';

class WuduCourtyardFrame extends StatelessWidget {
  const WuduCourtyardFrame({
    super.key,
    required this.title,
    required this.onExit,
    required this.child,
  });

  final String title;
  final VoidCallback onExit;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF184843),
    body: SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'العودة إلى الخريطة',
                    color: Colors.white,
                    onPressed: onExit,
                    icon: const BackButtonIcon(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFF1CB),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
