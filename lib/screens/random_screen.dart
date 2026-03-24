import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/food_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import 'home_screen.dart';

class RandomDetailScreen extends StatefulWidget {
  final VoidCallback onBack;
  final CategoryModel? selectedCategory;
  final bool favoriteOnly;

  const RandomDetailScreen({
    Key? key,
    required this.onBack,
    this.selectedCategory,
    this.favoriteOnly = false,
  }) : super(key: key);

  @override
  State<RandomDetailScreen> createState() => _RandomDetailScreenState();
}

class _RandomDetailScreenState extends State<RandomDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool isLiked = false;
  FoodModel? currentFood;
  bool loading = true;
  List<FoodModel> allFoods = [];
  List<FoodModel> shuffledFoods = []; // รายการที่ shuffle แล้ว
  Set<String> selectedFoodIds = {}; // เมนูที่เลือกไปแล้ว (เก็บ ID)
  bool imageLoaded = false;
  UserModel? userProfile;
  late Random random; // Random instance สำหรับการสุ่มที่ควบคุมได้
  static final Map<String, List<String>> _selectedIdsBySession = {};
  static final Map<String, String> _lastFoodIdBySession = {};

  String get userId => AuthService.currentUserId ?? '';

  String get _dateKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String get _categoryKey {
    if (widget.favoriteOnly) return '__favorite__';
    return widget.selectedCategory?.title ?? '__all__';
  }

  String get _sessionKey {
    final uid = AuthService.currentUserId ?? 'guest';
    return '$uid|$_categoryKey|$_dateKey';
  }

  String get _screenTitle {
    if (widget.favoriteOnly) return 'สุ่มเมนูโปรด';
    return widget.selectedCategory?.title ?? 'สุ่มทุกหมวด';
  }

  void _clearSessionProgress() {
    _selectedIdsBySession.remove(_sessionKey);
    _lastFoodIdBySession.remove(_sessionKey);
    selectedFoodIds.clear();
  }

  Set<String> _restoreSelectedFoodIds(List<FoodModel> foods) {
    final validIds = foods.map((food) => food.id).toSet();
    final savedIds = _selectedIdsBySession[_sessionKey] ?? const <String>[];
    return savedIds.where(validIds.contains).toSet();
  }

  FoodModel? _findFoodById(List<FoodModel> foods, String? foodId) {
    if (foodId == null || foodId.isEmpty) return null;
    for (final food in foods) {
      if (food.id == foodId) {
        return food;
      }
    }
    return null;
  }

  void _rememberSessionProgress() {
    _selectedIdsBySession[_sessionKey] = selectedFoodIds.toList(
      growable: false,
    );

    if (currentFood != null) {
      _lastFoodIdBySession[_sessionKey] = currentFood!.id;
    } else {
      _lastFoodIdBySession.remove(_sessionKey);
    }
  }

  @override
  void initState() {
    super.initState();
    // สร้าง Random instance ด้วย
    // จากวันที่ปัจจุบัน + userId (ให้แต่ละคนได้ลำดับเฉพาะตัว)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final userId = AuthService.currentUserId ?? 'guest';
    random = Random(today.millisecondsSinceEpoch + userId.hashCode);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      if (AuthService.currentUserId != null) {
        userProfile = await _databaseService.getUser(
          AuthService.currentUserId!,
        );
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      if (widget.favoriteOnly) {
        fetchFavoriteFoods();
      } else {
        fetchFoodsFromFirebase(); // ใช้ Firebase สำหรับการสุ่มเมนู
      }
    }
  }

  List<FoodModel> _filterFoodsByPreferences(List<FoodModel> foods) {
    if (userProfile == null) return foods;

    return foods.where((food) {
      // ตัดอาหารที่แพ้ออก (ลำดับความสำคัญสูงสุด)
      for (var allergen in userProfile!.allergies) {
        if (food.title.contains(allergen) ||
            food.ingredients.any((ing) => ing.contains(allergen))) {
          debugPrint('🔴 Filtered out "${food.title}" - แพ้: $allergen');
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool _containsAny(List<String> source, List<String> targets) {
    for (final t in targets) {
      if (source.contains(t)) return true;
    }
    return false;
  }

  double _calculateScore(
    FoodModel food,
    List<String> likedIngredients,
    List<String> dislikedIngredients,
  ) {
    double score = 0;

    // วัตถุดิบที่ชอบ
    for (final like in likedIngredients) {
      if (food.ingredients.contains(like)) {
        score += 3;
      }
    }

    // วัตถุดิบที่ไม่ชอบ
    for (final dislike in dislikedIngredients) {
      if (food.ingredients.contains(dislike)) {
        score -= 2;
      }
    }

    // เพิ่มความสุ่มเล็กน้อย
    score += random.nextDouble();

    // กันติดลบ
    if (score < 0) score = 0;

    return score;
  }

  List<FoodModel> _getSortedAndShuffledFoods(
    List<FoodModel> foods,
    List<String> likedIngredients,
    List<String> dislikedIngredients,
    List<String> allergicIngredients,
  ) {
    // 1. ตัดของที่แพ้ออกก่อน
    final filteredFoods = foods.where((food) {
      return !_containsAny(food.ingredients, allergicIngredients);
    }).toList();

    // กันเคสไม่มีเมนูเหลือ
    if (filteredFoods.isEmpty) {
      throw Exception("ไม่มีเมนูที่ปลอดภัยสำหรับผู้ใช้");
    }

    // 2. ให้คะแนนแต่ละเมนู
    final scoredFoods = filteredFoods.map((food) {
      final score = _calculateScore(
        food,
        likedIngredients,
        dislikedIngredients,
      );
      return _ScoredFood(food: food, score: score);
    }).toList();

    // 3. จัดเรียงตามคะแนนจากมากไปน้อย (สำหรับ weighted sampling)
    scoredFoods.sort((a, b) => b.score.compareTo(a.score));

    // 4. สร้างรายการเพื่อ weighted random sampling
    // ยิ่งคะแนนสูงต้องลดเลขฐาน ยิ่งเข้าหน้า (มี index ต่ำ)
    final List<FoodModel> result = [];
    final remaining = List<_ScoredFood>.from(scoredFoods);

    // สร้างลำดับแบบ weighted - ดึงรายการค่าสูง/ปานกลางมาก่อน
    // แล้วค่อย ๆ ดึงค่าต่ำ
    while (remaining.isNotEmpty) {
      // สุ่มตัวถัง weighted - เมนูที่มีคะแนนสูง + ต้นรายการ มี index ต่ำ
      // ให้สูตร: probability = 1 / (index + 1) ยิ่งต้นรายการยิ่งสูง
      double totalWeight = 0;
      final weights = <double>[];
      for (int i = 0; i < remaining.length; i++) {
        final weight = 1.0 / (i + 1);
        weights.add(weight);
        totalWeight += weight;
      }

      // เลือกแบบ weighted
      double randomValue = random.nextDouble() * totalWeight;
      double cumulative = 0;
      int selectedIndex = 0;
      for (int i = 0; i < weights.length; i++) {
        cumulative += weights[i];
        if (randomValue <= cumulative) {
          selectedIndex = i;
          break;
        }
      }

      result.add(remaining[selectedIndex].food);
      remaining.removeAt(selectedIndex);
    }

    debugPrint(
      '🎯 Weighted shuffled foods count: ${result.length} (weighted by score + position)',
    );
    return result;
  }

  FoodModel _pickNextFood(List<FoodModel> foods, Set<String> alreadySelected) {
    // สร้างรายการที่เหลือ (ยังไม่เลือก)
    final remaining = foods
        .where((f) => !alreadySelected.contains(f.id))
        .toList();

    // ถ้าเลือกครบแล้ว ให้รีเซ็ต
    if (remaining.isEmpty) {
      alreadySelected.clear();
      remaining.addAll(foods);
    }

    // สุ่มแบบ weighted ตามลำดับใน remaining
    // เมนูที่อยู่หน้า (index ต่ำ) มีโอกาสสูงกว่า
    double totalWeight = 0;
    final weights = <double>[];
    for (int i = 0; i < remaining.length; i++) {
      final weight = 1.0 / (i + 1);
      weights.add(weight);
      totalWeight += weight;
    }

    double randomValue = random.nextDouble() * totalWeight;
    double cumulative = 0;
    int selectedIndex = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (randomValue <= cumulative) {
        selectedIndex = i;
        break;
      }
    }

    final selected = remaining[selectedIndex];
    alreadySelected.add(selected.id);
    debugPrint(
      '🎯 Picked: "${selected.title}" (${alreadySelected.length}/${foods.length})',
    );
    return selected;
  }

  Future<void> fetchFavoriteFoods() async {
    try {
      setState(() => loading = true);

      if (AuthService.currentUserId == null) {
        _clearSessionProgress();
        if (!mounted) return;
        setState(() {
          allFoods = [];
          shuffledFoods = [];
          currentFood = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'กรุณาเข้าสู่ระบบเพื่อสุ่มเมนูโปรด',
              style: GoogleFonts.sarabun(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final foods = await FavoriteService.getFavoriteFoods(userId);

      if (!mounted) return;

      if (foods.isEmpty) {
        _clearSessionProgress();
        setState(() {
          allFoods = [];
          shuffledFoods = [];
          currentFood = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ยังไม่มีเมนูโปรดสำหรับสุ่ม กรุณากดหัวใจที่เมนูที่ชอบก่อน',
              style: GoogleFonts.sarabun(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final filteredFoods = _filterFoodsByPreferences(foods);
      if (filteredFoods.isEmpty) {
        _clearSessionProgress();
        setState(() {
          allFoods = [];
          shuffledFoods = [];
          currentFood = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เมนูโปรดที่บันทึกไว้ไม่ตรงกับข้อจำกัดอาหารของคุณ',
              style: GoogleFonts.sarabun(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() {
        allFoods = filteredFoods;
        if (filteredFoods.isNotEmpty) {
          try {
            shuffledFoods = _getSortedAndShuffledFoods(
              filteredFoods,
              userProfile?.likes ?? [],
              userProfile?.dislikes ?? [],
              userProfile?.allergies ?? [],
            );

            selectedFoodIds = _restoreSelectedFoodIds(shuffledFoods);
            final savedFood = _findFoodById(
              shuffledFoods,
              _lastFoodIdBySession[_sessionKey],
            );

            if (savedFood != null) {
              selectedFoodIds.add(savedFood.id);
            }
            currentFood = _pickNextFood(shuffledFoods, selectedFoodIds);
            imageLoaded = false;
          } catch (e) {
            debugPrint('Error getting random favorite food: $e');
            currentFood = null;
            shuffledFoods = [];
            _clearSessionProgress();
          }
        }
      });

      _rememberSessionProgress();

      if (currentFood != null) {
        await checkFavorite();
      }
    } catch (err) {
      debugPrint('Error fetching favorite foods: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการโหลดเมนูโปรด: $err',
              style: GoogleFonts.sarabun(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> fetchFoodsFromJson() async {
    try {
      setState(() => loading = true);

      debugPrint('========== FETCH FOODS FROM JSON ==========');
      debugPrint(
        'Selected Category: ${widget.selectedCategory?.title ?? "ALL (สุ่มทุกหมวด)"}',
      );

      // โหลดไฟล์ JSON จาก assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/menu.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      debugPrint('JSON items loaded: ${jsonData.length}');

      // แปลง JSON เป็น FoodModel
      List<FoodModel> foods = jsonData
          .map((item) => FoodModel.fromJson(item as Map<String, dynamic>))
          .where((food) => food.title.isNotEmpty)
          .toList();

      debugPrint('Total foods parsed: ${foods.length}');

      // กรองตาม category ถ้ามี
      if (widget.selectedCategory?.title != null) {
        final categoryFilter = widget.selectedCategory!.title;
        foods = foods.where((food) {
          return food.category.contains(categoryFilter);
        }).toList();
        debugPrint(
          'Filtered by category "$categoryFilter": ${foods.length} items',
        );
      }

      if (!mounted) return;

      // ถ้าไม่มีข้อมูลเลย
      if (foods.isEmpty) {
        _clearSessionProgress();
        setState(() {
          allFoods = [];
          shuffledFoods = [];
          currentFood = null;
          loading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.selectedCategory != null
                    ? 'ไม่พบเมนูในหมวด "${widget.selectedCategory!.title}"'
                    : 'ไม่พบเมนูอาหารในระบบ',
                style: GoogleFonts.sarabun(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Filter ตาม user preferences
      final filteredFoods = _filterFoodsByPreferences(foods);
      debugPrint('After filtering: ${filteredFoods.length}');

      if (filteredFoods.isEmpty) {
        _clearSessionProgress();
        // ไม่มีอาหารที่เหมาะสม แสดง error
        setState(() {
          allFoods = [];
          shuffledFoods = [];
          currentFood = null;
          loading = false;
        });

        if (mounted) {
          // สร้างรายการอาหารที่ถูกกรอง
          String filteredList = '';
          final removedFoods = <String>{};

          for (var food in foods) {
            for (var allergen in userProfile?.allergies ?? []) {
              if (food.title.contains(allergen) ||
                  food.ingredients.any((ing) => ing.contains(allergen))) {
                removedFoods.add('• ${food.title} (แพ้: $allergen)');
              }
            }
          }

          if (removedFoods.isNotEmpty) {
            filteredList = '\n\nเมนูที่ถูกกรองออก:\n${removedFoods.join('\n')}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'พบเมนู ${foods.length} รายการ แต่ไม่เหมาะสมกับความชอบของคุณ$filteredList\n\nแนะนำ: ไปแก้ไขความชอบในหน้าโปรไฟล์',
                style: GoogleFonts.sarabun(fontSize: 13),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ตกลง',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        allFoods = filteredFoods;
        if (filteredFoods.isNotEmpty) {
          // สร้างรายการสุ่มแบบคำนวณคะแนน แล้ว shuffle เสร็จ
          try {
            shuffledFoods = _getSortedAndShuffledFoods(
              filteredFoods,
              userProfile?.likes ?? [],
              userProfile?.dislikes ?? [],
              userProfile?.allergies ?? [],
            );

            selectedFoodIds = _restoreSelectedFoodIds(shuffledFoods);
            final savedFood = _findFoodById(
              shuffledFoods,
              _lastFoodIdBySession[_sessionKey],
            );

            if (savedFood != null) {
              selectedFoodIds.add(savedFood.id);
            }
            currentFood = _pickNextFood(shuffledFoods, selectedFoodIds);
            imageLoaded = false;
          } catch (e) {
            debugPrint('Error getting random food: $e');
            currentFood = null;
            shuffledFoods = [];
            _clearSessionProgress();
          }
        }
      });

      _rememberSessionProgress();

      if (currentFood != null) {
        await checkFavorite();
      }
    } catch (err) {
      debugPrint('Error loading foods from JSON: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการโหลดข้อมูลเมนู: $err',
              style: GoogleFonts.sarabun(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchFoodsFromFirebase() async {
    try {
      setState(() => loading = true);

      debugPrint('========== FETCH FOODS DEBUG ==========');
      debugPrint(
        'Selected Category: ${widget.selectedCategory?.title ?? "ALL (สุ่มทุกหมวด)"}',
      );

      // ดึงทั้งหมดก่อน แล้วกรองหมวดในแอป
      // เพื่อรองรับข้อมูล category ทั้งแบบ List และ String
      final snapshot = await _databaseService.foodCollection.get();
      debugPrint('Documents received from Firebase: ${snapshot.docs.length}');

      // แสดงรายละเอียดทุก document ที่ได้
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final foodName = (data['name'] ?? data['title'] ?? '').toString();
        final categories = data['category'] is List
            ? (data['category'] as List).join(', ')
            : data['category'].toString();
        debugPrint('  - ${doc.id}: $foodName (categories: [$categories])');
      }

      final allFirebaseFoods = <FoodModel>[];
      for (final doc in snapshot.docs) {
        try {
          final food = FoodModel.fromFirestore(doc.data(), doc.id);
          if (food.title.isNotEmpty) {
            allFirebaseFoods.add(food);
          }
        } catch (e) {
          debugPrint('⚠️ Skip invalid food doc ${doc.id}: $e');
        }
      }

      List<FoodModel> foods = allFirebaseFoods;
      if (widget.selectedCategory?.title != null) {
        final categoryFilter = widget.selectedCategory!.title.trim();
        foods = allFirebaseFoods
            .where(
              (food) =>
                  food.category.any((cat) => cat.trim() == categoryFilter),
            )
            .toList();
        debugPrint(
          'Filtered by category "$categoryFilter": ${foods.length} items',
        );
      } else {
        debugPrint('Query without filter: ดึงทุกหมวด');
      }

      debugPrint(
        'Total foods parsed: ${foods.length} (after removing null titles)',
      );

      if (!mounted) return;

      // ถ้าไม่มีข้อมูลเลยจาก Firebase
      if (foods.isEmpty) {
        _clearSessionProgress();
        setState(() {
          allFoods = [];
          shuffledFoods = [];
          currentFood = null;
          loading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.selectedCategory != null
                    ? 'ไม่พบเมนูในหมวด "${widget.selectedCategory!.title}"\nกรุณาตรวจสอบว่าข้อมูลใน Firebase มี category ตรงกันหรือไม่'
                    : 'ไม่พบเมนูอาหารในระบบ',
                style: GoogleFonts.sarabun(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Filter ตาม user preferences
      final filteredFoods = _filterFoodsByPreferences(foods);
      debugPrint('After filtering: ${filteredFoods.length}');

      if (filteredFoods.isEmpty) {
        _clearSessionProgress();
        // ไม่มีอาหารที่เหมาะสม แสดง error
        setState(() {
          allFoods = [];
          shuffledFoods = [];
          currentFood = null;
          loading = false;
        });

        if (mounted) {
          // สร้างรายการอาหารที่ถูกกรอง
          String filteredList = '';
          final removedFoods = <String>{};

          for (var food in foods) {
            for (var allergen in userProfile?.allergies ?? []) {
              if (food.title.contains(allergen) ||
                  food.ingredients.any((ing) => ing.contains(allergen))) {
                removedFoods.add('• ${food.title} (แพ้: $allergen)');
              }
            }
          }

          if (removedFoods.isNotEmpty) {
            filteredList = '\n\nเมนูที่ถูกกรองออก:\n${removedFoods.join('\n')}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'พบเมนู ${foods.length} รายการ แต่ไม่เหมาะสมกับความชอบของคุณ$filteredList\n\nแนะนำ: ไปแก้ไขความชอบในหน้าโปรไฟล์',
                style: GoogleFonts.sarabun(fontSize: 13),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ตกลง',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        allFoods = filteredFoods;
        if (filteredFoods.isNotEmpty) {
          // สร้างรายการสุ่มแบบคำนวณคะแนน แล้วเลือกจากท็อป 5
          try {
            shuffledFoods = _getSortedAndShuffledFoods(
              filteredFoods,
              userProfile?.likes ?? [],
              userProfile?.dislikes ?? [],
              userProfile?.allergies ?? [],
            );

            selectedFoodIds = _restoreSelectedFoodIds(shuffledFoods);
            final savedFood = _findFoodById(
              shuffledFoods,
              _lastFoodIdBySession[_sessionKey],
            );

            if (savedFood != null) {
              selectedFoodIds.add(savedFood.id);
            }
            currentFood = _pickNextFood(shuffledFoods, selectedFoodIds);
            imageLoaded = false;
          } catch (e) {
            debugPrint('Error getting random food: $e');
            currentFood = null;
            shuffledFoods = [];
            _clearSessionProgress();
          }
        }
      });

      _rememberSessionProgress();

      if (currentFood != null) {
        await checkFavorite();
      }
    } catch (err, stackTrace) {
      debugPrint('Error fetching foods: $err');
      debugPrint('Stacktrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการโหลดเมนู: $err',
              style: GoogleFonts.sarabun(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> checkFavorite() async {
    if (currentFood == null) return;

    try {
      if (userId.isEmpty) {
        if (mounted) setState(() => isLiked = false);
        return;
      }

      final liked = await FavoriteService.isFavorite(userId, currentFood!.id);

      if (mounted) {
        setState(() {
          isLiked = liked;
        });
      }
    } catch (err) {
      debugPrint('Error checking favorite: $err');
      if (mounted) {
        setState(() => isLiked = false);
      }
    }
  }

  Future<void> handleRandomAgain() async {
    if (shuffledFoods.isEmpty) return;

    // สุ่มเมนูจาก remaining (weighted ตามลำดับ)
    try {
      final newFood = _pickNextFood(shuffledFoods, selectedFoodIds);

      // เช็กว่าอาหารใหม่อยู่ใน favorites หรือไม่
      bool liked = false;
      try {
        if (userId.isNotEmpty) {
          liked = await FavoriteService.isFavorite(userId, newFood.id);
        }
      } catch (err) {
        debugPrint('Error checking favorite: $err');
      }

      // setState ครั้งเดียวพร้อมกันทั้งหมด
      if (mounted) {
        setState(() {
          currentFood = newFood;
          isLiked = liked;
          imageLoaded = false;
        });
      }

      _rememberSessionProgress();
    } catch (e) {
      debugPrint('Error getting next food: $e');
    }
  }

  Future<void> handleSelectMeal() async {
    if (currentFood == null) return;

    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'กรุณาเข้าสู่ระบบก่อนบันทึกเมนูโปรด',
              style: GoogleFonts.sarabun(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      if (isLiked) {
        await FavoriteService.removeFavorite(userId, currentFood!.id);

        if (widget.favoriteOnly) {
          // ลบออกจาก session cache ทันทีเพื่อไม่ให้เลือกอีก
          selectedFoodIds.remove(currentFood!.id);
          await fetchFavoriteFoods();
        } else {
          // อัปเดต UI ทันที
          if (mounted) {
            setState(() => isLiked = false);
          }
        }
      } else {
        await FavoriteService.addFavorite(userId, currentFood!);
        if (mounted) {
          setState(() => isLiked = true);
        }
      }
    } catch (err) {
      debugPrint('Error toggling favorite: $err');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'บันทึกเมนูโปรดไม่สำเร็จ: $err',
            style: GoogleFonts.sarabun(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, size: 24),
                          onPressed: widget.onBack,
                          color: const Color(0xFF333333),
                        ),
                        Expanded(
                          child: Text(
                            _screenTitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.sarabun(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),

                    // Meal Display
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: loading
                          ? Center(
                              child: Text(
                                widget.favoriteOnly
                                    ? 'กำลังสุ่มเมนูโปรด...'
                                    : 'กำลังสุ่มเมนู...',
                                style: GoogleFonts.sarabun(
                                  fontSize: 16,
                                  color: const Color(0xFF999999),
                                ),
                              ),
                            )
                          : currentFood != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    currentFood!.image,
                                    width: double.infinity,
                                    height: 400,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            imageLoaded = true;
                                            return child;
                                          }
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.error),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      currentFood!.title,
                                      style: GoogleFonts.sarabun(
                                        fontSize: 22,
                                        color: const Color(0xFF333333),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Text(
                                widget.favoriteOnly
                                    ? 'ยังไม่มีเมนูโปรดสำหรับสุ่ม'
                                    : 'ไม่พบเมนู',
                                style: GoogleFonts.sarabun(
                                  fontSize: 16,
                                  color: const Color(0xFF999999),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Ingredients Section
                    if (currentFood != null &&
                        currentFood!.ingredients.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วัตถุดิบ: ',
                                style: GoogleFonts.sarabun(
                                  fontSize: 16,
                                  color: const Color(0xFF999999),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentFood!.ingredients.join(', '),
                                style: GoogleFonts.sarabun(
                                  fontSize: 16,
                                  color: const Color(0xFFA18F76),
                                  fontWeight: FontWeight.w500,
                                ),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: handleRandomAgain,
                            icon: const Icon(LucideIcons.rotateCw, size: 20),
                            label: Text(
                              'สุ่มใหม่',
                              style: GoogleFonts.sarabun(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF333333),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        if (AuthService.currentUserId != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: handleSelectMeal,
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 22,
                                color: Colors.white,
                              ),
                              label: Text(
                                isLiked ? 'ลบเมนูโปรด' : 'เมนูโปรด',
                                style: GoogleFonts.sarabun(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLiked
                                    ? const Color(0xFFFF5A5F)
                                    : const Color(0xFFFF9966),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✨ Icon
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFFFC107),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'เคล็ดลับ',
                                  style: GoogleFonts.sarabun(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.favoriteOnly
                                      ? 'นี่คือเมนูที่คุณกดถูกใจไว้ กดปุ่ม “สุ่มใหม่” เพื่อสุ่มเมนูโปรดรายการอื่น'
                                      : 'ไม่ชอบเมนูนี้? กดปุ่ม “สุ่มใหม่” เพื่อเปลี่ยนเมนู',
                                  style: GoogleFonts.sarabun(
                                    fontSize: 14,
                                    color: const Color(0xFF777777),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoredFood {
  final FoodModel food;
  final double score;

  _ScoredFood({required this.food, required this.score});
}
