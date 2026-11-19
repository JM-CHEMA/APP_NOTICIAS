import 'package:flutter/material.dart';

import '../components/app_bottom_navigation.dart';

import '../../news/screens/home_screen.dart';
import '../../news/screens/search_screen.dart';
import '../../news/screens/bookmarks_screen.dart';

import '../../radio/screens/home_screen.dart' as radio;

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
    body: IndexedStack(
      index: _index,
      children: [
        HomeScreen(onSearchTap: () => setState(() => _index = 1)),
        const SearchScreen(),
        const BookmarksScreen(),
        radio.HomeScreen(),
        ProfileScreen(onOpenSaved: () => setState(() => _index = 2)),
      ],
    ),
    bottomNavigationBar: AppBottomNavigation(
      selectedIndex: _index,
      onDestinationSelected: (index) => setState(() => _index = index),
    ),
  );
}
