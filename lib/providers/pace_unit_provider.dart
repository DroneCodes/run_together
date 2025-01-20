import 'package:flutter_riverpod/flutter_riverpod.dart';

final paceUnitProvider = StateNotifierProvider<PaceUnitNotifier, String>((ref) {
  return PaceUnitNotifier();
});

class PaceUnitNotifier extends StateNotifier<String> {
  PaceUnitNotifier() : super('min/km');

  void toggleUnit() {
    state = state == 'min/km' ? 'min/mile' : 'min/km';
  }
}