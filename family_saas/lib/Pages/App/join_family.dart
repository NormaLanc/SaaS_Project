

//TODO: Once approved, the new member is added to the family and can access the family dashboard
//TODO: If the owner rejects the request, the new member is notified and cannot access the family dashboard
//TODO: Temporary permissions for family members can be set by the owner (future feature)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JoinFamilyPage extends StatefulWidget {
  const JoinFamilyPage({super.key});

  @override
  State<JoinFamilyPage> createState() => _JoinFamilyPageState();
}

class _JoinFamilyPageState extends State<JoinFamilyPage> {

  final inviteCodeController = TextEditingController();

  final supabase = Supabase.instance.client;

  bool isLoading = false;

  Future<void> submitInviteCode() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final code = inviteCodeController.text
        .trim()
        .toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your invite code."),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // final invite = await supabase
      //     .from('Family_Invitations')
      //     .select()
      //     .eq('invite_code', code)
      //     .maybeSingle();
      final enteredCode =
    inviteCodeController.text
        .trim()
        .toUpperCase();


final invite = await supabase
    .from('Family_Invitations')
    .select()
    .eq(
      'invite_code',
      enteredCode,
    )
    //  .gt(
    //   'expires_at',
    //   DateTime.now()
    //       .toUtc()
    //       .toIso8601String(),
    // )
    .maybeSingle();

//TODO: Delete when no longer needed
    debugPrint('ENTERED INVITE CODE: $enteredCode');
    debugPrint('INVITE RESULT: $invite');

      if (invite == null) {
        throw Exception("Invalid invite code.");
      }

      // Has it already been used?
      if (invite['used_at'] != null) {
        throw Exception(
          "This invite code has already been used.",
        );
      }

      // Is it expired?
      final expiresAt =
          DateTime.parse(invite['expires_at']);

      if (DateTime.now().toUtc().isAfter(expiresAt)) {
        throw Exception(
          "This invite code has expired.",
        );
      }

      //final familyId = invite['family_id'];

      // Create pending membership
    final membership = await supabase
    .from('Family_Members')
    .insert({
      'family_id': invite['family_id'],
      'user_id': supabase.auth.currentUser!.id,
      'role': invite['role'],
      'status': 'pending',
      'approved_by': null,

      'can_view_photos': invite['can_view_photos'] ?? false,
      'can_upload_photos': invite['can_upload_photos'] ?? false,

      'can_view_calendar': invite['can_view_calendar'] ?? false,
      'can_edit_calendar': invite['can_edit_calendar'] ?? false,

      'can_view_children': invite['can_view_children'] ?? false,
      'can_post': invite['can_post'] ?? false,
})
    .select()
    .single();


    final family = await supabase
    .from('Families')
    .select(
      'id, family_name, created_by',
    )
    .eq(
      'id',
      invite['family_id'],
    )
    .single();

    final familyOwnerId = family['created_by'];

    final requesterProfile =
      await supabase
        .from('Profiles')
        .select(
          'first_name, last_name',
        )
        .eq(
          'user_id',
          user.id,
        )
        .maybeSingle();

    final firstName = requesterProfile?['first_name']
            ?.toString() ??
            '';

    final lastName = requesterProfile?['last_name']
            ?.toString() ??
            '';
    
    await supabase
    .from('Notifications')
    .insert({
      'recipient_user_id': familyOwnerId,
      'requested_user_id': user.id,
      'family_id': invite['family_id'],
      'membership_id': membership['id'],
      'type': 'family_join_request',
      'title': 'Family Access Request',
      'message': '$firstName $lastName has requested access to family "${family['family_name']}".',
      'status': 'active',
      'is_read': false,
      'action_required': true,
      'action_status': 'pending',
    });

      // Mark invite as used
      await supabase
          .from('Family_Invitations')
          .update({
            'used_at':
                DateTime.now().toUtc().toIso8601String(),

            'used_by': user.id,
          })
          .eq('id', invite['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Request sent! The family owner must approve your access.",
          ),
        ),
      );

      context.go('/app');
    } catch (e) {
     
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    inviteCodeController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Family"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Join a Family",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Enter the one-time invitation code you received from the family owner.",
            ),

            const SizedBox(height: 30),

            TextField(
              controller: inviteCodeController,

              textCapitalization:
                  TextCapitalization.characters,

              decoration: const InputDecoration(
                labelText: "Invite Code",
                hintText: "XXXX-XXXX-XXXX",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed:
                    isLoading ? null : submitInviteCode,

                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        "Request to Join",
                      ),
              ),
            ),

            TextButton(
              onPressed: () {
                context.pop();
              },

              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}