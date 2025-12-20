import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/data/models/category_model.dart';
import 'package:chainly/data/models/wallet_model.dart';
import 'package:chainly/data/models/transaction_with_details.dart';
import 'package:chainly/presentation/pages/main/home_screen/components/transactions_home_section.dart';
import 'package:chainly/presentation/pages/main/home_screen/components/wallets_home_section.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';
import 'package:chainly/domain/providers/category_provider.dart';
import 'package:chainly/domain/providers/transaction_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch providers
    final walletsAsync = ref.watch(walletsProvider(const WalletFilters(includeArchived: false)));
    final categoriesAsync = ref.watch(categoriesProvider);
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletsProvider);
        ref.invalidate(categoriesProvider);
        ref.invalidate(recentTransactionsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
        children: [
          const SizedBox(height: 80),

          const Text(
            'Your Cards',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            'Cards information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),

          walletsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (wallets) => WalletsHomeSection(wallets: wallets),
          ),

          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'Latest account activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              Icon(Bootstrap.arrow_up_right, size: 35, color: AppColors.black),
            ],
          ),
          const SizedBox(height: 12),

          categoriesAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Center(child: Text('Error categories: $err')),
            data: (categories) {
              return recentTransactionsAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Center(child: Text('Error transactions: $err')),
                data: (transactions) {
                  return walletsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (wallets) {
                      // Map to TransactionWithDetails
                      final transactionsWithDetails = transactions.map((t) {
                        final wallet = wallets.firstWhere(
                          (w) => w.id == t.walletId,
                          orElse: () => Wallet(
                            id: 'unknown',
                            name: 'Unknown',
                            currency: '???',
                            userId: 'user',
                            color: '#000000',
                            type: 'cash',
                            balance: 0.0,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                           ),
                        );
                        
                        final category = categories.firstWhere(
                          (c) => c.id == t.categoryId,
                          orElse: () => Category(
                             id: 'unknown',
                             name: 'Unknown',
                             userId: 'user',
                             type: t.type,
                             createdAt: DateTime.now(),
                             updatedAt: DateTime.now(),
                          ),
                        );

                        return TransactionWithDetails(
                          transaction: t,
                          wallet: wallet,
                          category: category,
                        );
                      }).toList();

                      return TransactionsHomeSection(
                        transactions: transactionsWithDetails.take(5).toList(),
                        categories: categories,
                        onViewAllPressed: () {
                           // Navigate to all transactions if implemented
                        },
                      );
                    }
                  );
                },
              );
            },
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
