import 'package:flutter/material.dart';

import '../branding/brand_config.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 48, this.showName = false, super.key});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: BrandConfig.leaf,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          BrandConfig.logoAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.pets_rounded, color: BrandConfig.primary),
        ),
      ),
    );
    if (!showName) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                BrandConfig.hindiCommitteeName,
                style: const TextStyle(
                  color: BrandConfig.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                BrandConfig.committeeName,
                style: const TextStyle(color: BrandConfig.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
