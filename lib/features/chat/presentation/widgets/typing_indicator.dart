import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final String managerName;

  const TypingIndicator({super.key, required this.managerName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$managerName is typing...',
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}