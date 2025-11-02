import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wallet_app/core/constants/colors.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onPress;
  final IconData? iconOnPress; // IconData or null for default

  const CustomHeader({
    super.key,
    required this.title,
    this.onPress,
    this.iconOnPress,
  });

  @override
  Widget build(BuildContext context) {
    // final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.fondoSecundario,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  iconOnPress ?? Icons.info_outline, // Usar directamente el IconData
                  size: 30,
                  color: AppColors.fondoPrincipal,
                ),
                onPressed: onPress,
              ),
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Chillax',
                    color: AppColors.fondoPrincipal,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                  textAlign: TextAlign.center,
                ),
              SvgPicture.asset(
                'assets/Icon.svg',
                height: 50,
                width: 50,
                colorFilter: const ColorFilter.mode(
                  AppColors.fondoPrincipal,
                  BlendMode.srcIn,
                ),
                placeholderBuilder: (context) => const CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    return const Size.fromHeight(104);
  }
}