import 'package:wallet_app/core/constants/colors.dart';
import 'package:flutter/material.dart';

class CustomModal extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final double heightFactor;

  const CustomModal({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.heightFactor = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: const BoxDecoration(
        color: AppColors.fondoPrincipal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.fondoPrincipal,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.fondoSecundario,
            ),
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(child: child),
          // Actions
          if (actions != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.fondoPrincipal,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 20,
                children: 
                actions!,
              ),
            ),
            const SizedBox(height: 50,)
        ],
      ),
    );
  }
}

// Función helper para mostrar el modal
void showCustomModal({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  double heightFactor = 0.7,
  required Widget child,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      return SizedBox(
        width: mediaQuery.size.width,
        child: CustomModal(
          title: title,
          actions: actions,
          heightFactor: heightFactor,
          child: child,
        ),
      );
    },
  );
}