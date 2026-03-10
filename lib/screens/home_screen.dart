import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'icon': Icons.access_time,
        'title': 'เมนูกินง่าย',
        'subtitle': 'อาหารทำง่ายไม่ยุ่งยาก',
        'color': const Color(0xFFFFC4C4),
        'iconBg': const Color(0xFF12B894),
      },
      {
        'icon': Icons.local_fire_department,
        'title': 'เมนูรสเผ็ดจัด',
        'subtitle': 'สำหรับคนชอบรสจัดจ้าน',
        'color': const Color(0xFFFFC4C4),
        'iconBg': const Color(0xFFF35632),
      },
      {
        'icon': Icons.eco,
        'title': 'เมนูสุขภาพ',
        'subtitle': 'อาหารคลีน แคลลอรี่ต่ำ',
        'color': const Color(0xFFFFC4C4),
        'iconBg': const Color(0xFF5EC931),
      },
      {
        'icon': Icons.soup_kitchen,
        'title': 'เมนูอิ่มท้อง',
        'subtitle': 'กินแล้วอิ่มนาน',
        'color': const Color(0xFFFFC4C4),
        'iconBg': const Color(0xFFEEAB09),
      },
      {
        'icon': Icons.fastfood,
        'title': 'เมนูเบาๆ',
        'subtitle': 'ของว่างของทานเล่น',
        'color': const Color(0xFFFFC4C4),
        'iconBg': const Color(0xFF209CE5),
      },
      {
        'icon': Icons.favorite,
        'title': 'เมนูโปรด',
        'subtitle': 'อาหารที่โดนใจคุณ',
        'color': const Color(0xFFFFC4C4),
        'iconBg': const Color(0xFFF14274),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFCF5EE),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB366), Color(0xFFFF8C66)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'วันนี้กินอะไรดี?',
                            style: TextStyle(
                              fontSize: 26,
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'เลือกหมวดหมู่ที่คุณสนใจ แล้วเราจะสุ่มเมนูให้',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Section
                    const Text(
                      'เลือกหมวดหมู่',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return InkWell(
                          onTap: () {
                            // Navigate to random screen with category
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: category['color'] as Color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: category['iconBg'] as Color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    category['icon'] as IconData,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  category['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category['subtitle'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF666666),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Random Button
                    InkWell(
                      onTap: () {
                        // Navigate to random screen
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFD841F), Color(0xFFFFB07F)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'สุ่มเมนูเลย !',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'ไม่รู้จะกินอะไร ให้เราเลือกให้',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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