import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/presentation/widgets/common/wallet_card.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_button.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_number_field.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_select.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_text_field.dart';
import 'package:wallet_app/providers/wallet_provider.dart';
import 'package:wallet_app/services/transaction_service.dart';

class CreateTransactionConvertScreen extends ConsumerStatefulWidget {
  final Wallet? initialFromWallet;

  const CreateTransactionConvertScreen({
    super.key,
    this.initialFromWallet,
  });

  @override
  ConsumerState<CreateTransactionConvertScreen> createState() =>
      _CreateTransactionConvertScreenState();
}

class _CreateTransactionConvertScreenState
    extends ConsumerState<CreateTransactionConvertScreen> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _noteController = TextEditingController();

  Wallet? _fromWallet;
  Wallet? _toWallet;
  double _amount = 0.0;
  double _convertedAmount = 0.0;
  bool _isConverting = false;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Solo se ejecuta una vez cuando las wallets ya están cargadas
    if (!_hasInitialized && widget.initialFromWallet != null) {
      final wallets = ref.read(walletsProvider).value;
      if (wallets != null && wallets.isNotEmpty) {
        final foundWallet = wallets.firstWhere(
          (w) => w.id == widget.initialFromWallet!.id,
          orElse: () => widget.initialFromWallet!,
        );

        if (mounted) {
          setState(() {
            _fromWallet = foundWallet;
            _hasInitialized = true;
          });
        }
      }
    }
  }

  Future<void> _convertAndShow() async {
    if (_fromWallet == null || _toWallet == null || _amount <= 0) return;

    setState(() => _isConverting = true);
    try {
      if (_fromWallet!.currency == _toWallet!.currency) {
        _convertedAmount = _amount;
      } else {
        _convertedAmount = await _transactionService.convertCurrency(
          amount: _amount,
          fromCurrency: _fromWallet!.currency,
          toCurrency: _toWallet!.currency,
        );
      }
    } catch (e) {
      _convertedAmount = _amount;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transferencia realizada con éxito')),
        );
        ref.read(walletsProvider.notifier).refreshAfterTransaction();
        
        Navigator.pop(context, true); 
      }
    } finally {
      setState(() => _isConverting = false);
    }
  }

  Future<void> _makeTransfer() async {
    if (_fromWallet == null || _toWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona ambas billeteras')),
      );
      return;
    }
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }
    if (_fromWallet!.balance < _amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo insuficiente')),
      );
      return;
    }

    try {
      await _transactionService.transferBetweenWallets(
        fromWalletId: _fromWallet!.id!,
        toWalletId: _toWallet!.id!,
        fromAmount: _amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transferencia realizada con éxito')),
        );
        ref.read(walletsProvider.notifier).refreshAfterTransaction();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (wallets) {
          final activeWallets = wallets.where((w) => !w.isArchived).toList();

          if (activeWallets.length < 2) {
            return const Center(
              child: Text('Necesitas al menos 2 billeteras activas para transferir'),
            );
          }

          // Inicializar desde wallet si aún no se hizo y ya tenemos datos
          if (!_hasInitialized && widget.initialFromWallet != null) {
            final found = activeWallets.firstWhere(
              (w) => w.id == widget.initialFromWallet!.id,
              orElse: () => widget.initialFromWallet!,
            );
            if (_fromWallet == null && found.id != null) {
              _fromWallet = found;
              _hasInitialized = true;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CustomHeader(),

                const SizedBox(height: 20),

                // Desde
                CustomSelect<Wallet>(
                  label: "Desde",
                  items: activeWallets,
                  selectedItem: _fromWallet,
                  getDisplayText: (w) =>
                      '${w.name} • ${w.currency} • ${w.balance.toStringAsFixed(2)}',
                  onChanged: (wallet) {
                    setState(() {
                      _fromWallet = wallet;
                      _toWallet = null;
                      _convertedAmount = 0;
                    });
                  },
                ),

                const SizedBox(height: 20),
                if (_fromWallet != null) ...[
                  WalletCard(wallet: _fromWallet!),
                  const SizedBox(height: 20),
                ],

                CustomNumberField(
                  currency: _fromWallet?.currency ?? 'USD',
                  hintText: '0.00',
                  onChanged: (val) {
                    setState(() => _amount = val);
                    _convertAndShow();
                  },
                ),

                const SizedBox(height: 30),
                Icon(Icons.swap_vert, size: 48, color: AppColors.purple),
                const SizedBox(height: 30),

                // Hacia
                CustomSelect<Wallet>(
                  label: "Hacia",
                  items: activeWallets.where((w) => w.id != _fromWallet?.id).toList(),
                  selectedItem: _toWallet,
                  getDisplayText: (w) => '${w.name} • ${w.currency}',
                  onChanged: (wallet) {
                    setState(() {
                      _toWallet = wallet;
                      _convertAndShow();
                    });
                  },
                ),

                const SizedBox(height: 20),
                if (_toWallet != null) ...[
                  WalletCard(wallet: _toWallet!),
                  const SizedBox(height: 20),
                ],

                // Resultado de conversión
                if (_fromWallet != null && _toWallet != null && _amount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isConverting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else ...[
                          Text(
                            '${_amount.toStringAsFixed(2)} ${_fromWallet!.currency}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.arrow_forward, size: 20),
                          Text(
                            '${_convertedAmount.toStringAsFixed(2)} ${_toWallet!.currency}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                CustomTextField(
                  controller: _noteController,
                  label: "Nota (opcional)",
                  hintText: "Ej: Pago a amigo, viaje...",
                ),

                const SizedBox(height: 30),

                CustomButton(
                  text: "Transferir",
                  onPressed: (_fromWallet == null ||
                          _toWallet == null ||
                          _amount <= 0 ||
                          _isConverting)
                      ? null
                      : _makeTransfer,
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}