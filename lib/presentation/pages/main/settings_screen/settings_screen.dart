import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _launchBuyMeACoffee() async {
    final url = Uri.parse('https://www.buymeacoffee.com/meradev');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail({
    required String subject,
    required String body,
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'mera.dev.co@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    // Guardamos el context ANTES del await
    final BuildContext currentContext = context;

    if (!await canLaunchUrl(emailUri)) {
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de correo')),
      );
      return;
    }

    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error al abrir correo: $e')),
      );
    }
  }

  Future<void> _launchBugReport() async {
    await _openEmail(
      subject: 'Bug Report - Chainly',
      body: 'Describe el problema que encontraste:\n\nVersión de la app: \nDispositivo: \n',
    );
  }

  Future<void> _launchFeatureRequest() async {
    await _openEmail(
      subject: 'Feature Request - Chainly',
      body: 'Me encantaría que Chainly tuviera...\n\n',
    );
  }

  // Función auxiliar para codificar correctamente los parámetros
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(fontFamily: AppFonts.clashDisplay),
        ),
        content: const Text(
          'Se enviará un enlace de recuperación a tu correo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _auth.sendPasswordResetEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enlace enviado al correo')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(
            color: Colors.red,
            fontFamily: AppFonts.clashDisplay,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Esta acción es irreversible.\nIngresa tu contraseña para confirmar:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _auth.reauthenticate(passwordController.text);
      await _auth.deleteCurrentUserAccount();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Account',
                style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Cambiar contraseña',
                onPressed: _changePassword,
                leftIcon: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Cerrar sesión',
                onPressed: _signOut,
                isLoading: _isLoading,
                leftIcon: const Icon(Icons.logout),
                backgroundColor: Colors.grey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Eliminar cuenta',
                onPressed: _deleteAccount,
                isLoading: _isLoading,
                leftIcon: const Icon(Icons.delete_forever, color: Colors.red),
                backgroundColor: Colors.red.withValues(alpha: 0.25),
              ),

              const SizedBox(height: 60),
              const Text(
                'Buy me a coffe',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Text('Help me stay chainly for a bit longer'),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Buy Me a Coffee',
                onPressed: _launchBuyMeACoffee,
                leftIcon: const Icon(BoxIcons.bx_coffee_togo),
                backgroundColor: AppColors.yellow,
              ),

              const SizedBox(height: 60),
              const Text(
                'Requests',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Text('Help me improve (little by little)'),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Request a Feature',
                onPressed: _launchFeatureRequest,
                leftIcon: const Icon(IonIcons.ear),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Report bug',
                onPressed: _launchBugReport,
                leftIcon: const Icon(BoxIcons.bx_bug),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
