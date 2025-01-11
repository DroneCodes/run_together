import 'package:cloud_firestore/cloud_firestore.dart';

class RunningActivity {
  final String id;
  final DateTime date;
  final double distance;
  final Duration duration;
  final String userId;

  RunningActivity({
    required this.id,
    required this.date,
    required this.distance,
    required this.duration,
    required this.userId,
  });

  factory RunningActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RunningActivity(
      id: doc.id,
      date: DateTime.parse(data['date']),
      distance: data['distance'].toDouble(),
      duration: Duration(seconds: data['duration']),
      userId: data['userId'],
    );
  }
}