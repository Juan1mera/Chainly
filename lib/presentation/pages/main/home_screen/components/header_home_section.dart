import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/constants/fonts.dart';

class HeaderHomeSection extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onPress;
  final IconData? iconOnPress; // IconData or null for default

  const HeaderHomeSection({
    super.key,
    required this.title,
    this.onPress,
    this.iconOnPress, required List<IconButton> actions,
  });

  @override
  Widget build(BuildContext context) {
    // final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return SizedBox(
      width: double.infinity,
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
                  iconOnPress ?? Icons.info_outline, 
                  size: 30,
                  color: AppColors.black,
                ),
                onPressed: onPress,
              ),
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.clashDisplay,
                    color: AppColors.black,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                  textAlign: TextAlign.center,
                ),
              SvgPicture.asset(
                'assets/Icon.svg',
                height: 50,
                width: 50,
                colorFilter: const ColorFilter.mode(
                  AppColors.black,
                  BlendMode.srcIn,
                ),
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