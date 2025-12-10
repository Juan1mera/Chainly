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

  // Open Buy Me a Coffee in external browser
  Future<void> _launchBuyMeACoffee() async {
    final url = Uri.parse('https://www.buymeacoffee.com/meradev');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Reusable email launcher (safe from async context issues)
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

    final BuildContext ctx = context; // Capture context before async

    if (!await canLaunchUrl(emailUri)) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('No email app found')),
      );
      return;
    }

    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error opening email: $e')),
      );
    }
  }

  Future<void> _launchBugReport() async => _openEmail(
        subject: '[Bug Report] Chainly',
        body:
            'Please describe the bug you encountered:\n\nApp version:\nDevice:\nSteps to reproduce:\n\n',
      );

  Future<void> _launchFeatureRequest() async => _openEmail(
        subject: '[Feature Request] Chainly',
        body: 'I would love to see this feature in Chainly:\n\n',
      );

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // Sign Out
  Future<void> _signOut() async {
    // Mostrar diálogo de confirmación
    final bool shouldSignOut = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.white.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Log out',
              style: TextStyle(fontFamily: AppFonts.clashDisplay),
            ),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false; // Si el usuario cierra el diálogo tocando fuera → false

    // Si no confirmó, salir sin hacer nada
    if (!shouldSignOut) return;

    // Si confirmó proceder con el logout
    setState(() => _isLoading = true);

    try {
      await _auth.signOut();

      // Verificamos mounted antes de navegar
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Change Password
  Future<void> _changePassword() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Change Password',
          style: TextStyle(fontFamily: AppFonts.clashDisplay),
        ),
        content: const Text('A password reset link will be sent to your email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _auth.sendPasswordResetEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link sent to your email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  // Delete Account
  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontFamily: AppFonts.clashDisplay),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is permanent and cannot be undone.\nEnter your password to confirm:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: 'Change Password',
                onPressed: _changePassword,
                leftIcon: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: 12),

              CustomButton(
                text: 'Log Out',
                onPressed: _signOut,
                isLoading: _isLoading,
                leftIcon: const Icon(Icons.logout),
                backgroundColor: Colors.grey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),

              CustomButton(
                text: 'Delete Account',
                onPressed: _deleteAccount,
                isLoading: _isLoading,
                leftIcon: const Icon(Icons.delete_forever, color: Colors.red),
                backgroundColor: Colors.red.withValues(alpha: 0.25),
              ),

              const SizedBox(height: 60),
              const Text(
                'Support the Project',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
              ),
              const Text('Help me keep Chainly alive a little longer'),
              const SizedBox(height: 12),

              CustomButton(
                text: 'Buy Me a Coffee',
                onPressed: _launchBuyMeACoffee,
                leftIcon: const Icon(BoxIcons.bx_coffee_togo),
                backgroundColor: AppColors.yellow,
              ),

              const SizedBox(height: 60),
              const Text(
                'Feedback',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
              ),
              const Text('Help me improve the app step by step'),
              const SizedBox(height: 12),

              CustomButton(
                text: 'Request a Feature',
                onPressed: _launchFeatureRequest,
                leftIcon: const Icon(IonIcons.ear),
              ),
              const SizedBox(height: 12),

              CustomButton(
                text: 'Report a Bug',
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