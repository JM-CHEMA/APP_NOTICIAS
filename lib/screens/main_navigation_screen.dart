import 'package:flutter/material.dart';
import '../components/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'bookmarks_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: [
      HomeScreen(onSearchTap: () => setState(() => _index = 1)),
      const SearchScreen(),
      const BookmarksScreen(),
      ProfileScreen(onOpenSaved: () => setState(() => _index = 2)),
    ]),
    bottomNavigationBar: AppBottomNavigation(
      selectedIndex: _index,
      onDestinationSelected: (index) => setState(() => _index = index),
    ),
  );
}
