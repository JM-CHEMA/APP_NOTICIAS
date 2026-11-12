import 'package:flutter/material.dart';

import '../app_theme.dart';

class NexoLogo extends StatelessWidget {
  const NexoLogo({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
          ),
        ),
      ),
      const SizedBox(width: 9),
      const Text(
        'Noticias',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          fontSize: 18,
        ),
      ),
    ],
  );
}
