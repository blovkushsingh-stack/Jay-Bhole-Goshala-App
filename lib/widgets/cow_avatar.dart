import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/cow_record.dart';

const _forest = Color(0xFF2F6B45);
const _leaf = Color(0xFFE7F1E5);

class CowAvatar extends StatelessWidget {
  const CowAvatar({required this.cow, required this.size, super.key});

  final CowRecord cow;
  final double size;

  @override
  Widget build(BuildContext context) {
    final data = cow.photoData;
    MemoryImage? image;

    if (data != null && data.trim().isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(data));
      } catch (_) {
        image = null;
      }
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _leaf,
      backgroundImage: image,
      child: image == null
          ? const Icon(Icons.pets_rounded, color: _forest)
          : null,
    );
  }
}
