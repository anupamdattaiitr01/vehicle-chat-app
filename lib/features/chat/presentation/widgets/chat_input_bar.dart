import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isConnected;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback? onToggleQuickReplies;
  final bool showQuickReplies;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.onChanged,
    required this.onSend,
    this.onToggleQuickReplies,
    this.showQuickReplies = true,
  });

  @override
  Widget build(BuildContext context) {
    final milo = context.milo;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      color: milo.scaffoldBackground,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: milo.inputFill,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: milo.cardBorder),
                ),
                child: Row(
                  children: [
                    if (onToggleQuickReplies != null)
                      IconButton(
                        onPressed: onToggleQuickReplies,
                        icon: Icon(
                          showQuickReplies
                              ? Icons.close_rounded
                              : Icons.add_rounded,
                          color: milo.textSecondary,
                          size: 22,
                        ),
                        tooltip: 'Quick replies',
                      ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        onSubmitted: (_) => onSend(),
                        style: TextStyle(
                          color: milo.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: milo.textSecondary,
                            fontSize: 14,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isConnected
                      ? milo.burgundy
                      : milo.burgundy.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: milo.burgundy.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}