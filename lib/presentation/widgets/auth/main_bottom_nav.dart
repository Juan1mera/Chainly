// lib/main_bottom_nav.dart
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/presentation/pages/main/home_screen/home_screen.dart';
import 'package:wallet_app/presentation/pages/main/profile_screen/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/presentation/pages/main/stats_screen/stats_screen.dart';
import 'package:wallet_app/presentation/pages/main/wallets_screen/wallets_screen.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({super.key});

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WalletsScreen(),
    const StatsScreen(),
    const ProfileScreen(),
  ];

  final List<NavItem> _navItems = [
    NavItem(icon: Icons.home, label: 'Principal'),
    NavItem(icon: Icons.pets, label: 'Animales'),
    NavItem(icon: Icons.store, label: 'Tienda'),
    NavItem(icon: Icons.person, label: 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {  
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward().then((_) {
        _animationController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoSecundario,
      // extendBody permite que el contenido se extienda detrás del bottomNavigationBar
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.transparent, // Asi el fondo sera transparente
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.fondoSecundario, // Fondo de la pastilla
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _selectedIndex;

              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 20 : 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.verdeLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isSelected && _animationController.isAnimating
                            ? _scaleAnimation.value
                            : 1.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected
                                  ? AppColors.fondoPrincipal
                                  : Color.fromRGBO(255, 255, 255, 0.6),
                              size: 24,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: isSelected ? 1.0 : 0.0,
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: AppColors.fondoPrincipal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;

  NavItem({required this.icon, required this.label});
}