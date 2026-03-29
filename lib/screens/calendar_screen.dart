import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/photo_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
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
  final DatabaseService _databaseService = DatabaseService();
  late ScrollController _scrollController;
  Map<String, bool> _monthsLoaded = {};
  DateTime? _userCreatedAt;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _scrollController = ScrollController();
    _loadUserCreationDate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCreationDate() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final userModel = await _databaseService.getUser(user.uid);
      if (userModel != null && mounted) {
        setState(() {
          _userCreatedAt = userModel.createdAt;
        });
        // โหลดรูปภาพสำหรับทุกเดือนตั้งแต่สมัคร ถึงปัจจุบัน
        await _loadAllMonthsPhotos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถโหลดข้อมูลผู้ใช้: $e')),
        );
      }
    }
  }

  Future<void> _loadAllMonthsPhotos() async {
    if (_userCreatedAt == null) return;

    DateTime currentMonth = DateTime(
      _userCreatedAt!.year,
      _userCreatedAt!.month,
      1,
    );
    final now = DateTime.now();

    while (currentMonth.isBefore(DateTime(now.year, now.month + 1, 1))) {
      await _loadPhotosForMonth(currentMonth);
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
  }

  Future<void> _loadPhotosForMonth(DateTime month) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final yearMonth = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    // ตรวจสอบว่าเดือนนี้ถูกโหลดแล้วหรือไม่
    if (_monthsLoaded[yearMonth] == true) return;

    try {
      final photos = await _photoService.getPhotosByMonth(
        uid: user.uid,
        yearMonth: yearMonth,
      );

      if (mounted) {
        setState(() {
          // ลบ eventCounts เก่าของเดือนนี้ก่อน
          _eventCounts.removeWhere(
            (key, value) => key.year == month.year && key.month == month.month,
          );

          // เพิ่มรูปใหม่
          for (var photo in photos) {
            final dateParts = photo.date.split('-');
            final dateKey = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );
            _eventCounts[dateKey] = (_eventCounts[dateKey] ?? 0) + 1;
          }
          _monthsLoaded[yearMonth] = true;
        });
      }
    } catch (e) {
      if (mounted) {
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
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: _buildMonthsList()),
        ),
      ),
    );
  }

  List<Widget> _buildMonthsList() {
    List<Widget> months = [];

    if (_userCreatedAt == null) {
      return [const Center(child: CircularProgressIndicator())];
    }

    final now = DateTime.now();
    DateTime currentMonth = DateTime(
      _userCreatedAt!.year,
      _userCreatedAt!.month,
      1,
    );
    List<DateTime> monthDates = [];

    // สร้างปฏิทินตั้งแต่เดือนที่สมัครสมาชิก ถึงเดือนปัจจุบัน
    while (currentMonth.isBefore(DateTime(now.year, now.month + 1, 1))) {
      monthDates.add(currentMonth);
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }

    monthDates = monthDates.reversed.toList();

    for (int i = 0; i < monthDates.length; i++) {
      months.add(_buildCalendarCard(context, monthDates[i]));
      if (i != monthDates.length - 1) {
        months.add(const SizedBox(height: 16));
      }
    }

    return months;
  }

  Widget _buildCalendarCard(BuildContext context, DateTime month) {
    // คำนวณ firstDay และ lastDay สำหรับแต่ละเดือน
    DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
    DateTime lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // firstDay ต้องไม่น้อยกว่าวันที่ user สมัคร (ถ้ามี)
    DateTime effectiveFirstDay = firstDayOfMonth;
    if (_userCreatedAt != null && firstDayOfMonth.isBefore(_userCreatedAt!)) {
      effectiveFirstDay = _userCreatedAt!;
    }

    // lastDay ต้องไม่เกินวันปัจจุบัน
    DateTime effectiveLastDay = lastDayOfMonth;
    if (lastDayOfMonth.isAfter(DateTime.now())) {
      effectiveLastDay = DateTime.now();
    }

    // focusedDay ต้องอยู่ระหว่าง firstDay และ lastDay
    DateTime effectiveFocusedDay = month;
    if (month.isBefore(effectiveFirstDay)) {
      effectiveFocusedDay = effectiveFirstDay;
    } else if (month.isAfter(effectiveLastDay)) {
      effectiveFocusedDay = effectiveLastDay;
    }

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
              firstDay: effectiveFirstDay,
              lastDay: effectiveLastDay,
              focusedDay: effectiveFocusedDay,
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
                    // Refresh photos for this month when coming back
                    _monthsLoaded.remove(
                      '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}',
                    );
                    _loadPhotosForMonth(selectedDay);
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
                    // Refresh photos for this month when coming back
                    _monthsLoaded.remove(
                      '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}',
                    );
                    _loadPhotosForMonth(selectedDay);
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
