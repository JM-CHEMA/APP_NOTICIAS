import 'package:flutter/material.dart';

/// Componente único de navegación de NEXO (sin lógica de pantallas).
class AppBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const AppBottomNavigation({super.key, required this.selectedIndex,
    required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) => NavigationBar(
    height: 70,
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
      NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Guardados'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
    ],
  );
}
