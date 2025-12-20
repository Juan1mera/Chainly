import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import '../../core/database/local_database.dart';

class WalletRepository {
  final SupabaseClient _supabase;
  final Db _localDb;
  final Connectivity _connectivity;

  WalletRepository({
    required SupabaseClient supabase,
    required Db localDb,
    Connectivity? connectivity,
  })  : _supabase = supabase,
        _localDb = localDb,
        _connectivity = connectivity ?? Connectivity();

  // Stream de wallets en tiempo real desde Supabase
  Stream<List<Wallet>> watchWallets(String userId) {
    return _supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((json) => Wallet.fromSupabase(json)).toList();
        })
        .handleError((error) {
          debugPrint('Error en stream de wallets: $error');
          return <Wallet>[];
        });
  }

  // Obtiene wallets (intenta desde Supabase, fallback a local)
  Future<List<Wallet>> getWallets({
    required String userId,
    bool forceRefresh = false,
    bool onlyFavorites = false,
    bool includeArchived = false,
  }) async {
    final isOnline = await _checkConnectivity();

    // Si está offline o no fuerza refresh, usa caché local
    if (!isOnline || !forceRefresh) {
      return await _getWalletsFromLocal(
        userId: userId,
        onlyFavorites: onlyFavorites,
        includeArchived: includeArchived,
      );
    }

    try {
      // Intenta obtener desde Supabase
      var query = _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId);

      if (onlyFavorites) {
        query = query.eq('is_favorite', true);
      }

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      final response = await query.order('created_at', ascending: false);
      final wallets = (response as List)
          .map((json) => Wallet.fromSupabase(json))
          .toList();

      // Actualiza caché local
      await _updateLocalCache(wallets);

      return wallets;
    } catch (e) {
      debugPrint('Error obteniendo wallets de Supabase: $e');
      // Fallback a local
      return await _getWalletsFromLocal(
        userId: userId,
        onlyFavorites: onlyFavorites,
        includeArchived: includeArchived,
      );
    }
  }

  // Obtiene una wallet por ID
  Future<Wallet?> getWalletById(String id) async {
    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        final response = await _supabase
            .from('wallets')
            .select()
            .eq('id', id)
            .single();

        final wallet = Wallet.fromSupabase(response);
        
        // Actualiza local
        await _localDb.insert('wallets', wallet.toLocal());
        
        return wallet;
      } catch (e) {
        debugPrint('Error obteniendo wallet de Supabase: $e');
      }
    }

    // Fallback a local
    final results = await _localDb.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Wallet.fromLocal(results.first);
  }

  // Crea una nueva wallet
  Future<Wallet> createWallet(Wallet wallet) async {
    // Guarda primero en local (optimistic update)
    await _localDb.insert('wallets', wallet.toLocal());

    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        // Intenta sincronizar con Supabase
        await _supabase.from('wallets').insert(wallet.toSupabase());
        
        // Marca como sincronizado
        final syncedWallet = wallet.markAsSynced();
        await _localDb.update(
          'wallets',
          syncedWallet.toLocal(),
          where: 'id = ?',
          whereArgs: [wallet.id],
        );
        
        return syncedWallet;
      } catch (e) {
        debugPrint('Error creando wallet en Supabase: $e');
        
        // Agrega a cola de pendientes
        await _localDb.addPendingOperation(
          operationType: 'insert',
          tableName: 'wallets',
          recordId: wallet.id,
          data: json.encode(wallet.toSupabase()),
        );
      }
    } else {
      // Sin conexión, agrega a cola
      await _localDb.addPendingOperation(
        operationType: 'insert',
        tableName: 'wallets',
        recordId: wallet.id,
        data: json.encode(wallet.toSupabase()),
      );
    }

    return wallet;
  }

  // Actualiza una wallet
  Future<Wallet> updateWallet(Wallet wallet) async {
    final updatedWallet = wallet.incrementVersion();

    // Actualiza primero en local
    await _localDb.update(
      'wallets',
      updatedWallet.toLocal(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );

    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        // Verifica conflictos antes de actualizar
        final serverWallet = await _checkForConflicts(wallet.id);
        
        if (serverWallet != null && 
            serverWallet.updatedAt.isAfter(wallet.updatedAt)) {
          // Conflicto detectado - usa estrategia de resolución
          return await _resolveConflict(updatedWallet, serverWallet);
        }

        // No hay conflictos, actualiza
        await _supabase
            .from('wallets')
            .update(updatedWallet.toSupabase())
            .eq('id', wallet.id);

        // Marca como sincronizado
        final syncedWallet = updatedWallet.markAsSynced();
        await _localDb.update(
          'wallets',
          syncedWallet.toLocal(),
          where: 'id = ?',
          whereArgs: [wallet.id],
        );

        return syncedWallet;
      } catch (e) {
        debugPrint('Error actualizando wallet en Supabase: $e');
        
        // Agrega a cola de pendientes
        await _localDb.addPendingOperation(
          operationType: 'update',
          tableName: 'wallets',
          recordId: wallet.id,
          data: json.encode(updatedWallet.toSupabase()),
        );
      }
    } else {
      // Sin conexión, agrega a cola
      await _localDb.addPendingOperation(
        operationType: 'update',
        tableName: 'wallets',
        recordId: wallet.id,
        data: json.encode(updatedWallet.toSupabase()),
      );
    }

    return updatedWallet;
  }

  // Elimina una wallet
  Future<bool> deleteWallet(String id) async {
    // Elimina de local primero
    await _localDb.delete('wallets', where: 'id = ?', whereArgs: [id]);

    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        await _supabase.from('wallets').delete().eq('id', id);
        return true;
      } catch (e) {
        debugPrint('Error eliminando wallet de Supabase: $e');
        
        // Agrega a cola de pendientes
        await _localDb.addPendingOperation(
          operationType: 'delete',
          tableName: 'wallets',
          recordId: id,
          data: json.encode({}),
        );
      }
    } else {
      // Sin conexión, agrega a cola
      await _localDb.addPendingOperation(
        operationType: 'delete',
        tableName: 'wallets',
        recordId: id,
        data: json.encode({}),
      );
    }

    return true;
  }

  // Sincroniza operaciones pendientes
  Future<void> syncPendingOperations() async {
    final isOnline = await _checkConnectivity();
    if (!isOnline) return;

    final pending = await _localDb.getPendingOperations();

    for (final op in pending) {
      try {
        final opType = op['operation_type'] as String;
        final tableName = op['table_name'] as String;
        final recordId = op['record_id'] as String;
        
        if (tableName != 'wallets') continue;

        switch (opType) {
          case 'insert':
            final wallet = await _getWalletFromLocal(recordId);
            if (wallet != null) {
              await _supabase.from('wallets').insert(wallet.toSupabase());
              
              // Marca como sincronizado
              await _localDb.update(
                'wallets',
                wallet.markAsSynced().toLocal(),
                where: 'id = ?',
                whereArgs: [recordId],
              );
            }
            break;

          case 'update':
            final wallet = await _getWalletFromLocal(recordId);
            if (wallet != null) {
              await _supabase
                  .from('wallets')
                  .update(wallet.toSupabase())
                  .eq('id', recordId);
              
              // Marca como sincronizado
              await _localDb.update(
                'wallets',
                wallet.markAsSynced().toLocal(),
                where: 'id = ?',
                whereArgs: [recordId],
              );
            }
            break;

          case 'delete':
            await _supabase.from('wallets').delete().eq('id', recordId);
            break;
        }

        // Elimina de la cola si tuvo éxito
        await _localDb.removePendingOperation(op['id'] as int);
      } catch (e) {
        debugPrint('Error sincronizando operación: $e');
        
        // Incrementa contador de reintentos
        await _localDb.incrementRetryCount(op['id'] as int);
        
        // Si ha fallado más de 5 veces, considera eliminarlo o notificar
        if ((op['retry_count'] as int) > 5) {
          debugPrint('Operación falló demasiadas veces: ${op['id']}');
        }
      }
    }
  }

  // Métodos privados auxiliares
  Future<bool> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<List<Wallet>> _getWalletsFromLocal({
    required String userId,
    bool onlyFavorites = false,
    bool includeArchived = false,
  }) async {
    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (onlyFavorites) {
      where += ' AND is_favorite = 1';
    }

    if (!includeArchived) {
      where += ' AND is_archived = 0';
    }

    final results = await _localDb.query(
      'wallets',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return results.map((map) => Wallet.fromLocal(map)).toList();
  }

  Future<Wallet?> _getWalletFromLocal(String id) async {
    final results = await _localDb.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Wallet.fromLocal(results.first);
  }

  Future<void> _updateLocalCache(List<Wallet> wallets) async {
    for (final wallet in wallets) {
      await _localDb.insert('wallets', wallet.toLocal());
    }
  }

  Future<Wallet?> _checkForConflicts(String walletId) async {
    try {
      final response = await _supabase
          .from('wallets')
          .select()
          .eq('id', walletId)
          .single();

      return Wallet.fromSupabase(response);
    } catch (e) {
      return null;
    }
  }

  Future<Wallet> _resolveConflict(Wallet local, Wallet server) async {
    // Estrategia: Last-Write-Wins (el servidor gana)
    // Puedes implementar lógica más compleja aquí
    
    debugPrint('Conflicto detectado en wallet ${local.id}');
    debugPrint('Local version: ${local.version}, Server version: ${server.version}');
    
    // Guarda la versión del servidor
    await _localDb.update(
      'wallets',
      server.toLocal(),
      where: 'id = ?',
      whereArgs: [local.id],
    );
    
    return server;
  }
}