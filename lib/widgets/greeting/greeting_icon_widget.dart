import 'package:flutter/material.dart';
import '../../core/utils/greeting_helper.dart';

/// Widget hiển thị icon greeting động theo buổi sáng/chiều/tối
class GreetingIconWidget extends StatelessWidget {
  final double? size;

  const GreetingIconWidget({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final iconData = GreetingHelper.getTimeIcon();

    return Icon(
      iconData['icon'] as IconData,
      color: iconData['color'] as Color,
      size: size,
    );
  }
}
