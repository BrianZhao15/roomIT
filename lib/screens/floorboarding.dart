import 'package:flutter/material.dart';
import 'layout-lounge.dart';
import 'scene-it.dart';
import 'design-deck.dart';

class FloorboardingContent extends StatelessWidget {
  const FloorboardingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Image Placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
            // Text Section
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 24),
              child: Column(
                children: [
                  Text(
                    'Make your roomITs best self',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Design your room with our tools to your style and liking',
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text('Sign Up'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signin');
                      },
                      child: const Text('Sign In'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class FloorboardingScreen extends StatefulWidget {
const FloorboardingScreen({Key? key}) : super(key: key);

@override
State<FloorboardingScreen> createState() => _FloorboardingScreenState();
}

class _FloorboardingScreenState extends State<FloorboardingScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    FloorboardingContent(),
    LayoutLoungeScreen(),
    SceneItScreen(),
    DesignDeckScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == 0 ? 0 : _selectedIndex - 1,
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