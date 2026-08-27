import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvitesPage extends StatefulWidget {
  const InvitesPage({super.key});

  @override
  State<InvitesPage> createState() => _InvitesPageState();
}

class _InvitesPageState extends State<InvitesPage> {


  final supabase = Supabase.instance.client;

  // These will eventually come from your UI
  String? selectedFamilyId;
  String selectedRole = 'member';

  bool canViewPhotos = true;
  bool canUploadPhotos = false;
  bool canViewCalendar = true;
  bool canViewDocuments = false;
  bool canEditCalendar = false;
  bool canManageSchedule = false;
  bool canManageMembers = false;
  bool canViewChildren = true;
  bool canPost = false;


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


    // Generate one-time code
    final code = generateInviteCode();


    // Code expires 24 hours from now
    final expiresAt = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 24));


    // Save invitation to Supabase
    await Supabase.instance.client
        .from('Family_Invitations')
        .insert({
          'family_id': selectedFamilyId,
          'used_by': user.id,
          'code_hash': code,

          'role': selectedRole,

          'can_view_photos': canViewPhotos,
          'can_upload_photos': canUploadPhotos,
          'can_view_calendar': canViewCalendar,
          'can_view_documents': canViewDocuments,
          'can_edit_calendar': canEditCalendar,
          'can_view_children': canViewChildren,
          'can_post': canPost,

          'expires_at': expiresAt.toIso8601String(),
        });


    if (!mounted) return;


    // Show the generated code to the owner
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Invite Created"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Give this one-time invite code to the family member:",
              ),

              const SizedBox(height: 20),

              SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "This code expires in 24 hours and can only be used once.",
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invite a family member."),
      ),
      body: const Center(
        //child: Text("Join Family Page"),
      ),
    );
  }
}