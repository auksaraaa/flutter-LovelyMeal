import 'package:flutter/material.dart';
import '../widgets/nav_bar.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'random_screen.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _openRandomScreen(CategoryModel? category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => RandomDetailScreen(
          selectedCategory: category,
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _openFavoriteRandomScreen() {
    if (AuthService.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนใช้งานสุ่มเมนูโปรด'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => RandomDetailScreen(
          favoriteOnly: true,
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  List<Widget> get _screens => [
    HomeScreen(
      onRandomClick: _openRandomScreen,
      onFavoriteRandomClick: _openFavoriteRandomScreen,
      isUserLoggedIn: AuthService.currentUserId != null,
    ),
    const CalendarScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
