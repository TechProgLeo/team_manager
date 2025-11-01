import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'training_detail_page.dart';

class CalendarTrainingsPage extends StatefulWidget {
  const CalendarTrainingsPage({super.key});

  @override
  State<CalendarTrainingsPage> createState() => _CalendarTrainingsPageState();
}

class _CalendarTrainingsPageState extends State<CalendarTrainingsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('trainings')
        .orderBy('date')
        .get();

    final events = <DateTime, List<Map<String, dynamic>>>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final dayKey = DateTime(date.year, date.month, date.day);

      events.putIfAbsent(dayKey, () => []);
      events[dayKey]!.add({
        'id': doc.id,
        'title': data['title'],
        'location': data['location'],
        'date': date,
      });
    }

    setState(() => _events = events);
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final trainingsForDay = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainings Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: trainingsForDay.isEmpty
                ? const Center(child: Text('No trainings on this day'))
                : ListView.builder(
                    itemCount: trainingsForDay.length,
                    itemBuilder: (context, index) {
                      final t = trainingsForDay[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(t['title']),
                          subtitle: Text(
                            '${DateFormat('HH:mm').format(t['date'])} @ ${t['location']}',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrainingDetailPage(
                                  id: t['id'],
                                  data: t,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
