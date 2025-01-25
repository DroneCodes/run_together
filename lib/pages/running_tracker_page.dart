import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:run_together/pages/widgets/pace_unit_toggle.dart';

import '../providers/auth_provider.dart';
import '../providers/running_provider.dart';

class RunningTrackerPage extends ConsumerStatefulWidget {
  const RunningTrackerPage({super.key});

  @override
  ConsumerState<RunningTrackerPage> createState() => _RunningTrackerPageState();
}

class _RunningTrackerPageState extends ConsumerState<RunningTrackerPage> {
  bool _isTracking = false;
  bool _isPaused = false;
  Position? _lastPosition;
  double _distance = 0;
  Duration _duration = Duration.zero;
  late Stream<Position> _positionStream;
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required for tracking'),
        ),
      );
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _isPaused = false;
    });

    _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 1, // Trigger updates every 1 meter
            timeLimit: null // Continuous updates
        )
    );
    _positionSubscription = _positionStream.listen((Position position) {
      if (_lastPosition != null && !_isPaused) {
        final newDistance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        setState(() => _distance += newDistance);
      }
      _lastPosition = position;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTracking) {
        setState(() => _duration += const Duration(seconds: 1));
      }
    });
  }

  void _pauseTracking() {
    setState(() => _isPaused = true);
  }

  void _resumeTracking() {
    setState(() => _isPaused = false);
  }

  Future<void> _stopTracking() async {
    // Cancel all active subscriptions and timers
    _timer?.cancel();
    _positionSubscription?.cancel();

    setState(() {
      _isTracking = false;
      _isPaused = false;
    });

    // Show confirmation dialog
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Run?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${(_distance * 0.000621371).toStringAsFixed(2)} miles'),
            const SizedBox(height: 8),
            Text('Duration: ${_duration.toString().split('.').first}'),
            const SizedBox(height: 8),
            Text('Average Pace: ${_distance > 0 ? (_duration.inSeconds / (_distance * 0.621371 / 1000) / 60).toStringAsFixed(2) : '0.00'} min/mile'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave ?? false) {
      final user = ref.read(userProvider);
      if (user != null) {
        await FirebaseFirestore.instance.collection('running_activities').add({
          'userId': user.uid,
          'distance': _distance,
          'duration': _duration.inSeconds,
          'date': DateTime.now().toIso8601String(),
          'pace': _distance > 0 ? _duration.inSeconds / (_distance * 0.621371 / 1000) : 0,
          'wasInterrupted': _isPaused,
        });
      }
    }

    // Reset all tracking states
    setState(() {
      _distance = 0;
      _duration = Duration.zero;
      _lastPosition = null;
    });
  }


  @override
  Widget build(BuildContext context) {
    final runningActivities = ref.watch(runningActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Tracker'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatisticCard(
                        icon: Icons.straighten,
                        value: (_distance * 0.000621371).toStringAsFixed(2),
                        unit: 'miles',
                        label: 'Distance',
                      ),
                      const SizedBox(width: 8), // Add some spacing
                      _StatisticCard(
                        icon: Icons.timer,
                        value: _duration.toString().split('.').first,
                        unit: '',
                        label: 'Duration',
                      ),
                      const SizedBox(width: 8), // Add some spacing
                      _StatisticCard(
                        icon: Icons.speed,
                        value: _distance > 0
                            ? (_duration.inSeconds / (_distance * 0.621371 / 1000) / 60)
                            .toStringAsFixed(2)
                            : '0.00',
                        unit: 'min/mile',
                        label: 'Pace',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    if (!_isTracking)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _startTracking,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Running'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: FilledButton.icon(
                                onPressed: _isPaused ? _resumeTracking : _pauseTracking,
                                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                                label: Text(_isPaused ? 'Resume Run' : 'Pause Run'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: FilledButton.icon(
                                onPressed: _stopTracking,
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop Run'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Running History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: runningActivities.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_run,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No running activities yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final pace = activity.duration.inSeconds /
                        (activity.distance * 0.621371 / 1000) /
                        60;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.directions_run,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        title: Text(
                          DateFormat.yMMMd().add_jm().format(activity.date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _ActivityDetail(
                                    icon: Icons.straighten,
                                    value: '${(activity.distance * 0.000621371).toStringAsFixed(2)} miles',
                                  ),
                                  const SizedBox(width: 16),
                                  _ActivityDetail(
                                    icon: Icons.timer,
                                    value: activity.duration.toString().split('.').first,
                                  ),
                                  const SizedBox(width: 16),
                                  _ActivityDetail(
                                    icon: Icons.speed,
                                    value: '${pace.toStringAsFixed(2)} min/mile',
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _StatisticCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ActivityDetail extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ActivityDetail({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).hintColor,
        ),
        const SizedBox(width: 4),
        Text(value),
      ],
    );
  }
}