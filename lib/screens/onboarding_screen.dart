import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final Map<String, List<String>>? initialSelections;
  final int? initialStep;

  const OnboardingScreen({Key? key, this.initialSelections, this.initialStep})
    : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late int _currentStep;
  late Map<String, List<String>> _selections;
  String _searchInput = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep ?? 1;
    _selections =
        widget.initialSelections ??
        {'likes': [], 'dislikes': [], 'allergies': []};
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _commonFoods = [
    'ข้าว',
    'เนื้อ',
    'ไก่',
    'ปลา',
    'กุ้ง',
    'หอย',
    'หมู',
    'ผัก',
    'ผลไม้',
    'นม',
    'ไข่',
    'ถั่ว',
  ];

  final Map<String, Map<String, dynamic>> _stepConfig = {
    'likes': {
      'title': 'อาหารที่ชอบ',
      'subtitle': 'เลือกประเภทอาหารที่คุณชื่นชอบ (เลือกได้หลายอย่าง)',
      'description': 'บอกเราว่าชอบกินอะไร',
      'icon': Icons.thumb_up,
      'color': Color(0xFF4CAF50),
      'bgColor': Color(0xFFE8F5E9),
    },
    'dislikes': {
      'title': 'อาหารที่ไม่ชอบ',
      'subtitle': 'เลือกวัตถุดิบหรืออาหารที่คุณไม่ชอบ (เลือกได้หลายอย่าง)',
      'description': 'หลีกเลี่ยงสิ่งที่ไม่ชอบ',
      'icon': Icons.thumb_down,
      'color': Color(0xFFF44336),
      'bgColor': Color(0xFFFFEBEE),
    },
    'allergies': {
      'title': 'อาหารที่แพ้',
      'subtitle': 'เลือกวัตถุดิบหรืออาหารที่คุณแพ้ (เลือกได้หลายอย่าง)',
      'description': 'ความปลอดภัยมาก่อน',
      'icon': Icons.warning,
      'color': Color(0xFFFFC107),
      'bgColor': Color(0xFFFFFDE7),
    },
  };

  void _handleAddFood(String food, String category) {
    if (!_selections[category]!.contains(food)) {
      setState(() {
        _selections[category]!.add(food);
        _searchInput = '';
      });
    }
  }

  void _handleRemoveFood(String food, String category) {
    setState(() {
      _selections[category]!.remove(food);
    });
  }

  void _handleNext() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _handleBack() {
    if (_currentStep == 4 && widget.initialStep != null) {
      // ถ้าอยู่ในหน้าสรุปและมาจากการแก้ไข ให้กลับไปหน้าที่แก้ไข
      setState(() {
        _currentStep = widget.initialStep!;
      });
    } else if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _handleFinish() {
    Navigator.of(context).pop(_selections);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 4) {
      return _buildResult();
    } else {
      return _buildSelection();
    }
  }

  Widget _buildSelection() {
    final categories = ['likes', 'dislikes', 'allergies'];
    final category = categories[_currentStep - 1];
    final config = _stepConfig[category]!;
    final selected = _selections[category]!;
    final filteredFoods = _commonFoods
        .where(
          (food) =>
              food.toLowerCase().contains(_searchInput.toLowerCase()) &&
              !selected.contains(food),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Stack(
          children: [
            // ปุ่มย้อนกลับด้านบนซ้าย
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: _handleBack,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: const Color(0xFF333333),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ย้อนกลับ',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // เนื้อหาหลัก
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: config['bgColor'],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          config['icon'],
                          color: config['color'],
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        config['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        config['subtitle'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (category == 'allergies')
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEA),
                            border: Border.all(
                              color: const Color(0xFFFFC107),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: const Color(0xFFFFC107),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'ข้อมูลนี้สำคัญมาก เราจะใช้เพื่อกรองเมนูที่มีส่วนผสมที่คุณแพ้ออก',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF856404),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchInput = value),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาอาหาร${config['title']}...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (selected.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selected.map((food) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B9D),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    food,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        _handleRemoveFood(food, category),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: filteredFoods.length,
                          itemBuilder: (context, index) {
                            final food = filteredFoods[index];
                            return ElevatedButton(
                              onPressed: () => _handleAddFood(food, category),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5F5F5),
                                foregroundColor: const Color(0xFF333333),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                '+ $food',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'เลือกแล้ว ${selected.length} รายการ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // ถ้ามาจากการแก้ไข (มี initialStep) ให้ไปหน้าสรุปเลย
                            if (widget.initialStep != null) {
                              setState(() => _currentStep = 4);
                            } else if (_currentStep < 3) {
                              // ถ้าเป็นครั้งแรก ให้เดินตามลำดับ
                              _handleNext();
                            } else {
                              // step 3 ของครั้งแรก
                              setState(() => _currentStep = 4);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.initialStep != null
                                ? 'ถัดไป →'
                                : (_currentStep < 3 ? 'ถัดไป →' : 'เสร็จสิ้น'),
                            style: const TextStyle(
                              fontSize: 15,
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
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'เรียบร้อย!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ขอบคุณที่บอกความชอบของคุณ นี่คือสรุปข้อมูล',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 20),
                  _buildResultItem(
                    'อาหารที่ชอบ',
                    _selections['likes']!,
                    Icons.thumb_up,
                    const Color(0xFF4CAF50),
                    const Color(0xFFE8F5E9),
                    const Color(0xFFA5D6A7),
                  ),
                  const SizedBox(height: 10),
                  _buildResultItem(
                    'อาหารที่ไม่ชอบ',
                    _selections['dislikes']!,
                    Icons.thumb_down,
                    const Color(0xFFF44336),
                    const Color(0xFFFFEBEE),
                    const Color(0xFFEF9A9A),
                  ),
                  const SizedBox(height: 10),
                  _buildResultItem(
                    'อาหารที่แพ้',
                    _selections['allergies']!,
                    Icons.warning,
                    const Color(0xFFFFC107),
                    const Color(0xFFFFFDE7),
                    const Color(0xFFFFF59D),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleBack,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: const Color(0xFFF4A460),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'แก้ไข',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleFinish,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.initialSelections != null
                                ? 'บันทึกข้อมูล'
                                : 'เริ่มใช้งาน',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(
    String title,
    List<String> items,
    IconData icon,
    Color iconColor,
    Color bgColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title (${items.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  items.isNotEmpty ? items.join(', ') : 'ยังไม่ได้เลือก',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
