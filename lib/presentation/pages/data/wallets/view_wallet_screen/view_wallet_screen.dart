import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/data/models/wallet_model.dart';
import 'package:chainly/presentation/pages/data/wallets/view_wallet_screen/components/transaction_list_section.dart';
import 'package:chainly/presentation/pages/data/wallets/view_wallet_screen/components/wallet_options_section.dart';
import 'package:chainly/presentation/pages/data/wallets/view_wallet_screen/components/wallet_section.dart';
import 'package:chainly/presentation/widgets/ui/custom_header.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';
import 'package:chainly/domain/providers/transaction_provider.dart';
import 'package:chainly/domain/providers/category_provider.dart';

class ViewWalletScreen extends ConsumerStatefulWidget {
  final String walletId;
  const ViewWalletScreen({super.key, required this.walletId});

  @override
  ConsumerState<ViewWalletScreen> createState() => _ViewWalletScreenState();
}

class _ViewWalletScreenState extends ConsumerState<ViewWalletScreen> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final walletAsync = ref.watch(walletByIdProvider(widget.walletId));
    final transactionsAsync = ref.watch(transactionsByWalletProvider(widget.walletId));
    final categoriesAsync = ref.watch(categoriesProvider);

    // Combine loading/error states if needed, or handle individually in UI
    // Here we mainly depend on wallet being available
    
    return walletAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (wallet) {
        if (wallet == null) {
          return const Scaffold(
            body: Center(child: Text('Cartera no encontrada')),
          );
        }

        final menuItems = <PopupMenuEntry<dynamic>>[
          PopupMenuItem(
            onTap: () => _toggleArchive(wallet),
            child: Row(
              children: [
                Icon(wallet.isArchived ? Icons.unarchive : Icons.archive),
                const SizedBox(width: 12),
                Text(wallet.isArchived ? 'Desarchivar' : 'Archivar'),
              ],
            ),
          ),
          PopupMenuItem(
            onTap: () => _toggleFavorite(wallet),
            child: Row(
              children: [
                Icon(
                  wallet.isFavorite ? Icons.star : Icons.star_border,
                  color: wallet.isFavorite ? AppColors.yellow : null,
                ),
                const SizedBox(width: 12),
                Text(
                  wallet.isFavorite
                      ? 'Quitar de favoritos'
                      : 'Añadir a favoritos',
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            onTap: () => _deleteWallet(wallet),
            child: const Row(
              children: [
                Icon(Icons.delete_forever, color: AppColors.red),
                SizedBox(width: 12),
                Text('Eliminar cartera', style: TextStyle(color: AppColors.red)),
              ],
            ),
          ),
        ];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomHeader(menuItems: menuItems),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.green, AppColors.yellow],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(walletByIdProvider(widget.walletId));
                ref.invalidate(transactionsByWalletProvider(widget.walletId));
              },
              color: AppColors.purple,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: kToolbarHeight + 60),
                  ),
                  SliverToBoxAdapter(
                    child: _AnimatedSection(
                      delay: 100,
                      child: WalletSection(wallet: wallet),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _AnimatedSection(
                      delay: 250,
                      child: WalletOptionsSection(
                        wallet: wallet,
                        currentFilter: _filterType,
                        onFilterChanged: (filter) {
                          setState(() => _filterType = filter);
                          // Filtrado se puede hacer en el cliente o en el provider
                          // Por ahora simplificamos filtrando la lista recibida
                        },
                        onRefreshNeeded: () {
                           ref.invalidate(walletByIdProvider(widget.walletId));
                           ref.invalidate(transactionsByWalletProvider(widget.walletId));
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  
                  // Transactions List
                  transactionsAsync.when(
                    data: (transactions) {
                      // Apply filter locally
                      var filtered = transactions;
                      if (_filterType != 'all') {
                        filtered = transactions.where((t) => t.type == _filterType).toList();
                      }
                      
                      return categoriesAsync.when(
                        data: (categories) => TransactionListSection(
                          transactions: filtered,
                          categories: categories,
                          currency: wallet.currency,
                        ),
                         loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                         error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    ),
                    error: (e, st) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                         child: Center(child: Text('Error cargando transacciones: $e', style: const TextStyle(color: Colors.white))),
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleArchive(Wallet wallet) async {
    await ref.read(walletNotifierProvider.notifier).toggleArchive(wallet.id);
  }

  Future<void> _toggleFavorite(Wallet wallet) async {
    await ref.read(walletNotifierProvider.notifier).toggleFavorite(wallet.id);
  }

  Future<void> _deleteWallet(Wallet wallet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar cartera"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(walletNotifierProvider.notifier).deleteWallet(wallet.id);
      if (success && mounted) Navigator.of(context).pop();
    }
  }
}

class _AnimatedSection extends StatelessWidget {
  final Widget child;
  final int delay;
  const _AnimatedSection({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }
}