import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_together/providers/pace_unit_provider.dart';

class PaceUnitToggle extends ConsumerWidget {
  const PaceUnitToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paceUnit = ref.watch(paceUnitProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Pace Unit: $paceUnit'),
        Switch(
          value: paceUnit == 'min/mile',
          onChanged: (value) {
            ref.read(paceUnitProvider.notifier).toggleUnit();
          },
        ),
      ],
    );
  }
}