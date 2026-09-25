import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Styling/folktri_colors.dart';

class FamilyPage extends StatefulWidget {
  final String familyId;

  const FamilyPage({
    super.key,
    required this.familyId,
  });

  @override
  State<FamilyPage> createState() =>
      _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? family;

  List<Map<String, dynamic>> children = [];
  List<Map<String, dynamic>> photos = [];
  List<Map<String, dynamic>> milestones = [];
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> familyMembers = [];

  bool isLoadingActivity = true;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadFamilyData();
  }

  Future<void> loadFamilyData() async {
  if (mounted) {
    setState(() {
      isLoading = true;
    });
  }

  try {
    // ------------------------------------------
    // FAMILY
    // ------------------------------------------

    final familyResponse = await supabase
        .from('Families')
        .select(
          'id, family_name, created_by',
        )
        .eq(
          'id',
          widget.familyId,
        )
        .single();

    // ------------------------------------------
    // CHILDREN
    // ------------------------------------------

    final childrenResponse = await supabase
        .from('Children')
        .select()
        .eq(
          'family_id',
          widget.familyId,
        )
        .order(
          'first_name',
        );

    final loadedChildren =
        List<Map<String, dynamic>>.from(
      childrenResponse,
    );

    // ------------------------------------------
    // FAMILY MEMBERS
    // ------------------------------------------

    final membersResponse = await supabase
        .from('Family_Members')
        .select()
        .eq(
          'family_id',
          widget.familyId,
        )
        .eq(
          'status',
          'approved',
        );

    // ------------------------------------------
    // EVENTS
    // ------------------------------------------

    final eventsResponse = await supabase
        .from('Calendar_Events')
        .select()
        .eq(
          'family_id',
          widget.familyId,
        )
        .order(
          'start_at',
          ascending: false,
        );

    // ------------------------------------------
    // PHOTOS + MILESTONES
    //
    // Your current Photos/Milestones schema
    // connects these records to children.
    // ------------------------------------------

    final childIds = loadedChildren
        .map(
          (child) =>
              child['id']?.toString(),
        )
        .whereType<String>()
        .where(
          (id) => id.isNotEmpty,
        )
        .toList();

    List<Map<String, dynamic>> loadedPhotos = [];
    List<Map<String, dynamic>> loadedMilestones = [];

    if (childIds.isNotEmpty) {
      final photosResponse =
          await supabase
              .from('Photos')
              .select()
              .inFilter(
                'child_id',
                childIds,
              )
              .order(
                'created_at',
                ascending: false,
              );

      loadedPhotos =
          List<Map<String, dynamic>>.from(
        photosResponse,
      );

      final milestonesResponse =
          await supabase
              .from('Milestones')
              .select()
              .inFilter(
                'child_id',
                childIds,
              )
              .order(
                'milestone_date',
                ascending: false,
              );

      loadedMilestones =
          List<Map<String, dynamic>>.from(
        milestonesResponse,
      );
    }

    if (!mounted) return;

    setState(() {
      family =
          Map<String, dynamic>.from(
        familyResponse,
      );

      children = loadedChildren;

      familyMembers =
          List<Map<String, dynamic>>.from(
        membersResponse,
      );

      events =
          List<Map<String, dynamic>>.from(
        eventsResponse,
      );

      photos = loadedPhotos;
      milestones = loadedMilestones;

      isLoading = false;
      isLoadingActivity = false;
    });
  } catch (e) {
    debugPrint(
      'LOAD FAMILY ERROR: $e',
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
      isLoadingActivity = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load family: $e',
        ),
      ),
    );
  }
}

  // Future<void> loadFamily() async {
  //   try {
  //     // ==========================================
  //     // LOAD FAMILY
  //     // ==========================================

  //     final familyResponse = await supabase
  //         .from('Families')
  //         .select('id, family_name, created_by')
  //         .eq('id', widget.familyId)
  //         .single();

  //     // ==========================================
  //     // LOAD CHILDREN
  //     // ==========================================

  //     final childrenResponse = await supabase
  //         .from('Children')
  //         .select()
  //         .eq('family_id', widget.familyId)
  //         .order('first_name');

  //     if (!mounted) return;

  //     setState(() {
  //       family =
  //           Map<String, dynamic>.from(
  //         familyResponse,
  //       );

  //       children =
  //           List<Map<String, dynamic>>.from(
  //         childrenResponse,
  //       );

  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;

  //     setState(() {
  //       isLoading = false;
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           "Unable to load family: $e",
  //         ),
  //       ),
  //     );
  //   }
  // }

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

  Future<void> deleteFamily() async {
  final shouldDelete =
      await confirmDelete(
    title: 'Delete Family',
    message:
        'Deleting this family will permanently remove the family and its related children, milestones, events, documents, and photos. This cannot be undone.',
  );

  if (!shouldDelete) return;

  try {
    await supabase
        .from('Families')
        .delete()
        .eq(
          'id',
          widget.familyId,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Family deleted.',
        ),
      ),
    );

    context.go('/families');
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete family: $e',
        ),
      ),
    );
  }
}

  Widget buildFamilyHeader() {
  final familyName =
      family?['family_name']?.toString() ??
          'Family';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      20,
      26,
      20,
      22,
    ),
    decoration: const BoxDecoration(
      color: FolktriColors.surface,
    ),
    child: Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color:
                FolktriColors.lightLavender,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  FolktriColors.surface,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.06),
                blurRadius: 15,
                offset:
                    const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.family_restroom_rounded,
            size: 42,
            color:
                FolktriColors.primaryIndigo,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          familyName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color:
                FolktriColors.midnightIndigo,
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color:
                  FolktriColors.secondaryText,
            ),

            const SizedBox(
              width: 4,
            ),

            Text(
              '${familyMembers.length} members • Private',
              style: const TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 14,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 20,
        ),

        Row(
          children: [
            Expanded(
              child: buildFamilyStat(
                icon:
                    Icons.image_rounded,
                value: photos.length,
                label: 'Photos',
                color:
                    const Color(0xFF4C9BC5),
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: buildFamilyStat(
                icon:
                    Icons.star_rounded,
                value: milestones.length,
                label: 'Milestones',
                color:
                    FolktriColors.dustyRose,
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: buildFamilyStat(
                icon:
                    Icons.calendar_month_rounded,
                value: events.length,
                label: 'Events',
                color:
                    FolktriColors.primaryIndigo,
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: buildFamilyStat(
                icon:
                    Icons.people_rounded,
                value: familyMembers.length,
                label: 'Members',
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

  Widget buildFamilyStat({
  required IconData icon,
  required int value,
  required String label,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 4,
    ),
    decoration: BoxDecoration(
      color: FolktriColors.background,
      borderRadius:
          BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 21,
        ),

        const SizedBox(height: 5),

        Text(
          '$value',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color:
                FolktriColors.midnightIndigo,
          ),
        ),

        const SizedBox(height: 2),

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
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

  Widget buildChildrenSection() {
  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Our Children',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
                color:
                    FolktriColors.midnightIndigo,
              ),
            ),
          ),

          if (children.isNotEmpty)
            TextButton(
              onPressed: () {
                // Optional dedicated children
                // page can go here later.
              },
              child: const Text(
                'See all',
              ),
            ),
        ],
      ),

      const SizedBox(height: 10),

      SizedBox(
        height: 108,
        child: ListView(
          scrollDirection:
              Axis.horizontal,
          children: [
            // ADD CHILD
            InkWell(
              borderRadius:
                  BorderRadius.circular(16),
              onTap: () async {
                final result =
                    await context.push(
                  '/family/${widget.familyId}'
                  '/add-children',
                );

                if (result == true) {
                  await loadFamilyData();
                }
              },
              child: const SizedBox(
                width: 72,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor:
                          FolktriColors.primaryIndigo,
                      child: Icon(
                        Icons.add_rounded,
                        color:
                            FolktriColors.surface,
                        size: 30,
                      ),
                    ),

                    SizedBox(height: 7),

                    Text(
                      'Add Child',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            FolktriColors.primaryIndigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            ...children.map(
              (child) =>
                  buildChildAvatar(child),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget buildChildAvatar(
  Map<String, dynamic> child,
) {
  final firstName =
      child['first_name']?.toString() ??
          'Child';

  return InkWell(
    borderRadius:
        BorderRadius.circular(16),
    onTap: () async {
      await context.push(
        '/child/${child['id']}',
      );

      if (mounted) {
        await loadFamilyData();
      }
    },
    child: SizedBox(
      width: 78,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color:
                  FolktriColors.lightLavender,
            ),
            child: const Icon(
              Icons.child_care_rounded,
              color:
                  FolktriColors.primaryIndigo,
              size: 28,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            firstName,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color:
                  FolktriColors.primaryText,
            ),
          ),
        ],
      ),
    ),
  );
}

  List<Map<String, dynamic>>
    getFamilyActivity() {
  final activity =
      <Map<String, dynamic>>[];

  for (final milestone in milestones) {
    final date =
        DateTime.tryParse(
      milestone['milestone_date']
              ?.toString() ??
          '',
    );

    if (date != null) {
      activity.add({
        'type': 'milestone',
        'date': date,
        'data': milestone,
      });
    }
  }

  for (final photo in photos) {
    final date =
        DateTime.tryParse(
      photo['created_at']
              ?.toString() ??
          '',
    );

    if (date != null) {
      activity.add({
        'type': 'photo',
        'date': date,
        'data': photo,
      });
    }
  }

  for (final event in events) {
    final date =
        DateTime.tryParse(
      event['start_at']
              ?.toString() ??
          '',
    );

    if (date != null) {
      activity.add({
        'type': 'event',
        'date': date,
        'data': event,
      });
    }
  }

  activity.sort(
    (a, b) =>
        (b['date'] as DateTime)
            .compareTo(
      a['date'] as DateTime,
    ),
  );

  return activity;
}

Widget buildRecentActivity() {
  final activity =
      getFamilyActivity();

  final recent =
      activity.take(3).toList();

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
                color:
                    FolktriColors.midnightIndigo,
              ),
            ),
          ),

          if (activity.length > 3)
            TextButton(
              onPressed:
                  openFamilyTimeline,
              child: const Text(
                'See all',
              ),
            ),
        ],
      ),

      const SizedBox(height: 8),

      if (recent.isEmpty)
        buildEmptyActivity()
      else
        ...recent.map(
          buildActivityCard,
        ),

      if (activity.isNotEmpty) ...[
        const SizedBox(height: 8),

        Center(
          child: TextButton.icon(
            onPressed:
                openFamilyTimeline,
            icon: const Icon(
              Icons.auto_awesome_rounded,
              size: 17,
            ),
            label: const Text(
              'View Full Family Timeline',
            ),
          ),
        ),
      ],
    ],
  );
}

Widget buildEmptyActivity() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius:
          BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          color:
              FolktriColors.primaryIndigo,
          size: 34,
        ),

        SizedBox(height: 10),

        Text(
          'Your family memories will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                FolktriColors.secondaryText,
          ),
        ),
      ],
    ),
  );
}

Widget buildActivityCard(Map<String, dynamic> item,) {
  final type =
      item['type']?.toString() ??
          '';

  final data =
      Map<String, dynamic>.from(
    item['data'],
  );

  final date =
      item['date'] as DateTime;

  IconData icon;
  Color color;
  String typeLabel;
  String title;

  switch (type) {
    case 'milestone':
      icon = Icons.star_rounded;
      color = FolktriColors.dustyRose;
      typeLabel = 'Milestone';
      title =
          data['title']?.toString() ??
              'Milestone';
      break;

    case 'event':
      icon =
          Icons.calendar_month_rounded;
      color =
          FolktriColors.primaryIndigo;
      typeLabel = 'Event';
      title =
          data['title']?.toString() ??
              'Event';
      break;

    case 'photo':
      icon = Icons.image_rounded;
      color =
          const Color(0xFF4C9BC5);
      typeLabel = 'Photo';

      final caption =
          data['caption']
              ?.toString()
              .trim();

      title =
          caption != null &&
                  caption.isNotEmpty
              ? caption
              : 'Family Photo';

      break;

    default:
      icon = Icons.circle;
      color =
          FolktriColors.primaryIndigo;
      typeLabel = 'Activity';
      title = 'Family Activity';
  }

  return Container(
    margin:
        const EdgeInsets.only(
      bottom: 10,
    ),
    padding:
        const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius:
          BorderRadius.circular(17),
      boxShadow: [
        BoxShadow(
          color: Colors.black
              .withOpacity(0.04),
          blurRadius: 12,
          offset:
              const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      FolktriColors.primaryText,
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '$typeLabel • '
                '${formatActivityDate(date)}',
                style: const TextStyle(
                  color:
                      FolktriColors.secondaryText,
                  fontSize: 12,
                ),
              ),
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
  );
}

String formatActivityDate(DateTime date) {
  const months = [
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

  final local = date.toLocal();

  return '${months[local.month - 1]} '
      '${local.day}, ${local.year}';
}

void openFamilyTimeline() {
  context.push(
    '/family/${widget.familyId}/timeline',
  );
}

  @override
  Widget build(BuildContext context) {
    void showFamilyAddMenu() {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor:
        FolktriColors.surface,

    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            20,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                'Add to your family',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      FolktriColors.midnightIndigo,
                ),
              ),

              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(
                  Icons.calendar_month_rounded,
                  color:
                      FolktriColors.primaryIndigo,
                ),
                title:
                    const Text('Add Event'),
                onTap: () async {
                  Navigator.pop(
                    sheetContext,
                  );

                  final result =
                      await context.push<bool>(
                    '/family/${widget.familyId}'
                    '/calendar/add-event',
                  );

                  if (result == true) {
                    await loadFamilyData();
                  }
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.child_care_rounded,
                  color:
                      FolktriColors.connectionTeal,
                ),
                title:
                    const Text('Add Child'),
                onTap: () async {
                  Navigator.pop(
                    sheetContext,
                  );

                  final result =
                      await context.push(
                    '/family/${widget.familyId}'
                    '/add-children',
                  );

                  if (result == true) {
                    await loadFamilyData();
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (family == null) {
      return Scaffold(
        backgroundColor: FolktriColors.background,

        appBar: AppBar(
          backgroundColor: FolktriColors.midnightIndigo,
          foregroundColor: FolktriColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,

          leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          tooltip: 'Back to Family Dashboard',
          onPressed: () {
            context.go('/families');
          },
        ),
      ),
        body: const Center(
          child: Text(
            "Family could not be found.",
          ),
        ),
      );
    }

    final familyName =
        family!['family_name']?.toString() ??
            "Family";

    final currentUser = supabase.auth.currentUser;

    final isFamilyOwner =
      currentUser != null &&
      family!['created_by']
            ?.toString() ==
        currentUser.id;

    return Scaffold(
      backgroundColor: FolktriColors.background,

      appBar: AppBar(
        backgroundColor: FolktriColors.midnightIndigo,
        foregroundColor: FolktriColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        tooltip: 'Back to Family Dashboard',
        onPressed: () {
          context.go('/families');
        },
      ),
        title: Text(
          familyName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          if (isFamilyOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
              if (value == 'delete-family') {
                deleteFamily();
              }
            },

      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'delete-family',

          child: Row(
            children: [
              Icon(Icons.delete_forever_outlined,),
              SizedBox(width: 8,),
              Text('Delete Family',),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: RefreshIndicator(
  color:
      FolktriColors.primaryIndigo,

  onRefresh: loadFamilyData,

  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      buildFamilyHeader(),

      Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          100,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            buildChildrenSection(),

            const SizedBox(height: 20),

            buildRecentActivity(),
          ],
        ),
      ),
    ],
  ),
),

floatingActionButton:
    FloatingActionButton(
  backgroundColor:
      FolktriColors.primaryIndigo,

  foregroundColor:
      FolktriColors.surface,

  onPressed:
      showFamilyAddMenu,

  child: const Icon(
    Icons.add_rounded,
    size: 30,
  ),
),


    );
  }
}