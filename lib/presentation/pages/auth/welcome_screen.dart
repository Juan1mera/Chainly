import 'package:chainly/core/constants/svgs.dart';
import 'package:flutter/material.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgs.chainlyLabelSvg(width: 300),
              const SizedBox(height: 150,),
              CustomButton(
                text: 'Login', 
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ), 
              ),
              const SizedBox(height: 50,),
              CustomButton(
                text: 'Register', 
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
