import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/constants/currencies.dart';
import 'package:wallet_app/core/constants/fonts.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/presentation/pages/extra/wallet_screen/components/wallet_card.dart';
import 'package:wallet_app/presentation/pages/extra/wallet_screen/wallet_screen.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_button.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_modal.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_text_field.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_number_field.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_select.dart';
import 'package:wallet_app/services/wallet_service.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final WalletService _walletService = WalletService();
  late Future<List<Wallet>> _walletsFuture;

  final TextEditingController _nameController = TextEditingController();
  String _selectedCurrency = 'USD';
  double _initialBalance = 0.0;
  String _selectedType = 'cash';
  String _selectedColor = AppColors.walletColors[0];
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  void _loadWallets() {
    setState(() {
      _walletsFuture = _walletService.getWallets(includeArchived: true);
    });
  }

  // ===EL MODAL Y CREACIÓN (sin cambios) ===
  Future<void> _showCreateWalletModal() async {
    _nameController.clear();
    _selectedCurrency = 'USD';
    _initialBalance = 0.0;
    _selectedType = 'cash';
    _selectedColor = AppColors.walletColors[0];
    _isFavorite = false;

    showCustomModal(
      context: context,
      title: 'Add Wallet',
      heightFactor: 0.9,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Ej: Efectivo, Nubank, Ahorros',
                  icon: Icons.wallet,
                ),
                const SizedBox(height: 20),
                CustomSelect<String>(
                  label: 'Moneda',
                  items: Currencies.codes,
                  selectedItem: _selectedCurrency,
                  getDisplayText: (code) => code,
                  onChanged: (val) => setModalState(() => _selectedCurrency = val!),
                  dynamicIcon: (code) => Currencies.getIcon(code!),
                ),
                const SizedBox(height: 20),
                CustomNumberField(
                  currency: _selectedCurrency,
                  hintText: '0.00',
                  onChanged: (value) =>
                      setModalState(() => _initialBalance = value),
                ),
                const SizedBox(height: 24),
                _buildTypeSelector(setModalState),
                const SizedBox(height: 28),
                _buildColorSelector(setModalState),
              ],
            ),
          );
        },
      ),
      actions: [
        CustomButton(
          text: 'Cancelar',
          bgColor: Colors.grey.shade300,
          textColor: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Crear Cartera',
          onPressed: _isLoading ? null : _createWallet,
          isLoading: _isLoading,
          bgColor: AppColors.purple,
        ),
      ],
    );
  }

  Widget _buildTypeSelector(StateSetter s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          Expanded(child: _typeTile('cash', 'Efectivo', Icons.payments, s)),
          const SizedBox(width: 12),
          Expanded(
            child: _typeTile('bank', 'Banco', Icons.account_balance, s),
          ),
        ],
      ),
    );
  }

  Widget _typeTile(String v, String l, IconData i, StateSetter s) {
    final sel = _selectedType == v;
    return GestureDetector(
      onTap: () => s(() => _selectedType = v),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: sel ? AppColors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, color: sel ? AppColors.black : AppColors.greyDark),
            const SizedBox(width: 8),
            Text(
              l,
              style: TextStyle(
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                fontFamily: AppFonts.clashDisplay
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector(StateSetter s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AppColors.walletColors.map((c) {
            final sel = _selectedColor == c;
            return GestureDetector(
              onTap: () => s(() => _selectedColor = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: sel ? 4 : 0),
                ),
                child: sel
                    ? const Icon(Icons.check, color: Colors.white, size: 28)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }


  Future<void> _createWallet() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final wallet = Wallet(
      name: _nameController.text.trim(),
      currency: _selectedCurrency,
      balance: _initialBalance,
      color: _selectedColor,
      type: _selectedType,
      isFavorite: _isFavorite,
      isArchived: false,
      iconBank: _selectedType == 'bank' ? Icons.account_balance : null,
      createdAt: DateTime.now(),
    );
    try {
      await _walletService.createWallet(wallet);
      if (mounted) {
        Navigator.pop(context);
        _loadWallets();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('¡Cartera creada!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== BUILD (IGUAL QUE TU HOME) ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.black,
        onPressed: _showCreateWalletModal,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadWallets(),
        color: AppColors.purple,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
          children: [
            const SizedBox(height: 50),

            // Estado vacío
            FutureBuilder<List<Wallet>>(
              future: _walletsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final wallets = snapshot.data ?? [];
                wallets.sort(
                  (a, b) => b.isFavorite == a.isFavorite
                      ? 0
                      : b.isFavorite
                      ? -1
                      : 1,
                );

                if (wallets.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height - 250,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wallet,
                          size: 90,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No tienes carteras aún',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Toca el botón + para crear tu primera cartera',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: wallets.map((wallet) {
                    return Opacity(
                      opacity: wallet.isArchived ? 0.5 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: wallet.isArchived
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WalletScreen(walletId: wallet.id!),
                                  ),
                                ),
                          child: WalletCard(wallet: wallet),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
