import 'package:flutter/material.dart';

import '../models/ai_models.dart';

const _forest = Color(0xFF2F6B45);
const _leaf = Color(0xFFE7F1E5);
const _ink = Color(0xFF243127);
const _muted = Color(0xFF6B756D);

class AiChatBubble extends StatelessWidget {
  const AiChatBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? _forest : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E9DF)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : _ink,
            height: 1.45,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class AiTypingIndicator extends StatelessWidget {
  const AiTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: _leaf,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 8,
          height: 8,
          child: CircularProgressIndicator(strokeWidth: 2, color: _forest),
        ),
        SizedBox(width: 10),
        Text('सोच रहा हूं...', style: TextStyle(color: _muted)),
      ],
    ),
  );
}
