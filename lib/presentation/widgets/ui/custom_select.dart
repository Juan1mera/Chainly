import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';

class CustomSelect<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) getDisplayText;
  final Function(T?) onChanged;
  final Color? color;
  final String? hintText;
  final IconData? icon;
  final IconData Function(T? selectedItem)? dynamicIcon;

  const CustomSelect({
    super.key,
    required this.label,
    required this.items,
    required this.getDisplayText,
    required this.onChanged,
    this.color,
    this.selectedItem,
    this.hintText,
    this.icon,
    this.dynamicIcon,
  });

  @override
  CustomSelectState<T> createState() => CustomSelectState<T>();
}

class CustomSelectState<T> extends State<CustomSelect<T>> with TickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  Color get _effectiveColor => widget.color ?? AppColors.verde;

  IconData? get _effectiveIcon {
    if (widget.dynamicIcon != null) {
      return widget.dynamicIcon!(widget.selectedItem);
    }
    return widget.icon;
  }

  @override
  void initState() {
    super.initState();
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
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    setState(() => _isOpen = true);
    _animationController.forward();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    setState(() => _isOpen = false);
    _animationController.reverse();
    _removeOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final baseColor = _effectiveColor;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 16,
        top: offset.dy + size.height + 4,
        width: size.width - 32,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: AppColors.fondoPrincipal,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.fondoPrincipal,
              border: Border.all(color: baseColor.withValues(alpha: 0.3), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.selectedItem == item;

                return InkWell(
                  onTap: () {
                    widget.onChanged(item); // Llama al padre
                    _closeDropdown();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? baseColor.withValues(alpha: 0.2) : null,
                      borderRadius: index == 0
                          ? const BorderRadius.vertical(top: Radius.circular(10))
                          : index == widget.items.length - 1
                              ? const BorderRadius.vertical(bottom: Radius.circular(10))
                              : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.getDisplayText(item),
                            style: TextStyle(
                              color: isSelected ? AppColors.verde : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check, color: baseColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _effectiveColor;
    final backgroundColor = baseColor.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _toggleDropdown,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: _effectiveIcon != null ? 8 : 16,
                      right: 16,
                      top: 16,
                      bottom: 16,
                    ),
                    child: Row(
                      children: [
                        if (_effectiveIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: Icon(_effectiveIcon, color: baseColor, size: 24),
                          ),
                        Expanded(
                          child: Text(
                            widget.selectedItem != null
                                ? widget.getDisplayText(widget.selectedItem as T)
                                : widget.hintText ?? widget.label,
                            style: TextStyle(
                              color: widget.selectedItem != null ? AppColors.verde : baseColor,
                              fontSize: widget.selectedItem != null ? 16 : 14,
                              fontWeight: widget.selectedItem != null ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down, color: baseColor, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}