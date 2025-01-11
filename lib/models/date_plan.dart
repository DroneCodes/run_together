import 'package:cloud_firestore/cloud_firestore.dart';

class DatePlan {
  final String id;
  final DateTime date;
  final String activity;
  final String location;
  final String notes;
  final bool isCompleted;
  final List<String> participants;

  DatePlan({
    required this.id,
    required this.date,
    required this.activity,
    required this.location,
    this.notes = '',
    this.isCompleted = false,
    required this.participants,
  });

  factory DatePlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DatePlan(
      id: doc.id,
      date: DateTime.parse(data['date']),
      activity: data['activity'],
      location: data['location'],
      notes: data['notes'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      participants: List<String>.from(data['participants']),
    );
  }
}