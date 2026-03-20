import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/photo_service.dart';
import '../services/auth_service.dart';
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
  List<PhotoModel> _photosDay = [];
  List<PhotoModel> _photosMonth = [];
  bool _isLoading = false;
  XFile? _selectedImage; // Track selected image for preview

  @override
  void initState() {
    super.initState();
    _loadPhotosForMonth();
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
      final photos = await _photoService.getPhotosByMonth(
        uid: user.uid,
        yearMonth: yearMonth,
      );

      if (mounted) {
        setState(() {
          _photosMonth = photos;
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

  Future<void> _uploadFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.gallery);

      if (photo != null && mounted) {
        setState(() {
          _selectedImage = photo;
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const SizedBox.shrink(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 20.0),
              child: Text(
                'Food diary',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUploadScreen(),
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
          // Upload buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Camera button (left)
              IconButton(
                onPressed: _isToday() ? _uploadFromCamera : null,
                icon: const Icon(Icons.camera_alt_outlined, size: 48),
                color: Colors.black,
                disabledColor: Colors.grey[300],
              ),
              const SizedBox(width: 40),
              // Upload button (center) - Main action
              SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  onPressed: _selectedImage != null
                      ? () async {
                          await _uploadPhoto(_selectedImage!);
                          if (mounted) {
                            setState(() => _selectedImage = null);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedImage != null
                        ? const Color(0xFFFFB6C1)
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    padding: const EdgeInsets.only(left: 6),
                  ),
                  child: Icon(
                    Icons.send,
                    size: 48,
                    color: _selectedImage != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 40),
              // Gallery button (right)
              IconButton(
                onPressed: _isToday() ? _uploadFromGallery : null,
                icon: const Icon(Icons.image_outlined, size: 48),
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
