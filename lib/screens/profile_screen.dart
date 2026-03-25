import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'edit_profile_screen.dart';
import 'main_screen.dart';
import 'favorite_screen.dart';

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
      backgroundColor: const Color(0xFFFCF5EE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFB3D9),
        elevation: 0,
        title: const Text(
          'โปรไฟล์',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
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
      stream: databaseService.streamUserFlexible(
        uid: user.uid,
        email: user.email,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFFCF5EE),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'โหลดข้อมูลโปรไฟล์ไม่สำเร็จ\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB00020)),
                ),
              ),
            ),
          );
        }

        final userData = snapshot.data;
        final displayName = (userData?.username.isNotEmpty ?? false)
            ? userData!.username
            : (user.displayName ?? 'ไม่ระบุชื่อ');
        final profilePhotoUrl = (userData?.photoUrl?.isNotEmpty ?? false)
            ? userData!.photoUrl
            : user.photoURL;
        final likes = userData?.likes ?? [];
        final dislikes = userData?.dislikes ?? [];
        final allergies = userData?.allergies ?? [];

        final categories = [
          {'title': 'วัตถุดิบที่ชอบ', 'items': likes, 'key': 'likes'},
          {'title': 'วัตถุดิบที่ไม่ชอบ', 'items': dislikes, 'key': 'dislikes'},
          {'title': 'วัตถุดิบที่แพ้', 'items': allergies, 'key': 'allergies'},
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFFCF5EE),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFFFB3D9),
            elevation: 0,
            title: const Text(
              'โปรไฟล์',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
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
                                  image: profilePhotoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(profilePhotoUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: profilePhotoUrl == null
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
                                      displayName,
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
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'แก้ไขโปรไฟล์',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEE6983),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OnboardingScreen(
                                          initialSelections: {
                                            'likes': likes,
                                            'dislikes': dislikes,
                                            'allergies': allergies,
                                          },
                                          initialStep: 1,
                                        ),
                                      ),
                                    );

                                    if (result != null) {
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
                                  icon: const Icon(
                                    Icons.restaurant_menu,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'แก้ไขวัตถุดิบ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFED985F),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                              Text(
                                'ยังไม่ได้เลือก',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
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
                            if (!isEmpty) ...[const SizedBox(height: 4)],
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FavoriteScreen(
                                onBack: () => Navigator.of(context).pop(),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Color(0xFFEE6983),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'เมนูที่กดถูกใจ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ดูรายการอาหารที่คุณบันทึกเป็นเมนูโปรด',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF999999),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
