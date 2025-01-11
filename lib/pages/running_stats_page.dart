import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/running_activity.dart';
import '../providers/running_provider.dart';

class RunningStatsPage extends ConsumerWidget {
  const RunningStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runningActivities = ref.watch(runningActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Statistics'),
        elevation: 0,
        centerTitle: true,
      ),
      body: runningActivities.when(
        data: (activities) {
          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No running activities to analyze',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final weeklyData = _getWeeklyData(activities);
          final totalDistance = activities.fold<double>(
              0, (sum, activity) => sum + activity.distance);
          final totalDuration = activities.fold<Duration>(
              Duration.zero, (sum, activity) => sum + activity.duration);
          final averagePace = totalDuration.inSeconds / (totalDistance / 1000);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Distance',
                      value: '${(totalDistance / 1000).toStringAsFixed(2)} km',
                      icon: Icons.straighten,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Time',
                      value: totalDuration.toString().split('.').first,
                      icon: Icons.timer,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StatCard(
                title: 'Average Pace',
                value: '${(averagePace / 60).toStringAsFixed(2)} min/km',
                icon: Icons.speed,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(height: 32),
              Text(
                'Weekly Progress',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 2,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    weeklyData.keys
                                        .elementAt(value.toInt())
                                        .substring(5),
                                    style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 2,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()} km',
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: weeklyData.entries
                                .map((e) => FlSpot(
                                    weeklyData.keys
                                        .toList()
                                        .indexOf(e.key)
                                        .toDouble(),
                                    e.value))
                                .toList(),
                            isCurved: true,
                            color: Theme.of(context).primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Theme.of(context).primaryColor,
                                  strokeWidth: 2,
                                  strokeColor: Theme.of(context).cardColor,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                            ),
                          ),
                        ],
                        minY: 0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Recent Activities',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...activities.take(5).map((activity) => _RecentActivityCard(
                    activity: activity,
                    onTap: () => _showActivityDetails(context, activity),
                  )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showActivityDetails(BuildContext context, RunningActivity activity) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: DateFormat.yMMMd().add_jm().format(activity.date),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.straighten,
              label: 'Distance',
              value: '${(activity.distance / 1000).toStringAsFixed(2)} km',
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.timer,
              label: 'Duration',
              value: activity.duration.toString().split('.').first,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.speed,
              label: 'Average Pace',
              value:
                  '${(activity.duration.inSeconds / (activity.distance / 1000) / 60).toStringAsFixed(2)} min/km',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final RunningActivity activity;
  final VoidCallback onTap;

  const _RecentActivityCard({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_run,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(activity.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(activity.distance / 1000).toStringAsFixed(2)} km • ${activity.duration.toString().split('.').first}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

Map<String, double> _getWeeklyData(List<dynamic> activities) {
  final Map<String, double> weeklyDistance = {};
  final now = DateTime.now();

  for (var i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final dateStr = DateFormat('MM-dd').format(date);
    weeklyDistance[dateStr] = 0;
  }

  for (final activity in activities) {
    if (activity is RunningActivity) {
      final dateStr = DateFormat('MM-dd').format(activity.date);
      if (weeklyDistance.containsKey(dateStr)) {
        weeklyDistance[dateStr] =
            (weeklyDistance[dateStr] ?? 0) + activity.distance / 1000;
      }
    }
  }

  return weeklyDistance;
}
