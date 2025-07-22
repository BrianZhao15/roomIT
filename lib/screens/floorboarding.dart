import 'package:flutter/material.dart';
import 'layout-lounge.dart';
import 'scene-it.dart';
import 'design-deck.dart';

class FloorboardingScreen extends StatefulWidget {
const FloorboardingScreen({Key? key}) : super(key: key);

@override
State<FloorboardingScreen> createState() => _FloorboardingScreenState();
}

class _FloorboardingScreenState extends State<FloorboardingScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    LayoutLoungeScreen(),
    SceneItScreen(),
    DesignDeckScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.living),
            label: 'Layout Lounge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.theaters),
            label: 'Scene It',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.design_services),
            label: 'Design Deck',
          ),
        ],
      ),
    );
  }
}