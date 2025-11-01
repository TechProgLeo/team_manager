import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'training_detail_page.dart';
import 'calendar_trainings_page.dart';
import 'package:uuid/uuid.dart';

enum TrainingViewMode { week, month, all }

class TrainingsPage extends StatefulWidget {
  const TrainingsPage({super.key});

  @override
  State<TrainingsPage> createState() => _TrainingsPageState();
}

class _TrainingsPageState extends State<TrainingsPage> {
  TrainingViewMode _mode = TrainingViewMode.week;

  @override
  Widget build(BuildContext context) {
    final trainingsRef = FirebaseFirestore.instance.collection('trainings');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Trainings'),
        actions: [
          PopupMenuButton<TrainingViewMode>(
            onSelected: (value) => setState(() => _mode = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TrainingViewMode.week,
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: TrainingViewMode.month,
                child: Text('This Month'),
              ),
              const PopupMenuItem(
                value: TrainingViewMode.all,
                child: Text('All Trainings'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalendarTrainingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: trainingsRef.orderBy('date', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();

            switch (_mode) {
              case TrainingViewMode.week:
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                final endOfWeek = startOfWeek.add(const Duration(days: 7));
                return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
              case TrainingViewMode.month:
                return date.year == now.year && date.month == now.month;
              case TrainingViewMode.all:
                return true;
            }
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No trainings found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final training = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final title = training['title'] ?? 'Untitled';
              final location = training['location'] ?? 'Unknown';
              final date = (training['date'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainingDetailPage(
                            id: id,
                            data: training,
                          ),
                        ),
                      );
                    },
                  title: Text(title),
                  subtitle: Text(
                    '${DateFormat('EEE, MMM d – HH:mm').format(date)} @ $location',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showAddOrEditDialog(context, trainingsRef, id, training);
                      } else if (value == 'delete') {
                          final groupId = training['repeatGroupId'];

                          if (groupId != null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Training'),
                                content: const Text(
                                  'Do you want to delete only this session or all sessions in this series?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      await trainingsRef.doc(id).delete();
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                    child: const Text('Only this'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final query = await trainingsRef
                                          .where('repeatGroupId', isEqualTo: groupId)
                                          .get();
                                      for (final doc in query.docs) {
                                        await doc.reference.delete();
                                      }
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                    child: const Text('Entire series'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            await trainingsRef.doc(id).delete();
                          }
                        }

                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(context, trainingsRef, null, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Opens a dialog to add or edit a training.
  /// Opens a dialog to add or edit a training, with optional weekly repeat.
  void _showAddOrEditDialog(
      BuildContext context,
      CollectionReference trainingsRef,
      String? id,
      Map<String, dynamic>? data) {
    final titleController = TextEditingController(text: data?['title']);
    final locationController = TextEditingController(text: data?['location']);
    DateTime? selectedDate =
        data?['date'] != null ? (data!['date'] as Timestamp).toDate() : null;

    bool repeatWeekly = false;
    DateTime? repeatUntil;
    final existingGroupId = data?['repeatGroupId']; // for edits

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(id == null ? 'Add Training' : 'Edit Training'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'No date selected'
                                : DateFormat('yyyy-MM-dd HH:mm')
                                    .format(selectedDate!),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            FocusScope.of(context).unfocus(); // 🩹 Fix 1
                            Future<DateTime?> pickDateTime(BuildContext context, DateTime? initial) async {
                              final pickedDate = await showDatePicker(
                                context: Navigator.of(context, rootNavigator: true).context,
                                initialDate: initial ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (pickedDate == null) return null;

                              final pickedTime = await showTimePicker(
                                context: Navigator.of(context, rootNavigator: true).context,
                                initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
                              );

                              if (pickedTime == null) return null;

                              return DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            }
                                final newDate = await pickDateTime(context, selectedDate);
                                if (newDate != null) {
                                  setState(() => selectedDate = newDate);
                                }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    CheckboxListTile(
                      title: const Text('Repeat weekly'),
                      value: repeatWeekly,
                      onChanged: (v) => setState(() => repeatWeekly = v ?? false),
                    ),
                    if (repeatWeekly)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              repeatUntil == null
                                  ? 'No end date selected'
                                  : 'Until: ${DateFormat('yyyy-MM-dd').format(repeatUntil!)}',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: () async {
                              FocusScope.of(context).unfocus(); // 🩹 Fix 1
                              final first = selectedDate ?? DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: first,
                                firstDate: first,
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => repeatUntil = picked);
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        locationController.text.isEmpty ||
                        selectedDate == null) return;

                    final dataToSave = {
                      'title': titleController.text.trim(),
                      'location': locationController.text.trim(),
                      'date': Timestamp.fromDate(selectedDate!),
                      'repeatGroupId': existingGroupId ?? const Uuid().v4(),
                    };

                    if (id == null) {
                      // Add initial training
                      await trainingsRef.add(dataToSave);

                      // Add repeating ones weekly
                      if (repeatWeekly && repeatUntil != null) {
                        DateTime next = selectedDate!.add(const Duration(days: 7));
                        while (next.isBefore(
                            repeatUntil!.add(const Duration(days: 1)))) {
                          await trainingsRef.add({
                            ...dataToSave,
                            'date': Timestamp.fromDate(next),
                          });
                          next = next.add(const Duration(days: 7));
                        }
                      }
                    } else {
                      await trainingsRef.doc(id).update(dataToSave);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(id == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
