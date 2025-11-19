import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';

class CategoryEditDialog extends StatefulWidget {
  final TextEditingController controller;
  final String? initialIconCode;

  const CategoryEditDialog({
    super.key,
    required this.controller,
    this.initialIconCode,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late String? selectedIconCode;

  final List<IconData> icons = [
    Icons.fastfood, Icons.shopping_cart, Icons.local_movies, Icons.directions_car,
    Icons.home, Icons.school, Icons.health_and_safety, Icons.flight,
    Icons.coffee, Icons.sports_esports, Icons.pets, Icons.card_giftcard,
    Icons.work, Icons.savings, Icons.attach_money, Icons.receipt_long,
    Icons.restaurant, Icons.train, Icons.hotel, Icons.palette,
    Icons.lightbulb, Icons.beach_access, Icons.fitness_center, Icons.music_note,
  ];

  @override
  void initState() {
    super.initState();
    selectedIconCode = widget.initialIconCode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.initialIconCode != null ? 'Editar categoría' : 'Nueva categoría'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: widget.controller,
                decoration: const InputDecoration(
                  hintText: 'Nombre de la categoría',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              const Text('Ícono (opcional)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: icons.length,
                itemBuilder: (ctx, i) {
                  final icon = icons[i];
                  final code = icon.codePoint.toRadixString(16);
                  final isSelected = selectedIconCode == code;

                  return GestureDetector(
                    onTap: () => setState(() => selectedIconCode = isSelected ? null : code),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.purple.withValues(alpha: .2) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.purple : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, size: 28, color: isSelected ? AppColors.purple : Colors.grey[700]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
          onPressed: () {
            Navigator.pop(context, {
              'name': widget.controller.text,
              'iconCode': selectedIconCode,
            });
          },
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}