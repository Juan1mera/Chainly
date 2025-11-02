import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_button.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      setState(() {
        _user = currentUser;
        final metadata = currentUser?.userMetadata ?? {};
        final name = metadata['display_name'] ?? metadata['name'];
        setState(() {
          _displayName = name;
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'No disponible';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Future<bool> _showSignOutDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Mi Perfil',
        onPress: () async {
          if (await _showSignOutDialog()) {
            await _authService.signOut();
          }
        },
        iconOnPress: Icons.logout,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'No se pudo cargar la información del usuario',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadUserData();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.verdeLight,
                                child: Text(
                                  _user!.email != null && _user!.email!.isNotEmpty
                                      ? _user!.email![0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _authService.getCurrentUserName() ?? _user!.email ?? 'Usuario',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Información de la Cuenta',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: _user!.email ?? 'No disponible',
                                ),
                                _buildInfoRow(
                                  icon: Icons.person,
                                  label: 'Nombre',
                                  value: _displayName ?? 'Nombre no disponible',
                                ),
                                _buildInfoRow(
                                  icon: Icons.fingerprint,
                                  label: 'ID de Usuario',
                                  value: _user!.id,
                                ),
                                _buildInfoRow(
                                  icon: Icons.phone,
                                  label: 'Teléfono',
                                  value: _user!.phone ?? 'No configurado',
                                ),
                                _buildInfoRow(
                                  icon: Icons.calendar_today,
                                  label: 'Cuenta creada',
                                  value: _formatDate(_user!.createdAt),
                                ),
                                _buildInfoRow(
                                  icon: Icons.access_time,
                                  label: 'Último acceso',
                                  value: _formatDate(_user!.lastSignInAt),
                                ),
                                _buildInfoRow(
                                  icon: Icons.verified_user,
                                  label: 'Email verificado',
                                  value: _user!.emailConfirmedAt != null ? 'Sí' : 'No',
                                  valueColor: _user!.emailConfirmedAt != null ? Colors.green : Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Cerrar Sesión',
                          onPressed: () async {
                            if (await _showSignOutDialog()) {
                              await _authService.signOut();
                            }
                          },
                          bgColor: AppColors.rojo,
                          textColor: AppColors.fondoPrincipal,
                          leftIcon: const Icon(Icons.logout),
                        ),
                        const SizedBox(height: 100,)
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}