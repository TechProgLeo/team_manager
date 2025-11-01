import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TrainingDetailPage extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const TrainingDetailPage({super.key, required this.id, required this.data});

  @override
  State<TrainingDetailPage> createState() => _TrainingDetailPageState();
}

class _TrainingDetailPageState extends State<TrainingDetailPage> {
  late bool isAttending;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    final attendees = List<String>.from(widget.data['attendees'] ?? []);
    isAttending = user != null && attendees.contains(user!.email);
  }

  Future<void> _toggleAttendance() async {
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('trainings').doc(widget.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data() ?? {};
      final attendees = List<String>.from(data['attendees'] ?? []);

      if (attendees.contains(user!.email)) {
        attendees.remove(user!.email);
      } else {
        attendees.add(user!.email!);
      }

      transaction.update(ref, {'attendees': attendees});
    });

    setState(() {
      isAttending = !isAttending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final date = (data['date'] as Timestamp).toDate();

    return Scaffold(
      appBar: AppBar(title: Text(data['title'] ?? 'Training Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Location: ${data['location'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('🗓 Date: ${DateFormat('EEE, MMM d – HH:mm').format(date)}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trainings')
                  .doc(widget.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final attendees = List<String>.from(data['attendees'] ?? []);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👥 Attendees (${attendees.length}):',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    ...attendees.map((a) => Text('- $a')),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _toggleAttendance,
                      icon: Icon(
                        isAttending ? Icons.remove_circle : Icons.add_circle,
                      ),
                      label: Text(isAttending
                          ? 'Cancel Attendance'
                          : 'Join This Training'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
