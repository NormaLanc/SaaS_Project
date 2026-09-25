import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../Styling/folktri_colors.dart';

class ChildProfilePage extends StatefulWidget {
  final String childId;

  const ChildProfilePage({
    super.key,
    required this.childId,
  });

  @override
  State<ChildProfilePage> createState() =>
      _ChildProfilePageState();
}

// Calculate child's age based on date of birth
    int calculateAge(DateTime birthDate) {
      final today = DateTime.now();

      int age = today.year - birthDate.year;

      final birthdayHasOccurred =
        today.month > birthDate.month ||
          (today.month == birthDate.month &&
            today.day >= birthDate.day);

        if (!birthdayHasOccurred) {
          age--;
        }

  return age;
}

class _ChildProfilePageState extends State<ChildProfilePage> {

  final supabase = Supabase.instance.client;

  Map<String, dynamic>? child;
  bool isLoading = true;

  int selectedTabIndex = 0;

  List<Map<String, dynamic>> milestones = [];
  bool isLoadingMilestones = true;

  List<Map<String, dynamic>> photos = [];
  bool isLoadingPhotos = true;

  List<Map<String, dynamic>> events = [];
  bool isLoadingEvents = true;

  List<Map<String, dynamic>> documents = [];
  bool isLoadingDocuments = true;

  @override
  void initState() {
    super.initState();
    loadChild();
    loadMilestones();
    loadPhotos();
    loadEvents();
    loadDocuments();
  }

  Future<void> loadChild() async {
    try {
      final response = await supabase
          .from('Children')
          .select()
          .eq('id', widget.childId)
          .single();

      if (!mounted) return;

      setState(() {
        child =
            Map<String, dynamic>.from(
          response,
        );

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load child: $e',
          ),
        ),
      );
    }
  }

  Future<void> loadMilestones() async {
  try {
    final response = await supabase
        .from('Milestones')
        .select()
        .eq('child_id', widget.childId)
        .order(
          'milestone_date',
          ascending: false,
        );

    if (!mounted) return;

    setState(() {
      milestones =
          List<Map<String, dynamic>>.from(
        response,
      );

      isLoadingMilestones = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingMilestones = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load milestones: $e',
        ),
      ),
    );
  }
}

Future<void> loadEvents() async {
  try {
    final response = await supabase
        .from('Calendar_Events')
        .select()
        .eq(
          'child_id',
          widget.childId,
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

      isLoadingEvents = false;
    });
  } catch (e) {
    debugPrint(
      'Unable to load child events: $e',
    );

    if (!mounted) return;

    setState(() {
      isLoadingEvents = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load events: $e',
        ),
      ),
    );
  }
}

Future<void> loadPhotos() async {
  try {
    final response =
        await supabase
            .from('Photos')
            .select()
            .eq(
              'child_id',
              widget.childId,
            )
            .order(
              'created_at',
              ascending: false,
            );

    if (!mounted) return;

    setState(() {
      photos =
          List<Map<String, dynamic>>
              .from(
        response,
      );

      isLoadingPhotos = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingPhotos = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load photos: $e',
        ),
      ),
    );
  }
}

Future<void> loadDocuments() async {
  try {
    final response =
        await supabase
            .from('Documents')
            .select()
            .eq(
              'child_id',
              widget.childId,
            )
            .order(
              'document_date',
              ascending: false,
            );

    if (!mounted) return;

    setState(() {
      documents =
          List<Map<String, dynamic>>
              .from(
        response,
      );

      isLoadingDocuments =
          false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingDocuments =
          false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load documents: $e',
        ),
      ),
    );
  }
}

Future<void> addChildEvent() async {
  final familyId =
      child?['family_id']?.toString();

  if (familyId == null ||
      familyId.isEmpty) {
    return;
  }

  final result =
      await context.push<bool>(
    '/family/$familyId/calendar/add-event'
    '?childId=${widget.childId}',
  );

  if (result == true) {
    await loadEvents();
  }
}

Future<void> handleAddButton() async {
  switch (selectedTabIndex) {
    case 0:
      final result =
          await context.push<bool>(
        '/family/${child!['family_id']}'
        '/child/${widget.childId}'
        '/add-milestone',
      );

      if (result == true) {
        await loadMilestones();
      }

      break;

    case 1:
      final result =
          await context.push<bool>(
        '/family/${child!['family_id']}'
        '/child/${widget.childId}'
        '/add-photo',
      );

      if (result == true) {
        await loadPhotos();
      }

      break;

    case 2:
      await addChildEvent();
      break;

    case 3:
      final result =
          await context.push<bool>(
        '/family/${child!['family_id']}'
        '/child/${widget.childId}'
        '/add-document',
      );

      if (result == true) {
        await loadDocuments();
      }

      break;
  }
}

Widget buildMilestonesTab(){
  return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async{
                      final result = await context.push<bool>(
                        '/family/${child!['family_id']}/child/${widget.childId}/add-milestone',
                      );
                      if (result == true) {
                        loadMilestones();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Milestone'),
                  )
                ),
              ),

              Expanded(
                child: isLoadingMilestones
                    ? const Center(
                      child: CircularProgressIndicator(),
                      )
                      : milestones.isEmpty
                      ? const Center(child: Text("No minestones added yet."),
                      )
                      : ListView.builder(
                        itemCount: milestones.length,
                        itemBuilder: (context, index) {
                          final milestone = milestones[index];

                          return Card(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if(milestone['photo_url'] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          milestone['photo_url'],
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              milestone['title'] ?? '',
                                              style:
                                                Theme.of(context).textTheme.titleLarge,
                                              ),
                                            ),

                                      IconButton(
                                        tooltip: 'Delete Milestone',
                                        icon: const Icon(Icons.delete_outline,),
                                        onPressed: () {
                                          deleteMilestone(milestone['id'].toString(),);
                                        },
                                      ),
                                    ],
                                  ),
                                      const SizedBox(height: 4),
                                      Text(
                                        milestone['milestone_date'].toString(),
                                    ),
                                     if (milestone[
                                        'description'] !=
                                    null) ...[
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    milestone[
                                        'description'],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }
                    )
              ),
            ],
  );
}

Widget buildPhotosTab(){
  return Column(
    children: [
      Padding(
        padding:
          const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child:
            ElevatedButton.icon(
              onPressed: () async {
              final result =
                await context.push<bool>(
              '/family/${child!['family_id']}/child/${widget.childId}/add-photo',
            );

            if (result == true) {
              loadPhotos();
            }
          },
          icon: const Icon(Icons.add_photo_alternate,),
          label: const Text('Add Photo'),
        ),
      ),
    ),

    Expanded(
      child:
          isLoadingPhotos
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : photos.isEmpty
                  ? const Center(
                      child: Text(
                        'No photos added yet.',
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: photos.length,
                      itemBuilder:
                          (context, index,) {
                        final photo = photos[index];

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8,),
                                child: Image.network(photo['photo_url'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20,),
                                ),

                              child: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),

                                onPressed: () {
                                  deletePhoto(photo['id'].toString(),
                                  );
                                },
                              ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            }

Widget buildDocumentsTab() {
  if (isLoadingDocuments) {
    return const Center(
      child:
          CircularProgressIndicator(),
    );
  }

  return Column(
    children: [
      Padding(
        padding:
            const EdgeInsets.all(16),

        child: SizedBox(
          width: double.infinity,

          child: ElevatedButton.icon(
            onPressed:
                () async {
              final result =
                  await context
                      .push<bool>(
                '/family/${child!['family_id']}/child/${widget.childId}/add-document',
              );

              if (result == true) {
                loadDocuments();
              }
            },

            icon:
                const Icon(Icons.upload_file,),

            label:
                const Text('Add Document',),
          ),
        ),
      ),

      if (documents.isEmpty)
        const Expanded(
          child: Center(
            child: Text('No documents added yet.',),
          ),
        )
      else
        Expanded(
          child:
              ListView.separated(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16,),

            itemCount: documents.length,

            separatorBuilder: (context, index,) => const SizedBox(height: 8),

            itemBuilder: (context, index,) {
              final document = documents[index];
              final date = DateTime.tryParse(document['document_date'].toString(),);
              final dateText =
                  date == null
                      ? ''
                      : '${date.month}/${date.day}/${date.year}';

              return Card(
                child:
                    ListTile(
                  leading:
                      const CircleAvatar(
                    child:
                        Icon(Icons.description),
                  ),

                  title:
                      Text(document['title'] ?.toString() ??
                        '',),

                  subtitle:
                      Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(document['category'] ?.toString() ?? '',),

                      if (dateText
                          .isNotEmpty)
                        Text(dateText,),
                    ],
                  ),

                  trailing:
                      const Icon(Icons.chevron_right),

                  onTap:
                      () {
                    // We will add secure
                    // document viewing next.
                  },
                ),
              );
            },
          ),
        ),
    ],
  );
}

Future<bool> confirmDelete({
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
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

Future<void> deleteChild() async {
  final shouldDelete =
      await confirmDelete(
    title: 'Delete Child',
    message:
        'Are you sure you want to delete this child? Their milestones, documents, photos, and other related information may also be permanently deleted.',
  );

  if (!shouldDelete) return;

  try {
    await supabase
        .from('Children')
        .delete()
        .eq(
          'id',
          widget.childId,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Child deleted.',
        ),
      ),
    );

    context.pop(true);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete child: $e',
        ),
      ),
    );
  }
}

Future<void> deleteMilestone(
  String milestoneId,
) async {
  final shouldDelete =
      await confirmDelete(
    title: 'Delete Milestone',
    message:
        'Are you sure you want to delete this milestone?',
  );

  if (!shouldDelete) return;

  try {
    await supabase
        .from('Milestones')
        .delete()
        .eq(
          'id',
          milestoneId,
        );

    await loadMilestones();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Milestone deleted.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete milestone: $e',
        ),
      ),
    );
  }
}

Future<void> deletePhoto(
  String photoId,
) async {
  final shouldDelete =
      await confirmDelete(
    title: 'Delete Photo',
    message:
        'Are you sure you want to permanently delete this photo?',
  );

  if (!shouldDelete) return;

  try {
    await supabase
        .from('Photos')
        .delete()
        .eq(
          'id',
          photoId,
        );

    await loadPhotos();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Photo deleted.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete photo: $e',
        ),
      ),
    );
  }
}

IconData eventIcon(
  String? eventType,
) {
  switch (eventType?.toLowerCase()) {
    case 'daycare':
      return Icons.child_care_rounded;

    case 'school':
      return Icons.school_rounded;

    case 'sports':
      return Icons.sports_soccer_rounded;

    case 'birthday':
      return Icons.cake_rounded;

    case 'appointment':
    case 'medical':
      return Icons.medical_services_rounded;

    case 'family':
      return Icons.family_restroom_rounded;

    default:
      return Icons.event_rounded;
  }
}

Color eventColor(
  String? eventType,
) {
  switch (eventType?.toLowerCase()) {
    case 'sports':
      return FolktriColors.connectionTeal;

    case 'birthday':
      return FolktriColors.dustyRose;

    case 'appointment':
    case 'medical':
      return FolktriColors.primaryIndigo;

    case 'school':
      return const Color(0xFF4C8BC7);

    case 'daycare':
      return const Color(0xFFE9A23B);

    case 'family':
      return const Color(0xFF8C68C8);

    default:
      return FolktriColors.primaryIndigo;
  }
}

String monthAbbreviation(
  int month,
) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  return months[month - 1];
}

String weekdayAbbreviation(
  int weekday,
) {
  const days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  return days[weekday - 1];
}

String formatEventTime(
  DateTime date,
) {
  return TimeOfDay.fromDateTime(
    date,
  ).format(context);
}

Widget buildEventsTab() {
  if (isLoadingEvents) {
    return const Center(
      child: CircularProgressIndicator(
        color: FolktriColors.primaryIndigo,
      ),
    );
  }

  final now = DateTime.now();

  final upcomingEvents =
      events.where(
    (event) {
      final startAt =
          DateTime.tryParse(
        event['start_at']?.toString() ?? '',
      );

      if (startAt == null) {
        return false;
      }

      return startAt
          .toLocal()
          .isAfter(now);
    },
  ).toList();

  final pastEvents =
      events.where(
    (event) {
      final startAt =
          DateTime.tryParse(
        event['start_at']?.toString() ?? '',
      );

      if (startAt == null) {
        return false;
      }

      return startAt
          .toLocal()
          .isBefore(now);
    },
  ).toList();

  // Upcoming: soonest first
  upcomingEvents.sort(
    (a, b) {
      final aDate =
          DateTime.parse(
        a['start_at'].toString(),
      );

      final bDate =
          DateTime.parse(
        b['start_at'].toString(),
      );

      return aDate.compareTo(bDate);
    },
  );

  // Past: most recent first
  pastEvents.sort(
    (a, b) {
      final aDate =
          DateTime.parse(
        a['start_at'].toString(),
      );

      final bDate =
          DateTime.parse(
        b['start_at'].toString(),
      );

      return bDate.compareTo(aDate);
    },
  );

  return RefreshIndicator(
    onRefresh: loadEvents,

    child: ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        100,
      ),

      children: [
        _buildEventSectionHeader(
          title: 'Upcoming Events',
          count: upcomingEvents.length,
        ),

        const SizedBox(
          height: 12,
        ),

        if (upcomingEvents.isEmpty)
          _buildEmptyEventsCard(
            message:
                'No upcoming events for this child.',
          )
        else
          ...upcomingEvents.map(
            (event) =>
                _buildChildEventCard(event),
          ),

        const SizedBox(
          height: 28,
        ),

        _buildEventSectionHeader(
          title: 'Past Events',
          count: pastEvents.length,
        ),

        const SizedBox(
          height: 12,
        ),

        if (pastEvents.isEmpty)
          _buildEmptyEventsCard(
            message:
                'No past events yet.',
          )
        else
          ...pastEvents.map(
            (event) =>
                _buildChildEventCard(event),
          ),
      ],
    ),
  );
}

Widget _buildEventSectionHeader({
  required String title,
  required int count,
}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color:
                FolktriColors.midnightIndigo,
          ),
        ),
      ),

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
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color:
                FolktriColors.primaryIndigo,
          ),
        ),
      ),
    ],
  );
}

Widget _buildEmptyEventsCard({
  required String message,
}) {
  return Container(
    width: double.infinity,
    padding:
        const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 28,
    ),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius:
          BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset:
              const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color:
                FolktriColors.lightLavender,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_outlined,
            color:
                FolktriColors.primaryIndigo,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color:
                FolktriColors.secondaryText,
          ),
        ),
      ],
    ),
  );
}

Widget _buildChildEventCard(
  Map<String, dynamic> event,
) {
  final startAt =
      DateTime.tryParse(
    event['start_at']?.toString() ?? '',
  )?.toLocal();

  if (startAt == null) {
    return const SizedBox.shrink();
  }

  final endAt =
      DateTime.tryParse(
    event['end_at']?.toString() ?? '',
  )?.toLocal();

  final allDay =
      event['all_day'] == true;

  final type =
      event['event_type']?.toString();

  final color =
      eventColor(type);

  final location =
      event['location']
          ?.toString()
          .trim();

  String timeText;

  if (allDay) {
    timeText = 'All day';
  } else if (endAt != null) {
    timeText =
        '${formatEventTime(startAt)} – '
        '${formatEventTime(endAt)}';
  } else {
    timeText =
        formatEventTime(startAt);
  }

  return Container(
    margin:
        const EdgeInsets.only(
      bottom: 12,
    ),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius:
          BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset:
              const Offset(0, 5),
        ),
      ],
    ),
    child: InkWell(
      borderRadius:
          BorderRadius.circular(18),

      onTap: () {
        // Event detail page can be added
        // here later.
      },

      child: Padding(
        padding:
            const EdgeInsets.all(14),

        child: Row(
          children: [
            // DATE BLOCK
            Container(
              width: 58,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color:
                    FolktriColors.lightLavender,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    monthAbbreviation(
                      startAt.month,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          FolktriColors.primaryIndigo,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    '${startAt.day}',
                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          FolktriColors.midnightIndigo,
                    ),
                  ),

                  Text(
                    weekdayAbbreviation(
                      startAt.weekday,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          FolktriColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // EVENT ICON
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                eventIcon(type),
                color: color,
                size: 21,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // EVENT DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title']
                            ?.toString() ??
                        'Event',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          FolktriColors.midnightIndigo,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color:
                            FolktriColors.secondaryText,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Expanded(
                        child: Text(
                          timeText,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                FolktriColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (location != null &&
                      location.isNotEmpty) ...[
                    const SizedBox(
                      height: 5,
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: color,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 13,
                              color:
                                  FolktriColors.secondaryText,
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
                  FolktriColors.secondaryText,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildChildProfileHeader() {
  final firstName =
      child?['first_name']
          ?.toString() ??
      '';

  final middleName =
      child?['middle_name']
          ?.toString() ??
      '';

  final lastName =
      child?['last_name']
          ?.toString() ??
      '';

  final fullName = [
    firstName,
    middleName,
    lastName,
  ]
      .where(
        (name) =>
            name.trim().isNotEmpty,
      )
      .join(' ');

  final dob =
      DateTime.tryParse(
    child?['date_of_birth']
            ?.toString() ??
        '',
  );

  final age =
      dob != null
          ? calculateAge(dob)
          : null;

  return Container(
    width: double.infinity,
    padding:
        const EdgeInsets.fromLTRB(
      20,
      24,
      20,
      20,
    ),
    decoration:
        const BoxDecoration(
      color: FolktriColors.background,
    ),
    child: Column(
      children: [
        // PROFILE PHOTO
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                FolktriColors.lightLavender,
            border: Border.all(
              color:
                  FolktriColors.surface,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(
                  0.08,
                ),
                blurRadius: 16,
                offset:
                    const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.child_care_rounded,
            size: 45,
            color:
                FolktriColors.primaryIndigo,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          fullName,
          textAlign:
              TextAlign.center,
          style:
              const TextStyle(
            fontSize: 23,
            fontWeight:
                FontWeight.w800,
            color:
                FolktriColors.midnightIndigo,
          ),
        ),

        if (age != null) ...[
          const SizedBox(
            height: 4,
          ),

          Text(
            age == 1
                ? '1 year old'
                : '$age years old',
            style:
                const TextStyle(
              fontSize: 15,
              color:
                  FolktriColors.secondaryText,
            ),
          ),
        ],

        if (dob != null) ...[
          const SizedBox(
            height: 4,
          ),

          Text(
            'Birthday • '
            '${_monthName(dob.month)} '
            '${dob.day}, ${dob.year}',
            style:
                const TextStyle(
              fontSize: 14,
              color:
                  FolktriColors.secondaryText,
            ),
          ),
        ],

        const SizedBox(
          height: 20,
        ),

        Row(
          children: [
            Expanded(
              child:
                  _buildProfileStat(
                icon:
                    Icons.star_rounded,
                count:
                    milestones.length,
                label:
                    'Milestones',
                color:
                    FolktriColors.dustyRose,
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            Expanded(
              child:
                  _buildProfileStat(
                icon:
                    Icons.image_rounded,
                count:
                    photos.length,
                label:
                    'Photos',
                color:
                    const Color(
                  0xFF4C9BC5,
                ),
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            Expanded(
              child:
                  _buildProfileStat(
                icon:
                    Icons.calendar_month_rounded,
                count:
                    events.length,
                label:
                    'Events',
                color:
                    FolktriColors.primaryIndigo,
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            Expanded(
              child:
                  _buildProfileStat(
                icon:
                    Icons.description_outlined,
                count:
                    documents.length,
                label:
                    'Documents',
                color:
                    FolktriColors.connectionTeal,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildProfileStat({
  required IconData icon,
  required int count,
  required String label,
  required Color color,
}) {
  return Container(
    padding:
        const EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 4,
    ),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius:
          BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset:
              const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 21,
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          '$count',
          style:
              const TextStyle(
            fontSize: 17,
            fontWeight:
                FontWeight.w800,
            color:
                FolktriColors.midnightIndigo,
          ),
        ),

        const SizedBox(
          height: 2,
        ),

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style:
                const TextStyle(
              fontSize: 11,
              color:
                  FolktriColors.secondaryText,
            ),
          ),
        ),
      ],
    ),
  );
}

String _monthName(
  int month,
) {
  const months = [
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

  return months[month - 1];
}

  @override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  if (child == null) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Child not found.',
        ),
      ),
    );
  }

  final firstName =
      child!['first_name'] ?? '';

  final middleName =
      child!['middle_name'] ?? '';

  final lastName =
      child!['last_name'] ?? '';

  final fullName = [
    firstName,
    middleName,
    lastName,
  ]
      .where(
        (name) =>
            name.toString().trim().isNotEmpty,
      )
      .join(' ');

  return DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        //title: Text(fullName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
            if (value == 'delete') {
              deleteChild();
            }
          },

          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline,),
                  SizedBox(width: 8,),
                  Text('Delete Child',),
                ],
              ),
            ),
          ],
        ),
      ],

      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: handleAddButton,

      //   backgroundColor: FolktriColors.primaryIndigo,

      //   foregroundColor: FolktriColors.surface,

      //   child: const Icon(Icons.add_rounded,
      //     size: 30,
      //   ),
      // ),
      body: Column(
        children: [
          buildChildProfileHeader(),

          const TabBar(
            labelColor: FolktriColors.primaryIndigo,

            unselectedLabelColor: FolktriColors.secondaryText,

            indicatorColor: FolktriColors.primaryIndigo,

            indicatorWeight: 3,

            tabs: [
              Tab(text: 'Milestones',),
              Tab(text: 'Events',),
              Tab(text: 'Photos',),
              Tab(text: 'Documents',),
            ],
          ),
          
          Expanded(
            child: TabBarView(
          // Milestones, Documents, and Photos tabs content
              children: [
                // MILESTONES TAB
                buildMilestonesTab(),
                // EVENTS TAB
                buildEventsTab(),
                // PHOTOS TAB
                buildPhotosTab(),
                //DOCUMENTS TAB
                buildDocumentsTab(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}