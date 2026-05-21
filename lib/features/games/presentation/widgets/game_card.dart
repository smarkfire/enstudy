import 'package:flutter/material.dart';

class GameCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;

  const GameCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = 12,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: elevation,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: padding!,
          child: child,
        ),
      ),
    );
  }
}
