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
    final photo = cow.photoUrl ?? cow.photoData;
    ImageProvider? image;

    if (photo != null && photo.trim().isNotEmpty) {
      final trimmed = photo.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        image = NetworkImage(trimmed);
      } else if (trimmed.length < 500000) {
        try {
          final cleanBase64 = trimmed
              .replaceFirst(RegExp(r'^data:image\/[a-zA-Z0-9]+;base64,'), '')
              .replaceAll(RegExp(r'\s+'), '');
          image = MemoryImage(base64Decode(cleanBase64));
        } catch (_) {
          image = null;
        }
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
