import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AddEventPage extends StatefulWidget {
  final String familyId;

  const AddEventPage({
    super.key,
    required this.familyId,
  });

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  List<Map<String, dynamic>> children = [];
  List<Map<String, dynamic>> familyMembers = [];

  String? selectedChildId;
  String? assignedUserId;

  String eventType = 'Other';

  DateTime? startDateTime;
  DateTime? endDateTime;

  bool allDay = false;
  bool isSaving = false;

  int reminderMinutes = 1440;

  String recurrenceType = 'none';

  final eventTypes = [
    'Daycare',
    'School',
    'Sports',
    'Birthday',
    'Appointment',
    'Family',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    loadChildren();
    loadFamilyMembers();
  }

  // ADD STEP 8 RIGHT HERE
  Future<void> loadChildren() async {
    try {
      final response = await supabase
          .from('Children')
          .select(
            '''
            id,
            first_name,
            middle_name,
            last_name
            ''',
          )
          .eq(
            'family_id',
            widget.familyId,
          )
          .order(
            'first_name',
          );

      if (!mounted) return;

      setState(() {
        children =
            List<Map<String, dynamic>>.from(
          response,
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load children: $e',
          ),
        ),
      );
    }
  }

  Future<void> loadFamilyMembers() async {
  final response =
      await supabase
          .from('Family_Members')
          .select(
            '''
            user_id,
            role
            ''',
          )
          .eq(
            'family_id',
            widget.familyId,
          )
          .eq(
            'status',
            'approved',
          );

  if (!mounted) return;

  setState(() {
    familyMembers =
        List<Map<String, dynamic>>.from(
      response,
    );
  });
}

  Future<void> selectStartDateTime() async {
  final date =
      await showDatePicker(
    context: context,
    initialDate:
        startDateTime ??
            DateTime.now(),
    firstDate:
        DateTime.now().subtract(
      const Duration(
        days: 365,
      ),
    ),
    lastDate:
        DateTime.now().add(
      const Duration(
        days: 3650,
      ),
    ),
  );

  if (date == null) return;

  if (allDay) {
    setState(() {
      startDateTime =
          DateTime(
        date.year,
        date.month,
        date.day,
      );
    });

    return;
  }

  if (!mounted) return;

  final time =
      await showTimePicker(
    context: context,
    initialTime:
        TimeOfDay.now(),
  );

  if (time == null) return;

  setState(() {
    startDateTime =
        DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  });
}

  Future<void> saveEvent() async {
  final user =
      supabase.auth.currentUser;

  if (user == null) return;

  if (titleController.text
      .trim()
      .isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Please enter an event title.',
        ),
      ),
    );

    return;
  }

  if (startDateTime == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Please select an event date.',
        ),
      ),
    );

    return;
  }

  try {
    setState(() {
      isSaving = true;
    });

    // final createdEvent =
        await supabase
            .from('Calendar_Events')
            .insert({
              'family_id': widget.familyId,
              'child_id': selectedChildId,
              'title': titleController.text.trim(),
              'description': descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
              'event_type': eventType,
              'start_at': startDateTime!.toUtc().toIso8601String(),
              'end_at': endDateTime?.toUtc().toIso8601String(),
              'all_day': allDay,
              'location': locationController.text.trim().isEmpty
                      ? null
                      : locationController.text.trim(),
              'assigned_to': assignedUserId,
              'reminder_minutes': reminderMinutes,
              'recurrence': recurrenceType,
              'created_by': user.id,
            });
            // .select()
            // .single();

    if (!mounted) return;

    context.pop(true);
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to create event: $e',
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      title:
          const Text(
        'Add Event',
      ),
    ),

    body:
        SingleChildScrollView(
      padding:
          const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          TextField(
            controller:
                titleController,
            decoration:
                const InputDecoration(
              labelText:
                  'Event title',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          DropdownButtonFormField<String>(
            initialValue:
                eventType,
            decoration:
                const InputDecoration(
              labelText:
                  'Event type',
              border:
                  OutlineInputBorder(),
            ),
            items:
                eventTypes.map(
              (type) {
                return DropdownMenuItem(
                  value:
                      type,
                  child:
                      Text(type),
                );
              },
            ).toList(),
            onChanged:
                (value) {
              if (value == null) {
                return;
              }

              setState(() {
                eventType =
                    value;
              });
            },
          ),

          const SizedBox(
            height: 16,
          ),

          DropdownButtonFormField<String?>(
            initialValue:
                selectedChildId,
            decoration:
                const InputDecoration(
              labelText:
                  'Child (optional)',
              border:
                  OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<
                  String?>(
                value:
                    null,
                child:
                    Text(
                  'Whole family / No specific child',
                ),
              ),

              ...children.map(
                (child) {
                  final name = [
                    child[
                        'first_name'],
                    child[
                        'middle_name'],
                    child[
                        'last_name'],
                  ]
                      .where(
                        (value) =>
                            value !=
                                null &&
                            value.toString().trim().isNotEmpty,
                      ).join(' ');

                  return DropdownMenuItem<
                      String?>(
                    value:
                        child['id'].toString(),
                    child:
                        Text(name),
                  );
                },
              ),
            ],
            onChanged:
                (value) {
              setState(() {
                selectedChildId =
                    value;
              });
            },
          ),

          const SizedBox(height: 16),
          SwitchListTile(
            title:
                const Text('All-day event'),
            value:
                allDay,
            onChanged:
                (value) {
              setState(() {
                allDay = value;
              });
            },
          ),

          ListTile(
            leading:
                const Icon(Icons.schedule,),
            title:
                const Text('Date & Time',),
            subtitle: Text(startDateTime == null
                  ? 'Select date'
                  : startDateTime.toString(),
            ),
            onTap: selectStartDateTime,
          ),

          const SizedBox(height: 8,),

          TextField(
            controller: locationController,
            decoration: const InputDecoration(
              labelText: 'Location (optional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16,),

          TextField(
            controller: descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16,),

          DropdownButtonFormField<int>(
            initialValue: reminderMinutes,
            decoration: const InputDecoration(
              labelText: 'Reminder',
              border: OutlineInputBorder(),
            ),
            items:
                const [
              DropdownMenuItem(
                value: 15,
                child:
                    Text('15 minutes before',),
              ),
              DropdownMenuItem(
                value: 60,
                child:
                    Text('1 hour before',),
              ),
              DropdownMenuItem(
                value: 1440,
                child:
                    Text('1 day before',),
              ),
              DropdownMenuItem(
                value: 10080,
                child:
                    Text('1 week before',),
              ),
            ],
            onChanged:
                (value) {
              if (value ==
                  null) {
                return;
              }

              setState(() {
                reminderMinutes =
                    value;
              });
            },
          ),

          const SizedBox(height: 16,),

          DropdownButtonFormField<String>(
            initialValue:
                recurrenceType,
            decoration:
                const InputDecoration(
              labelText: 'Repeat',
              border: OutlineInputBorder(),
            ),
            items:
                const [
              DropdownMenuItem(
                value: 'none',
                child:
                    Text('Does not repeat',),
              ),
              DropdownMenuItem(
                value: 'daily',
                child:
                    Text('Daily',),
              ),
              DropdownMenuItem(
                value: 'weekly',
                child:
                    Text('Weekly',),
              ),
              DropdownMenuItem(
                value: 'monthly',
                child:
                    Text('Monthly',),
              ),
              DropdownMenuItem(
                value: 'yearly',
                child:
                    Text('Yearly',),
              ),
            ],
            onChanged:
                (value) {
              if (value == null) {
                return;
              }

              setState(() {
                recurrenceType = value;
              });
            },
          ),

          const SizedBox( height: 24,),

          SizedBox(
            width: double.infinity,
            child:
                ElevatedButton(
              onPressed: 
                    isSaving
                      ? null
                      : saveEvent,

              child:
                  isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Create Event',),
            ),
          ),
        ],
      ),
    ),
  );
  }
}