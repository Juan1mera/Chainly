import 'package:chainly/core/database/db.dart';
import 'package:chainly/models/category_model.dart';
import 'package:chainly/services/auth_service.dart';

class CategoryService {
  final Db _db = Db();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? get _userData => _authService.currentUserData;
  String? get _displayId => _userData?['id'];


  Future<int> createCategory(Category category) async {
    final db = await _db.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final userId = _displayId;
    if (userId == null) return [];

    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      // El null es para obtener 'sin categoria' que no tiene user id
      where: 'user_id = ? OR user_id IS NULL', 
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Category.fromMap(map)).toList();
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