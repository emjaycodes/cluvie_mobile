import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

/// Logo mark (gold tile, speech bubble + reel dots) with optional wordmark.
class ClLogo extends StatelessWidget {
  const ClLogo({super.key, this.size = 28, this.wordmark = true});

  final double size;
  final bool wordmark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cluvie',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset('assets/images/cluvie_mark.svg', width: size, height: size),
        if (wordmark) ...[
          SizedBox(width: size * 0.3),
          Text(
            'CLUVIE',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: size * 0.6,
            ),
          ),
        ],
      ]),
    );
  }
}
