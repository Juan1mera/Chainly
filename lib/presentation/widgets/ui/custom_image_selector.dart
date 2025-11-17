import 'dart:io';
import 'package:wallet_app/presentation/widgets/common/dashed_border.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:flutter/material.dart';

class CustomImageSelector extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onSelectImage;
  final VoidCallback? onRemoveImage;
  final double size;
  final Color? accentColor;
  final String placeholderText;
  final IconData placeholderIcon;

  const CustomImageSelector({
    super.key,
    required this.imagePath,
    required this.onSelectImage,
    this.onRemoveImage,
    this.size = 200,
    this.accentColor,
    this.placeholderText = 'Agrega una foto',
    this.placeholderIcon = Icons.camera_alt,
  });

  Widget _buildImagePlaceholder() {
    final color = accentColor ?? AppColors.purple;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.6),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(Icons.pets, size: 60, color: AppColors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.purple;
    final hasImage = imagePath != null && File(imagePath!).existsSync();

    return SizedBox(
      height: size,
      width: size,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.red.withValues(alpha: 0.5),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 16, color: Colors.white),
                          onPressed: onRemoveImage,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                onTap: onSelectImage,
                child: DashedBorderContainer(
                  height: size,
                  width: size,
                  color: color,
                  dashWidth: 8,
                  gapWidth: 4,
                  borderRadius: 12,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        placeholderIcon,
                        size: 48,
                        color: color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        placeholderText,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}