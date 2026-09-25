import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Styling/folktri_colors.dart';
import 'package:google_fonts/google_fonts.dart';



class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});


  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}


class _FamilyDashboardState extends State<FamilyDashboard> {

  bool isLoading = true;
  bool hasApprovedFamily = false;

  List<Map<String, dynamic>> feedItems = [];
  bool isLoadingFeed = true;

  List<Map<String, dynamic>> upcomingEvents = [];
  bool isLoadingEvents = true;

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> families = [];

  String? selectedFamilyId;

  Map<String, dynamic>? userProfile;

  String? profilePhotoUrl;

  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    checkFamilyMembership();
    loadFeed();
    loadUpcomingEvents();
    loadUserProfile();
  }

Future<void> checkFamilyMembership() async {
  try {
    final user =
        supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        families = [];
        selectedFamilyId = null;
        hasApprovedFamily = false;
        isLoading = false;
      });

      return;
    }

    // ==========================================
    // FAMILIES CREATED BY THE USER
    // ==========================================

    final createdFamiliesResponse =
        await supabase
            .from('Families')
            .select(
              'id, family_name',
            )
            .eq(
              'created_by',
              user.id,
            );

    final createdFamilies =
        List<Map<String, dynamic>>.from(
      createdFamiliesResponse,
    );

    // ==========================================
    // FAMILIES THE USER JOINED
    // ==========================================

    final membershipResponse =
        await supabase
            .from('Family_Members')
            .select(
              'family_id',
            )
            .eq(
              'user_id',
              user.id,
            )
            .eq(
              'status',
              'approved',
            );

    final memberships =
        List<Map<String, dynamic>>.from(
      membershipResponse,
    );

    debugPrint('APPROVED MEMBERSHIPS: $memberships',);

    final joinedFamilyIds =
        memberships.map(
              (membership) => membership['family_id']
                      ?.toString(),
            )
            .whereType<String>()
            .toList();

    List<Map<String, dynamic>> joinedFamilies = [];

    if (joinedFamilyIds.isNotEmpty) {
      final joinedFamiliesResponse =
          await supabase
              .from('Families')
              .select(
                'id, family_name',
              )
              .inFilter(
                'id',
                joinedFamilyIds,
              );

      joinedFamilies =
          List<Map<String, dynamic>>.from(
        joinedFamiliesResponse,
      );

      debugPrint('JOINED FAMILIES: $joinedFamilies',);
    }

    // ==========================================
    // COMBINE BOTH LISTS
    // ==========================================

    final combinedFamilies = [
      ...createdFamilies,
      ...joinedFamilies,
    ];

    // Remove duplicates.
    final uniqueFamilies =
        <String, Map<String, dynamic>>{};

    for (final family
        in combinedFamilies) {
      final familyId =
          family['id'].toString();

      uniqueFamilies[familyId] =
          family;
    }

    final finalFamilies =
        uniqueFamilies.values.toList();

    finalFamilies.sort(
      (a, b) {
        final aName =
            a['family_name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final bName =
            b['family_name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return aName.compareTo(
          bName,
        );
      },
    );

    if (!mounted) return;

    setState(() {
      families = finalFamilies;

      hasApprovedFamily =
          finalFamilies.isNotEmpty;

      // IMPORTANT:
      // Make sure the selected family
      // still actually exists.
      final selectedStillExists =
          selectedFamilyId != null &&
          finalFamilies.any(
            (family) =>
                family['id']
                    .toString() ==
                selectedFamilyId,
          );

      if (selectedStillExists) {
        // Keep the current selection.
      } else if (finalFamilies.isNotEmpty) {
        selectedFamilyId =
            finalFamilies.first['id']
                .toString();
      } else {
        selectedFamilyId = null;
      }

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
          'Error loading families: $e',
        ),
      ),
    );
  }
}

//Dialog box to ask the user if they want to join an existing family or create a new one
void showFamilyOptions() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Add a Family"),

          content: const Text(
            "Would you like to join an existing family or create a new one?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                context.push('/join-family');
              },
              child: const Text("Join Existing Family"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                context.push('/create-family');
              },
              child: const Text("Create New Family"),
            ),
          ],
        );
      },
    );
  }

Future<void> loadFeed() async {
  try {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final membershipResponse = await supabase
        .from('Family_Members')
        .select('family_id')
        .eq('user_id', user.id)
        .eq('status', 'approved');

    final memberships =
        List<Map<String, dynamic>>.from(
      membershipResponse,
    );

    final familyIds = memberships
        .map(
          (membership) =>
              membership['family_id'],
        )
        .where(
          (id) => id != null,
        )
        .toList();

    if (familyIds.isEmpty) {
      if (!mounted) return;

      setState(() {
        feedItems = [];
        isLoadingFeed = false;
      });

      return;
    }

    final milestoneResponse = await supabase
        .from('Milestones')
        .select(
          '''
          id,
          family_id,
          child_id,
          title,
          description,
          milestone_date,
          photo_url,
          created_at,
          Children(
            first_name,
            middle_name,
            last_name
          )
          ''',
        )
        .inFilter(
          'family_id',
          familyIds,
        )
        .order(
          'created_at',
          ascending: false,
        );

    final photoResponse = await supabase
    .from('Photos')
    .select(
      '''
      id,
      family_id,
      child_id,
      photo_url,
      caption,
      created_at,
      Children(
        first_name,
        middle_name,
        last_name
      )
      ''',
    )
    .inFilter(
      'family_id',
      familyIds,
    )
    .order(
      'created_at',
      ascending: false,
    );


    final photos =
        List<Map<String, dynamic>>.from(
      photoResponse,
    );

    final milestones =
        List<Map<String, dynamic>>.from(
      milestoneResponse,
    );

    final milestoneFeed = milestones.map(
      (milestone) {
        return {
          'type': 'milestone',
          'id': milestone['id'],
          'family_id': milestone['family_id'],
          'child_id': milestone['child_id'],
          'title': milestone['title'],
          'description': milestone['description'],
          'photo_url': milestone['photo_url'],
          'event_date': milestone['milestone_date'],
          'created_at': milestone['created_at'],
          'child': milestone['Children'],
        };
      },
    ).toList();

    final photoFeed = photos.map(
      (photo) {
        return {
          'type': 'photo',
          'id': photo['id'],
          'family_id': photo['family_id'],
          'child_id': photo['child_id'],
          'photo_url': photo['photo_url'],
          'caption': photo['caption'],
          'created_at': photo['created_at'],
          'child': photo['Children'],
        };
      },
    ).toList();
    
    final combinedFeed = [
      ...milestoneFeed,
      ...photoFeed,
    ];

    combinedFeed.sort(
      (a, b) {
        final aDate =
          DateTime.parse(
            a['created_at']
              .toString(),
          );

        final bDate =
          DateTime.parse(
            b['created_at']
              .toString(),
          );

    return bDate.compareTo(
      aDate,
    );
  },
);

    if (!mounted) return;

    setState(() {
      feedItems = combinedFeed;
      isLoadingFeed = false;
    });
  } catch (e) {
    debugPrint(
      'Unable to load dashboard feed: $e',
    );

    if (!mounted) return;

    setState(() {
      isLoadingFeed = false;
    });
  }
}

Widget buildFeedItem(
  Map<String, dynamic> item,
) {
  final type =
      item['type']?.toString();

  if (type == 'milestone') {
    return buildMilestoneFeedCard(
      item,
    );
  }

  if (type == 'photo') {
    return buildPhotoFeedCard(
      item,
    );
  }

  return const SizedBox.shrink();
}

Widget buildPhotoFeedCard(
  Map<String, dynamic> photo,
) {
  final childData =
      photo['child'];

String childName = '';

  if (childData is Map) {
    childName = [
      childData['first_name'],
      childData['middle_name'],
      childData['last_name'],
    ]
        .where(
          (value) =>
              value != null &&
              value.toString().trim().isNotEmpty,
        )
        .join(' ');
  }

  final caption =
      photo['caption']?.toString().trim() ?? '';

  final photoUrl =
      photo['photo_url']?.toString() ?? '';

  final createdAt = DateTime.tryParse(
    photo['created_at']?.toString() ?? '',
  )?.toLocal();

  final dateLabel = createdAt == null
      ? 'Family photo'
      : '${createdAt.month}/${createdAt.day}/${createdAt.year}';

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: FolktriColors.midnightIndigo
              .withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor:
                    FolktriColors.lightLavender,
                child: Icon(
                  Icons.family_restroom_rounded,
                  color: FolktriColors.primaryIndigo,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName.isNotEmpty
                          ? 'A moment with $childName'
                          : 'Family photo',
                      style: const TextStyle(
                        color: FolktriColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '$dateLabel · Family only',
                      style: const TextStyle(
                        color:
                            FolktriColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: FolktriColors.secondaryText,
              ),
            ],
          ),
        ),

        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              14, 0, 14, 12,
            ),
            child: Text(
              caption,
              style: const TextStyle(
                color: FolktriColors.primaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

        if (photoUrl.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(18),
            ),
            child: Image.network(
              photoUrl,
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  height: 180,
                  alignment: Alignment.center,
                  color: FolktriColors.lightLavender,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: FolktriColors.primaryIndigo,
                    size: 36,
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
  // String? childName;

  // if (childData != null) {
  //   final firstName =
  //       childData['first_name'] ?? '';

  //   final middleName =
  //       childData['middle_name'] ?? '';

  //   final lastName =
  //       childData['last_name'] ?? '';

  //   final name = [
  //     firstName,
  //     middleName,
  //     lastName,
  //   ]
  //       .where(
  //         (value) =>
  //             value
  //                 .toString()
  //                 .trim()
  //                 .isNotEmpty,
  //       )
  //       .join(' ');

  //   if (name.isNotEmpty) {
  //     childName = name;
  //   }
  // }

  // return Card(
  //   margin:
  //       const EdgeInsets.only(
  //     bottom: 16,
  //   ),
  //   child: Column(
  //     crossAxisAlignment:
  //         CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding:
  //             const EdgeInsets.all(
  //           16,
  //         ),
  //         child: Row(
  //           children: [
  //             const CircleAvatar(
  //               child: Icon(
  //                 Icons.photo,
  //               ),
  //             ),

  //             const SizedBox(
  //               width: 12,
  //             ),

  //             Expanded(
  //               child: Text(
  //                 childName != null
  //                     ? 'New photo of $childName'
  //                     : 'New family photo',
  //                 style:
  //                     const TextStyle(
  //                   fontWeight:
  //                       FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),

  //       if (photo['photo_url'] !=
  //           null)
  //         Image.network(
  //           photo['photo_url'],
  //           width:
  //               double.infinity,
  //           height: 300,
  //           fit:
  //               BoxFit.cover,
  //         ),

  //       if (photo['caption'] !=
  //           null)
  //         Padding(
  //           padding:
  //               const EdgeInsets
  //                   .all(16),
  //           child: Text(
  //             photo['caption'],
  //           ),
  //         ),
  //     ],
  //   ),
  // );
}

Widget buildMilestoneFeedCard(
  Map<String, dynamic> milestone,
) {
  final childData =
      milestone['child'];

  String childName = 'A child';

  if (childData is Map) {
    final name = [
      childData['first_name'],
      childData['middle_name'],
      childData['last_name'],
    ]
        .where(
          (value) =>
              value != null &&
              value.toString().trim().isNotEmpty,
        )
        .map((value) => value.toString().trim())
        .join(' ');

    if (name.isNotEmpty) {
      childName = name;
    }
  }

  final title =
      milestone['title']?.toString().trim() ?? '';

  final description =
      milestone['description']?.toString().trim() ?? '';

  final photoUrl =
      milestone['photo_url']?.toString().trim() ?? '';

  final childId =
      milestone['child_id']?.toString();

  final milestoneDate = DateTime.tryParse(
    milestone['event_date']?.toString() ?? '',
  );

  final createdAt = DateTime.tryParse(
    milestone['created_at']?.toString() ?? '',
  )?.toLocal();

  // Display the date when the milestone occurred.
  final dateLabel = milestoneDate == null
      ? 'Milestone'
      : '${milestoneDate.month}/'
        '${milestoneDate.day}/'
        '${milestoneDate.year}';

  // Display when the milestone was shared.
  String sharedLabel = 'Family milestone';

  if (createdAt != null) {
    final difference =
        DateTime.now().difference(createdAt);

    if (difference.isNegative ||
        difference.inMinutes < 1) {
      sharedLabel = 'Just now';
    } else if (difference.inMinutes < 60) {
      sharedLabel =
          '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      sharedLabel =
          '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      sharedLabel =
          '${difference.inDays}d ago';
    } else {
      sharedLabel =
          '${createdAt.month}/'
          '${createdAt.day}/'
          '${createdAt.year}';
    }
  }

  // ==========================================
  // MILESTONE CARD
  // ==========================================

  return Container(
    margin: const EdgeInsets.only(
      bottom: 16,
    ),

    decoration: BoxDecoration(
      color: FolktriColors.surface,

      borderRadius: BorderRadius.circular(18),

      boxShadow: [
        BoxShadow(
          color: FolktriColors.midnightIndigo
              .withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),

    child: Material(
      color: Colors.transparent,

      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: childId == null || childId.isEmpty
            ? null
            : () {
                context.push(
                  '/child/$childId',
                );
              },

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================
            // HEADER
            // ==================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                14, 14, 14, 12,
              ),

              child: Row(
                children: [
                  // Milestone avatar
                  const CircleAvatar(
                    radius: 21,

                    backgroundColor:
                        FolktriColors.lightLavender,

                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color:
                          FolktriColors.primaryIndigo,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          '$childName reached a milestone',
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,

                          style: const TextStyle(
                            color:
                                FolktriColors.primaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sharedLabel,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color:
                                      FolktriColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            const Text(
                              '·',
                              style: TextStyle(
                                color:
                                    FolktriColors.secondaryText,
                              ),
                            ),

                            const SizedBox(width: 5),

                            const Icon(
                              Icons.lock_outline_rounded,
                              color:
                                  FolktriColors.secondaryText,
                              size: 12,
                            ),

                            const SizedBox(width: 3),

                            const Text(
                              'Family only',
                              style: TextStyle(
                                color:
                                    FolktriColors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Decorative milestone indicator
                  const Icon(
                    Icons.stars_rounded,
                    color: FolktriColors.dustyRose,
                    size: 23,
                  ),
                ],
              ),
            ),

            // ==================================
            // MILESTONE TITLE AND DESCRIPTION
            // ==================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                14, 0, 14, 12,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,

                      style: const TextStyle(
                        color:
                            FolktriColors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 7),

                    Text(
                      description,

                      style: const TextStyle(
                        color:
                            FolktriColors.primaryText,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Date of the milestone
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: FolktriColors.lightLavender
                          .withValues(alpha: 0.55),

                      borderRadius:
                          BorderRadius.circular(20),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        const Icon(
                          Icons.event_available_outlined,
                          size: 14,
                          color:
                              FolktriColors.primaryIndigo,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          'Milestone date: $dateLabel',

                          style: const TextStyle(
                            color:
                                FolktriColors.midnightIndigo,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================================
            // MILESTONE PHOTO
            // ==================================

            if (photoUrl.isNotEmpty)
              Image.network(
                photoUrl,

                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,

                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    width: double.infinity,
                    height: 180,

                    color:
                        FolktriColors.lightLavender,

                    alignment: Alignment.center,

                    child: const Column(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color:
                              FolktriColors.primaryIndigo,
                          size: 34,
                        ),

                        SizedBox(height: 8),

                        Text(
                          'Unable to load milestone photo',
                          style: TextStyle(
                            color:
                                FolktriColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ==================================
            // CARD FOOTER
            // ==================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: FolktriColors.dustyRose,
                    size: 20,
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    'A special family moment',
                    style: TextStyle(
                      color:
                          FolktriColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),

                  if (childId != null &&
                      childId.isNotEmpty) ...[
                    const Text(
                      'View profile',
                      style: TextStyle(
                        color:
                            FolktriColors.primaryIndigo,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 4),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color:
                          FolktriColors.primaryIndigo,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // if (childData != null) {
  //   final firstName =
  //       childData['first_name'] ?? '';

  //   final middleName =
  //       childData['middle_name'] ?? '';

  //   final lastName =
  //       childData['last_name'] ?? '';

  //   childName = [
  //     firstName,
  //     middleName,
  //     lastName,
  //   ]
  //       .where(
  //         (name) =>
  //             name
  //                 .toString()
  //                 .trim()
  //                 .isNotEmpty,
  //       )
  //       .join(' ');
  // }

  // return Card(
  //   margin: const EdgeInsets.only(
  //     bottom: 16,
  //   ),
  //   child: InkWell(
  //     borderRadius:
  //         BorderRadius.circular(12),
  //     onTap: () {
  //       final childId =
  //           milestone['child_id'];

  //       if (childId != null) {
  //         context.push(
  //           '/child/$childId',
  //         );
  //       }
  //     },
  //     child: Padding(
  //       padding:
  //           const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment:
  //             CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               const CircleAvatar(
  //                 child: Icon(
  //                   Icons.emoji_events,
  //                 ),
  //               ),

  //               const SizedBox(
  //                 width: 12,
  //               ),

  //               Expanded(
  //                 child: Text(
  //                   '$childName reached a milestone',
  //                   style:
  //                       const TextStyle(
  //                     fontWeight:
  //                         FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),

  //           const SizedBox(
  //             height: 16,
  //           ),

  //           if (milestone[
  //                   'photo_url'] !=
  //               null)
  //             ClipRRect(
  //               borderRadius:
  //                   BorderRadius.circular(
  //                 12,
  //               ),
  //               child: Image.network(
  //                 milestone[
  //                     'photo_url'],
  //                 width:
  //                     double.infinity,
  //                 height: 220,
  //                 fit:
  //                     BoxFit.cover,
  //               ),
  //             ),

  //           if (milestone[
  //                   'photo_url'] !=
  //               null)
  //             const SizedBox(
  //               height: 16,
  //             ),

  //           Text(
  //             milestone['title'] ?? '',
  //             style:
  //                 Theme.of(context)
  //                     .textTheme
  //                     .titleLarge,
  //           ),

  //           if (milestone[
  //                   'description'] !=
  //               null) ...[
  //             const SizedBox(
  //               height: 8,
  //             ),
  //             Text(
  //               milestone[
  //                   'description'],
  //             ),
  //           ],

  //           const SizedBox(
  //             height: 12,
  //           ),

  //           Text(
  //             milestone['event_date']
  //                 .toString(),
  //             style:
  //                 Theme.of(context)
  //                     .textTheme
  //                     .bodySmall,
  //           ),
  //         ],
  //       ),
  //     ),
  //   ),
  // );
}

Future<void> loadUpcomingEvents() async {
  try {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final createdFamiliesResponse =
        await supabase
            .from('Families')
            .select('id')
            .eq(
              'created_by',
              user.id,
            );

    final createdFamilies =
        List<Map<String, dynamic>>.from(
      createdFamiliesResponse,
    );

    final membershipResponse =
        await supabase
            .from('Family_Members')
            .select(
              'family_id, can_view_calendar',
            )
            .eq(
              'user_id',
              user.id,
            )
            .eq(
              'status',
              'approved',
            )
            .eq(
              'can_view_calendar',
              true,
            );

    final memberships =
        List<Map<String, dynamic>>.from(
      membershipResponse,
    );

    final familyIds = <String>{
      ...createdFamilies.map(
        (family) =>
            family['id'].toString(),
      ),
      ...memberships.map(
        (membership) =>
            membership['family_id']
                .toString(),
      ),
    }.toList();

    if (familyIds.isEmpty) {
      if (!mounted) return;

      setState(() {
        upcomingEvents = [];
        isLoadingEvents = false;
      });

      return;
    }

    final now =
        DateTime.now().toUtc();

    final response =
        await supabase
            .from('Calendar_Events')
            .select(
              '''
              id,
              family_id,
              child_id,
              title,
              description,
              event_type,
              start_at,
              end_at,
              all_day,
              location,
              assigned_to,
              Children(
                first_name,
                middle_name,
                last_name
              )
              ''',
            )
            .inFilter(
              'family_id',
              familyIds,
            )
            .gte(
              'start_at',
              now.toIso8601String(),
            )
            .order(
              'start_at',
              ascending: true,
            )
            .limit(5);

    if (!mounted) return;

    setState(() {
      upcomingEvents =
          List<Map<String, dynamic>>.from(
        response,
      );

      isLoadingEvents = false;
    });
  } catch (e) {
    debugPrint(
      'Unable to load upcoming events: $e',
    );

    if (!mounted) return;

    setState(() {
      isLoadingEvents = false;
    });
  }
}
  
Widget buildUpcomingEventCard(
  Map<String, dynamic> event,
) {
  final startDate =
      DateTime.parse(
    event['start_at'].toString(),
  ).toLocal();

  final childData =
      event['Children'];

  String? childName;

  if (childData != null) {
    final firstName =
        childData['first_name'] ?? '';

    final middleName =
        childData['middle_name'] ?? '';

    final lastName =
        childData['last_name'] ?? '';

    final fullName = [
      firstName,
      middleName,
      lastName,
    ]
        .where(
          (name) =>
              name
                  .toString()
                  .trim()
                  .isNotEmpty,
        )
        .join(' ');

    if (fullName.isNotEmpty) {
      childName = fullName;
    }
  }

  final dateText =
      '${startDate.month}/${startDate.day}/${startDate.year}';

  final timeText =
      TimeOfDay.fromDateTime(
    startDate,
  ).format(context);

  return Card(
    margin:
        const EdgeInsets.only(
      right: 12,
    ),
    child: SizedBox(
      width: 260,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    event['event_type'] ??
                        'Event',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              event['title'] ?? '',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              '$dateText • $timeText',
            ),

            if (childName != null) ...[
              const SizedBox(
                height: 6,
              ),
              Text(
                'For: $childName',
              ),
            ],

            if (event['location'] !=
                null) ...[
              const SizedBox(
                height: 6,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    child: Text(
                      event['location']
                          .toString(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<void> loadUserProfile() async {
  final user =
      supabase.auth.currentUser;

  if (user == null) {
    return;
  }

  try {
    final response =
        await supabase
            .from('Profiles')
            .select(
              '''
              first_name,
              last_name,
              profile_photo_path
              ''',
            )
            .eq(
              'user_id',
              user.id,
            )
            .maybeSingle();

    String? signedPhotoUrl;

    if (response != null) {
      final photoPath =
          response[
                  'profile_photo_path']
              ?.toString();

      if (photoPath != null &&
          photoPath.isNotEmpty) {
        signedPhotoUrl =
            await supabase.storage
                .from('profile-photos')
                .createSignedUrl(
                  photoPath,
                  3600,
                );
      }
    }

    if (!mounted) return;

    setState(() {
      userProfile = response;

      profilePhotoUrl =
          signedPhotoUrl;

      isLoadingProfile =
          false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingProfile =
          false;
    });

    debugPrint(
      'Unable to load user profile: $e',
    );
  }
}

Widget buildProfileHeader() {
  if (isLoadingProfile) {
    return const SizedBox.shrink();
  }

  final firstName =
      userProfile?['first_name']
          ?.toString() ??
      '';

  final lastName =
      userProfile?['last_name']
          ?.toString() ??
      '';

  final fullName = [
    firstName,
    lastName,
  ]
      .where(
        (name) =>
            name.trim().isNotEmpty,
      )
      .join(' ');

  return InkWell(
    borderRadius:
        BorderRadius.circular(30),

    onTap: () {
      context.go('/profile');
    },

    child: Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          CircleAvatar(
            radius: 18,

            backgroundImage:
                profilePhotoUrl != null
                    ? NetworkImage(
                        profilePhotoUrl!,
                      )
                    : null,

            child:
                profilePhotoUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 20,
                      )
                    : null,
          ),

          const SizedBox(
            width: 8,
          ),

          if (fullName.isNotEmpty)
            Text(
              fullName,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
        ],
      ),
    ),
  );
}

Widget buildFamilySelector() {
  final selectedFamily = families.where(
    (family) =>
        family['id']?.toString() == selectedFamilyId,
  );

  final familyName = selectedFamily.isNotEmpty
      ? selectedFamily.first['family_name']
              ?.toString() ??
          'My Family'
      : 'My Family';

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: FolktriColors.midnightIndigo
              .withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: FolktriColors.lightLavender,
          child: const Icon(
            Icons.family_restroom_rounded,
            color: FolktriColors.primaryIndigo,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                familyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FolktriColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: FolktriColors.secondaryText,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Private family space',
                    style: TextStyle(
                      color: FolktriColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        PopupMenuButton<String>(
          tooltip: 'Choose family',
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: FolktriColors.midnightIndigo,
          ),
          onSelected: (value) {
            if (value == 'add') {
              showFamilyOptions();
              return;
            }

            setState(() {
              selectedFamilyId = value;
            });
          },
          itemBuilder: (context) => [
            ...families.map(
              (family) => PopupMenuItem<String>(
                value: family['id'].toString(),
                child: Text(
                  family['family_name']?.toString() ??
                      'Unnamed Family',
                ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'add',
              child: Text('Add or join a family'),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildQuickPostCard() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: FolktriColors.lightLavender,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: FolktriColors.lightLavender,
              backgroundImage: profilePhotoUrl != null
                  ? NetworkImage(profilePhotoUrl!)
                  : null,
              child: profilePhotoUrl == null
                  ? const Icon(
                      Icons.person_rounded,
                      color: FolktriColors.primaryIndigo,
                    )
                  : null,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  _showPostOptions();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: FolktriColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: FolktriColors.lightLavender,
                    ),
                  ),
                  child: const Text(
                    'Share a moment with your family...',
                    style: TextStyle(
                      color: FolktriColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        const Divider(
          height: 1,
          color: FolktriColors.lightLavender,
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _postAction(
              Icons.photo_library_outlined,
              'Photo',
              FolktriColors.primaryIndigo,
            ),
            _postAction(
              Icons.videocam_outlined,
              'Video',
              FolktriColors.primaryIndigo,
            ),
            _postAction(
              Icons.event_outlined,
              'Event',
              FolktriColors.primaryIndigo,
            ),
            _postAction(
              Icons.star_outline_rounded,
              'Milestone',
              FolktriColors.dustyRose,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _postAction(
  IconData icon,
  String label,
  Color color,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: _showPostOptions,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FolktriColors.primaryText,
            ),
          ),
        ],
      ),
    ),
  );
}

void _showPostOptions() {
  final familyId = selectedFamilyId;

  if (familyId == null) {
    showFamilyOptions();
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20, 8, 20, 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share with your family',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FolktriColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(
                Icons.family_restroom_rounded,
                color: FolktriColors.primaryIndigo,
              ),
              title: const Text('Open family page'),
              subtitle: const Text(
                'Share photos, milestones, and more.',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/family/$familyId');
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildTodaySection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Today',
            style: TextStyle(
              color: FolktriColors.primaryText,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          TextButton(
            onPressed: () {
              final familyId = selectedFamilyId;
              if (familyId != null) {
                context.push(
                  '/family/$familyId/calendar',
                );
              }
            },
            child: const Text(
              'See all',
              style: TextStyle(
                color: FolktriColors.primaryIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 4),

      Row(
        children: [
          Expanded(
            child: _todayCard(
              icon: Icons.calendar_month_rounded,
              title: 'Upcoming\nEvents',
              detail: isLoadingEvents
                  ? 'Loading...'
                  : '${upcomingEvents.length} coming up',
              background: FolktriColors.lightLavender,
              accent: FolktriColors.primaryIndigo,
              onTap: () {
                final familyId = selectedFamilyId;
                if (familyId != null) {
                  context.push(
                    '/family/$familyId/calendar',
                  );
                }
              },
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _todayCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Family\nMoments',
              detail: isLoadingFeed
                  ? 'Loading...'
                  : '${feedItems.length} shared',
              background: FolktriColors.dustyRose
                  .withValues(alpha: 0.17),
              accent: FolktriColors.dustyRose,
              onTap: () {
                _showPostOptions();
              },
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _todayCard(
              icon: Icons.photo_library_outlined,
              title: 'Family\nPhotos',
              detail: isLoadingFeed
                  ? 'Loading...'
                  : '${feedItems.where(
                      (item) => item['type'] == 'photo',
                    ).length} shared',
              background: FolktriColors.lightLavender
                  .withValues(alpha: 0.55),
              accent: FolktriColors.primaryIndigo,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Family Albums is coming soon!',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _todayCard({
  required IconData icon,
  required String title,
  required String detail,
  required Color background,
  required Color accent,
  required VoidCallback onTap,
}) {
  return Material(
    color: background,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 128,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 12,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: FolktriColors.surface,
                child: Icon(
                  icon,
                  color: accent,
                  size: 19,
                ),
              ),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FolktriColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),

              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FolktriColors.secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context){

    return Scaffold(
      backgroundColor: FolktriColors.background,
      
      appBar: AppBar(
        backgroundColor: FolktriColors.midnightIndigo,
        elevation: 0,
        toolbarHeight: 64,
        title:  Text("Folktri", 
          style: GoogleFonts.marckScript(
            fontWeight: FontWeight.w400,
            color: FolktriColors.surface,
            fontSize: 34,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: FolktriColors.surface,
              ),
            tooltip: "Add Family",
            onPressed: showFamilyOptions,
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: FolktriColors.surface
              ),
            tooltip: "Notifications",
            onPressed: () {
              context.push('/notifications',);
            },
          ),  
          // buildProfileHeader(),
           const SizedBox(width: 6,),
        ],
      ),

  bottomNavigationBar: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,

  backgroundColor: FolktriColors.surface,

  selectedItemColor: FolktriColors.primaryIndigo,

  unselectedItemColor: FolktriColors.secondaryText,

  selectedLabelStyle: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12,
  ),

  unselectedLabelStyle: const TextStyle(
    fontSize: 12,
  ),

  showSelectedLabels: true,
  showUnselectedLabels: true,

  currentIndex: 0,

  onTap: (index) {
    switch (index) {
      case 0:
        // Already on the Family Dashboard.
        break;

      case 1:
        // Open the selected family's calendar.
        final familyId = selectedFamilyId;

        if (familyId != null) {
          context.go(
            '/family/$familyId/calendar',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please create or join a family first.',
              ),
            ),
          );
        }
        break;

      case 2:
        // Open the selected family.
        context.go('/families');
        break;

      case 3:
        // Open family albums.
        // Add this route when your Albums page is ready.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Family Albums is coming soon!',
            ),
          ),
        );
        break;

      case 4:
        // Open the user's profile.
        context.go('/profile');//.then((_) {
        //   if (mounted) {
        //     loadUserProfile();
        //   }
        // });
        break;
    }
  },

  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_month_outlined),
      activeIcon: Icon(Icons.calendar_month),
      label: 'Calendar',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.family_restroom_outlined),
      activeIcon: Icon(Icons.family_restroom),
      label: 'Family',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.photo_library_outlined),
      activeIcon: Icon(Icons.photo_library),
      label: 'Albums',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ],
),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: FolktriColors.primaryIndigo,
              ),
            )
          : !hasApprovedFamily
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.family_restroom_rounded, 
                            size: 64,
                            color: FolktriColors.primaryIndigo
                            ),

                          const SizedBox(height: 16,),

                          const Text("Create a family or join an existing family",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              color: FolktriColors.primaryText,
                              fontWeight: FontWeight.bold,
                            )
                          ),

                          const SizedBox(height: 20,),

              //             ElevatedButton.icon(
              //               onPressed: () async {
              //                 setState(() {
              //                   isLoading = true;
              //               });

              //               await checkFamilyMembership();

              //               await Future.wait([
              //                 loadFeed(),
              //                 loadUpcomingEvents(),
              //               ]);
              //             },
              //   icon: const Icon(Icons.refresh,),
              //   label: const Text('Check for Family Access',),
              // ),
                                    ElevatedButton(
                        onPressed: showFamilyOptions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              FolktriColors.primaryIndigo,
                          foregroundColor:
                              FolktriColors.surface,
                        ),
                        child: const Text(
                          'Get Started',
                        ),
                      ),

                      TextButton(
                        onPressed: () async {
                          await checkFamilyMembership();
                          await Future.wait([
                            loadFeed(),
                            loadUpcomingEvents(),
                          ]);
                        },
                        child: const Text(
                          'Check for Family Access',
                        ),
                      ),
            ],
          ),
        ),
      )
              : RefreshIndicator(
                onRefresh: () async {
                  await checkFamilyMembership();

                  await Future.wait([
                    loadFeed(),
                    loadUpcomingEvents(),
                    loadUserProfile(),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                  children: [
    //                 Row(
    //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                   children: [
    //                     Text('Upcoming',
    //                     style:
    //                       Theme.of(context).textTheme.titleLarge,
    //                     ),

    //     if (families.isNotEmpty)
    //       TextButton(
    //         onPressed: () {
    //           final familyId = selectedFamilyId;

    //           if (familyId == null) {
    //             return;
    //           }

    //           context.push('/family/$familyId/calendar',);
    //         },
    //         child:
    //             const Text('View Calendar',),
    //       ),
    //   ],
    // ),

    // const SizedBox(height: 8,),

    // if (isLoadingEvents)
    //   const Center(
    //     child:
    //         CircularProgressIndicator(),
    //   )
    // else if (upcomingEvents.isEmpty)
    //   const Padding(
    //     padding:
    //         EdgeInsets.symmetric(vertical: 24,),
    //     child: Text('No upcoming events.',),
    //   )
    // else
    //   SizedBox(
    //     height: 190,
    //     child:
    //         ListView.builder(
    //       scrollDirection: Axis.horizontal,
    //       itemCount: upcomingEvents.length,
    //       itemBuilder:
    //           (
    //         context,
    //         index,
    //       ) {
    //         final event = upcomingEvents[index];

    //         return buildUpcomingEventCard(
    //           event,
    //         );
    //       },
    //     ),
    //   ),

    buildFamilySelector(),

    const SizedBox(height: 12),

    buildQuickPostCard(),

    const SizedBox(height: 18,),

    buildTodaySection(),

    const SizedBox(height: 22,),

    Text('Family Feed',
      style:
          TextStyle(
            color: FolktriColors.primaryText,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
    ),

    const SizedBox(height: 12,),

    if (isLoadingFeed)
      const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
           child: CircularProgressIndicator(
            color: FolktriColors.primaryIndigo,
            ),
          ),
        )
    else if (feedItems.isEmpty)
      Container( 
        
        padding: EdgeInsets.all(24,),
        decoration: BoxDecoration(
          color: FolktriColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 38,
              color:FolktriColors.primaryIndigo,
            ),

            SizedBox(height: 12,),

            Text('No family activity yet.',
              style: TextStyle(
                color: FolktriColors.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 6,),

            Text('Share a moment with your family to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FolktriColors.secondaryText,
              ),
            ),
          ],
        )
      
      )   
    else
      ...feedItems.map(
        (item) {
          return buildFeedItem(
            item,
          );
        },
      ),
  ],
),
      ),
    );
  }
}
