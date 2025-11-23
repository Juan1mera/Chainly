import 'package:flutter/material.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';

class CircleBottom extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? bgColor;
  final Color? textColor;
  final Widget icon;
  final bool isLoading;

  const CircleBottom({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    required this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = bgColor ?? AppColors.white;
    final Color foregroundColor = textColor ?? AppColors.black;

    return InkWell(
      borderRadius: BorderRadius.circular(40), 
      onTap: isLoading ? null : onPressed,
      child: Opacity(
        opacity: isLoading ? 0.6 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Círculo con el icono
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                // Opcional: sombra suave
              ),
              child: isLoading
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                      ),
                    )
                  : IconTheme(
                      data: IconThemeData(color: foregroundColor.withValues(alpha: 0.7), size: 24),
                      child: icon,
                    ),
            ),
            
            const SizedBox(height: 8), 
            
            // Texto debajo
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: foregroundColor,
                fontFamily: AppFonts.clashDisplay
              ),
            ),
          ],
        ),
      ),
    );
  }
}