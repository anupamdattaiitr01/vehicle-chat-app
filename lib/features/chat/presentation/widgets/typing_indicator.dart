import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TypingIndicator extends StatelessWidget {
  final String managerName;

  const TypingIndicator({super.key, required this.managerName});

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: milo.incomingBubble,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: milo.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: milo.onlineGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$managerName is typing...',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: milo.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}