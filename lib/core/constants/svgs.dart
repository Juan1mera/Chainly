import 'package:chainly/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgs {

  static Widget chainlyLabelSvg({
    double? width = 150,
    double? height = 90,
    Color? color = AppColors.black,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        'assets/chainly_label.svg',
        fit: BoxFit.contain,
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,  
      ),
    );
  }

  static Widget chainlyLogoSvg({
    double? width = 100,
    double? height = 100,
    Color? color = AppColors.black,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        'assets/chainly_logo.svg',
        fit: BoxFit.contain,
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
      ),
    );
  }
}