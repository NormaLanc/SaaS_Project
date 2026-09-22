import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Styling/folktri_colors.dart';

class FamilyPage extends StatefulWidget {
  final String familyId;

  const FamilyPage({
    super.key,
    required this.familyId,
  });

  @override
  State<FamilyPage> createState() =>
      _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? family;

  List<Map<String, dynamic>> children = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadFamily();
  }

  Future<void> loadFamily() async {
    try {
      // ==========================================
      // LOAD FAMILY
      // ==========================================

      final familyResponse = await supabase
          .from('Families')
          .select('id, family_name, created_by')
          .eq('id', widget.familyId)
          .single();

      // ==========================================
      // LOAD CHILDREN
      // ==========================================

      final childrenResponse = await supabase
          .from('Children')
          .select()
          .eq('family_id', widget.familyId)
          .order('first_name');

      if (!mounted) return;

      setState(() {
        family =
            Map<String, dynamic>.from(
          familyResponse,
        );

        children =
            List<Map<String, dynamic>>.from(
          childrenResponse,
        );

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to load family: $e",
          ),
        ),
      );
    }
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

  Future<void> deleteFamily() async {
  final shouldDelete =
      await confirmDelete(
    title: 'Delete Family',
    message:
        'Deleting this family will permanently remove the family and its related children, milestones, events, documents, and photos. This cannot be undone.',
  );

  if (!shouldDelete) return;

  try {
    await supabase
        .from('Families')
        .delete()
        .eq(
          'id',
          widget.familyId,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Family deleted.',
        ),
      ),
    );

    context.go('/families');
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete family: $e',
        ),
      ),
    );
  }
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

    if (family == null) {
      return Scaffold(
        backgroundColor: FolktriColors.background,

        appBar: AppBar(
          backgroundColor: FolktriColors.midnightIndigo,
          foregroundColor: FolktriColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,

          leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          tooltip: 'Back to Family Dashboard',
          onPressed: () {
            context.go('/families');
          },
        ),
      ),
        body: const Center(
          child: Text(
            "Family could not be found.",
          ),
        ),
      );
    }

    final familyName =
        family!['family_name']?.toString() ??
            "Family";

    final currentUser = supabase.auth.currentUser;

    final isFamilyOwner =
      currentUser != null &&
      family!['created_by']
            ?.toString() ==
        currentUser.id;

    return Scaffold(
      backgroundColor: FolktriColors.background,

      appBar: AppBar(
        backgroundColor: FolktriColors.midnightIndigo,
        foregroundColor: FolktriColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        tooltip: 'Back to Family Dashboard',
        onPressed: () {
          context.go('/families');
        },
      ),
        title: Text(
          familyName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          if (isFamilyOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
              if (value == 'delete-family') {
                deleteFamily();
              }
            },

      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'delete-family',

          child: Row(
            children: [
              Icon(Icons.delete_forever_outlined,),
              SizedBox(width: 8,),
              Text('Delete Family',),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              familyName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

                const Text(
                  "Calendar",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

          const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading:
                  const Icon(
                Icons.calendar_month,
              ),
                title: const Text('Family Calendar',),
                subtitle: const Text('Schedules, birthdays, sports, and events',),
                trailing: const Icon(Icons.chevron_right,),

                onTap: () {
                  context.push(
                    '/family/${widget.familyId}/calendar',
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Children",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton.icon(
                  onPressed: () {
                    context.push(
                      '/family/${widget.familyId}/add-children',
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Child"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (children.isEmpty)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.child_care,
                        size: 50,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        "No children have been added yet.",
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      ElevatedButton.icon(
                        onPressed: () {
                          context.push(
                            '/family/${widget.familyId}/add-children',
                          );
                        },
                        icon: const Icon(
                          Icons.add,
                        ),
                        label: const Text(
                          "Add Your First Child",
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...children.map(
                (child) {
                  final firstName =
                      child['first_name']
                              ?.toString() ??
                          '';

                  final middleName =
                      child['middle_name']
                              ?.toString() ??
                          '';

                  final lastName =
                      child['last_name']
                              ?.toString() ??
                          '';

                  final fullName = [
                    firstName,
                    middleName,
                    lastName,
                  ]
                      .where(
                        (name) =>
                            name.trim().isNotEmpty,
                      )
                      .join(' ');

                  return Card(
                      color: FolktriColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(
                        color: FolktriColors.lightLavender,
                      ),
                    ),
                    
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            child['profile_photo_url'] !=
                                    null
                                ? NetworkImage(
                                    child[
                                        'profile_photo_url'],
                                  )
                                : null,

                        child:
                            child['profile_photo_url'] ==
                                    null
                                ? const Icon(
                                    Icons.child_care,
                                  )
                                : null,
                      ),

                      title: Text(fullName),

                      trailing:
                          const Icon(
                        Icons.chevron_right,
                      ),

                      onTap: () {
                         context.push(
                          '/child/${child['id']}',
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}