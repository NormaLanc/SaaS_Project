import 'dart:math';
import 'package:flutter/material.dart';
//import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvitesPage extends StatefulWidget {
  const InvitesPage({super.key});

  @override
  State<InvitesPage> createState() => _InvitesPageState();
}

class _InvitesPageState extends State<InvitesPage> {


  final supabase = Supabase.instance.client;

  // -----------------------
  // FAMILY DATA
  // -----------------------
  List<Map<String, dynamic>> families = [];

  bool isLoadingFamilies = true;


  // These will eventually come from your UI
  String? selectedFamilyId;

  // ------------------------
  // ROLE
  // ------------------------

  String selectedRole = 'Parent';

  final List<String> roles = [
    'Parent',
    'Grandparent',
    'Sibling',
    'Aunt',
    'Uncle',
    'Cousin',
    'Guardian',
    'Caregiver',
    'Extended Family',
    'Other',
  ];

  // -----------------------
  // PERMISSIONS
  // -----------------------

  bool canViewPhotos = true;
  bool canUploadPhotos = false;
  bool canViewCalendar = true;
  bool canViewDocuments = false;
  bool canEditCalendar = false;
  bool canManageSchedule = false;
  bool canManageMembers = false;
  bool canViewChildren = true;
  bool canPost = false;

// -----------------------
// INVITE
// -----------------------
  String? generatedCode;
  bool isGeneratingInvite = false;

  //INIT
  @override
void initState() {
  super.initState();

  loadFamilies();
}

Future<void> loadFamilies() async {
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

    if (!mounted) return;

    setState(() {
      families =
          List<Map<String, dynamic>>.from(response);

      if (families.isNotEmpty) {
        selectedFamilyId =
            families.first['id'].toString();
      }

      isLoadingFamilies = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingFamilies = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Unable to load families: $e",
        ),
      ),
    );
  }
}

  // Generates the random one-time code
  String generateInviteCode() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    String generatePart(int length) {
      return List.generate(
        length,
        (_) => characters[random.nextInt(characters.length)],
      ).join();
    }

    return '${generatePart(4)}-${generatePart(4)}-${generatePart(4)}';
  }

//==========================
//CREATE INVITE
//==========================
  // Runs when owner presses "Generate Invite"
  Future<void> createInvite() async {

    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    if (selectedFamilyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a family."),
        ),
      );

      return;
    }

     setState(() {
    isGeneratingInvite = true;
    });

  try{
    // Generate one-time code
    final code = generateInviteCode();


    // Code expires 24 hours from now
    final expiresAt = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 24));


    // Save invitation to Supabase
    await supabase
        .from('Family_Invitations')
        .insert({
          'family_id': selectedFamilyId,
          'created_by': user.id,
          'invite_code': code,

          'role': selectedRole,

          'can_view_photos': canViewPhotos,
          'can_upload_photos': canUploadPhotos,
          'can_view_calendar': canViewCalendar,
          'can_view_documents': canViewDocuments,
          'can_edit_calendar': canEditCalendar,
          'can_manage_schedule': canManageSchedule,
          'can_manage_members': canManageMembers,
          'can_view_child': canViewChildren,
          'can_post': canPost,

          'expires_at': expiresAt.toIso8601String(),
        });


    if (!mounted) return;

    setState(() {
      generatedCode = code;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Invite created successfully!",
        ),
      ),
    );

  }catch(e){
    if(!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Unable to create invite: $e"),
      ),
    );
  } finally {
    if(mounted) {
      setState(() {
        isGeneratingInvite = false;
      });
    }
  }
}
    
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invite a family member."),
      ),
      body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Create an Invitation",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Choose a family, role, and permissions for the person you want to invite.",
            ),

            const SizedBox(height: 30),

            // =========================
            // FAMILY DROPDOWN
            // =========================

            const Text(
              "Family",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            if (isLoadingFamilies)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (families.isEmpty)
              const Text(
                "You have not created any families yet.",
              )
            else
              DropdownButtonFormField<String>(
                value: selectedFamilyId,

                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),

                items: families.map((family) {
                  return DropdownMenuItem<String>(
                    value: family['id'].toString(),

                    child: Text(
                      family['family_name']?.toString() ??
                          "Unnamed Family",
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedFamilyId = value;
                  });
                },
              ),

            const SizedBox(height: 28),

            // =========================
            // ROLE DROPDOWN
            // =========================

            const Text(
              "Role",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedRole,

              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),

              items: roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedRole = value;
                });
              },
            ),

            const SizedBox(height: 30),

            // =========================
            // PERMISSIONS
            // =========================

            const Text(
              "Permissions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Choose what this person will be allowed to access.",
            ),

            const SizedBox(height: 10),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("View Photos"),
              value: canViewPhotos,
              onChanged: (value) {
                setState(() {
                  canViewPhotos = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Upload Photos"),
              value: canUploadPhotos,
              onChanged: (value) {
                setState(() {
                  canUploadPhotos = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("View Calendar"),
              value: canViewCalendar,
              onChanged: (value) {
                setState(() {
                  canViewCalendar = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Edit Calendar"),
              value: canEditCalendar,
              onChanged: (value) {
                setState(() {
                  canEditCalendar = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("View Documents"),
              value: canViewDocuments,
              onChanged: (value) {
                setState(() {
                  canViewDocuments = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Manage Schedule"),
              value: canManageSchedule,
              onChanged: (value) {
                setState(() {
                  canManageSchedule = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Manage Members"),
              value: canManageMembers,
              onChanged: (value) {
                setState(() {
                  canManageMembers = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("View Children"),
              value: canViewChildren,
              onChanged: (value) {
                setState(() {
                  canViewChildren = value ?? false;
                });
              },
            ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Create Posts"),
              value: canPost,
              onChanged: (value) {
                setState(() {
                  canPost = value ?? false;
                });
              },
            ),

            const SizedBox(height: 30),

            // =========================
            // GENERATE BUTTON
            // =========================

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed:
                    isGeneratingInvite || families.isEmpty
                        ? null
                        : createInvite,

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  child: isGeneratingInvite
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Generate Invite Code",
                        ),
                ),
              ),
            ),

            // =========================
            // GENERATED CODE
            // =========================

            if (generatedCode != null) ...[
              const SizedBox(height: 35),

              const Divider(),

              const SizedBox(height: 20),

              const Text(
                "Invite Code",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Send this code privately to the person you want to invite.",
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Column(
                  children: [
                    SelectableText(
                      generatedCode!,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Expires in 24 hours",
                    ),

                    const Text(
                      "Can only be used once",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,

                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: generatedCode!,
                      ),
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Invite code copied!",
                        ),
                      ),
                    );
                  },

                  icon: const Icon(
                    Icons.copy,
                  ),

                  label: const Text(
                    "Copy Invite Code",
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

