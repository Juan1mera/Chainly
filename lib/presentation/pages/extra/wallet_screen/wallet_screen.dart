import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  final int walletId;

  const WalletScreen({
    super.key,
    required this.walletId,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  
  Wallet? _wallet;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _filterType = 'all'; // 'all', 'income', 'expense'
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    setState(() {
      switch (_tabController.index) {
        case 0:
          _filterType = 'all';
          break;
        case 1:
          _filterType = 'income';
          break;
        case 2:
          _filterType = 'expense';
          break;
      }
    });
    _loadTransactions();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
    
    try {
      final wallets = await _walletService.getWallets(includeArchived: true);
      _wallet = wallets.firstWhere((w) => w.id == widget.walletId);
      await _loadTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _walletService.getTransactionsByWallet(
        widget.walletId,
        type: _filterType == 'all' ? null : _filterType,
      );
      if (mounted) {
        setState(() => _transactions = transactions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar transacciones: $e')),
        );
      }
    }
  }

  String _getCurrencySymbol(String currency) {
    const Map<String, String> symbols = {
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'MXN': r'$',
      'BRL': r'R$',
      'INR': '₹',
    };
    return symbols[currency] ?? currency;
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward;
      case 'expense':
        return Icons.arrow_upward;
      default:
        return Icons.swap_horiz;
    }
  }

  Widget _buildWalletHeader() {
    if (_wallet == null) return const SizedBox.shrink();

    final currencySymbol = _getCurrencySymbol(_wallet!.currency);
    final walletColor = Color(int.parse(_wallet!.color.replaceFirst('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            walletColor,
            walletColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: walletColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _wallet!.iconBank ?? Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _wallet!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_wallet!.type == 'bank' ? 'Banco' : 'Efectivo'} • ${_wallet!.currency}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_wallet!.isFavorite)
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Saldo actual',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currencySymbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _wallet!.balance.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.verde,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Todas'),
          Tab(text: 'Ingresos'),
          Tab(text: 'Gastos'),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay transacciones',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las transacciones aparecerán aquí',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar transacciones por fecha
    final Map<String, List<Transaction>> groupedTransactions = {};
    final dateFormat = DateFormat('dd MMM yyyy', 'es_ES');

    for (var transaction in _transactions) {
      final dateKey = dateFormat.format(transaction.date);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ...transactions.map((transaction) => _buildTransactionCard(transaction)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final currencySymbol = _getCurrencySymbol(_wallet?.currency ?? 'USD');
    final color = _getTransactionColor(transaction.type);
    final icon = _getTransactionIcon(transaction.type);
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              timeFormat.format(transaction.date),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transaction.note!,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Text(
          '${transaction.type == 'expense' ? '-' : '+'}$currencySymbol${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          // TODO: Navegar a detalle de transacción
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Detalle de Cartera',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Editar cartera
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Más opciones (archivar, eliminar, etc.)
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.verde,
        onPressed: () {
          // TODO: Crear nueva transacción
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva transacción',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wallet == null
              ? const Center(
                  child: Text('Cartera no encontrada'),
                )
              : RefreshIndicator(
                  onRefresh: _loadWalletData,
                  child: Column(
                    children: [
                      _buildWalletHeader(),
                      _buildTabBar(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildTransactionsList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}