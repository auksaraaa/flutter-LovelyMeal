import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'edit_profile_screen.dart';
import 'main_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return _buildLoginPrompt(context);
        }

        return _buildProfileContent(context);
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 24),
                const Text(
                  'กรุณาเข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'เข้าสู่ระบบเพื่อดูโปรไฟล์และจัดการข้อมูลของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEE6983),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    final AuthService authService = AuthService();
    final DatabaseService databaseService = DatabaseService();
    final user = authService.currentUser;

    if (user == null) {
      return _buildLoginPrompt(context);
    }

    return StreamBuilder<UserModel?>(
      stream: databaseService.streamUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data;
        final likes = userData?.likes ?? [];
        final dislikes = userData?.dislikes ?? [];
        final allergies = userData?.allergies ?? [];

        final categories = [
          {'title': 'อาหารที่ชอบ', 'items': likes, 'key': 'likes'},
          {'title': 'อาหารที่ไม่ชอบ', 'items': dislikes, 'key': 'dislikes'},
          {'title': 'อาหารที่แพ้', 'items': allergies, 'key': 'allergies'},
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFFCF5EE),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  children: [
                    // Profile Header - แก้ไขส่วนนี้
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Avatar
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1D1D1),
                                  shape: BoxShape.circle,
                                  image: user.photoURL != null
                                      ? DecorationImage(
                                          image: NetworkImage(user.photoURL!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: user.photoURL == null
                                    ? Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey[600],
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 20),
                              // User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName ?? 'ไม่ระบุชื่อ',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Edit Profile Button - ย้ายออกมาจาก Stack
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEE6983),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'แก้ไขโปรไฟล์',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Divider
                          Container(
                            height: 1.5,
                            color: const Color(0xFFD9D9D9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Profile Cards
                    ...categories.map((category) {
                      final categoryItems = category['items'] as List<String>;
                      final isEmpty = categoryItems.isEmpty;

                      return Container(
                        width: 335,
                        margin: const EdgeInsets.symmetric(vertical: 15),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 0.5,
                              color: const Color(0xFFD9D9D9),
                            ),
                            const SizedBox(height: 12),
                            if (isEmpty)
                              Column(
                                children: [
                                  Text(
                                    'ยังไม่ได้เลือก',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // กำหนด step ตามหมวดหมู่
                                        int targetStep = 1;
                                        if (category['key'] == 'likes') {
                                          targetStep = 1;
                                        } else if (category['key'] ==
                                            'dislikes') {
                                          targetStep = 2;
                                        } else if (category['key'] ==
                                            'allergies') {
                                          targetStep = 3;
                                        }

                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OnboardingScreen(
                                                  initialSelections: {
                                                    'likes': likes,
                                                    'dislikes': dislikes,
                                                    'allergies': allergies,
                                                  },
                                                  initialStep: targetStep,
                                                ),
                                          ),
                                        );
                                        if (result != null && user != null) {
                                          await databaseService
                                              .updateFoodPreferences(
                                                uid: user.uid,
                                                likes: List<String>.from(
                                                  result['likes'] ?? [],
                                                ),
                                                dislikes: List<String>.from(
                                                  result['dislikes'] ?? [],
                                                ),
                                                allergies: List<String>.from(
                                                  result['allergies'] ?? [],
                                                ),
                                              );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'บันทึกข้อมูลสำเร็จ',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4CAF50,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        '+ เพิ่มรายการ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: categoryItems
                                    .map(
                                      (item) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0E0E0),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          item,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            if (!isEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                height: 0.5,
                                color: const Color(0xFFD9D9D9),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // กำหนด step ตามหมวดหมู่
                                    int targetStep = 1;
                                    if (category['key'] == 'likes') {
                                      targetStep = 1;
                                    } else if (category['key'] == 'dislikes') {
                                      targetStep = 2;
                                    } else if (category['key'] == 'allergies') {
                                      targetStep = 3;
                                    }

                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OnboardingScreen(
                                          initialSelections: {
                                            'likes': likes,
                                            'dislikes': dislikes,
                                            'allergies': allergies,
                                          },
                                          initialStep: targetStep,
                                        ),
                                      ),
                                    );
                                    if (result != null && user != null) {
                                      await databaseService
                                          .updateFoodPreferences(
                                            uid: user.uid,
                                            likes: List<String>.from(
                                              result['likes'] ?? [],
                                            ),
                                            dislikes: List<String>.from(
                                              result['dislikes'] ?? [],
                                            ),
                                            allergies: List<String>.from(
                                              result['allergies'] ?? [],
                                            ),
                                          );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('บันทึกข้อมูลสำเร็จ'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFED985F),
                                    minimumSize: const Size(57, 30),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    elevation: 2,
                                    shadowColor: const Color(
                                      0xFFED985F,
                                    ).withOpacity(0.3),
                                  ),
                                  child: const Text(
                                    'แก้ไข',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 30),
                    // Logout Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              // Navigate ก่อนแล้วค่อย signOut เพื่อไม่ให้ StreamBuilder rebuild
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(),
                                ),
                                (route) => false,
                              );
                              await authService.signOut();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF5350),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: const Color(
                              0xFFEF5350,
                            ).withOpacity(0.3),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'ออกจากระบบ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
