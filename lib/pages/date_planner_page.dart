import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/auth_provider.dart';
import '../providers/date_provider.dart';

class DatePlannerPage extends ConsumerStatefulWidget {
  const DatePlannerPage({super.key});

  @override
  ConsumerState<DatePlannerPage> createState() => _DatePlannerPageState();
}

class _DatePlannerPageState extends ConsumerState<DatePlannerPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final datePlans = ref.watch(datePlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Planner'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) {
                return datePlans.when(
                  data: (plans) => plans
                      .where((plan) => isSameDay(plan.date, day))
                      .toList(),
                  loading: () => [],
                  error: (_, __) => [],
                );
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: datePlans.when(
              data: (plans) {
                final selectedDayPlans = plans
                    .where((plan) => isSameDay(plan.date, _selectedDay))
                    .toList();

                if (selectedDayPlans.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No plans for ${DateFormat.yMMMd().format(_selectedDay)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedDayPlans.length,
                  itemBuilder: (context, index) {
                    final plan = selectedDayPlans[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.event,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        title: Text(
                          plan.activity,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Theme.of(context).hintColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(child: Text(plan.location)),
                              ],
                            ),
                            if (plan.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.notes,
                                    size: 16,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(plan.notes)),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Checkbox(
                          value: plan.isCompleted,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('date_plans')
                                .doc(plan.id)
                                .update({'isCompleted': value});
                          },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Plan'),
      ),
    );
  }

  Future<void> _showAddDateDialog(BuildContext context) async {
    final activityController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.event_available,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text('Plan a Date'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${DateFormat.yMMMd().format(_selectedDay)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: activityController,
                decoration: InputDecoration(
                  labelText: 'Activity',
                  prefixIcon: const Icon(Icons.local_activity),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Time'),
                leading: const Icon(Icons.access_time),
                trailing: Text(
                  selectedTime.format(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    selectedTime = picked;
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (activityController.text.isEmpty ||
                  locationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in activity and location'),
                  ),
                );
                return;
              }

              final user = ref.read(userProvider);
              if (user != null) {
                final DateTime dateTime = DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                await FirebaseFirestore.instance.collection('date_plans').add({
                  'activity': activityController.text,
                  'location': locationController.text,
                  'notes': notesController.text,
                  'date': dateTime.toIso8601String(),
                  'isCompleted': false,
                  'participants': [user.uid],
                });
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}