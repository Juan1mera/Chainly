import 'package:chainly/core/database/db.dart';
import 'package:chainly/models/wallet_model.dart';
import 'package:chainly/services/auth_service.dart';

class WalletService {
  final Db _db = Db();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? get _userData => _authService.currentUserData;
  String? get _displayId => _userData?['id'];
  String? get _displayEmail => _userData?['email'];

  Future<int> createWallet(Wallet wallet) async {
    final userEmail = _displayEmail;
    if (userEmail == null) throw Exception('User not authenticated');

    final db = await _db.database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<Wallet?> getWalletById(int id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Wallet.fromMap(maps.first);
  }

  Future<List<Wallet>> getWallets({
    bool onlyFavorites = false,
    bool includeArchived = false,
  }) async {
    final userId = _displayId;
    if (userId == null) return [];
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    final db = await _db.database;

    if (onlyFavorites) {
      whereClause += ' AND is_favorite = 1';
    }

    if (!includeArchived) {
      whereClause += ' AND is_archived = 0';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Wallet.fromMap(map)).toList();
  }

  Future<bool> updateWallet(Wallet wallet) async {
    if (wallet.id == null) throw Exception('Wallet ID required');

    final db = await _db.database;
    final result = await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
    return result > 0;
  }

  Future<bool> deleteWallet(int id) async {
    final db = await _db.database;
    final result = await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
    return result > 0;
  }
}
