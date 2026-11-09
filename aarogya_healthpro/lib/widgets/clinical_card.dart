import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ClinicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Color? leftAccentColor;
  final double leftAccentWidth;
  final List<BoxShadow>? customShadow;
  final double borderRadius;

  const ClinicalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.leftAccentColor,
    this.leftAccentWidth = 3.5,
    this.customShadow,
    this.borderRadius = AppRadii.lg,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.borderHairline,
          width: borderWidth,
        ),
        boxShadow: customShadow ?? AppColors.cardElevation,
      ),
      child: leftAccentColor != null
          ? Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: leftAccentWidth,
                    decoration: BoxDecoration(
                      color: leftAccentColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(borderRadius),
                        bottomLeft: Radius.circular(borderRadius),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: leftAccentWidth > 0 ? 12 : 0),
                  child: child,
                ),
              ],
            )
          : child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: content,
    );
  }
}
