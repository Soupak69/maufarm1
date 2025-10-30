import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../screens/main/home_Screen.dart';
import '../screens/main/camera_screen.dart';
import '../screens/main/more_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Placeholder(), // Replace with ProductsScreen()
    const CameraScreen(),
    const Placeholder(), // Replace with ChatBotScreen()
    const MoreScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 179, 245, 181),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/botNav_plantLogo.png',
              width: 26,
              height: 26,
              color: Colors.grey,
            ),
            activeIcon: Image.asset(
              'assets/botNav_plantLogo.png',
              width: 26,
              height: 26,
              color: const Color.fromARGB(255, 179, 245, 181),
            ),
            label: 'plants'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.camera_alt),
            label: 'camera'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: 'chat bot'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz),
            label: 'more'.tr(),
          ),
        ],
      ),
    );
  }
}
