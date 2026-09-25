//This page will display the list of families and allow the user to select a family to view its details.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Styling/folktri_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FamiliesPage extends StatefulWidget {
  const FamiliesPage({super.key});

  @override
  State<FamiliesPage> createState() => _FamiliesPageState();
}

class _FamiliesPageState extends State<FamiliesPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> families = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadFamilies();
  }

  Future<void> loadFamilies() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in to view your families.');
      }

      // Load approved memberships.
      final membershipResponse = await supabase
          .from('Family_Members')
          .select('family_id')
          .eq('user_id', user.id)
          .eq('status', 'approved');

      final familyIds = membershipResponse
          .map((membership) =>
              membership['family_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      // Include families created by the current user,
      // even if an owner membership row is missing.
      final ownedResponse = await supabase
          .from('Families')
          .select('id, family_name, created_by')
          .eq('created_by', user.id);

      for (final ownedFamily in ownedResponse) {
        final id = ownedFamily['id']?.toString();
        if (id != null && id.isNotEmpty) {
          familyIds.add(id);
        }
      }

      List<Map<String, dynamic>> result = [];

      if (familyIds.isNotEmpty) {
        final familyResponse = await supabase
            .from('Families')
            .select('id, family_name, created_by')
            .inFilter('id', familyIds.toList())
            .order('family_name');

        result = List<Map<String, dynamic>>.from(
          familyResponse,
        );
      }

      if (!mounted) return;

      setState(() {
        families = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD FAMILIES ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load your families.';
      });
    }
  }

  void showFamilyOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: FolktriColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20, 8, 20, 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your family space',
                  style: TextStyle(
                    color: FolktriColors.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Create a new family or join one '
                  'you have been invited to.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FolktriColors.secondaryText,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: FolktriColors.primaryIndigo,
                  ),
                  title: const Text('Create a family'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    // Use your existing route for creating
                    // a family. Update this path if needed.
                    context.push('/create-family');
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.group_add_outlined,
                    color: FolktriColors.primaryIndigo,
                  ),
                  title: const Text('Join a family'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    // Use your existing route for joining
                    // a family. Update this path if needed.
                    context.push('/join-family');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildFamilyCard(
    Map<String, dynamic> family,
  ) {
    final familyId = family['id']?.toString() ?? '';

    final familyName =
        family['family_name']?.toString() ?? 'Family';

    final currentUserId =
        supabase.auth.currentUser?.id;

    final isOwner =
        family['created_by']?.toString() == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          onTap: familyId.isEmpty
              ? null
              : () async {
                  await context.push(
                    '/family/$familyId',
                  );

                  if (mounted) {
                    loadFamilies();
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      FolktriColors.lightLavender,
                  child: Icon(
                    Icons.family_restroom_rounded,
                    color: FolktriColors.primaryIndigo,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        familyName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FolktriColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 13,
                            color: FolktriColors.secondaryText,
                          ),

                          const SizedBox(width: 4),

                          Flexible(
                            child: Text(
                              isOwner
                                  ? 'Your family · Private'
                                  : 'Joined family · Private',
                              style: const TextStyle(
                                color:
                                    FolktriColors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: FolktriColors.primaryIndigo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolktriColors.background,

      appBar: AppBar(
        backgroundColor: FolktriColors.midnightIndigo,
        foregroundColor: FolktriColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title:  Text(
          'Your Families',
          style: GoogleFonts.marckScript(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: FolktriColors.surface,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back to dashboard',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            context.go('/app');
          },
        ),
      ),

      body: RefreshIndicator(
        color: FolktriColors.primaryIndigo,
        onRefresh: loadFamilies,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: FolktriColors.primaryIndigo,
                ),
              )
            : errorMessage != null
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: FolktriColors.dustyRose,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: FolktriColors.secondaryText,
                        ),
                      ),
                      TextButton(
                        onPressed: loadFamilies,
                        child: const Text('Try again'),
                      ),
                    ],
                  )
                : families.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 80),
                          const Icon(
                            Icons.family_restroom_rounded,
                            size: 64,
                            color: FolktriColors.primaryIndigo,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your families will appear here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FolktriColors.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a family or join one '
                            'to start sharing moments.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FolktriColors.secondaryText,
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          16, 20, 16, 24,
                        ),
                        children: [
                          const Text(
                            'Every family, one special place.',
                            style: TextStyle(
                              color: FolktriColors.secondaryText,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 20),

                          ...families.map(buildFamilyCard),
                        ],
                      ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: FolktriColors.primaryIndigo,
        foregroundColor: FolktriColors.surface,
        onPressed: showFamilyOptions,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create or Join'),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Calendar

        type: BottomNavigationBarType.fixed,

        backgroundColor: FolktriColors.surface,

        selectedItemColor:FolktriColors.primaryIndigo,

        unselectedItemColor: FolktriColors.secondaryText,

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
              context.go('/family/:familyId/calendar');
              break;

            // FAMILY
            case 2:
              // Already on family page.
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
    );
  }
}