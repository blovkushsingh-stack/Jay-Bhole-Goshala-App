import 'package:flutter/material.dart';

import '../models/ai_models.dart';

const _forest = Color(0xFF2F6B45);
const _ink = Color(0xFF243127);

class AiTaskCard extends StatelessWidget {
  const AiTaskCard({required this.task, required this.onChanged, super.key});

  final AiTask task;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final priorityColor = task.priority == 'जरूरी'
        ? const Color(0xFFC8563A)
        : task.priority == 'उच्च'
        ? const Color(0xFFE58B3A)
        : _forest;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: CheckboxListTile(
        value: task.completed,
        onChanged: onChanged,
        activeColor: _forest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        title: Text(
          task.name,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${task.time}  ·  ${task.priority}',
          style: TextStyle(color: priorityColor, fontSize: 12),
        ),
      ),
    );
  }
}
