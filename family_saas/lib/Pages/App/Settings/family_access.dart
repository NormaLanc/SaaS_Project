import 'package:flutter/material.dart';
import '../../Styling/folktri_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyAccessPage extends StatefulWidget {

    const FamilyAccessPage({super.key});


  @override
  State<FamilyAccessPage> createState() => _FamilyAccessPageState();
}

class _FamilyAccessPageState extends State<FamilyAccessPage> {

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> ownedFamilies = [];
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> memberProfiles = [];

  String? selectedFamilyId;

  bool isLoadingFamilies = true;
  bool isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    loadOwnedFamilies();
  }

  Future<void> loadOwnedFamilies() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          isLoadingFamilies = false;
        });
      }
      return;
    }

    try {
      final response = await supabase
          .from('Families')
          .select('id, family_name')
          .eq('created_by', user.id)
          .order('family_name');

      final loadedFamilies =
          List<Map<String, dynamic>>.from(
        response,
      );

      if (!mounted) return;

      setState(() {
        ownedFamilies = loadedFamilies;

        if (loadedFamilies.isNotEmpty) {
          selectedFamilyId =
              loadedFamilies.first['id']
                  ?.toString();
        }

        isLoadingFamilies = false;
      });

      if (selectedFamilyId != null) {
        await loadMembers();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingFamilies = false;
      });

      showMessage(
        'Unable to load your families.',
      );

      debugPrint(
        'LOAD OWNED FAMILIES ERROR: $e',
      );
    }
  }

  Future<void> loadMembers() async {
    final familyId = selectedFamilyId;

    if (familyId == null) return;

    setState(() {
      isLoadingMembers = true;
    });

    try {
      final memberResponse = await supabase
          .from('Family_Members')
          .select()
          .eq('family_id', familyId)
          .eq('status', 'approved')
          .order('joined_at');

      final loadedMembers =
        List<Map<String, dynamic>>.from(memberResponse);

    // -----------------------------------------
    // COLLECT USER IDS
    // -----------------------------------------

      final userIds = loadedMembers
        .map(
          (member) =>
              member['user_id']?.toString(),
        )
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    // -----------------------------------------
    // LOAD MEMBER PROFILES
    // -----------------------------------------

    List<Map<String, dynamic>>
        loadedProfiles = [];

    if (userIds.isNotEmpty) {
      final profileResponse = await supabase
          .from('Profiles')
          .select(
            'user_id, first_name, last_name, profile_photo_path',
          )
          .inFilter(
            'user_id',
            userIds,
          );

      loadedProfiles =
          List<Map<String, dynamic>>.from(profileResponse);
    }



     if (!mounted) return;

     setState(() {
      members = loadedMembers;
      memberProfiles = loadedProfiles;
      isLoadingMembers = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingMembers = false;
    });

    showMessage(
      'Unable to load family members.',
    );

    debugPrint(
      'LOAD FAMILY MEMBERS ERROR: $e',
    );
  }

    //   setState(() {
    //     members =
    //         List<Map<String, dynamic>>.from(
    //       response,
    //     );

    //     isLoadingMembers = false;
    //   });
    // } catch (e) {
    //   if (!mounted) return;

    //   setState(() {
    //     isLoadingMembers = false;
    //   });

    //   showMessage(
    //     'Unable to load family members.',
    //   );

    //   debugPrint(
    //     'LOAD FAMILY MEMBERS ERROR: $e',
    //   );
    // }
  }

  Map<String, dynamic>? getProfileForMember(
  Map<String, dynamic> member,
) {
  final userId =
      member['user_id']?.toString();

  if (userId == null || userId.isEmpty) {
    return null;
  }

  for (final profile in memberProfiles) {
    if (profile['user_id']?.toString() ==
        userId) {
      return profile;
    }
  }

  return null;
}

String getMemberName(
  Map<String, dynamic> member,
) {
  final profile =
      getProfileForMember(member);

  if (profile == null) {
    return 'Family Member';
  }

  final firstName =
      profile['first_name']
              ?.toString()
              .trim() ??
          '';

  final lastName =
      profile['last_name']
              ?.toString()
              .trim() ??
          '';

  final fullName = [
    firstName,
    lastName,
  ].where(
    (name) => name.isNotEmpty,
  ).join(' ');

  return fullName.isNotEmpty
      ? fullName
      : 'Family Member';
}

String getMemberInitials(
  Map<String, dynamic> member,
) {
  final profile =
      getProfileForMember(member);

  if (profile == null) {
    return 'F';
  }

  final firstName =
      profile['first_name']
              ?.toString()
              .trim() ??
          '';

  final lastName =
      profile['last_name']
              ?.toString()
              .trim() ??
          '';

  final firstInitial =
      firstName.isNotEmpty
          ? firstName[0].toUpperCase()
          : '';

  final lastInitial =
      lastName.isNotEmpty
          ? lastName[0].toUpperCase()
          : '';

  final initials =
      '$firstInitial$lastInitial';

  return initials.isNotEmpty
      ? initials
      : 'F';
}

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(

      backgroundColor: FolktriColors.background,

      appBar: AppBar(
        backgroundColor:
            FolktriColors.midnightIndigo,
        foregroundColor:
            FolktriColors.surface,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'Family Access',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: isLoadingFamilies
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ownedFamilies.isEmpty
              ? buildNoOwnedFamilies()
              : buildContent(),
    );
  }

  Widget buildContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await loadOwnedFamilies();
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          22,
          16,
          40,
        ),
        children: [
          const Text(
            'Manage Family Access',
            style: TextStyle(
              color:
                  FolktriColors.midnightIndigo,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Manage members and permissions for families you created.',
            style: TextStyle(
              color:
                  FolktriColors.secondaryText,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 26),

          buildSectionTitle('FAMILY'),

          buildFamilySelector(),

          const SizedBox(height: 28),

          buildSectionTitle('FAMILY MEMBERS'),

          if (isLoadingMembers)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child:
                    CircularProgressIndicator(),
              ),
            )
          else if (members.isEmpty)
            buildEmptyMembers()
          else
            buildMembersCard(),
        ],
      ),
    );
  }

   Widget buildFamilySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: FolktriColors.lightLavender,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedFamilyId,
          isExpanded: true,

          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color:
                FolktriColors.primaryIndigo,
          ),

          items: ownedFamilies.map(
            (family) {
              final id =
                  family['id'].toString();

              final name =
                  family['family_name']
                          ?.toString() ??
                      'Family';

              return DropdownMenuItem<String>(
                value: id,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: FolktriColors
                            .lightLavender,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        size: 18,
                        color: FolktriColors
                            .primaryIndigo,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: FolktriColors
                              .midnightIndigo,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),

          onChanged: (value) async {
            if (value == null) return;

            setState(() {
              selectedFamilyId = value;
              members = [];
            });

            await loadMembers();
          },
        ),
      ),
    );
  }

  Widget buildMembersCard() {
    return Container(
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FolktriColors.midnightIndigo
                .withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        children: List.generate(
          members.length,
          (index) {
            final member = members[index];

            return Column(
              children: [
                buildMemberTile(member),

                if (index != members.length - 1)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      left: 74,
                    ),
                    child: Divider(
                      height: 1,
                      color: FolktriColors
                          .lightLavender,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildMemberTile(Map<String, dynamic> member) {
  final role =
      member['role']?.toString().trim();

  final displayRole =
      role != null && role.isNotEmpty
          ? role
          : 'Family Member';

  final memberName =
      getMemberName(member);

  final initials =
      getMemberInitials(member);

  return InkWell(
    borderRadius: BorderRadius.circular(20),

    onTap: () async {
  final membershipId =
      member['id']?.toString();

  if (membershipId == null ||
      membershipId.isEmpty) {
    return;
  }

  final result = await context.push<bool>(
    '/settings/family-access/member/'
    '$membershipId',
  );

  if (!mounted) return;

  if (result == true) {
    await loadMembers();
  }
},

    // onTap: () {
    //   final membershipId = member['id']?.toString();

    //   if (membershipId == null ||
    //       membershipId.isEmpty) {
    //     return;
    //   }

    //   context
    //       .push(
    //         '/settings/family-access/member/'
    //         '$membershipId',
    //       )
    //       .then((_) {
    //     // Refresh in case permissions or
    //     // membership changed.
    //     loadMembers();
    //   });
    // },

    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      child: Row(
        children: [
          // ---------------------------------------
          // MEMBER AVATAR
          // ---------------------------------------

          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color:
                  FolktriColors.lightLavender,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color:
                    FolktriColors.primaryIndigo,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ---------------------------------------
          // NAME + ROLE
          // ---------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        FolktriColors.midnightIndigo,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  displayRole,
                  style: const TextStyle(
                    color:
                        FolktriColors.secondaryText,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'Manage',
            style: TextStyle(
              color:
                  FolktriColors.primaryIndigo,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 2),

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

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 5,
        bottom: 9,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: FolktriColors.midnightIndigo
              .withValues(alpha: 0.62),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  Widget buildEmptyMembers() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 38,
            color:
                FolktriColors.secondaryText,
          ),

          SizedBox(height: 12),

          Text(
            'No approved members yet',
            style: TextStyle(
              color:
                  FolktriColors.midnightIndigo,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Approved family members will appear here.',
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

  Widget buildNoOwnedFamilies() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.family_restroom_rounded,
              size: 48,
              color:
                  FolktriColors.primaryIndigo,
            ),

            const SizedBox(height: 16),

            const Text(
              'No families to manage',
              style: TextStyle(
                color:
                    FolktriColors.midnightIndigo,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Only families you created can be managed from Family Access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Back to Settings'),
            ),
          ],
        ),
      ),
    );
  }
}