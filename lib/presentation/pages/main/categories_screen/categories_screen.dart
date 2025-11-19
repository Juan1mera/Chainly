
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/presentation/pages/main/categories_screen/components/category_card.dart';
import 'package:wallet_app/presentation/pages/main/categories_screen/components/category_edit_dialog.dart';
import 'package:wallet_app/services/category_service.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categoriesFuture = _categoryService.getCategories();
    });
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final isEdit = category != null;
    final controller = TextEditingController(text: category?.name ?? '');
    String? selectedIconCode = category?.icon;

    final result = await showDialog<Map<String, String?>?>(
      context: context,
      builder: (ctx) => CategoryEditDialog(
        controller: controller,
        initialIconCode: selectedIconCode,
      ),
    );

    if (result == null || result['name']?.trim().isEmpty != false) return;

    final name = result['name']!.trim();
    final iconCode = result['iconCode']; // ← ¡Aquí estaba el error! Usamos iconCode

    try {
      if (isEdit) {
        await _categoryService.updateCategory(Category(
          id: category.id,
          name: name,
          icon: iconCode, // ← CORREGIDO: era "finalCode"
          monthlyBudget: category.monthlyBudget,
        ));
      } else {
        await _categoryService.createCategory(Category(
          name: name,
          icon: iconCode, // ← CORREGIDO
          monthlyBudget: 0.0,
        ));
      }

      _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Categoría actualizada' : 'Categoría creada'),
            backgroundColor: AppColors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar permanentemente "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && category.id != null) {
      try {
        await _categoryService.deleteCategory(category.id!);
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showCategoryDialog(),
      label: const Text("Nueva categoría"),
      icon: const Icon(Icons.add),
      backgroundColor: AppColors.purple,
      foregroundColor: Colors.white,
    ),
    body: RefreshIndicator(
      onRefresh: () async {
        _loadCategories();
        await _categoriesFuture;
      },
      color: AppColors.purple,
      child: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.purple));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(), 
              children: const [
                SizedBox(height: 200), 
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.category_outlined, size: 90, color: Colors.grey),
                      SizedBox(height: 24),
                      Text(
                        'No hay categorías aún',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '¡Crea tu primera categoría!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Lista normal de categorías
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CategoryCard(
                  category: cat,
                  onEdit: () => _showCategoryDialog(category: cat),
                  onDelete: () => _deleteCategory(cat),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
}

