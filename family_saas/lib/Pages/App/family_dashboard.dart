import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



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

    final joinedFamilyIds =
        memberships
            .map(
              (membership) =>
                  membership['family_id']
                      ?.toString(),
            )
            .whereType<String>()
            .toList();

    List<Map<String, dynamic>>
        joinedFamilies = [];

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

  String? childName;

  if (childData != null) {
    final firstName =
        childData['first_name'] ?? '';

    final middleName =
        childData['middle_name'] ?? '';

    final lastName =
        childData['last_name'] ?? '';

    final name = [
      firstName,
      middleName,
      lastName,
    ]
        .where(
          (value) =>
              value
                  .toString()
                  .trim()
                  .isNotEmpty,
        )
        .join(' ');

    if (name.isNotEmpty) {
      childName = name;
    }
  }

  return Card(
    margin:
        const EdgeInsets.only(
      bottom: 16,
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.all(
            16,
          ),
          child: Row(
            children: [
              const CircleAvatar(
                child: Icon(
                  Icons.photo,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  childName != null
                      ? 'New photo of $childName'
                      : 'New family photo',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (photo['photo_url'] !=
            null)
          Image.network(
            photo['photo_url'],
            width:
                double.infinity,
            height: 300,
            fit:
                BoxFit.cover,
          ),

        if (photo['caption'] !=
            null)
          Padding(
            padding:
                const EdgeInsets
                    .all(16),
            child: Text(
              photo['caption'],
            ),
          ),
      ],
    ),
  );
}

Widget buildMilestoneFeedCard(
  Map<String, dynamic> milestone,
) {
  final childData =
      milestone['child'];

  String childName = 'A child';

  if (childData != null) {
    final firstName =
        childData['first_name'] ?? '';

    final middleName =
        childData['middle_name'] ?? '';

    final lastName =
        childData['last_name'] ?? '';

    childName = [
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
  }

  return Card(
    margin: const EdgeInsets.only(
      bottom: 16,
    ),
    child: InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: () {
        final childId =
            milestone['child_id'];

        if (childId != null) {
          context.push(
            '/child/$childId',
          );
        }
      },
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.emoji_events,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Text(
                    '$childName reached a milestone',
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
              height: 16,
            ),

            if (milestone[
                    'photo_url'] !=
                null)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                child: Image.network(
                  milestone[
                      'photo_url'],
                  width:
                      double.infinity,
                  height: 220,
                  fit:
                      BoxFit.cover,
                ),
              ),

            if (milestone[
                    'photo_url'] !=
                null)
              const SizedBox(
                height: 16,
              ),

            Text(
              milestone['title'] ?? '',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge,
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

            const SizedBox(
              height: 12,
            ),

            Text(
              milestone['event_date']
                  .toString(),
              style:
                  Theme.of(context)
                      .textTheme
                      .bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
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

  @override
  Widget build(BuildContext context){

    return Scaffold(

      
      appBar: AppBar(
        title: const Text("Family Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Family",
            onPressed: showFamilyOptions,
          ),
          // buildProfileHeader(),
          // const SizedBox(width: 8,),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
                  DrawerHeader(
        child: InkWell(
          onTap: () async {
            Navigator.of(context).pop();

            await context.push(
              '/profile',
            );

            loadUserProfile();
          },

          child: Row(
            children: [
              CircleAvatar(
                radius: 30,

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
                            size: 30,
                          )
                        : null,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        userProfile?['first_name']
                                ?.toString() ??
                            '',
                        userProfile?['last_name']
                                ?.toString() ??
                            '',
                      ]
                          .where(
                            (name) =>
                                name
                                    .trim()
                                    .isNotEmpty,
                          )
                          .join(' '),

                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      'View Profile',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

  if (families.isNotEmpty)
  Padding(
    padding: const EdgeInsets.fromLTRB(
      16,
      16,
      16,
      8,
    ),
    child: DropdownButtonFormField<String>(
      initialValue: selectedFamilyId,
      decoration: const InputDecoration(
        labelText: 'Family',
        prefixIcon: Icon(
          Icons.family_restroom,
        ),
        border: OutlineInputBorder(),
      ),
      items: families.map(
        (family) {
          return DropdownMenuItem<String>(
            value: family['id'].toString(),
            child: Text(
              family['family_name']
                      ?.toString() ??
                  'Unnamed Family',
            ),
          );
        },
      ).toList(),
      onChanged: (familyId) {
        if (familyId == null) {
          return;
        }

        setState(() {
          selectedFamilyId =
              familyId;
        });

        Navigator.pop(context);

        context.push(
          '/family/$familyId',
        );
      },
    ),
  ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                // Navigate to the home page
                Navigator.pop(context);
                context.go('/app');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined,),
              title: const Text('Notifications',),
              onTap: () {
                Navigator.pop(context);
                context.push('/notifications',);
            },
          ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () async {
          Navigator.of(context).pop();

          await context.push(
            '/profile',
          );
          loadUserProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                //Close the drawer before navigating to the settings page
                Navigator.pop(context);
                // Navigate to the settings page
                context.push('/settings');
              },
            ),
          ],
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : !hasApprovedFamily
              ? const Center(
                  child: Text(
                    "Create a family or join an existing family to get started.",
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Upcoming',
                        style:
                          Theme.of(context).textTheme.titleLarge,
                        ),

        if (families.isNotEmpty)
          TextButton(
            onPressed: () {
              final familyId = selectedFamilyId;

              if (familyId == null) {
                return;
              }

              context.push('/family/$familyId/calendar',);
            },
            child:
                const Text('View Calendar',),
          ),
      ],
    ),

    const SizedBox(height: 8,),

    if (isLoadingEvents)
      const Center(
        child:
            CircularProgressIndicator(),
      )
    else if (upcomingEvents.isEmpty)
      const Padding(
        padding:
            EdgeInsets.symmetric(vertical: 24,),
        child: Text('No upcoming events.',),
      )
    else
      SizedBox(
        height: 190,
        child:
            ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: upcomingEvents.length,
          itemBuilder:
              (
            context,
            index,
          ) {
            final event = upcomingEvents[index];

            return buildUpcomingEventCard(
              event,
            );
          },
        ),
      ),

    const SizedBox(height: 24,),

    Text('Family Feed',
      style:
          Theme.of(context).textTheme.titleLarge,
    ),

    const SizedBox(height: 12,),

    if (isLoadingFeed)
      const Center(
        child:
            CircularProgressIndicator(),
      )
    else if (feedItems.isEmpty)
      const Padding(
        padding:
            EdgeInsets.symmetric(vertical: 40,),
        child: Center(
          child: Text('No family activity yet.',),
        ),
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
