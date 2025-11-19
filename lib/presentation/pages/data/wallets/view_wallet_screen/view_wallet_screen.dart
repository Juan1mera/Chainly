import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/presentation/pages/data/transactions/create_transaction_screen/create_transaction_screen.dart';
import 'package:wallet_app/presentation/pages/data/wallets/view_wallet_screen/components/transaction_list_section.dart';
import 'package:wallet_app/presentation/pages/data/wallets/view_wallet_screen/components/wallet_options_section.dart';
import 'package:wallet_app/presentation/pages/data/wallets/view_wallet_screen/components/wallet_section.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/services/category_service.dart';
import 'package:wallet_app/services/transaction_service.dart';
import 'package:wallet_app/services/wallet_service.dart';

class ViewWalletScreen extends ConsumerStatefulWidget {
  final int walletId;
  const ViewWalletScreen({super.key, required this.walletId});

  @override
  ConsumerState<ViewWalletScreen> createState() => _ViewWalletScreenState();
}

class _ViewWalletScreenState extends ConsumerState<ViewWalletScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();

  Wallet? _wallet;
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  String _filterType = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final walletFuture = _walletService.getWallets(includeArchived: true);
    final categoriesFuture = _categoryService.getCategories();

    final results = await Future.wait([walletFuture, categoriesFuture]);
    final wallets = results[0] as List<Wallet>;
    final categories = results[1] as List<Category>;

    if (!mounted) return;

    setState(() {
      _wallet = wallets.firstWhere((w) => w.id == widget.walletId);
      _categories = categories;
    });

    await _loadTransactions();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTransactions() async {
    final transactions = await _transactionService.getTransactionsByWallet(
      widget.walletId,
      type: _filterType == 'all' ? null : _filterType,
    );
    if (mounted) {
      setState(() => _transactions = transactions);
    }
  }

  void _goToCreateTransaction({required String type}) async {
    if (_wallet == null) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CreateTransactionScreen(
          initialWalletId: _wallet!.id!,
          initialType: type,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  // === ACCIONES DE CARTERA ===
  Future<void> _toggleArchive() async {
    if (_wallet == null) return;
    await _walletService.updateWallet(
      _wallet!.copyWith(isArchived: !_wallet!.isArchived),
    );
    if (mounted) await _loadWallet();
  }

  Future<void> _toggleFavorite() async {
    if (_wallet == null) return;
    await _walletService.updateWallet(
      _wallet!.copyWith(isFavorite: !_wallet!.isFavorite),
    );
    if (mounted) await _loadWallet();
  }

  Future<void> _deleteWallet() async {
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
      await _walletService.deleteWallet(_wallet!.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _loadWallet() async {
    final wallets = await _walletService.getWallets(includeArchived: true);
    if (mounted) {
      setState(() {
        _wallet = wallets.firstWhere((w) => w.id == widget.walletId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _wallet == null
        ? <PopupMenuEntry<dynamic>>[]
        : <PopupMenuEntry<dynamic>>[
            PopupMenuItem(
              onTap: _toggleArchive,
              child: Row(
                children: [
                  Icon(_wallet!.isArchived ? Icons.unarchive : Icons.archive),
                  const SizedBox(width: 12),
                  Text(_wallet!.isArchived ? 'Desarchivar' : 'Archivar'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: _toggleFavorite,
              child: Row(
                children: [
                  Icon(
                    _wallet!.isFavorite ? Icons.star : Icons.star_border,
                    color: _wallet!.isFavorite ? AppColors.yellow : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _wallet!.isFavorite
                        ? 'Quitar de favoritos'
                        : 'Añadir a favoritos',
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              onTap: _deleteWallet,
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _wallet == null
            ? const Center(
                child: Text(
                  'Cartera no encontrada',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.purple,
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: kToolbarHeight + 60),
                    ),

                    SliverToBoxAdapter(
                      child: _AnimatedSection(
                        delay: 100,
                        child: WalletSection(wallet: _wallet!),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: _AnimatedSection(
                        delay: 250,
                        child: WalletOptionsSection(
                          wallet: _wallet!,
                          currentFilter: _filterType,
                          onCreateTransaction: _goToCreateTransaction,
                          onFilterChanged: (filter) {
                            setState(() => _filterType = filter);
                            _loadTransactions();
                          },
                          onRefreshNeeded: _loadData, // ← Aquí le dices que recargue todo
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // LISTA DE TRANSACCIONES
                    TransactionListSection(
                      transactions: _transactions,
                      categories: _categories,
                      currency: _wallet!.currency,
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
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
