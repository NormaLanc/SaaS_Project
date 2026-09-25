import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Styling/folktri_colors.dart';


class AddEventPage extends StatefulWidget {
  final String familyId;
  final String? childId;

  const AddEventPage({
    super.key,
    required this.familyId,
    this.childId,
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

    selectedChildId = widget.childId;

    loadChildren();
    loadFamilyMembers();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();

    super.dispose();
  }

  // ADD STEP 8 RIGHT HERE
  Future<void> loadChildren() async {
    try {
      final response = await supabase
          .from('Children')
          .select(
            'id, first_name, middle_name, last_name',
          )
          .eq(
            'family_id',
            widget.familyId,
          )
          .order(
            'first_name',
            ascending: true,
          );

      if (!mounted) return;

      setState(() {
        children =
            List<Map<String, dynamic>>.from(
          response,
        );
      });
    } catch (e) {
      debugPrint('Unable to load children: $e');
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
    try{
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
    } catch (e) {
      debugPrint('LOAD FAMILY MEMBERS ERROR: $e');
    }
}

// ============================================================
  // DATE
  // ============================================================

  Future<void> selectDate() async {
    final current =
        startDateTime ?? DateTime.now();

    final date =
        await showDatePicker(
      context: context,
      initialDate: current,
      firstDate:
          DateTime.now().subtract(
        const Duration(days: 365),
      ),
      lastDate:
          DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (date == null) return;

    setState(() {
      final existingStart =
          startDateTime;

      final existingEnd =
          endDateTime;

      if (allDay) {
        startDateTime = DateTime(
          date.year,
          date.month,
          date.day,
        );

        endDateTime = null;
      } else {
        startDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          existingStart?.hour ?? 9,
          existingStart?.minute ?? 0,
        );

        if (existingEnd != null) {
          endDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            existingEnd.hour,
            existingEnd.minute,
          );
        }
      }
    });
  }

  // ============================================================
  // START TIME
  // ============================================================

  Future<void> selectStartTime() async {
    if (allDay) return;

    final initial =
        startDateTime != null
            ? TimeOfDay.fromDateTime(
                startDateTime!,
              )
            : TimeOfDay.now();

    final time =
        await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (time == null) return;

    final date =
        startDateTime ?? DateTime.now();

    final newStart =
        DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      startDateTime = newStart;

      // Give new events a default
      // one-hour duration.
      if (endDateTime == null ||
          !endDateTime!.isAfter(
            newStart,
          )) {
        endDateTime =
            newStart.add(
          const Duration(hours: 1),
        );
      }
    });
  }

  // ============================================================
  // END TIME
  // ============================================================

  Future<void> selectEndTime() async {
    if (allDay) return;

    final start =
        startDateTime ?? DateTime.now();

    final initialEnd =
        endDateTime ??
            start.add(
              const Duration(hours: 1),
            );

    final time =
        await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(
        initialEnd,
      ),
    );

    if (time == null) return;

    var newEnd =
        DateTime(
      start.year,
      start.month,
      start.day,
      time.hour,
      time.minute,
    );

    if (!newEnd.isAfter(start)) {
      newEnd = newEnd.add(
        const Duration(days: 1),
      );
    }

    setState(() {
      endDateTime = newEnd;
    });
  }

//   Future<void> selectStartDateTime() async {
//   final date =
//       await showDatePicker(
//     context: context,
//     initialDate:
//         startDateTime ??
//             DateTime.now(),
//     firstDate:
//         DateTime.now().subtract(
//       const Duration(
//         days: 365,
//       ),
//     ),
//     lastDate:
//         DateTime.now().add(
//       const Duration(
//         days: 3650,
//       ),
//     ),
//   );

//   if (date == null) return;

//   if (allDay) {
//     setState(() {
//       startDateTime =
//           DateTime(
//         date.year,
//         date.month,
//         date.day,
//       );
//     });

//     return;
//   }

//   if (!mounted) return;

//   final time =
//       await showTimePicker(
//     context: context,
//     initialTime:
//         TimeOfDay.now(),
//   );

//   if (time == null) return;

//   setState(() {
//     startDateTime =
//         DateTime(
//       date.year,
//       date.month,
//       date.day,
//       time.hour,
//       time.minute,
//     );
//   });
// }

  Future<void> saveEvent() async {
  final user =
      supabase.auth.currentUser;

  if (user == null) return;

  if (titleController.text
      .trim()
      .isEmpty) {
        showMessage('Please enter an event title.');

    return;
  }

  if (startDateTime == null) {
    showMessage('Please enter an event date.');

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
              'end_at': allDay ? null : endDateTime?.toUtc().toIso8601String(),
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

    showMessage('Unable to create event: $e');
  }
}

void showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // DATE FORMATTING
  // ============================================================

  static const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Select date';
    }

    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  String formatTime(
    DateTime? date,
  ) {
    if (date == null) {
      return '--:--';
    }

    final hour =
        date.hour > 12
            ? date.hour - 12
            : date.hour == 0
                ? 12
                : date.hour;

    final minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  String childFullName(
    Map<String, dynamic> child,
  ) {
    return [
      child['first_name'],
      child['middle_name'],
      child['last_name'],
    ]
        .where(
          (value) =>
              value != null &&
              value
                  .toString()
                  .trim()
                  .isNotEmpty,
        )
        .map(
          (value) =>
              value.toString().trim(),
        )
        .join(' ');
  }

  // ============================================================
  // EVENT TYPE
  // ============================================================

  IconData eventIcon(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'daycare':
        return Icons.child_care_rounded;

      case 'school':
        return Icons.school_rounded;

      case 'sports':
        return Icons.sports_soccer_rounded;

      case 'birthday':
        return Icons.cake_rounded;

      case 'appointment':
        return Icons
            .medical_services_outlined;

      case 'family':
        return Icons
            .family_restroom_rounded;

      default:
        return Icons.event_rounded;
    }
  }

  // ============================================================
  // SECTION LABEL
  // ============================================================

  Widget sectionLabel(
    String label,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color:
              FolktriColors.primaryText,
          fontSize: 13,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // FIELD DECORATION
  // ============================================================

  InputDecoration fieldDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color:
            FolktriColors.secondaryText,
        fontSize: 13,
      ),

      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color:
                  FolktriColors.primaryIndigo,
              size: 20,
            ),

      filled: true,

      fillColor:
          FolktriColors.surface,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide(
          color: FolktriColors
              .lightLavender
              .withValues(alpha: 0.9),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color:
              FolktriColors.primaryIndigo,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // EVENT TYPE CHIPS
  // ============================================================

  Widget buildEventTypes() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          eventTypes.map((type) {
        final selected =
            eventType == type;

        return ChoiceChip(
          selected: selected,

          onSelected: (_) {
            setState(() {
              eventType = type;
            });
          },

          avatar: Icon(
            eventIcon(type),
            size: 16,
            color: selected
                ? FolktriColors.surface
                : FolktriColors
                    .primaryIndigo,
          ),

          label: Text(type),

          labelStyle: TextStyle(
            color: selected
                ? FolktriColors.surface
                : FolktriColors
                    .primaryText,
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),

          selectedColor:
              FolktriColors.primaryIndigo,

          backgroundColor:
              FolktriColors.surface,

          side: BorderSide(
            color: selected
                ? FolktriColors
                    .primaryIndigo
                : FolktriColors
                    .lightLavender,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // CHILD SELECTOR
  // ============================================================

  Widget buildChildSelector() {
    return Column(
      children: [
        // Whole family
        buildChildOption(
          id: null,
          name: 'Whole family',
          photoUrl: null,
          icon:
              Icons.family_restroom_rounded,
        ),

        ...children.map(
          (child) {
            return buildChildOption(
              id:
                  child['id'].toString(),
              name:
                  childFullName(child),
              photoUrl:
                  child['profile_photo_url']
                      ?.toString(),
              icon:
                  Icons.child_care_rounded,
            );
          },
        ),
      ],
    );
  }

  Widget buildChildOption({
    required String? id,
    required String name,
    required String? photoUrl,
    required IconData icon,
  }) {
    final selected =
        selectedChildId == id;

    return InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: () {
        setState(() {
          selectedChildId = id;
        });
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 7,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration:
                  BoxDecoration(
                color: selected
                    ? FolktriColors
                        .primaryIndigo
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(
                  5,
                ),
                border: Border.all(
                  color: selected
                      ? FolktriColors
                          .primaryIndigo
                      : FolktriColors
                          .secondaryText,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color:
                          FolktriColors
                              .surface,
                      size: 16,
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            CircleAvatar(
              radius: 18,
              backgroundColor:
                  FolktriColors
                      .lightLavender,
              backgroundImage:
                  photoUrl != null &&
                          photoUrl.isNotEmpty
                      ? NetworkImage(
                          photoUrl,
                        )
                      : null,
              child: photoUrl == null ||
                      photoUrl.isEmpty
                  ? Icon(
                      icon,
                      color:
                          FolktriColors
                              .primaryIndigo,
                      size: 18,
                    )
                  : null,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                name,
                style:
                    const TextStyle(
                  color:
                      FolktriColors
                          .primaryText,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE BUTTON
  // ============================================================

  Widget buildDateButton() {
    return InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: selectDate,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color:
              FolktriColors.surface,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color:
                FolktriColors.lightLavender,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons
                  .calendar_month_outlined,
              color:
                  FolktriColors.primaryIndigo,
              size: 20,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                formatDate(
                  startDateTime,
                ),
                style:
                    const TextStyle(
                  color:
                      FolktriColors
                          .primaryText,
                  fontSize: 13,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color:
                  FolktriColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIME BUTTON
  // ============================================================

  Widget buildTimeButton({
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color:
              FolktriColors.surface,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color:
                FolktriColors.lightLavender,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              color:
                  FolktriColors.primaryIndigo,
              size: 18,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                formatTime(value),
                style:
                    const TextStyle(
                  color:
                      FolktriColors
                          .primaryText,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color:
                  FolktriColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          FolktriColors.background,

      appBar: AppBar(
        backgroundColor:
            FolktriColors.midnightIndigo,
        foregroundColor:
            FolktriColors.surface,
        elevation: 0,
        automaticallyImplyLeading:
            false,

        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
          ),
          tooltip: 'Cancel',
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'Add Event',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        centerTitle: true,

        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: IconButton(
              tooltip: 'Create Event',
              onPressed:
                  isSaving
                      ? null
                      : saveEvent,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            FolktriColors
                                .surface,
                      ),
                    )
                  : const CircleAvatar(
                      radius: 17,
                      backgroundColor:
                          FolktriColors
                              .primaryIndigo,
                      child: Icon(
                        Icons.check_rounded,
                        color:
                            FolktriColors
                                .surface,
                        size: 19,
                      ),
                    ),
            ),
          ),
        ],
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          40,
        ),

        child: Container(
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color:
                FolktriColors.surface,
            borderRadius:
                BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: FolktriColors
                    .midnightIndigo
                    .withValues(
                      alpha: 0.04,
                    ),
                blurRadius: 18,
                offset:
                    const Offset(0, 5),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // TITLE
              sectionLabel('Title'),

              TextField(
                controller:
                    titleController,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                decoration:
                    fieldDecoration(
                  hint: 'Event title',
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // EVENT TYPE
              sectionLabel(
                'Event Type',
              ),

              buildEventTypes(),

              const SizedBox(
                height: 22,
              ),

              // DATE
              sectionLabel('Date'),

              buildDateButton(),

              const SizedBox(
                height: 20,
              ),

              // ALL DAY
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'All-day event',
                      style:
                          TextStyle(
                        color:
                            FolktriColors
                                .primaryText,
                        fontSize: 13,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ),

                  Switch(
                    value: allDay,
                    activeThumbColor:
                        FolktriColors
                            .primaryIndigo,
                    onChanged: (value) {
                      setState(() {
                        allDay = value;

                        if (value) {
                          final date =
                              startDateTime ??
                                  DateTime
                                      .now();

                          startDateTime =
                              DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );

                          endDateTime =
                              null;
                        }
                      });
                    },
                  ),
                ],
              ),

              if (!allDay) ...[
                const SizedBox(
                  height: 12,
                ),

                sectionLabel('Time'),

                Row(
                  children: [
                    Expanded(
                      child:
                          buildTimeButton(
                        value:
                            startDateTime,
                        onTap:
                            selectStartTime,
                      ),
                    ),

                    const Padding(
                      padding:
                          EdgeInsets
                              .symmetric(
                        horizontal: 10,
                      ),
                      child: Text(
                        'to',
                        style:
                            TextStyle(
                          color:
                              FolktriColors
                                  .secondaryText,
                        ),
                      ),
                    ),

                    Expanded(
                      child:
                          buildTimeButton(
                        value:
                            endDateTime,
                        onTap:
                            selectEndTime,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(
                height: 22,
              ),

              // CHILD
              sectionLabel(
                'Add to Child (optional)',
              ),

              buildChildSelector(),

              const SizedBox(
                height: 22,
              ),

              // LOCATION
              sectionLabel(
                'Location (optional)',
              ),

              TextField(
                controller:
                    locationController,
                textCapitalization:
                    TextCapitalization
                        .words,
                decoration:
                    fieldDecoration(
                  hint:
                      'Enter location',
                  icon: Icons
                      .location_on_outlined,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // DESCRIPTION
              sectionLabel(
                'Description (optional)',
              ),

              TextField(
                controller:
                    descriptionController,
                maxLines: 4,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                decoration:
                    fieldDecoration(
                  hint: 'Add details...',
                  icon: Icons
                      .notes_rounded,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // REMINDER
              sectionLabel(
                'Reminder',
              ),

              DropdownButtonFormField<
                  int>(
                initialValue:
                    reminderMinutes,

                decoration:
                    fieldDecoration(
                  hint:
                      'Select reminder',
                  icon: Icons
                      .notifications_none_rounded,
                ),

                items: const [
                  DropdownMenuItem(
                    value: 15,
                    child: Text(
                      '15 minutes before',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 60,
                    child: Text(
                      '1 hour before',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 1440,
                    child: Text(
                      '1 day before',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 10080,
                    child: Text(
                      '1 week before',
                    ),
                  ),
                ],

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    reminderMinutes =
                        value;
                  });
                },
              ),

              const SizedBox(
                height: 20,
              ),

              // REPEAT
              sectionLabel('Repeat'),

              DropdownButtonFormField<
                  String>(
                initialValue:
                    recurrenceType,

                decoration:
                    fieldDecoration(
                  hint:
                      'Does not repeat',
                  icon:
                      Icons.repeat_rounded,
                ),

                items: const [
                  DropdownMenuItem(
                    value: 'none',
                    child: Text(
                      'Does not repeat',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'daily',
                    child:
                        Text('Daily'),
                  ),
                  DropdownMenuItem(
                    value: 'weekly',
                    child:
                        Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child:
                        Text('Monthly'),
                  ),
                  DropdownMenuItem(
                    value: 'yearly',
                    child:
                        Text('Yearly'),
                  ),
                ],

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    recurrenceType =
                        value;
                  });
                },
              ),

              const SizedBox(
                height: 28,
              ),

              // CREATE EVENT
              SizedBox(
                width: double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      isSaving
                          ? null
                          : saveEvent,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        FolktriColors
                            .primaryIndigo,
                    foregroundColor:
                        FolktriColors
                            .surface,
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                    ),
                  ),

                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                FolktriColors
                                    .surface,
                          ),
                        )
                      : const Icon(
                          Icons
                              .check_rounded,
                        ),

                  label: Text(
                    isSaving
                        ? 'Creating...'
                        : 'Create Event',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}