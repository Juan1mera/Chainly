// lib/presentation/widgets/ui/custom_number_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/constants/fonts.dart';

class CustomNumberField extends StatefulWidget {
  final String currency;
  final Function(double)? onChanged;
  final TextEditingController? controller;
  final String? hintText;

  const CustomNumberField({
    super.key,
    required this.currency,
    this.onChanged,
    this.controller,
    this.hintText,
  });

  @override
  State<CustomNumberField> createState() => _CustomNumberFieldState();
}

class _CustomNumberFieldState extends State<CustomNumberField>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    hasFocus ? _animationController.forward() : _animationController.reverse();
  }

  // FORMATEO MANUAL: solo enteros con separador de miles
  String _formatInteger(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );
  }

  String _getCurrencySymbol(String currency) {
    const Map<String, String> symbols = {
      'USD': r'$', 'EUR': '€', 'GBP': '£', 'JPY': '¥',
      'MXN': r'$', 'BRL': r'R$', 'INR': '₹', 'COP': r'$',
    };
    return symbols[currency] ?? currency;
  }

  void _onTextChanged() {
    if (_isUpdating) return;

    final text = _controller.text;
    final clean = text.replaceAll(RegExp(r'[^\d]'), ''); // solo dígitos

    if (clean.isEmpty) {
      widget.onChanged?.call(0.0);
      return;
    }

    final intValue = int.tryParse(clean) ?? 0;
    final formatted = _formatInteger(intValue);

    _isUpdating = true;
    _controller.text = formatted;

    // Mantener cursor al final
    _controller.selection = TextSelection.collapsed(offset: formatted.length);

    _isUpdating = false;
    widget.onChanged?.call(intValue.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = AppColors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              border: Border.all(width: 2, color: AppColors.black)
            ),
            child: Focus(
              onFocusChange: _onFocusChange,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Solo dígitos
                ],
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFonts.clashDisplay
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? '0',
                  hintStyle: TextStyle(color: baseColor.withValues(alpha: .6)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      _getCurrencySymbol(widget.currency),
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.clashDisplay
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
                onChanged: (_) => _onTextChanged(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}