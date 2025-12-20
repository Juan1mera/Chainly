import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/data/models/wallet_model.dart';
import 'package:chainly/presentation/pages/data/transactions/create_transaction_screen/create_transaction_screen.dart';
import 'package:chainly/presentation/pages/data/transactions/create_transaction_convert_screen/create_transaction_convert_screen.dart';
import 'package:chainly/presentation/widgets/common/circle_bottom.dart';

class WalletOptionsSection extends ConsumerWidget {
  final Wallet wallet;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onRefreshNeeded;

  const WalletOptionsSection({
    super.key,
    required this.wallet,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onRefreshNeeded,
  });

  void _goToCreateTransaction(BuildContext context, {required String type}) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CreateTransactionScreen(
          initialWalletId: wallet.id,
          initialType: type,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    if (result == true && context.mounted) {
      onRefreshNeeded();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> filterLabels = {
      'all': 'All',
      'income': 'Incomes',
      'expense': 'Expenses',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CircleBottom(
              text: 'Income',
              icon: const Icon(Bootstrap.arrow_down_left, size: 28),
              onPressed: () => _goToCreateTransaction(context, type: 'income'),
            ),
            CircleBottom(
              text: 'Expense',
              icon: const Icon(Bootstrap.arrow_up_right, size: 28),
              onPressed: () => _goToCreateTransaction(context, type: 'expense'),
            ),
            CircleBottom(
              text: 'Convert',
              icon: const Icon(Bootstrap.shuffle, size: 28),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => CreateTransactionConvertScreen(
                      initialFromWallet: wallet,
                    ),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                );

                if (result == true && context.mounted) {
                  onRefreshNeeded();
                }
              },
            ),
            CircleBottom(
              text: filterLabels[currentFilter] ?? 'Filtro',
              icon: const Icon(Icons.tune_rounded, size: 28),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _FilterBottomSheet(
                    currentFilter: currentFilter,
                    onSelected: (value) {
                      onFilterChanged(value);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final String currentFilter;
  final Function(String) onSelected;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filtrar transacciones',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOption('all', 'Todas las transacciones'),
          _buildOption('income', 'Solo ingresos'),
          _buildOption('expense', 'Solo gastos'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildOption(String value, String label) {
    final bool isSelected = currentFilter == value;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? AppColors.black : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => onSelected(value),
    );
  }
}