import 'dart:async';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/presentation/pages/auth/login_screen.dart';
import 'package:wallet_app/presentation/widgets/navigation/main_drawer_nav.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_button.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_text_field.dart';
import 'package:wallet_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _redirecting = false;
  List<String> _errors = [];
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = _authService.authStateChanges.listen(
      (data) {
        if (_redirecting) return;
        final session = data.session;
        if (session != null && mounted) {
          _redirecting = true;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainDrawerNav()),
            (route) => false,
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            if (error is AuthException) {
              _errors = [error.message];
            } else {
              _errors = ['Error inesperado'];
            }
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errors.clear();
    });

    try {
      await _authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      // La navegación se manejará por el listener de authStateChanges
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errors = [e.message];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errors = ['Error: ${e.toString()}'];
          _isLoading = false;
        });
      }
    }
  }

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // === HEADER CON LOGO Y PERRO ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 30),
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: SvgPicture.asset(
                      'assets/Icon.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        AppColors.fondoSecundario,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    height: 190,
                    child: SvgPicture.asset(
                      'assets/animals_login/dog.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        AppColors.fondoSecundario,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),

              // Textos de bienvenida
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Crea tu cuenta!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Synonym',
                        color: AppColors.fondoSecundario,
                      ),
                    ),
                    const Text(
                      'Regístrate en wallet_app',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Synonym',
                        color: AppColors.fondoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Únete a nuestra comunidad veterinaria',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Chillax-Extralight',
                        color: AppColors.fondoSecundario,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Completa tus datos para comenzar',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Chillax-Extralight',
                        color: AppColors.fondoSecundario,
                      ),
                    ),
                  ],
                ),
              ),

              // === ERRORES ===
              if (_errors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  child: Column(
                    children: _errors
                        .map((err) => Text(
                              err,
                              style: const TextStyle(
                                color: AppColors.rojo,
                                fontSize: 14,
                                fontFamily: 'Chillax-Extralight',
                              ),
                            ))
                        .toList(),
                  ),
                ),

              // === FORMULARIO ===
              CustomTextField(
                hintText: 'Nombre completo',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                onChanged: (value) => setState(() {}),
                controller: _nameController,
              ),
              CustomTextField(
                hintText: 'Correo electrónico',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => setState(() {}),
                controller: _emailController,
              ),
              CustomTextField(
                hintText: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: true,
                onChanged: (value) => setState(() {}),
                controller: _passwordController,
              ),

              const SizedBox(height: 16),

              // Botón Registrarse
              Center(
                child: CustomButton(
                  text: 'Regístrate',
                  onPressed: _isFormValid() ? _register : null,
                  bgColor: AppColors.verdeLight,
                  textColor: AppColors.fondoSecundario,
                  isLoading: _isLoading,
                ),
              ),

              const SizedBox(height: 16),
              const Divider(
                color: AppColors.fondoSecundario,
                thickness: 2,
                indent: 20,
                endIndent: 20,
              ),

              // Texto "¿Ya tienes cuenta?"
              const Center(
                child: Text(
                  '¿Ya tienes una cuenta? Inicia sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Chillax-Extralight',
                    color: AppColors.fondoSecundario,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Botón Iniciar Sesión
              Center(
                child: CustomButton(
                  text: 'Iniciar sesión',
                  onPressed: _isLoading ? null : () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  bgColor: AppColors.fondoSecundario,
                  textColor: AppColors.fondoPrincipal,
                ),
              ),

              // === FOOTER CON VACA Y GATO ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 160,
                    child: SvgPicture.asset(
                      'assets/animals_login/cow.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        AppColors.fondoSecundario,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 160,
                    child: SvgPicture.asset(
                      'assets/animals_login/cat.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        AppColors.fondoSecundario,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}