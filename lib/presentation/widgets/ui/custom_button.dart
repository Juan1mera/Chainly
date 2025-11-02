import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? bgColor;
  final Color? textColor;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.leftIcon,
    this.rightIcon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color finalTextColor = textColor ?? AppColors.fondoSecundario;
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor ?? AppColors.verdeLight,
        foregroundColor: textColor ?? AppColors.verdeLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
        disabledBackgroundColor: (bgColor ?? AppColors.verdeLight).withValues(alpha: 0.6),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(finalTextColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leftIcon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: finalTextColor),
                    child: leftIcon!,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: finalTextColor,
                  ),
                ),
                if (rightIcon != null) ...[
                  const SizedBox(width: 8),
                  IconTheme(
                    data: IconThemeData(color: finalTextColor),
                    child: rightIcon!,
                  ),
                ],
              ],
            ),
    );
  }
}