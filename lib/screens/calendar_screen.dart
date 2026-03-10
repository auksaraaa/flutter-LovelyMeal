import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Sample data - days with meals recorded
    _loadSampleData();
  }

  void _loadSampleData() {
    // Add some sample days with meals
    final now = DateTime.now();
    for (int i = 1; i <= 30; i++) {
      final day = DateTime(now.year, now.month, i);
      if (i % 2 == 0 || i % 3 == 0) {
        _events[DateTime(day.year, day.month, day.day)] = ['meal'];
      }
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text(
          'Food diary',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCalendarCard(context, DateTime.now()),
                const SizedBox(height: 20),
                _buildCalendarCard(
                  context,
                  DateTime(DateTime.now().year, DateTime.now().month + 1),
                ),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                // Add meal photo
                _showAddMealDialog();
              },
              backgroundColor: const Color(0xFFFFB6C1),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.black,
                size: 30,
              ),
            ),
          ),
        ],
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
              lastDay: DateTime.utc(2030, 12, 31),
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
              },
              eventLoader: _getEventsForDay,
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
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF757575),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(
                            color: Colors.white,
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    // Using Buddhist calendar year (add 543)
    return '${months[date.month - 1]} ${date.year + 543}';
  }

  void _showAddMealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Meal Photo'),
        content: const Text('Select option to add your meal photo'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add camera functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera feature coming soon!')),
              );
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add gallery functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gallery feature coming soon!')),
              );
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
