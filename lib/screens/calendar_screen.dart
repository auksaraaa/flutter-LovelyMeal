import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/photo_service.dart';
import '../services/auth_service.dart';
import 'photo_day_screen.dart';
import 'photo_history_screen.dart';
import 'login_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, int> _eventCounts = {}; // เก็บจำนวนรูปต่อวัน
  final PhotoService _photoService = PhotoService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadPhotosForMonth(_focusedDay);
  }

  Future<void> _loadPhotosForMonth(DateTime month) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final yearMonth =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final photos = await _photoService.getPhotosByMonth(
        uid: user.uid,
        yearMonth: yearMonth,
      );

      if (mounted) {
        setState(() {
          _eventCounts.clear();
          for (var photo in photos) {
            final dateParts = photo.date.split('-');
            final dateKey = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );
            _eventCounts[dateKey] = (_eventCounts[dateKey] ?? 0) + 1;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่สามารถโหลดรูปภาพ: $e')));
      }
    }
  }

  int _getEventCountForDay(DateTime day) {
    return _eventCounts[DateTime(day.year, day.month, day.day)] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    // Check if user is not logged in
    if (user == null) {
      return _buildLoginRequired(context);
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFB3D9),
        elevation: 0,
        title: const Text(
          'ปฏิทิน',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildCalendarCard(context, DateTime.now()),
                  const SizedBox(height: 20), // Space at bottom
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, DateTime month) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFB6C1).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFE91E63),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              _getMonthYearText(month),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: month,
              currentDay: DateTime.now(),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                // Check if selected day is today
                final today = DateTime.now();
                final isToday =
                    selectedDay.year == today.year &&
                    selectedDay.month == today.month &&
                    selectedDay.day == today.day;

                if (isToday) {
                  // Navigate to photo day screen for today
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PhotoDayScreen(selectedDate: selectedDay),
                    ),
                  ).then((_) {
                    // Refresh photos when coming back
                    _loadPhotosForMonth(_focusedDay);
                  });
                } else {
                  // Navigate to photo history screen for past days
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoHistoryScreen(
                        photos: [],
                        selectedDate: selectedDay,
                        dateDisplay: _getDateDisplay(selectedDay),
                        photosDay: [],
                      ),
                    ),
                  ).then((_) {
                    // Refresh photos when coming back
                    _loadPhotosForMonth(_focusedDay);
                  });
                }
              },
              eventLoader: (day) {
                final count = _getEventCountForDay(day);
                return List.filled(count, 'photo');
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerVisible: false,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: true,
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF757575).withOpacity(0.5),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFF757575),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFF757575),
                  shape: BoxShape.rectangle,
                ),
                defaultDecoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                ),
                weekendDecoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                ),
                outsideDecoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                ),
                defaultTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                weekendTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                outsideTextStyle: TextStyle(
                  color: Colors.black.withOpacity(0.3),
                ),
                cellMargin: const EdgeInsets.all(4),
                cellPadding: const EdgeInsets.all(0),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF757575),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthYearText(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year + 543}';
  }

  String _getDateDisplay(DateTime date) {
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
      'เสาร์',
    ];
    return '${dayOfWeek[date.weekday % 7]} ${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF5EE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFB3D9),
        elevation: 0,
        title: const Text(
          'ปฏิทิน',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey[500]),
              const SizedBox(height: 16),
              const Text(
                'ต้องเข้าสู่ระบบก่อนดูปฏิทิน',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'เข้าสู่ระบบเพื่อบันทึกและดูประวัติอาหารของคุณ ได้ทุกที่ทุกเวลา',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 24),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    );
  }
}
