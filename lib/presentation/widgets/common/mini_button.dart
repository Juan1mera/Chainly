import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';

class MiniButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Icon? leftIcon;

  const MiniButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.leftIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: AppColors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(90, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leftIcon != null) ...[
            leftIcon!,
          ],
          Text(
            text,
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }
}