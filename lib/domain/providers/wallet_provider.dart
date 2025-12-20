import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../core/database/local_database.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

// Provider del cliente Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provider de la base de datos local
final localDatabaseProvider = Provider<Db>((ref) {
  return Db();
});

// Provider del repositorio de wallets
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(
    supabase: ref.watch(supabaseClientProvider),
    localDb: ref.watch(localDatabaseProvider),
    connectivity: Connectivity(),
  );
});

// Provider de stream de wallets (tiempo real desde Supabase)
final walletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value([]);
  }

  return repository.watchWallets(userId);
});

// Provider de lista de wallets con caché y filtros
final walletsProvider = FutureProvider.family<List<Wallet>, WalletFilters>(
  (ref, filters) async {
    final repository = ref.watch(walletRepositoryProvider);
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) return [];

    final wallets = await repository.getWallets(
      userId: userId,
      forceRefresh: filters.forceRefresh,
      onlyFavorites: filters.onlyFavorites,
      includeArchived: filters.includeArchived,
    );

    // Ordena: favoritos primero, luego por fecha
    wallets.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return wallets;
  },
);

// Provider de una wallet específica
final walletByIdProvider = FutureProvider.family<Wallet?, String>(
  (ref, walletId) async {
    final repository = ref.watch(walletRepositoryProvider);
    return await repository.getWalletById(walletId);
  },
);

// Provider de wallets favoritas
final favoriteWalletsProvider = FutureProvider<List<Wallet>>((ref) async {
  return ref.watch(walletsProvider(const WalletFilters(onlyFavorites: true)).future);
});

// Provider de balance total
final totalBalanceProvider = FutureProvider<Map<String, double>>((ref) async {
  final wallets = await ref.watch(
    walletsProvider(const WalletFilters(includeArchived: false)).future,
  );

  final balancesByCurrency = <String, double>{};

  for (final wallet in wallets) {
    balancesByCurrency[wallet.currency] = 
        (balancesByCurrency[wallet.currency] ?? 0) + wallet.balance;
  }

  return balancesByCurrency;
});

// Notifier para operaciones de wallets
final walletNotifierProvider = 
    StateNotifierProvider<WalletNotifier, AsyncValue<void>>((ref) {
  return WalletNotifier(ref);
});

class WalletNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  WalletNotifier(this._ref) : super(const AsyncValue.data(null));

  WalletRepository get _repository => _ref.read(walletRepositoryProvider);

  // Crea una nueva wallet
  Future<Wallet?> createWallet({
    required String name,
    required String color,
    required String currency,
    required String type,
    double balance = 0.0,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = AsyncValue.error('Usuario no autenticado', StackTrace.current);
      return null;
    }

    state = const AsyncValue.loading();
    
    try {
      final wallet = Wallet.create(
        userId: userId,
        name: name,
        color: color,
        currency: currency,
        type: type,
        balance: balance,
      );

      final createdWallet = await _repository.createWallet(wallet);
      
      state = const AsyncValue.data(null);
      
      // Invalida los providers para refrescar
      _invalidateProviders();
      
      return createdWallet;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  // Actualiza una wallet
  Future<bool> updateWallet(Wallet wallet) async {
    state = const AsyncValue.loading();
    
    try {
      await _repository.updateWallet(wallet);
      state = const AsyncValue.data(null);
      
      // Invalida los providers para refrescar
      _invalidateProviders();
      
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Actualiza el balance de una wallet
  Future<bool> updateBalance(String walletId, double newBalance) async {
    try {
      final wallet = await _repository.getWalletById(walletId);
      if (wallet == null) return false;

      final updatedWallet = wallet.copyWith(balance: newBalance);
      return await updateWallet(updatedWallet);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // Toggle favorito
  Future<bool> toggleFavorite(String walletId) async {
    try {
      final wallet = await _repository.getWalletById(walletId);
      if (wallet == null) return false;

      final updatedWallet = wallet.copyWith(isFavorite: !wallet.isFavorite);
      return await updateWallet(updatedWallet);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // Archivar/desarchivar
  Future<bool> toggleArchive(String walletId) async {
    try {
      final wallet = await _repository.getWalletById(walletId);
      if (wallet == null) return false;

      final updatedWallet = wallet.copyWith(isArchived: !wallet.isArchived);
      return await updateWallet(updatedWallet);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // Elimina una wallet
  Future<bool> deleteWallet(String walletId) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await _repository.deleteWallet(walletId);
      state = const AsyncValue.data(null);
      
      if (success) {
        _invalidateProviders();
      }
      
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Sincroniza operaciones pendientes
  Future<void> syncPendingOperations() async {
    try {
      await _repository.syncPendingOperations();
      _invalidateProviders();
    } catch (e) {
      debugPrint('Error sincronizando operaciones: $e');
    }
  }

  // Refresca los datos desde el servidor
  Future<void> refresh() async {
    _invalidateProviders();
  }

  void _invalidateProviders() {
    _ref.invalidate(walletsProvider);
    _ref.invalidate(walletsStreamProvider);
    _ref.invalidate(favoriteWalletsProvider);
    _ref.invalidate(totalBalanceProvider);
  }
}

// Listener de conectividad para sincronización automática
final connectivityListenerProvider = Provider<void>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  
  connectivity.whenData((isConnected) {
    if (isConnected) {
      // Cuando se recupera la conexión, sincroniza
      ref.read(walletNotifierProvider.notifier).syncPendingOperations();
    }
  });
});

// Clase para filtros de wallets
class WalletFilters {
  final bool forceRefresh;
  final bool onlyFavorites;
  final bool includeArchived;

  const WalletFilters({
    this.forceRefresh = false,
    this.onlyFavorites = false,
    this.includeArchived = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletFilters &&
          runtimeType == other.runtimeType &&
          forceRefresh == other.forceRefresh &&
          onlyFavorites == other.onlyFavorites &&
          includeArchived == other.includeArchived;

  @override
  int get hashCode =>
      forceRefresh.hashCode ^
      onlyFavorites.hashCode ^
      includeArchived.hashCode;
}