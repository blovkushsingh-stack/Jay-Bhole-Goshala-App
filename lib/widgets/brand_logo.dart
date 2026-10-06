import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      child: SvgPicture.asset(BrandConfig.logoAsset),
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
