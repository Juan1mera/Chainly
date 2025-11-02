import 'dart:ui';
import 'package:flutter/material.dart';

class BlurGradientContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxShape shape;

  const BlurGradientContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding = const EdgeInsets.all(0),
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: child,
      ),
    );

    if (shape == BoxShape.circle) {
      return ClipOval(child: content);
    } else {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: content,
      );
    }
  }
}