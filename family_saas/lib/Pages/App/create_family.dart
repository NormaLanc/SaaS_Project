import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateFamilyPage extends StatefulWidget {
  const CreateFamilyPage({super.key});

  @override
  State<CreateFamilyPage> createState() => _CreateFamilyPageState();
}

class _CreateFamilyPageState extends State<CreateFamilyPage> {

  final familyNameController = TextEditingController();

  bool isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> createFamily() async {
    final familyName = familyNameController.text.trim();

    // Make sure the user entered a family name
    if (familyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a family name."),
        ),
      );

      return;
    }

    // Get the currently logged-in user
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be signed in to create a family."),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // STEP 1:
      // Create the family
      final family = await supabase
          .from('Families')
          .insert({
            'family_name': familyName,
            'created_by': user.id,
          })
          .select()
          .single();

      final familyId = family['id'];

      // STEP 2:
      // Add the creator as an approved owner
      await supabase.from('Family_Members').insert({
        'family_id': familyId,
        'user_id': user.id,
        'role': 'owner',
        'status': 'approved',
        'can_view_photos': true,
        'can_edit_child': true,
        'can_view_documents': true,
        'can_manage_schedule': true,
        'can_manage_members': true,
        'approved_by': user.id,
        'approved_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Family created successfully!"),
        ),
      );

      // Return to Family Dashboard
      context.go('/app');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to create family: $e"),
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
    familyNameController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Family"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Create your family",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Create a private family space where you can invite trusted family members.",
            ),

            const SizedBox(height: 30),

            TextField(
              controller: familyNameController,

              decoration: const InputDecoration(
                labelText: "Family Name",
                hintText: "Example: The Smith Family",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: isLoading ? null : createFamily,

                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Create Family"),
              ),
            ),

            const SizedBox(height: 12),
            //TODO: Upload family photo
            //TODO: Add family description
            //TODO:Add children to family
            //TODO: Add family members to family
            SizedBox(
              width: double.infinity,

              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        context.pop();
                      },

                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}