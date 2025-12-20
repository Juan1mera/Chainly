import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider del usuario actual
final currentUserProvider = StateProvider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// Provider del ID del usuario actual
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

// Provider del email del usuario actual
final currentUserEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

// Stream provider del estado de autenticación
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Notifier para operaciones de autenticación
final authNotifierProvider = 
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _ref.read(currentUserProvider.notifier).state = response.user;
        state = const AsyncValue.data(null);
        return true;
      }

      state = AsyncValue.error('Error al iniciar sesión', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _ref.read(currentUserProvider.notifier).state = response.user;
        state = const AsyncValue.data(null);
        return true;
      }

      state = AsyncValue.error('Error al registrarse', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      await _supabase.auth.signOut();
      _ref.read(currentUserProvider.notifier).state = null;
      
      // Limpia la base de datos local al cerrar sesión
      // await _ref.read(localDatabaseProvider).clearAllData();
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}