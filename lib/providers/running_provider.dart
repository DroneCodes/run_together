import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/running_activity.dart';
import 'auth_provider.dart';

final runningActivitiesProvider = StreamProvider.autoDispose((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('running_activities')
      .where('userId', isEqualTo: user.uid)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => RunningActivity.fromFirestore(doc))
      .toList());
});
