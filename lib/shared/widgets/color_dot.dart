import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// A circular color swatch that renders a rainbow sweep gradient for
/// [AppColor.isMulti] items and a solid fill for everything else.
class ColorDot extends StatelessWidget {
  final AppColor appColor;
  final double size;

  const ColorDot({super.key, required this.appColor, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: appColor.isMulti
            ? const SweepGradient(
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
              )
            : null,
        color: appColor.isMulti ? null : appColor.value,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
    );
  }
}
