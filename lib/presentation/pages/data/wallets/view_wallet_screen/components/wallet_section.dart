import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/utils/number_format.dart';
import 'package:chainly/models/wallet_model.dart';

class WalletSection extends StatelessWidget {
  final Wallet wallet;
  final String? ownerName;

  const WalletSection({
    super.key,
    required this.wallet,
    this.ownerName,
  });


  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: TextStyle(
                fontFamily: AppFonts.clashDisplay,
                fontSize: 38,
                fontWeight: FontWeight.w500
              ),
            ),

            // Nombre + Icono tipo
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.clashDisplay,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 12),
                Icon(
                  wallet.type == 'bank' ? Bootstrap.credit_card : Bootstrap.cash_stack,
                  color: AppColors.black,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Moneda + Monto grande
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formatAmount(wallet.balance),
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.clashDisplay,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  wallet.currency,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.clashDisplay,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}