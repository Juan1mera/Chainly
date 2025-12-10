import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'display_name': name},
    );

    if (response.user != null) {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'name': name, 'display_name': name}),
      );
    }
    return response;
  }

  Future<void> signOut() async => await _supabase.auth.signOut();

  String? get currentUserEmail => _supabase.auth.currentSession?.user.email;

  String? get currentUserName {
    final meta = _supabase.auth.currentUser?.userMetadata;
    return meta?['name'] ?? meta?['display_name'];
  }

  String? get currentUserAvatarUrl => _supabase.auth.currentUser?.userMetadata?['avatar_url'];

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> sendPasswordResetEmail() async {
    final email = currentUserEmail;
    if (email == null) throw Exception('No hay usuario autenticado');
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> deleteCurrentUserAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');

    try {
      await deleteProfilePicture();
      await _supabase.rpc('delete_current_user');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reauthenticate(String password) async {
    final email = currentUserEmail;
    if (email == null) throw Exception('No hay email disponible');
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name;
      updates['display_name'] = name;
    }
    if (updates.isEmpty && phone == null) return;

    await _supabase.auth.updateUser(
      UserAttributes(data: updates.isNotEmpty ? updates : null, phone: phone),
    );
  }

  Future<String> uploadProfilePicture() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, maxHeight: 300);
    if (imageFile == null) throw Exception('No se seleccionó imagen');

    final bytes = await imageFile.readAsBytes();
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: imageFile.mimeType, upsert: true),
        );

    final url = _supabase.storage.from('avatars').getPublicUrl(fileName);
    await _supabase.auth.updateUser(UserAttributes(data: {'avatar_url': url}));
    return url;
  }

  Future<void> deleteProfilePicture() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final url = user.userMetadata?['avatar_url'] as String?;
    if (url == null) return;

    final fileName = Uri.parse(url).pathSegments.last;
    if (fileName.isEmpty) return;

    await _supabase.storage.from('avatars').remove([fileName]);
    await _supabase.auth.updateUser(UserAttributes(data: {'avatar_url': null}));
  }
}