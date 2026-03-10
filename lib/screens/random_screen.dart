import 'package:flutter/material.dart';
import 'dart:math';

class RandomScreen extends StatefulWidget {
  final String? category;

  const RandomScreen({Key? key, this.category}) : super(key: key);

  @override
  State<RandomScreen> createState() => _RandomScreenState();
}

class _RandomScreenState extends State<RandomScreen> {
  Map<String, dynamic>? currentMeal;
  bool isLiked = false;

  final List<Map<String, dynamic>> meals = [
    {
      'name': 'ข้าวมันไก่',
      'image':
          'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=500&h=500&fit=crop',
      'credit': 'ไอเดียจาก "กูเกิล" เพื่อการประยุกต์ใช้งานเท่านั้น',
    },
    {
      'name': 'ข้าวผัดกุ้ง',
      'image':
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=500&h=500&fit=crop',
      'credit': 'ไอเดียจาก "คุกกิ้ง" เพื่อการประยุกต์ใช้งานเท่านั้น',
    },
    {
      'name': 'ส้มตำไทย',
      'image':
          'https://images.unsplash.com/photo-1559847844-5315695dadae?w=500&h=500&fit=crop',
      'credit': 'ไอเดียจาก "บล็อกอาหาร" เพื่อการประยุกต์ใช้งานเท่านั้น',
    },
    {
      'name': 'ผัดไทย',
      'image':
          'https://images.unsplash.com/photo-1626804475297-41608ea09aeb?w=500&h=500&fit=crop',
      'credit': 'ไอเดียจาก "เชฟดัง" เพื่อการประยุกต์ใช้งานเท่านั้น',
    },
    {
      'name': 'ต้มยำกุ้ง',
      'image':
          'https://images.unsplash.com/photo-1548943487-a2e4e43b4853?w=500&h=500&fit=crop',
      'credit': 'ไอเดียจาก "สูตรอาหาร" เพื่อการประยุกต์ใช้งานเท่านั้น',
    },
  ];

  @override
  void initState() {
    super.initState();
    getRandomMeal();
  }

  void getRandomMeal() {
    final random = Random();
    final randomIndex = random.nextInt(meals.length);
    setState(() {
      currentMeal = meals[randomIndex];
      isLiked = false;
    });
  }

  void handleSelectMeal() {
    if (currentMeal != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('คุณเลือก "${currentMeal!['name']}" แล้ว!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 24),
                          onPressed: () => Navigator.pop(context),
                          color: const Color(0xFF333333),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 24),
                          onPressed: () {},
                          color: const Color(0xFF333333),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Meal Display
                    Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: currentMeal != null
                          ? Stack(
                              children: [
                                Image.network(
                                  currentMeal!['image'],
                                  width: double.infinity,
                                  height: 400,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xFFF5F5F5),
                                      child: const Center(
                                        child: Icon(
                                          Icons.restaurant,
                                          size: 64,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                    );
                                  },
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
                                      currentMeal!['name'],
                                      style: const TextStyle(
                                        fontSize: 28,
                                        color: Color(0xFF333333),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Text(
                                'กำลังสุ่มเมนู...',
                                style: TextStyle(color: Color(0xFF999999)),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: getRandomMeal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF333333),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'สุ่มใหม่',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: currentMeal != null
                                ? handleSelectMeal
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9966),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: const Color(
                                0xFFFF9966,
                              ).withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 20,
                                  color: isLiked
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'เลือกเมนูนี้',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Credit Section
                    if (currentMeal != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentMeal!['credit'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
