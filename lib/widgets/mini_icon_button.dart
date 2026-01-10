import 'package:flutter/material.dart';

class MiniIconButton extends StatelessWidget {
  const MiniIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.padding = const EdgeInsets.all(6),
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    const double iconSize = 22;
    const double splashRadius = 22;
    return IconButton(
      iconSize: iconSize,
      padding: padding,
      constraints: const BoxConstraints(),
      splashRadius: splashRadius,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
    );
  }
}
