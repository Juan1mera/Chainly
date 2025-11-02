import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Login con Email y Contraseña
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Crear usuario con Email, Contraseña y Nombre
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'display_name': name, 
      },
    );

    // Actualizar el perfil del usuario
    if (response.user != null) {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'display_name': name,
          },
        ),
      );
    }

    return response;
  }

  // signOut
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Obtener el Usuario
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  // Obtener el nombre del usuario
  String? getCurrentUserName() {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['name'] as String? ?? 
           user?.userMetadata?['display_name'] as String?;
  }

  // Stream para escuchar cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Actualizar perfil
  Future<void> updateProfile({
    String? name,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name;
      updates['display_name'] = name;
    }

    await _supabase.auth.updateUser(
      UserAttributes(
        data: updates.isNotEmpty ? updates : null,
        phone: phone,
      ),
    );
  }
}