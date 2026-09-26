import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Styling/folktri_colors.dart';

class MemberPermissionsPage extends StatefulWidget {
  final String membershipId;

  const MemberPermissionsPage({
    super.key,
    required this.membershipId,
  });

   @override
  State<MemberPermissionsPage> createState() => _MemberPermissionsPageState();
}

class _MemberPermissionsPageState extends State<MemberPermissionsPage>{

  final supabase = Supabase.instance.client;

  Map<String, dynamic>? membership;
  Map<String, dynamic>? memberProfile;

  bool isLoading = true;
  bool isSaving = false;

  bool canViewPhotos = true;
  bool canUploadPhotos = false;

  bool canViewCalendar = true;
  bool canEditCalendar = false;

  bool canViewChild = true;
  bool canEditChild = false;

  bool canViewDocuments = false;

  bool canManageSchedule = false;
  bool canManageMembers = false;

  bool canPost = false;

  @override
  void initState() {
    super.initState();
    loadMembership();
  }

  Future<void> loadMembership() async {
  try {
    // -----------------------------------------
    // LOAD MEMBERSHIP
    // -----------------------------------------

    final response = await supabase
        .from('Family_Members')
        .select()
        .eq('id', widget.membershipId)
        .single();

    final loadedMembership = Map<String, dynamic>.from(response,);

    // -----------------------------------------
    // LOAD PROFILE
    // -----------------------------------------

    Map<String, dynamic>? loadedProfile;

    final userId = loadedMembership['user_id']
            ?.toString();

    if (userId != null &&
        userId.isNotEmpty) {
      final profileResponse = await supabase
              .from('Profiles')
              .select('user_id, first_name, last_name, profile_photo_path',)
              .eq(
                'user_id',
                userId,
              )
              .maybeSingle();

      if (profileResponse != null) {
        loadedProfile =
            Map<String, dynamic>.from(profileResponse);
      }
    }

    if (!mounted) return;

    setState(() {
      membership = loadedMembership;
      memberProfile = loadedProfile;

      canViewPhotos =
          loadedMembership['can_view_photos'] == true;

      canUploadPhotos =
          loadedMembership['can_upload_photos'] == true;

      canViewCalendar =
          loadedMembership['can_view_calendar'] == true;

      canEditCalendar =
          loadedMembership['can_edit_calendar'] == true;

      canViewChild =
          loadedMembership['can_view_child'] == true;

      canEditChild =
          loadedMembership['can_edit_child'] == true;

      canViewDocuments =
          loadedMembership['can_view_documents'] == true;

      canManageSchedule =
          loadedMembership['can_manage_schedule'] == true;

      canManageMembers =
          loadedMembership['can_manage_members'] == true;

      canPost =
          loadedMembership['can_post'] == true;

      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    showMessage('Unable to load member permissions.');

    debugPrint('LOAD MEMBER PERMISSIONS ERROR: $e');
  }
}

  String get memberName {
  final firstName = memberProfile?['first_name']
              ?.toString()
              .trim() ??
          '';

  final lastName = memberProfile?['last_name']
              ?.toString()
              .trim() ??
          '';

  final fullName = [firstName, lastName].where(
    (name) => name.isNotEmpty,
    ).join(' ');

  return fullName.isNotEmpty
      ? fullName
      : 'Family Member';
}

String get memberInitials {

  final firstName = memberProfile?['first_name']
              ?.toString()
              .trim() ??
          '';

  final lastName = memberProfile?['last_name']
              ?.toString()
              .trim() ??
          '';

  final firstInitial = firstName.isNotEmpty
          ? firstName[0].toUpperCase()
          : '';

  final lastInitial = lastName.isNotEmpty
          ? lastName[0].toUpperCase()
          : '';

  final initials = '$firstInitial$lastInitial';

  return initials.isNotEmpty
      ? initials
      : 'F';
}

  Future<void> savePermissions() async {
    if (membership == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await supabase
          .from('Family_Members')
          .update({
            'can_view_photos': canViewPhotos,
            'can_upload_photos':
                canUploadPhotos,
            'can_view_calendar':
                canViewCalendar,
            'can_edit_calendar':
                canEditCalendar,
            'can_view_child': canViewChild,
            'can_edit_child': canEditChild,
            'can_view_documents':
                canViewDocuments,
            'can_manage_schedule':
                canManageSchedule,
            'can_manage_members':
                canManageMembers,
            'can_post': canPost,
          })
          .eq('id', widget.membershipId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissions updated.',
          ),
        ),
      );

      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Unable to update permissions.',
      );

      debugPrint(
        'SAVE MEMBER PERMISSIONS ERROR: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> removeMember() async {
  final name = memberName;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: FolktriColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Remove from Family?',
          style: TextStyle(
            color: FolktriColors.midnightIndigo,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to remove $name from this family? '
          'They will no longer have access to this family.',
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
            child: const Text('Cancel'),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            child: Text(
              'Remove',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  try {
    final deletedRows = await supabase
        .from('Family_Members')
        .delete()
        .eq(
          'id',
          widget.membershipId,
        )
        .select('id');

    debugPrint(
      'DELETE MEMBER RESULT: $deletedRows',
    );

    if (!mounted) return;

    if (deletedRows.isEmpty) {
      showMessage(
        'The member could not be removed. '
        'Your account may not have permission to delete this membership.',
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name was removed from the family.',
        ),
      ),
    );

    context.pop(true);
  } catch (e) {
    if (!mounted) return;

    debugPrint(
      'REMOVE MEMBER ERROR: $e',
    );

    showMessage(
      'Unable to remove this family member.',
    );
  }
}

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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

    if (membership == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'Member could not be found.',
          ),
        ),
      );
    }

    final role =
        membership!['role']?.toString() ??
            'Family Member';

    return Scaffold(
      backgroundColor:
          FolktriColors.background,

      appBar: AppBar(
        backgroundColor:
            FolktriColors.midnightIndigo,
        foregroundColor:
            FolktriColors.surface,
        centerTitle: true,
        elevation: 0,

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
          'Member Permissions',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          22,
          16,
          40,
        ),
        children: [
          Center(
            child: Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                color:
                    FolktriColors.lightLavender,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                memberInitials,
                style: const TextStyle(
                  color:
                      FolktriColors.primaryIndigo,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            memberName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  FolktriColors.midnightIndigo,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FolktriColors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Choose what this family member can access.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FolktriColors.secondaryText,
            ),
          ),

          const SizedBox(height: 30),

          buildSectionTitle('CHILDREN'),

          buildPermissionCard(
            children: [
              buildPermissionSwitch(
                title: 'View Children',
                subtitle:
                    'View child profiles and information',
                icon:
                    Icons.child_care_rounded,
                value: canViewChild,
                onChanged: (value) {
                  setState(() {
                    canViewChild = value;

                    if (!value) {
                      canEditChild = false;
                    }
                  });
                },
              ),

              buildDivider(),

              buildPermissionSwitch(
                title: 'Edit Children',
                subtitle:
                    'Edit child information',
                icon: Icons.edit_outlined,
                value: canEditChild,
                onChanged: canViewChild
                    ? (value) {
                        setState(() {
                          canEditChild = value;
                        });
                      }
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 24),

          buildSectionTitle('PHOTOS'),

          buildPermissionCard(
            children: [
              buildPermissionSwitch(
                title: 'View Photos',
                subtitle:
                    'View family photos',
                icon:
                    Icons.photo_outlined,
                value: canViewPhotos,
                onChanged: (value) {
                  setState(() {
                    canViewPhotos = value;

                    if (!value) {
                      canUploadPhotos = false;
                    }
                  });
                },
              ),

              buildDivider(),

              buildPermissionSwitch(
                title: 'Upload Photos',
                subtitle:
                    'Add photos to the family',
                icon:
                    Icons.add_photo_alternate_outlined,
                value: canUploadPhotos,
                onChanged: canViewPhotos
                    ? (value) {
                        setState(() {
                          canUploadPhotos =
                              value;
                        });
                      }
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 24),

          buildSectionTitle('CALENDAR'),

          buildPermissionCard(
            children: [
              buildPermissionSwitch(
                title: 'View Calendar',
                subtitle:
                    'View family events and schedules',
                icon:
                    Icons.calendar_month_outlined,
                value: canViewCalendar,
                onChanged: (value) {
                  setState(() {
                    canViewCalendar = value;

                    if (!value) {
                      canEditCalendar = false;
                    }
                  });
                },
              ),

              buildDivider(),

              buildPermissionSwitch(
                title: 'Edit Calendar',
                subtitle:
                    'Create and update events',
                icon:
                    Icons.edit_calendar_outlined,
                value: canEditCalendar,
                onChanged: canViewCalendar
                    ? (value) {
                        setState(() {
                          canEditCalendar = value;
                        });
                      }
                    : null,
              ),

              buildDivider(),

              buildPermissionSwitch(
                title: 'Manage Schedule',
                subtitle:
                    'Manage family scheduling',
                icon:
                    Icons.schedule_rounded,
                value: canManageSchedule,
                onChanged: (value) {
                  setState(() {
                    canManageSchedule = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          buildSectionTitle('OTHER ACCESS'),

          buildPermissionCard(
            children: [
              buildPermissionSwitch(
                title: 'View Documents',
                subtitle:
                    'View shared family documents',
                icon:
                    Icons.description_outlined,
                value: canViewDocuments,
                onChanged: (value) {
                  setState(() {
                    canViewDocuments = value;
                  });
                },
              ),

              buildDivider(),

              buildPermissionSwitch(
                title: 'Post',
                subtitle:
                    'Post family content',
                icon:
                    Icons.post_add_rounded,
                value: canPost,
                onChanged: (value) {
                  setState(() {
                    canPost = value;
                  });
                },
              ),

              buildDivider(),

              buildPermissionSwitch(
                title: 'Manage Members',
                subtitle:
                    'Manage family membership',
                icon:
                    Icons.manage_accounts_outlined,
                value: canManageMembers,
                onChanged: (value) {
                  setState(() {
                    canManageMembers = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    FolktriColors.primaryIndigo,
                foregroundColor:
                    FolktriColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),

              onPressed:
                  isSaving ? null : savePermissions,

              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            FolktriColors.surface,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  Colors.red.shade600,
              side: BorderSide(
                color: Colors.red.shade200,
              ),
              padding:
                  const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
            onPressed: removeMember,
            icon: const Icon(
              Icons.person_remove_outlined,
            ),
            label: const Text(
              'Remove from Family',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

   Widget buildSectionTitle(String title) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 5, bottom: 9),
      child: Text(
        title,
        style: TextStyle(
          color: FolktriColors.midnightIndigo
              .withOpacity(0.62),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  Widget buildPermissionCard({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FolktriColors.midnightIndigo
                .withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget buildPermissionSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,

      activeColor:
          FolktriColors.primaryIndigo,

      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color:
              FolktriColors.lightLavender,
          borderRadius:
              BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          size: 21,
          color:
              FolktriColors.primaryIndigo,
        ),
      ),

      title: Text(
        title,
        style: const TextStyle(
          color:
              FolktriColors.midnightIndigo,
          fontWeight: FontWeight.w600,
        ),
      ),

      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color:
              FolktriColors.secondaryText,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildDivider() {
    return Padding(
      padding:
          const EdgeInsets.only(left: 72),
      child: Divider(
        height: 1,
        color:
            FolktriColors.lightLavender,
      ),
    );
  }
}