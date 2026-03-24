import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/photo_service.dart';
import '../services/auth_service.dart';
import '../services/food_classifier_service.dart';
import '../models/photo_model.dart';
import 'photo_history_screen.dart';

class PhotoDayScreen extends StatefulWidget {
  final DateTime selectedDate;

  const PhotoDayScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<PhotoDayScreen> createState() => _PhotoDayScreenState();
}

class _PhotoDayScreenState extends State<PhotoDayScreen> {
  final PhotoService _photoService = PhotoService();
  final AuthService _authService = AuthService();
  final FoodClassifierService _classifierService =
      FoodClassifierService.instance;
  List<PhotoModel> _photosDay = [];
  bool _isLoading = false;
  XFile? _selectedImage; // Track selected image for preview
  ClassificationResult? _classificationResult; // Food classification result
  bool _isClassifying = false; // Loading state for classification

  @override
  void initState() {
    super.initState();
    _loadPhotosForMonth();
    _initClassifier();
  }

  // Initialize TFLite classifier
  void _initClassifier() {
    _classifierService.initialize().then((_) {
      print('Food classifier initialized successfully');
    }).catchError((e) {
      print('Error initializing classifier: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ข้อผิดพลาด: ไม่สามารถโหลดโมเดล: $e')),
        );
      }
    });
  }

  @override
  void dispose() {
    _classifierService.dispose();
    super.dispose();
  }

  // Classify selected image
  Future<void> _classifySelectedImage(XFile image) async {
    setState(() => _isClassifying = true);
    try {
      final result = await _classifierService.classifyImage(File(image.path));
      if (mounted) {
        setState(() {
          _classificationResult = result;
          _isClassifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClassifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _loadPhotosForDay() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final dateStr =
          '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';

      final photos = await _photoService.getPhotosByDate(
        uid: user.uid,
        date: dateStr,
      );

      if (mounted) {
        // เรียงรูปตามเวลาที่อัพโหลด (เก่าสุดก่อน)
        photos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        setState(() {
          _photosDay = photos;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _loadPhotosForMonth() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final yearMonth = '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}';
      await _photoService.getPhotosByMonth(
        uid: user.uid,
        yearMonth: yearMonth,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Load photos for the specific day after month photos
        _loadPhotosForDay();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  bool _isToday() {
    final today = DateTime.now();
    return widget.selectedDate.year == today.year &&
        widget.selectedDate.month == today.month &&
        widget.selectedDate.day == today.day;
  }

  String _getDateDisplayForHistory() {
    final months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    final dayOfWeek = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์'
    ];
    return '${dayOfWeek[widget.selectedDate.weekday % 7]} ${widget.selectedDate.day} ${months[widget.selectedDate.month - 1]} ${widget.selectedDate.year + 543}';
  }

  Future<void> _uploadPhoto(XFile photo) async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โปรดเข้าสู่ระบบก่อน')),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final dateStr =
          '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';

      final photoFile = File(photo.path);

      await _photoService.uploadPhoto(
        uid: user.uid,
        photoFile: photoFile,
        date: dateStr,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดสำเร็จ!')),
        );
        setState(() {
          _isLoading = false;
          _selectedImage = null;
        });
        await _loadPhotosForDay();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ล้มเหลว: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null && mounted) {
        setState(() {
          _selectedImage = photo;
          _classificationResult = null;
        });
        // Automatically classify the image
        await _classifySelectedImage(photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _uploadFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.gallery);

      if (photo != null && mounted) {
        setState(() {
          _selectedImage = photo;
          _classificationResult = null;
        });
        // Automatically classify the image
        await _classifySelectedImage(photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        toolbarHeight: 100,
        leading: Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        flexibleSpace: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 56.0, bottom: 16.0),
              child: Text(
                'Food diary',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUploadScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodClassificationWidget() {
    if (_isClassifying) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue.withOpacity(0.1),
          border: Border.all(color: Colors.blue, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'กำลังตรวจสอบ...',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_classificationResult == null) {
      return const SizedBox.shrink();
    }

    final result = _classificationResult!;
    final isFood = result.isFood;
    final backgroundColor =
        isFood ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
    final borderColor = isFood ? Colors.green : Colors.red;
    final textColor = isFood ? Colors.green : Colors.red;
    final icon = isFood ? Icons.check_circle : Icons.cancel;
    final status = isFood ? 'ตรวจสอบแล้ว: อาหาร ✓' : 'ตรวจสอบแล้ว: ไม่ใช่อาหาร ✗';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (!isFood)
                    Text(
                      'ไม่พบอาหารในภาพ ลองเปลี่ยนมุม\nหรือถ่ายให้ใกล้ขึ้น',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Upload preview area
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[300],
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(height: 20),
          // Food classification result
          if (_selectedImage != null) _buildFoodClassificationWidget(),
          const SizedBox(height: 20),
          // Upload buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Camera button (left)
              IconButton(
                onPressed: _isToday() ? _uploadFromCamera : null,
                icon: const Icon(CupertinoIcons.camera, size: 48),
                color: Colors.black,
                disabledColor: Colors.grey[300],
              ),
              const SizedBox(width: 40),
              // Upload button (center) - Main action
              SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  onPressed: _selectedImage != null &&
                          _classificationResult != null &&
                          _classificationResult!.isFood
                      ? () async {
                          await _uploadPhoto(_selectedImage!);
                          if (mounted) {
                            setState(() {
                              _selectedImage = null;
                              _classificationResult = null;
                            });
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_selectedImage != null && _classificationResult != null
                                ? const Color(0xFFFFB6C1)
                                : Colors.grey[300]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    padding: const EdgeInsets.only(right: 3),
                  ),
                  child: Icon(
                    CupertinoIcons.paperplane,
                    size: 48,
                    color: (_selectedImage != null &&
                            _classificationResult != null &&
                            _classificationResult!.isFood)
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 40),
              // Gallery button (right)
              IconButton(
                onPressed: _isToday() ? _uploadFromGallery : null,
                icon: const Icon(CupertinoIcons.photo_on_rectangle, size: 48),
                color: Colors.black,
                disabledColor: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // History button
          if (_photosDay.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoHistoryScreen(
                        photos: _photosDay,
                        selectedDate: widget.selectedDate,
                        dateDisplay: _getDateDisplayForHistory(),
                        photosDay: _photosDay,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('ดูประวัติ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFFFB6C1), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
