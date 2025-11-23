import 'package:chainly/core/database/db.dart';
import 'package:chainly/models/category_model.dart';

class CategoryService {
  final Db _db = Db();

  Future<int> createCategory(Category category) async {
    final db = await _db.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<bool> updateCategory(Category category) async {
    if (category.id == null) throw Exception('Category ID required');

    final db = await _db.database;
    final result = await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return result > 0;
  }

  Future<bool> deleteCategory(int id) async {
    final db = await _db.database;
    final result = await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  // Útil para crear categoría si no existe
  Future<int> getOrCreateCategoryId(String categoryName) async {
    final db = await _db.database;

    final result = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [categoryName.trim()],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }

    return await db.insert('categories', {
      'name': categoryName.trim(),
      'monthly_budget': 0.0,
    });
  }
}