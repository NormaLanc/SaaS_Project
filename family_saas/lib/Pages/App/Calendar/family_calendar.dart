import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../Styling/folktri_colors.dart';

class FamilyCalendarPage extends StatefulWidget {
  final String familyId;

  const FamilyCalendarPage({
    super.key,
    required this.familyId,
  });

  @override
  State<FamilyCalendarPage> createState() =>
      _FamilyCalendarPageState();
}

class _FamilyCalendarPageState
    extends State<FamilyCalendarPage> {

  final supabase = Supabase.instance.client;

  DateTime focusedDay = DateTime.now();

  DateTime? selectedDay = DateTime.now();

  List<Map<String, dynamic>> events = [];

  bool isLoading = true;

  String familyName = 'Family';
  String? selectedFamilyId;

  List<Map<String, dynamic>> userFamilies = [];
  List<Map<String, dynamic>> children = [];

  bool isLoadingFamilies = true;
  String calendarView = 'month';

  @override
  void initState() {
    super.initState();
    selectedFamilyId = widget.familyId;

    loadCalendar();
  }

  Future<void> loadCalendar() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      await loadUserFamilies();

      await Future.wait([
        loadFamily(),
        loadEvents(),
        loadChildren(),
      ]);

      if (!mounted) return;

      setState(() {
        // events =
        //     List<Map<String, dynamic>>
        //         .from(response);

        isLoading = false;
      });

    } catch (e) {
      debugPrint('CALENDAR LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load calendar: $e',
          ),
        ),
      );
    }
  }

  Future<void> loadUserFamilies() async {
  final user = supabase.auth.currentUser;

  if (user == null) return;

  try {
    // Families created by the current user.
    final ownedResponse = await supabase
        .from('Families')
        .select(
          'id, family_name, created_by',
        )
        .eq(
          'created_by',
          user.id,
        );

    // Families the current user has joined.
    final membershipResponse = await supabase
        .from('Family_Members')
        .select('family_id')
        .eq(
          'user_id',
          user.id,
        )
        .eq(
          'status',
          'approved',
        );

    final familyIds = <String>{};

    for (final family in ownedResponse) {
      final id = family['id']?.toString();

      if (id != null && id.isNotEmpty) {
        familyIds.add(id);
      }
    }

    for (final membership in membershipResponse) {
      final id =
          membership['family_id']?.toString();

      if (id != null && id.isNotEmpty) {
        familyIds.add(id);
      }
    }

    if (familyIds.isEmpty) {
      if (!mounted) return;

      setState(() {
        userFamilies = [];
        isLoadingFamilies = false;
      });

      return;
    }

    final familyResponse = await supabase
        .from('Families')
        .select(
          'id, family_name, created_by',
        )
        .inFilter(
          'id',
          familyIds.toList(),
        )
        .order('family_name');

    if (!mounted) return;

    final loadedFamilies =
        List<Map<String, dynamic>>.from(
      familyResponse,
    );

    setState(() {
      userFamilies = loadedFamilies;
      isLoadingFamilies = false;

      // Safety fallback in case the family that
      // opened Calendar is no longer accessible.
      final selectedStillExists =
          loadedFamilies.any(
        (family) =>
            family['id']?.toString() ==
            selectedFamilyId,
      );

      if (!selectedStillExists &&
          loadedFamilies.isNotEmpty) {
        selectedFamilyId =
            loadedFamilies.first['id']
                .toString();
      }
    });
  } catch (e) {
    debugPrint(
      'LOAD USER FAMILIES ERROR: $e',
    );

    if (!mounted) return;

    setState(() {
      isLoadingFamilies = false;
    });

    rethrow;
  }
}

Future<void> loadChildren() async {
  final familyId = selectedFamilyId;

  if (familyId == null) {
    if (!mounted) return;

    setState(() {
      children = [];
    });

    return;
  }

  try {
    final response = await supabase
        .from('Children')
        .select(
          'id, first_name, middle_name, last_name, profile_photo_path',
        )
        .eq(
          'family_id',
          familyId,
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
    debugPrint(
      'LOAD CALENDAR CHILDREN ERROR: $e',
    );

    rethrow;
  }
}

   // ============================================================
  // LOAD FAMILY
  // ============================================================

  Future<void> loadFamily() async {
    final familyId = selectedFamilyId;

    if (familyId == null) return;

    final response = await supabase
        .from('Families')
        .select('id, family_name')
        .eq('id', familyId)
        .maybeSingle();

    if (!mounted || response == null) return;

    setState(() {
      familyName =
          response['family_name']?.toString() ??
              'Family';
    });
  }

  // ============================================================
  // LOAD EVENTS
  // ============================================================

  Future<void> loadEvents() async {
    final familyId = selectedFamilyId;

    if (familyId == null) {
      if (!mounted) return;

    setState(() {
      events = [];
    });

    return;
  }

  try{
    final response = await supabase
        .from('Calendar_Events')
        .select(
          // '''
          // *,
          // Children (
          //   id,
          //   first_name,
          //   middle_name,
          //   last_name,
          //   profile_photo_path
          // )
          // ''',
        )
        .eq(
          'family_id',
          familyId,
        )
        .order(
          'start_at',
          ascending: true,
        );

    if (!mounted) return;

    setState(() {
      events =
          List<Map<String, dynamic>>.from(
        response,
      );
    });
  } catch(e){
    debugPrint('LOAD CALENDAR EVENTS ERROR: $e');
    rethrow;
  }
  }

  List<Map<String, dynamic>> eventsForDay(DateTime day) {

    return events.where((event) {

      final value = event['start_at']?.toString();

      if (value == null) return false;

      final eventDate = DateTime.tryParse(value)?.toLocal();

      if (eventDate == null) return false;

      // final eventDate = DateTime.parse(
      //   event['start_at'].toString(),
      // ).toLocal();

      return eventDate.year == day.year &&
          eventDate.month == day.month &&
          eventDate.day == day.day;
    }).toList();
  }

  Future<bool> confirmDelete({
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: FolktriColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
          style: const TextStyle(
            color: FolktriColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: FolktriColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child: const Text(
              'Cancel',
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FolktriColors.dustyRose,
              foregroundColor: FolktriColors.surface,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            child: const Text(
              'Delete',
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

  Future<void> deleteEvent(
  String eventId,
) async {
  final shouldDelete =
      await confirmDelete(
    title: 'Delete Event',
    message:
        'Are you sure you want to delete this event?',
  );

  if (!shouldDelete) return;

  try {
    await supabase
        .from('Calendar_Events')
        .delete()
        .eq(
          'id',
          eventId,
        );

    await loadEvents();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Event deleted.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete event: $e',
        ),
      ),
    );
  }
}

// ============================================================
  // ADD EVENT
  // ============================================================

  Future<void> openAddEvent() async {

    final familyId = selectedFamilyId;

    if (familyId == null) {
      ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Please select a family first.',
        ),
      ),
    );

    return;
  }

    final result =
        await context.push<bool>(
      '/family/${widget.familyId}/calendar/add-event',
    );

    if (result == true) {
      await loadEvents();
    }
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _shortMonths = [
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

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String formatFullDate(
    DateTime date,
  ) {
    return '${_weekdays[date.weekday - 1]}, '
        '${_months[date.month - 1]} '
        '${date.day}';
  }

  String formatMonthYear(
    DateTime date,
  ) {
    return '${_months[date.month - 1]} ${date.year}';
  }

  String formatShortDate(
    DateTime date,
  ) {
    return '${_shortMonths[date.month - 1]} '
        '${date.day}';
  }

  String formatTime(
    DateTime date,
  ) {
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String formatEventTime(
    Map<String, dynamic> event,
  ) {
    if (event['all_day'] == true) {
      return 'All day';
    }

    final start = DateTime.tryParse(
      event['start_at']?.toString() ?? '',
    )?.toLocal();

    final end = DateTime.tryParse(
      event['end_at']?.toString() ?? '',
    )?.toLocal();

    if (start == null) {
      return '';
    }

    if (end == null) {
      return formatTime(start);
    }

    return '${formatTime(start)} – ${formatTime(end)}';
  }

  // ============================================================
  // CHILD NAME
  // ============================================================

  String childName(Map<String, dynamic> event,) {
    //final child = event['Children'];

    // if (child is! Map) {
    //   return '';
    // }
    final childId =
      event['child_id']?.toString();

  if (childId == null ||
      childId.isEmpty) {
    return '';
  }

  Map<String, dynamic>? matchingChild;

  for (final child in children) {
    if (child['id']?.toString() ==
        childId) {
      matchingChild = child;
      break;
    }
  }

  if (matchingChild == null) {
    return '';
  }

    return [
      matchingChild['first_name'],
      matchingChild['middle_name'],
      matchingChild['last_name'],
    ]
        .where(
          (value) =>
              value != null &&
              value.toString().trim().isNotEmpty,
        )
        .map(
          (value) => value.toString().trim(),
        )
        .join(' ');
  }

  // ============================================================
  // EVENT ICON
  // ============================================================

  IconData eventIcon(
    dynamic type,
  ) {
    switch (
        type?.toString().toLowerCase()) {
      case 'daycare':
        return Icons.child_care_rounded;

      case 'sports':
        return Icons.sports_soccer_rounded;

      case 'birthday':
        return Icons.cake_rounded;

      case 'school':
        return Icons.school_rounded;

      case 'medical':
      case 'appointment':
        return Icons.medical_services_outlined;

      case 'family':
        return Icons.family_restroom_rounded;

      default:
        return Icons.event_rounded;
    }
  }

  // ============================================================
  // EVENT COLOR
  // ============================================================

  Color eventColor(dynamic type,) {
    switch (
        type?.toString().toLowerCase()) {
      case 'sports':
        return FolktriColors.connectionTeal;

      case 'birthday':
        return FolktriColors.dustyRose;

      case 'school':
        return const Color(0xFF5E8BCB);

      case 'medical':
      case 'appointment':
        return FolktriColors.primaryIndigo;

      case 'daycare':
        return const Color(0xFFE6A75C);

      case 'family':
        return const Color(0xFF8D67C8);

      default:
        return FolktriColors.primaryIndigo;
    }
  }

  // ============================================================
  // FAMILY SELECTOR
  // ============================================================

  Widget buildFamilySelector() {

     if (isLoadingFamilies) {
    return const SizedBox(
      height: 44,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: FolktriColors.surface,
          ),
        ),
      ),
    );
  }

  if (userFamilies.isEmpty) {
    return const Text(
      'No family available',
      style: TextStyle(
        color: FolktriColors.surface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  return Center(
    child: SizedBox(
      width: 215, // <-- CHANGE THIS TO CONTROL BOX WIDTH
      height: 44,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),

        decoration: BoxDecoration(
          color: FolktriColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),

        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedFamilyId,

            // This now expands only inside
            // the 215px SizedBox.
            isExpanded: true,

            borderRadius: BorderRadius.circular(18),

            dropdownColor: FolktriColors.surface,

            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: FolktriColors.primaryIndigo,
            ),

            selectedItemBuilder: (context) {
              return userFamilies.map(
                (family) {
                  final name =
                      family['family_name']
                              ?.toString() ??
                          'Family';

                  return Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            FolktriColors.lightLavender,
                        child: Icon(
                          Icons.family_restroom_rounded,
                          size: 15,
                          color:
                              FolktriColors.primaryIndigo,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                                FolktriColors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ).toList();
            },

            items: userFamilies.map(
              (family) {
                final id =
                    family['id'].toString();

                final name =
                    family['family_name']
                            ?.toString() ??
                        'Family';

                final isSelected =
                    id == selectedFamilyId;

                return DropdownMenuItem<String>(
                  value: id,

                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            FolktriColors.lightLavender,
                        child: Icon(
                          Icons.family_restroom_rounded,
                          size: 16,
                          color: isSelected
                              ? FolktriColors.primaryIndigo
                              : FolktriColors.secondaryText,
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                FolktriColors.primaryText,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),

                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.check_rounded,
                            color:
                                FolktriColors.primaryIndigo,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ).toList(),

            onChanged: (familyId) async {
              if (familyId == null ||
                  familyId == selectedFamilyId) {
                return;
              }

              setState(() {
                selectedFamilyId = familyId;
                events = [];
                children = [];
                isLoading = true;
              });

              try {
                await Future.wait([
                  loadFamily(),
                  loadEvents(),
                  loadChildren(),
                ]);
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to switch family: $e',
                    ),
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }
              }
            },
          ),
        ),
      ),
    ),
  );
  //   if (isLoadingFamilies) {
  //   return const SizedBox(
  //     height: 44,
  //     child: Center(
  //       child: SizedBox(
  //         width: 18,
  //         height: 18,
  //         child: CircularProgressIndicator(
  //           strokeWidth: 2,
  //           color: FolktriColors.surface,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // if (userFamilies.isEmpty) {
  //   return const Text(
  //     'No family available',
  //     style: TextStyle(
  //       color: FolktriColors.surface,
  //       fontSize: 14,
  //       fontWeight: FontWeight.w600,
  //     ),
  //   );
  // }

  // return Container(
  //   constraints: const BoxConstraints(
  //     maxWidth: 330,
  //   ),
  //   padding: const EdgeInsets.symmetric(
  //     horizontal: 14,
  //   ),
  //   decoration: BoxDecoration(
  //     color: FolktriColors.surface,
  //     borderRadius: BorderRadius.circular(24),
  //   ),
  //   child: DropdownButtonHideUnderline(
  //     child: DropdownButton<String>(
  //       value: selectedFamilyId,

  //       isExpanded: true,

  //       borderRadius: BorderRadius.circular(18),

  //       icon: const Icon(
  //         Icons.keyboard_arrow_down_rounded,
  //         color: FolktriColors.primaryIndigo,
  //       ),

  //       dropdownColor: FolktriColors.surface,

  //       selectedItemBuilder: (context) {
  //         return userFamilies.map(
  //           (family) {
  //             final name =
  //                 family['family_name']
  //                         ?.toString() ??
  //                     'Family';

  //             return Row(
  //               children: [
  //                 const CircleAvatar(
  //                   radius: 15,
  //                   backgroundColor:
  //                       FolktriColors.lightLavender,
  //                   child: Icon(
  //                     Icons.family_restroom_rounded,
  //                     size: 16,
  //                     color:
  //                         FolktriColors.primaryIndigo,
  //                   ),
  //                 ),

  //                 const SizedBox(width: 9),

  //                 Expanded(
  //                   child: Text(
  //                     name,
  //                     maxLines: 1,
  //                     overflow:
  //                         TextOverflow.ellipsis,
  //                     style: const TextStyle(
  //                       color:
  //                           FolktriColors.primaryText,
  //                       fontSize: 14,
  //                       fontWeight:
  //                           FontWeight.w700,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         ).toList();
  //       },

  //       items: userFamilies.map(
  //         (family) {
  //           final id =
  //               family['id'].toString();

  //           final name =
  //               family['family_name']
  //                       ?.toString() ??
  //                   'Family';

  //           final isSelected =
  //               id == selectedFamilyId;

  //           return DropdownMenuItem<String>(
  //             value: id,
  //             child: Row(
  //               children: [
  //                 CircleAvatar(
  //                   radius: 16,
  //                   backgroundColor:
  //                       FolktriColors.lightLavender,
  //                   child: Icon(
  //                     Icons.family_restroom_rounded,
  //                     size: 17,
  //                     color: isSelected
  //                         ? FolktriColors
  //                             .primaryIndigo
  //                         : FolktriColors
  //                             .secondaryText,
  //                   ),
  //                 ),

  //                 const SizedBox(width: 10),

  //                 Expanded(
  //                   child: Text(
  //                     name,
  //                     overflow:
  //                         TextOverflow.ellipsis,
  //                     style: TextStyle(
  //                       color:
  //                           FolktriColors.primaryText,
  //                       fontSize: 14,
  //                       fontWeight: isSelected
  //                           ? FontWeight.w700
  //                           : FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),

  //                 if (isSelected)
  //                   const Icon(
  //                     Icons.check_rounded,
  //                     color:
  //                         FolktriColors.primaryIndigo,
  //                     size: 19,
  //                   ),
  //               ],
  //             ),
  //           );
  //         },
  //       ).toList(),

  //       onChanged: (familyId) async {
  //         if (familyId == null ||
  //             familyId == selectedFamilyId) {
  //           return;
  //         }

  //         setState(() {
  //           selectedFamilyId = familyId;

  //           // Clear the previous family's events
  //           // while the new family loads.
  //           events = [];

  //           isLoading = true;
  //         });

  //         try {
  //           await Future.wait([
  //             loadFamily(),
  //             loadEvents(),
  //           ]);
  //         } catch (e) {
  //           if (!mounted) return;

  //           ScaffoldMessenger.of(context)
  //               .showSnackBar(
  //             SnackBar(
  //               content: Text(
  //                 'Unable to switch family: $e',
  //               ),
  //             ),
  //           );
  //         } finally {
  //           if (mounted) {
  //             setState(() {
  //               isLoading = false;
  //             });
  //           }
  //         }
  //       },
  //     ),
  //   ),
  // );
    // return Center(
    //   child: Material(
    //     color: FolktriColors.surface,
    //     borderRadius:
    //         BorderRadius.circular(24),
    //     child: InkWell(
    //       borderRadius:
    //           BorderRadius.circular(24),
    //       onTap: () {
    //         context.push('/families');
    //       },
    //       child: Padding(
    //         padding:
    //             const EdgeInsets.symmetric(
    //           horizontal: 16,
    //           vertical: 10,
    //         ),
    //         child: Row(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             const CircleAvatar(
    //               radius: 16,
    //               backgroundColor:
    //                   FolktriColors.lightLavender,
    //               child: Icon(
    //                 Icons.family_restroom_rounded,
    //                 size: 17,
    //                 color:
    //                     FolktriColors.primaryIndigo,
    //               ),
    //             ),

    //             const SizedBox(width: 9),

    //             Flexible(
    //               child: Text(
    //                 familyName,
    //                 overflow:
    //                     TextOverflow.ellipsis,
    //                 style: const TextStyle(
    //                   color:
    //                       FolktriColors.primaryText,
    //                   fontSize: 14,
    //                   fontWeight:
    //                       FontWeight.w700,
    //                 ),
    //               ),
    //             ),

    //             const SizedBox(width: 8),

    //             const Icon(
    //               Icons.keyboard_arrow_down_rounded,
    //               color:
    //                   FolktriColors.primaryIndigo,
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  // ============================================================
  // VIEW SELECTOR
  // ============================================================

  Widget buildViewSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FolktriColors.lightLavender
            .withValues(alpha: 0.45),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          buildViewButton(
            label: 'Month',
            value: 'month',
          ),
          buildViewButton(
            label: 'Week',
            value: 'week',
          ),
          buildViewButton(
            label: 'List',
            value: 'list',
          ),
        ],
      ),
    );
  }

  Widget buildViewButton({
    required String label,
    required String value,
  }) {
    final selected =
        calendarView == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            calendarView = value;
          });
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? FolktriColors.primaryIndigo
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? FolktriColors.surface
                  : FolktriColors.primaryText,
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MONTH VIEW
  // ============================================================

  Widget buildMonthView() {
    final selectedEvents =
        selectedDay == null
            ? <Map<String, dynamic>>[]
            : eventsForDay(
                selectedDay!,
              );

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formatMonthYear(
                    focusedDay,
                  ),
                  style: const TextStyle(
                    color:
                        FolktriColors.primaryText,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              calendarArrowButton(
                icon:
                    Icons.chevron_left_rounded,
                onTap: () {
                  setState(() {
                    focusedDay = DateTime(
                      focusedDay.year,
                      focusedDay.month - 1,
                      1,
                    );
                  });
                },
              ),

              const SizedBox(width: 8),

              calendarArrowButton(
                icon:
                    Icons.chevron_right_rounded,
                onTap: () {
                  setState(() {
                    focusedDay = DateTime(
                      focusedDay.year,
                      focusedDay.month + 1,
                      1,
                    );
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          margin:
              const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: FolktriColors.surface,
            borderRadius:
                BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: FolktriColors
                    .midnightIndigo
                    .withValues(alpha: 0.05),
                blurRadius: 16,
                offset:
                    const Offset(0, 5),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay:
                DateTime.utc(2000, 1, 1),
            lastDay:
                DateTime.utc(2100, 12, 31),
            focusedDay: focusedDay,

            rowHeight: 47,

            daysOfWeekHeight: 32,

            headerVisible: false,

            availableGestures:
                AvailableGestures.horizontalSwipe,

            selectedDayPredicate:
                (day) {
              return isSameDay(
                selectedDay,
                day,
              );
            },

            onDaySelected: (
              newSelectedDay,
              newFocusedDay,
            ) {
              setState(() {
                selectedDay =
                    newSelectedDay;

                focusedDay =
                    newFocusedDay;
              });
            },

            onPageChanged:
                (newFocusedDay) {
              setState(() {
                focusedDay =
                    newFocusedDay;
              });
            },

            eventLoader:
                eventsForDay,

            calendarStyle:
                const CalendarStyle(
              outsideDaysVisible: true,

              defaultTextStyle:
                  TextStyle(
                color:
                    FolktriColors.primaryText,
              ),

              weekendTextStyle:
                  TextStyle(
                color:
                    FolktriColors.primaryText,
              ),

              outsideTextStyle:
                  TextStyle(
                color: Color(0xFFBEC1D3),
              ),

              todayDecoration:
                  BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),

              todayTextStyle:
                  TextStyle(
                color:
                    FolktriColors.primaryIndigo,
                fontWeight:
                    FontWeight.bold,
              ),

              selectedDecoration:
                  BoxDecoration(
                color:
                    FolktriColors.primaryIndigo,
                shape: BoxShape.circle,
              ),

              selectedTextStyle:
                  TextStyle(
                color:
                    FolktriColors.surface,
                fontWeight:
                    FontWeight.bold,
              ),

              markerDecoration:
                  BoxDecoration(
                color:
                    FolktriColors.dustyRose,
                shape: BoxShape.circle,
              ),

              markersMaxCount: 3,

              markerSize: 5,

              markerMargin:
                  EdgeInsets.symmetric(
                horizontal: 1.5,
              ),
            ),

            daysOfWeekStyle:
                const DaysOfWeekStyle(
              weekdayStyle:
                  TextStyle(
                color:
                    FolktriColors.primaryText,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
              weekendStyle:
                  TextStyle(
                color:
                    FolktriColors.primaryText,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        buildSelectedDateHeader(
          selectedEvents.length,
        ),

        const SizedBox(height: 12),

        if (selectedEvents.isEmpty)
          buildNoEventsCard()
        else
          ...selectedEvents.map(
            buildEventCard,
          ),

        const SizedBox(height: 100),
      ],
    );
  }

  // ============================================================
  // WEEK VIEW
  // ============================================================

  Widget buildWeekView() {
    final startOfWeek = focusedDay.subtract(
      Duration(
        days: focusedDay.weekday - 1,
      ),
    );

    final weekDays =
        List.generate(
      7,
      (index) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      ),
    );

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            0,
          ),
          child: Row(
            children: [
              calendarArrowButton(
                icon:
                    Icons.chevron_left_rounded,
                onTap: () {
                  setState(() {
                    focusedDay =
                        focusedDay.subtract(
                      const Duration(
                        days: 7,
                      ),
                    );
                  });
                },
              ),

              Expanded(
                child: Text(
                  '${formatShortDate(weekDays.first)} – '
                  '${formatShortDate(weekDays.last)}, '
                  '${weekDays.last.year}',
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color:
                        FolktriColors.primaryText,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              calendarArrowButton(
                icon:
                    Icons.chevron_right_rounded,
                onTap: () {
                  setState(() {
                    focusedDay =
                        focusedDay.add(
                      const Duration(
                        days: 7,
                      ),
                    );
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Container(
          margin:
              const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            color: FolktriColors.surface,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Row(
            children:
                weekDays.map((day) {
              final selected =
                  isSameDay(
                selectedDay,
                day,
              );

              final dayEvents =
                  eventsForDay(day);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDay = day;
                      focusedDay = day;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    decoration:
                        BoxDecoration(
                      color: selected
                          ? FolktriColors
                              .primaryIndigo
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _weekdays[
                                  day.weekday -
                                      1]
                              .substring(
                            0,
                            3,
                          ),
                          style: TextStyle(
                            color: selected
                                ? FolktriColors
                                    .surface
                                : FolktriColors
                                    .secondaryText,
                            fontSize: 10,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: selected
                                ? FolktriColors
                                    .surface
                                : FolktriColors
                                    .primaryText,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Container(
                          width: 5,
                          height: 5,
                          decoration:
                              BoxDecoration(
                            color: dayEvents
                                    .isNotEmpty
                                ? selected
                                    ? FolktriColors
                                        .surface
                                    : FolktriColors
                                        .primaryIndigo
                                : Colors
                                    .transparent,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        ...weekDays.expand(
          (day) {
            final dayEvents =
                eventsForDay(day);

            if (dayEvents.isEmpty) {
              return <Widget>[];
            }

            return <Widget>[
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  10,
                ),
                child: Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    formatFullDate(day),
                    style:
                        const TextStyle(
                      color: FolktriColors
                          .primaryText,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              ...dayEvents.map(
                buildEventCard,
              ),
            ];
          },
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  // ============================================================
  // LIST VIEW
  // ============================================================

  Widget buildListView() {
    if (events.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.all(16),
        child: buildNoEventsCard(),
      );
    }

    final grouped =
        <DateTime,
            List<Map<String, dynamic>>>{};

    for (final event in events) {
      final start =
          DateTime.tryParse(
        event['start_at']?.toString() ?? '',
      )?.toLocal();

      if (start == null) continue;

      final day = DateTime(
        start.year,
        start.month,
        start.day,
      );

      grouped
          .putIfAbsent(
            day,
            () => [],
          )
          .add(event);
    }

    final dates =
        grouped.keys.toList()
          ..sort();

    return Column(
      children: [
        const SizedBox(height: 12),

        ...dates.expand(
          (date) => <Widget>[
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                10,
              ),
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  formatFullDate(date),
                  style:
                      const TextStyle(
                    color:
                        FolktriColors.primaryText,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            ...grouped[date]!.map(
              buildEventCard,
            ),
          ],
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  // ============================================================
  // SELECTED DATE HEADER
  // ============================================================

  Widget buildSelectedDateHeader(
    int eventCount,
  ) {
    final date =
        selectedDay ?? focusedDay;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatFullDate(date),
              style: const TextStyle(
                color:
                    FolktriColors.primaryText,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          if (eventCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color:
                    FolktriColors.lightLavender,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                '$eventCount '
                '${eventCount == 1 ? 'event' : 'events'}',
                style: const TextStyle(
                  color:
                      FolktriColors.primaryIndigo,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // EVENT CARD
  // ============================================================

  Widget buildEventCard(
    Map<String, dynamic> event,
  ) {
    final type =
        event['event_type'];

    final color =
        eventColor(type);

    final name =
        childName(event);

    final location =
        event['location']
            ?.toString()
            .trim() ??
            '';

    final title =
        event['title']
            ?.toString()
            .trim() ??
            'Event';

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: FolktriColors
                .midnightIndigo
                .withValues(alpha: 0.05),
            blurRadius: 14,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(18),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: () {
            showEventDetails(event);
          },
          child: Padding(
            padding:
                const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color: color.withValues(
                      alpha: 0.13,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child: Icon(
                    eventIcon(type),
                    color: color,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          color:
                              FolktriColors
                                  .primaryText,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        formatEventTime(
                          event,
                        ),
                        style:
                            const TextStyle(
                          color:
                              FolktriColors
                                  .primaryText,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),

                      if (name.isNotEmpty) ...[
                        const SizedBox(
                          height: 7,
                        ),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                FolktriColors
                                    .lightLavender,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                          child: Text(
                            name,
                            style:
                                const TextStyle(
                              color:
                                  FolktriColors
                                      .primaryIndigo,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ],

                      if (location
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 7,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size: 14,
                              color:
                                  FolktriColors
                                      .secondaryText,
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Expanded(
                              child: Text(
                                location,
                                style:
                                    const TextStyle(
                                  color:
                                      FolktriColors
                                          .secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color:
                      FolktriColors.primaryIndigo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EVENT DETAILS
  // ============================================================

  void showEventDetails(
    Map<String, dynamic> event,
  ) {
    final title =
        event['title']?.toString() ??
            'Event';

    final description =
        event['description']
            ?.toString()
            .trim() ??
            '';

    final location =
        event['location']
            ?.toString()
            .trim() ??
            '';

    final name =
        childName(event);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          FolktriColors.surface,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        FolktriColors.primaryText,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  formatEventTime(event),
                  style:
                      const TextStyle(
                    color:
                        FolktriColors.secondaryText,
                  ),
                ),

                if (name.isNotEmpty) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    'For $name',
                    style:
                        const TextStyle(
                      color:
                          FolktriColors.primaryText,
                    ),
                  ),
                ],

                if (location.isNotEmpty) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .location_on_outlined,
                        size: 18,
                        color:
                            FolktriColors
                                .primaryIndigo,
                      ),
                      const SizedBox(
                        width: 7,
                      ),
                      Expanded(
                        child: Text(
                          location,
                        ),
                      ),
                    ],
                  ),
                ],

                if (description
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    description,
                    style:
                        const TextStyle(
                      color:
                          FolktriColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    deleteEvent(
                      event['id'].toString(),
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color:
                        FolktriColors.dustyRose,
                  ),
                  label: const Text(
                    'Delete Event',
                    style: TextStyle(
                      color:
                          FolktriColors.dustyRose,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SMALL UI HELPERS
  // ============================================================

  Widget calendarArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: FolktriColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(8),
          child: Icon(
            icon,
            color:
                FolktriColors.primaryIndigo,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget buildNoEventsCard() {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            color:
                FolktriColors.primaryIndigo,
            size: 32,
          ),
          SizedBox(height: 10),
          Text(
            'Nothing planned for this day',
            style: TextStyle(
              color:
                  FolktriColors.primaryText,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Enjoy the open space.',
            style: TextStyle(
              color:
                  FolktriColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          FolktriColors.background,

      appBar: AppBar(
        backgroundColor: FolktriColors.midnightIndigo,
        foregroundColor: FolktriColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,

        // leading: IconButton(
        //   tooltip: 'Back to family',
        //   icon: const Icon(
        //     Icons
        //         .arrow_back_ios_new_rounded,
        //   ),
        //   onPressed: () {
        //     context.go(
        //       '/family/${widget.familyId}',
        //     );
        //   },
        // ),

        title: const Text(
          'Family Calendar',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(
              Icons.calendar_today_outlined,
            ),
            onPressed: () {
              final now = DateTime.now();

              setState(() {
                focusedDay = now;
                selectedDay = now;
              });
            },
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
  currentIndex: 1, // Calendar

  type: BottomNavigationBarType.fixed,

  backgroundColor: FolktriColors.surface,

  selectedItemColor:
      FolktriColors.primaryIndigo,

  unselectedItemColor:
      FolktriColors.secondaryText,

  selectedLabelStyle: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 11,
  ),

  unselectedLabelStyle: const TextStyle(
    fontSize: 11,
  ),

  onTap: (index) {
    switch (index) {
      // HOME
      case 0:
        context.go('/app');
        break;

      // CALENDAR
      case 1:
        // Already on Calendar.
        break;

      // FAMILY
      case 2:
        context.go('/families');
        break;

      // ALBUMS
      case 3:
        // We'll connect this when
        // Family Albums is built.
        break;

      // PROFILE
      case 4:
        context.go('/profile');
        break;
    }
  },

  items: const [
    BottomNavigationBarItem(
      icon: Icon(
        Icons.home_outlined,
      ),
      activeIcon: Icon(
        Icons.home_rounded,
      ),
      label: 'Home',
    ),

    BottomNavigationBarItem(
      icon: Icon(
        Icons.calendar_month_outlined,
      ),
      activeIcon: Icon(
        Icons.calendar_month_rounded,
      ),
      label: 'Calendar',
    ),

    BottomNavigationBarItem(
      icon: Icon(
        Icons.family_restroom_outlined,
      ),
      activeIcon: Icon(
        Icons.family_restroom_rounded,
      ),
      label: 'Family',
    ),

    BottomNavigationBarItem(
      icon: Icon(
        Icons.photo_library_outlined,
      ),
      activeIcon: Icon(
        Icons.photo_library_rounded,
      ),
      label: 'Albums',
    ),

    BottomNavigationBarItem(
      icon: Icon(
        Icons.person_outline_rounded,
      ),
      activeIcon: Icon(
        Icons.person_rounded,
      ),
      label: 'Profile',
    ),
  ],
),

      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            FolktriColors.primaryIndigo,
        foregroundColor:
            FolktriColors.surface,
        elevation: 4,
        onPressed: openAddEvent,
        child: const Icon(
          Icons.add_rounded,
          size: 30,
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: FolktriColors
                    .primaryIndigo,
              ),
            )
          : RefreshIndicator(
              color: FolktriColors
                  .primaryIndigo,
              onRefresh: loadCalendar,
              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width:
                          double.infinity,
                      color: FolktriColors
                          .midnightIndigo,
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        16,
                        4,
                        16,
                        18,
                      ),
                      child:
                          buildFamilySelector(),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child:
                          buildViewSelector(),
                    ),

                    if (calendarView == 'month')
                      buildMonthView(),

                    if (calendarView == 'week')
                      buildWeekView(),

                    if (calendarView == 'list')
                      buildListView(),
                  ],
                ),
              ),
            ),
    );
  }
}