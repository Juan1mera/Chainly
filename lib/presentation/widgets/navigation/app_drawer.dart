// lib/presentation/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.black,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.purple,
            ),
            child: Center(
              child: Text(
                'Wallet App',
                style: TextStyle(
                  color: AppColors.background4,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Opciones del menú
          _buildDrawerItem(
            context,
            index: 0,
            icon: Icons.home,
            title: 'Home',
            isSelected: currentIndex == 0,
          ),
          _buildDrawerItem(
            context,
            index: 1,
            icon: Icons.wallet,
            title: 'Wallets',
            isSelected: currentIndex == 1,
          ),
          _buildDrawerItem(
            context,
            index: 2,
            icon: Icons.view_kanban_outlined,
            title: 'Stats',
            isSelected: currentIndex == 2,
          ),
          _buildDrawerItem(
            context,
            index: 3,
            icon: Icons.person,
            title: 'Profile',
            isSelected: currentIndex == 3,
          ),

          const Spacer(),

          // Versión o info adicional (opcional)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'v1.0.0',
              style: TextStyle(color: AppColors.greyDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required bool isSelected,
  }) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.purple.withValues(alpha: .3),
      leading: Icon(
        icon,
        color: isSelected ? AppColors.white : AppColors.greyDark,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.white : AppColors.greyDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      onTap: () {
        onItemTapped(index);
        Navigator.pop(context); // Cierra el drawer
      },
    );
  }
}