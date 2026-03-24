import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/food_model.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';

class FavoriteScreen extends StatefulWidget {
  final VoidCallback onBack;

  const FavoriteScreen({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  String get userId => AuthService.currentUserId ?? '';
  List<FoodModel> favorites = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    try {
      if (userId.isEmpty) {
        if (!mounted) return;
        setState(() => favorites = []);
        return;
      }

      final resolvedFoods = await FavoriteService.getFavoriteFoods(userId);

      if (!mounted) return;
      setState(() {
        favorites = resolvedFoods;
      });
    } catch (err) {
      debugPrint('Error fetching favorites: $err');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> handleRemoveFavorite(FoodModel food) async {
    try {
      if (userId.isEmpty) return;

      await FavoriteService.removeFavorite(userId, food.id);

      // Fetch ข้อมูลใหม่จาก Firebase แทนการลบใน local state
      await fetchFavorites();
    } catch (err) {
      debugPrint('ลบเมนูโปรดไม่สำเร็จ: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF8E1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft, size: 24),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          widget.onBack();
                        }
                      },
                      color: const Color(0xFF333333),
                    ),
                    Text(
                      'เมนูโปรด',
                      style: GoogleFonts.sarabun(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      '(${favorites.length})',
                      style: GoogleFonts.sarabun(
                        fontSize: 14,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: loading
                    ? Center(
                        child: Text(
                          'กำลังโหลด...',
                          style: GoogleFonts.sarabun(
                            fontSize: 16,
                            color: const Color(0xFF999999),
                          ),
                        ),
                      )
                    : favorites.isEmpty
                        ? Center(
                            child: Text(
                              'ยังไม่มีเมนูโปรด',
                              style: GoogleFonts.sarabun(
                                fontSize: 16,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: favorites.length,
                            itemBuilder: (context, index) {
                              final food = favorites[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              food.image,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.error),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  food.title,
                                                  style: GoogleFonts.sarabun(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF333333),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: food.category.map((cat) {
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFF2F2),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        cat,
                                                        style: GoogleFonts.sarabun(
                                                          fontSize: 12,
                                                          color: const Color(0xFFFF6B6B),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Trash button
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: InkWell(
                                        onTap: () => handleRemoveFavorite(food),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            LucideIcons.trash2,
                                            size: 16,
                                            color: Color(0xFFFF6B6B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}