import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:google_fonts/google_fonts.dart';
import '../Styling/folktri_colors.dart';

//This page contains all the data for the specific family selected.

class FamilyTimelinePage extends StatefulWidget {
  final String familyId;

  const FamilyTimelinePage({
    super.key,
    required this.familyId,
  });

  @override
  State<FamilyTimelinePage> createState() =>
      _FamilyTimelinePageState();
}

class _FamilyTimelinePageState
    extends State<FamilyTimelinePage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? family;

  List<Map<String, dynamic>> photos = [];
  List<Map<String, dynamic>> milestones = [];
  List<Map<String, dynamic>> events = [];

  bool isLoading = true;

  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();

    loadTimeline();
  }

  // =========================================================
  // LOAD TIMELINE
  // =========================================================

  Future<void> loadTimeline() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // -------------------------------------------------------
      // FAMILY
      // -------------------------------------------------------

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

      // -------------------------------------------------------
      // CHILDREN
      //
      // Photos and milestones currently connect to children,
      // so first get every child belonging to this family.
      // -------------------------------------------------------

      final childrenResponse = await supabase
          .from('Children')
          .select('id')
          .eq(
            'family_id',
            widget.familyId,
          );

      final childIds = childrenResponse
          .map(
            (child) =>
                child['id']?.toString(),
          )
          .whereType<String>()
          .where(
            (id) => id.isNotEmpty,
          )
          .toList();

      // -------------------------------------------------------
      // EVENTS
      // -------------------------------------------------------

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

      // -------------------------------------------------------
      // PHOTOS + MILESTONES
      // -------------------------------------------------------

      List<Map<String, dynamic>> loadedPhotos = [];
      List<Map<String, dynamic>> loadedMilestones = [];

      if (childIds.isNotEmpty) {
        final photosResponse = await supabase
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

        final milestonesResponse = await supabase
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

        photos = loadedPhotos;
        milestones = loadedMilestones;

        events =
            List<Map<String, dynamic>>.from(
          eventsResponse,
        );

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'LOAD FAMILY TIMELINE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load family timeline: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // COMBINE ACTIVITY
  // =========================================================

  List<Map<String, dynamic>> getFamilyActivity() {
    final activity =
        <Map<String, dynamic>>[];

    // -------------------------------------------------------
    // MILESTONES
    // -------------------------------------------------------

    for (final milestone in milestones) {
      final date = DateTime.tryParse(
        milestone['milestone_date']
                ?.toString() ??
            '',
      );

      if (date != null) {
        activity.add({
          'type': 'milestone',
          'date': date.toLocal(),
          'data': milestone,
        });
      }
    }

    // -------------------------------------------------------
    // PHOTOS
    // -------------------------------------------------------

    for (final photo in photos) {
      final date = DateTime.tryParse(
        photo['created_at']
                ?.toString() ??
            '',
      );

      if (date != null) {
        activity.add({
          'type': 'photo',
          'date': date.toLocal(),
          'data': photo,
        });
      }
    }

    // -------------------------------------------------------
    // EVENTS
    // -------------------------------------------------------

    for (final event in events) {
      final date = DateTime.tryParse(
        event['start_at']
                ?.toString() ??
            '',
      );

      if (date != null) {
        activity.add({
          'type': 'event',
          'date': date.toLocal(),
          'data': event,
        });
      }
    }

    // -------------------------------------------------------
    // FILTER
    // -------------------------------------------------------

    final filtered = selectedFilter == 'all'
        ? activity
        : activity.where(
            (item) {
              return item['type'] ==
                  selectedFilter;
            },
          ).toList();

    // NEWEST FIRST
    filtered.sort(
      (a, b) =>
          (b['date'] as DateTime)
              .compareTo(
        a['date'] as DateTime,
      ),
    );

    return filtered;
  }

  // =========================================================
  // GROUP ACTIVITY BY MONTH
  // =========================================================

  Map<String, List<Map<String, dynamic>>>
      groupActivityByMonth() {
    final activity =
        getFamilyActivity();

    final grouped =
        <String,
            List<Map<String, dynamic>>>{};

    for (final item in activity) {
      final date =
          item['date'] as DateTime;

      final key =
          '${date.year}-${date.month}';

      grouped.putIfAbsent(
        key,
        () => [],
      );

      grouped[key]!.add(item);
    }

    return grouped;
  }

  // =========================================================
  // FILTER BAR
  // =========================================================

  Widget buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: [
          buildFilterChip(
            label: 'All Activity',
            value: 'all',
          ),

          const SizedBox(width: 8),

          buildFilterChip(
            label: 'Photos',
            value: 'photo',
          ),

          const SizedBox(width: 8),

          buildFilterChip(
            label: 'Milestones',
            value: 'milestone',
          ),

          const SizedBox(width: 8),

          buildFilterChip(
            label: 'Events',
            value: 'event',
          ),
        ],
      ),
    );
  }

  Widget buildFilterChip({
    required String label,
    required String value,
  }) {
    final isSelected =
        selectedFilter == value;

    return InkWell(
      borderRadius:
          BorderRadius.circular(22),

      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? FolktriColors.primaryIndigo
              : FolktriColors.lightLavender
                  .withOpacity(0.55),

          borderRadius:
              BorderRadius.circular(22),
        ),

        child: Text(
          label,

          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,

            color: isSelected
                ? FolktriColors.surface
                : FolktriColors.primaryText,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MONTH SECTION
  // =========================================================

  Widget buildMonthSection(
    String key,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final date =
        items.first['date']
            as DateTime;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Padding(
          padding:
              const EdgeInsets.only(
            top: 8,
            bottom: 12,
          ),

          child: Text(
            '${monthName(date.month)} '
            '${date.year}',

            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color:
                  FolktriColors.midnightIndigo,
            ),
          ),
        ),

        // Timeline
        ...List.generate(
          items.length,
          (index) {
            final item = items[index];

            final isLast =
                index ==
                    items.length - 1;

            return buildTimelineItem(
              item,
              showLine: !isLast,
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  String? getActivityImageUrl(
  String type,
  Map<String, dynamic> data,
) {
  if (type == 'photo') {
    final url =
        data['photo_url']?.toString().trim();

    if (url != null && url.isNotEmpty) {
      return url;
    }
  }

  if (type == 'milestone') {
    final url =
        data['photo_url']?.toString().trim();

    if (url != null && url.isNotEmpty) {
      return url;
    }
  }

  return null;
}

  // =========================================================
  // TIMELINE ITEM
  // =========================================================

  Widget buildTimelineItem(
    Map<String, dynamic> item, {required bool showLine,}) {
    final type = item['type']?.toString() ?? '';

    final data = Map<String, dynamic>.from(item['data'],);

    final date = item['date'] as DateTime;

    final imageUrl = getActivityImageUrl(type, data,);

    IconData icon;
    Color color;
    String typeLabel;
    String title;

    switch (type) {
      case 'milestone':
        icon = Icons.star_rounded;
        color =
            FolktriColors.dustyRose;
        typeLabel = 'Milestone';

        title =
            data['title']
                    ?.toString() ??
                'Milestone';

        break;

      case 'photo':
        icon = Icons.image_rounded;
        color = const Color(0xFF4C9BC5);

        typeLabel = 'Photo';

        final caption = data['caption']
                ?.toString()
                .trim();

        title = caption != null && caption.isNotEmpty
                ? caption
                : 'Family Photo';

        break;

      case 'event':
        icon = eventIcon(data['event_type']
              ?.toString(),
        );

        color = eventColor(data['event_type']
              ?.toString(),
        );

        typeLabel = 'Event';

        title = data['title']
                    ?.toString() ??
                'Event';

        break;

      default:
        icon = Icons.circle_rounded;

        color =FolktriColors.primaryIndigo;

        typeLabel = 'Activity';
        title = 'Family Activity';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,

        children: [
          // -------------------------------------------------
          // TIMELINE DOT + LINE
          // -------------------------------------------------

          SizedBox(
            width: 38,

            child: Column(
              children: [
                Container(
                  width: 13,
                  height: 13,

                  decoration:
                      BoxDecoration(
                    color: color,
                    shape:
                        BoxShape.circle,

                    border:
                        Border.all(
                      color:
                          FolktriColors.surface,
                      width: 3,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: color
                            .withOpacity(
                          0.25,
                        ),

                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),

                if (showLine)
                  Expanded(
                    child:
                        Container(
                      width: 2,

                      margin:
                          const EdgeInsets
                              .symmetric(
                        vertical: 3,
                      ),

                      color:
                          FolktriColors
                              .lightLavender,
                    ),
                  ),
              ],
            ),
          ),

          // -------------------------------------------------
          // CARD
          // -------------------------------------------------

          Expanded(
            child: Container(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),

              padding:
                  const EdgeInsets.all(
                14,
              ),

              decoration:
                  BoxDecoration(
                color:
                    FolktriColors.surface,

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withOpacity(
                      0.04,
                    ),

                    blurRadius: 12,

                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Container(
                    width: 42,
                    height: 42,

                    decoration:
                        BoxDecoration(
                      color: color
                          .withOpacity(
                        0.12,
                      ),

                      shape:
                          BoxShape.circle,
                    ),

                    child: Icon(
                      icon,
                      color: color,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 12,),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                typeLabel,

                                style: TextStyle(
                                  color: color,

                                  fontSize: 11,

                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            Text(
                              formatActivityDate(date,),
                              style: const TextStyle(
                                color: FolktriColors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5,),

                        Text(
                          title,
                          style: const TextStyle(
                            color: FolktriColors.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        buildActivityDetails(type, data, date,),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (imageUrl != null) ...[
  const SizedBox(
    width: 10,
  ),

  ClipRRect(
    borderRadius:
        BorderRadius.circular(12),
    child: Image.network(
      imageUrl,
      width: 78,
      height: 78,
      fit: BoxFit.cover,

      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          width: 78,
          height: 78,
          color:
              FolktriColors.lightLavender,
          child: const Center(
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  FolktriColors.primaryIndigo,
            ),
          ),
        );
      },

      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          width: 78,
          height: 78,
          color:
              FolktriColors.lightLavender,
          child: const Icon(
            Icons.image_outlined,
            color:
                FolktriColors.primaryIndigo,
          ),
        );
      },
    ),
  ),
],
        ],
      ),
    );
  }

  // =========================================================
  // ACTIVITY DETAILS
  // =========================================================

  Widget buildActivityDetails(
    String type,
    Map<String, dynamic> data,
    DateTime date,
  ) {
    if (type == 'milestone') {
      final description =
          data['description']
              ?.toString()
              .trim();

      if (description == null ||
          description.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding:
            const EdgeInsets.only(
          top: 5,
        ),

        child: Text(
          description,

          maxLines: 2,

          overflow:
              TextOverflow.ellipsis,

          style: const TextStyle(
            color:
                FolktriColors.secondaryText,

            fontSize: 13,

            height: 1.35,
          ),
        ),
      );
    }

    if (type == 'event') {
      final allDay =
          data['all_day'] == true;

      final location =
          data['location']
              ?.toString()
              .trim();

      return Padding(
        padding:
            const EdgeInsets.only(
          top: 6,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color:
                      FolktriColors
                          .secondaryText,
                ),

                const SizedBox(width: 5),

                Text(
                  allDay
                      ? 'All day'
                      : formatEventTime(
                          date,
                        ),

                  style:
                      const TextStyle(
                    color:
                        FolktriColors
                            .secondaryText,

                    fontSize: 12,
                  ),
                ),
              ],
            ),

            if (location != null &&
                location.isNotEmpty) ...[
              const SizedBox(height: 5),

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
                    width: 5,
                  ),

                  Expanded(
                    child: Text(
                      location,

                      maxLines: 1,

                      overflow:
                          TextOverflow
                              .ellipsis,

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
      );
    }

    return const SizedBox.shrink();
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget buildEmptyState() {
    String message;

    switch (selectedFilter) {
      case 'photo':
        message =
            'No family photos yet.';
        break;

      case 'milestone':
        message =
            'No family milestones yet.';
        break;

      case 'event':
        message =
            'No family events yet.';
        break;

      default:
        message =
            'Your family timeline will appear here.';
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        top: 70,
      ),

      child: Center(
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,

              decoration:
                  const BoxDecoration(
                color:
                    FolktriColors
                        .lightLavender,

                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons
                    .auto_awesome_outlined,

                size: 30,

                color:
                    FolktriColors
                        .primaryIndigo,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              message,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    FolktriColors
                        .secondaryText,

                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EVENT HELPERS
  // =========================================================

  IconData eventIcon(
    String? eventType,
  ) {
    switch (
        eventType?.toLowerCase()) {
      case 'daycare':
        return Icons
            .child_care_rounded;

      case 'school':
        return Icons.school_rounded;

      case 'sports':
        return Icons
            .sports_soccer_rounded;

      case 'birthday':
        return Icons.cake_rounded;

      case 'appointment':
      case 'medical':
        return Icons
            .medical_services_rounded;

      case 'family':
        return Icons
            .family_restroom_rounded;

      default:
        return Icons.event_rounded;
    }
  }

  Color eventColor(
    String? eventType,
  ) {
    switch (
        eventType?.toLowerCase()) {
      case 'sports':
        return FolktriColors
            .connectionTeal;

      case 'birthday':
        return FolktriColors
            .dustyRose;

      case 'appointment':
      case 'medical':
        return FolktriColors
            .primaryIndigo;

      case 'school':
        return const Color(
          0xFF4C8BC7,
        );

      case 'daycare':
        return const Color(
          0xFFE9A23B,
        );

      case 'family':
        return const Color(
          0xFF8C68C8,
        );

      default:
        return FolktriColors
            .primaryIndigo;
    }
  }

  // =========================================================
  // DATE HELPERS
  // =========================================================

  String monthName(
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

  String formatActivityDate(
    DateTime date,
  ) {
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

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  String formatEventTime(
    DateTime date,
  ) {
    return TimeOfDay
        .fromDateTime(
      date,
    ).format(context);
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final familyName =
        family?['family_name']
                ?.toString() ??
            'Family';

    final groupedActivity =
        groupActivityByMonth();

    return Scaffold(
      backgroundColor: FolktriColors.background,

      appBar: AppBar(
        backgroundColor: FolktriColors.background,

        // foregroundColor:
        //     FolktriColors.midnightIndigo,

        // elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons
                .arrow_back_ios_new_rounded,
          ),

          onPressed: () {
            context.pop();
          },
        ),

        // title: Text(
        //   'Folktri',

        //   style: GoogleFonts.marckScript(
        //     color:
        //         FolktriColors.primaryIndigo,

        //     fontSize: 34,

        //     fontWeight: FontWeight.w400,
        //   ),
        // ),

        //centerTitle: true,
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                    color: FolktriColors.primaryIndigo,
                  ),
            )
          : RefreshIndicator(
              color: FolktriColors.primaryIndigo,

              onRefresh: loadTimeline,

              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 40,),

                children: [
                  // -----------------------------------------
                  // PAGE HEADER
                  // -----------------------------------------

                  Text(
                    familyName,

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      color: FolktriColors.midnightIndigo,

                      fontSize: 23,

                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox( height: 4,),

                  const Text(
                    'Family Timeline',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: FolktriColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20,),

                  // -----------------------------------------
                  // FILTERS
                  // -----------------------------------------

                  buildFilterBar(),

                  const SizedBox(height: 20,),

                  // -----------------------------------------
                  // TIMELINE
                  // -----------------------------------------

                  if (groupedActivity.isEmpty)
                    buildEmptyState()
                  else
                    ...groupedActivity.entries.map(
                      (entry) =>
                          buildMonthSection(entry.key, entry.value,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}