import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'glass_colors.dart';

/// Adaptive Glassmorphism Surface:
/// - iOS / macOS: High-end frosted glass with BackdropFilter.
/// - Android: GPU-efficient translucent container WITHOUT blur shader to guarantee 60/120fps.
class PlatformGlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final double blurSigma;
  final Color? fillColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const PlatformGlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blurSigma = 18.0,
    this.fillColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    final effectiveBorderColor = borderColor ?? GlassColors.glassBorder;
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    final effectiveFill = fillColor ??
        (isAndroid
            ? const Color(0xFF13151F).withValues(alpha: 0.92)
            : const Color(0xFF13151F).withValues(alpha: 0.65));

    final decoration = BoxDecoration(
      color: effectiveFill,
      borderRadius: radius,
      border: Border.all(color: effectiveBorderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );

    // ANDROID OPTIMIZATION: Bypasses expensive BackdropFilter to prevent GPU fillrate stalls
    if (isAndroid) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      );
    }

    // iOS / DESKTOP / WEB: Native Frosted Glass
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: decoration,
            child: Material(
              type: MaterialType.transparency,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
