import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
      decoration: BoxDecoration(
        color: milo.badgeAmberBg,
        border: Border(
          bottom: BorderSide(
            color: milo.badgeAmberText.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: milo.badgeAmberText,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Connection lost — Reconnecting...',
            style: TextStyle(
              color: milo.badgeAmberText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}