import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/date_plan.dart';
import 'auth_provider.dart';

final datePlansProvider = StreamProvider.autoDispose((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('date_plans')
      .where('participants', arrayContains: user.uid)
      .orderBy('date')
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => DatePlan.fromFirestore(doc))
      .toList());
});