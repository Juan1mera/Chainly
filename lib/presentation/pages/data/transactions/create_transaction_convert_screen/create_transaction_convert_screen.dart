import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/utils/number_format.dart';
import 'package:chainly/data/models/wallet_model.dart';
import 'package:chainly/presentation/widgets/common/wallet_mini_card.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/presentation/widgets/ui/custom_header.dart';
import 'package:chainly/presentation/widgets/ui/custom_number_field.dart';
import 'package:chainly/presentation/widgets/ui/custom_select.dart';
import 'package:chainly/presentation/widgets/ui/custom_text_field.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';
import 'package:chainly/domain/providers/transaction_provider.dart';

class CreateTransactionConvertScreen extends ConsumerStatefulWidget {
  final Wallet? initialFromWallet;

  const CreateTransactionConvertScreen({super.key, this.initialFromWallet});

  @override
  ConsumerState<CreateTransactionConvertScreen> createState() =>
      _CreateTransactionConvertScreenState();
}

class _CreateTransactionConvertScreenState
    extends ConsumerState<CreateTransactionConvertScreen> {
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
    // Using ref.watch here might trigger too many rebuilds, usually better to do in build
    // but we need to initialize _fromWallet once.
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _convertAndShow() async {
    if (_fromWallet == null || _toWallet == null || _amount <= 0) return;

    setState(() => _isConverting = true);
    try {
      if (_fromWallet!.currency == _toWallet!.currency) {
        setState(() => _convertedAmount = _amount);
      } else {
        // Use repository directly via provider for conversion (read-only op)
        final repo = ref.read(transactionRepositoryProvider);
        final converted = await repo.convertCurrency(
          amount: _amount,
          fromCurrency: _fromWallet!.currency,
          toCurrency: _toWallet!.currency,
        );
        setState(() => _convertedAmount = converted);
      }
    } catch (e) {
      if (mounted) {
         setState(() => _convertedAmount = _amount); // Fallback
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error conversión: $e')));
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un monto válido')));
      return;
    }
    if (_fromWallet!.balance < _amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo insuficiente')));
      return;
    }

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);
      await notifier.transfer(
        fromWalletId: _fromWallet!.id,
        toWalletId: _toWallet!.id,
        amount: _amount,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        fromCurrency: _fromWallet!.currency,
        toCurrency: _toWallet!.currency,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transferencia realizada con éxito')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider(const WalletFilters(includeArchived: false)));

    return Scaffold(
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (wallets) {
          final activeWallets = wallets.where((w) => !w.isArchived).toList();

          if (activeWallets.length < 2) {
            return const Center(
              child: Text(
                'Necesitas al menos 2 billeteras activas para transferir',
              ),
            );
          }

          // Initial setup
          if (!_hasInitialized && widget.initialFromWallet != null) {
            final found = activeWallets.firstWhere(
              (w) => w.id == widget.initialFromWallet!.id,
              orElse: () => widget.initialFromWallet!,
            );
            // Ensure we only set it if we haven't selected yet (or it matches initial intent)
            // and checking if found exists in current list (it should based on firstWhere orElse logic, careful if not in list)
             
            if (_fromWallet == null) {
               _fromWallet = found;
               _hasInitialized = true;
            }
          }

          return SingleChildScrollView(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.green, AppColors.yellow],
                ),
              ),
              child: Column(
                children: [
                  const CustomHeader(),

                  // Desde
                  CustomSelect<Wallet>(
                    label: "Desde",
                    items: activeWallets,
                    selectedItem: _fromWallet,
                    getDisplayText: (w) => '${w.name} • ${w.currency}',
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
                    WalletMiniCard(wallet: _fromWallet!),
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

                  const SizedBox(height: 10),
                  const Icon(
                    Bootstrap.arrow_down_up,
                    size: 28,
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 10),

                  // Hacia
                  CustomSelect<Wallet>(
                    label: "Hacia",
                    items: activeWallets
                        .where((w) => w.id != _fromWallet?.id)
                        .toList(),
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
                    WalletMiniCard(wallet: _toWallet!),
                    const SizedBox(height: 20),
                  ],

                  // Resultado de conversión
                  if (_fromWallet != null &&
                      _toWallet != null &&
                      _amount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
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
                              '${formatAmount(_amount)} ${_fromWallet!.currency}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFonts.clashDisplay
                              ),
                            ),
                            const SizedBox(height: 10,),
                            const Icon(Bootstrap.arrow_down_up, size: 20),
                            const SizedBox(height: 10,),
                            Text(
                              '${formatAmount(_convertedAmount)} ${_toWallet!.currency}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFonts.clashDisplay
                              ),
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


                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CustomButton(
                      text: "Convert",
                      leftIcon: const Icon(Bootstrap.arrow_down_up),
                      onPressed:
                          (_fromWallet == null ||
                              _toWallet == null ||
                              _amount <= 0 ||
                              _isConverting)
                          ? null
                          : _makeTransfer,
                    ),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
