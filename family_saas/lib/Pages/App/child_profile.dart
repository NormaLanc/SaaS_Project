import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ChildProfilePage extends StatefulWidget {
  final String childId;

  const ChildProfilePage({
    super.key,
    required this.childId,
  });

  @override
  State<ChildProfilePage> createState() =>
      _ChildProfilePageState();
}

// Calculate child's age based on date of birth
    int calculateAge(DateTime birthDate) {
      final today = DateTime.now();

      int age = today.year - birthDate.year;

      final birthdayHasOccurred =
        today.month > birthDate.month ||
          (today.month == birthDate.month &&
            today.day >= birthDate.day);

        if (!birthdayHasOccurred) {
          age--;
        }

  return age;
}

class _ChildProfilePageState extends State<ChildProfilePage> {

  final supabase = Supabase.instance.client;

  Map<String, dynamic>? child;
  bool isLoading = true;

  List<Map<String, dynamic>> milestones = [];
  bool isLoadingMilestones = true;

  List<Map<String, dynamic>> photos = [];
  bool isLoadingPhotos = true;

  List<Map<String, dynamic>> documents = [];
  bool isLoadingDocuments = true;

  @override
  void initState() {
    super.initState();
    loadChild();
    loadMilestones();
    loadPhotos();
    loadDocuments();
  }

  Future<void> loadChild() async {
    try {
      final response = await supabase
          .from('Children')
          .select()
          .eq('id', widget.childId)
          .single();

      if (!mounted) return;

      setState(() {
        child =
            Map<String, dynamic>.from(
          response,
        );

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
            'Unable to load child: $e',
          ),
        ),
      );
    }
  }

  Future<void> loadMilestones() async {
  try {
    final response = await supabase
        .from('Milestones')
        .select()
        .eq('child_id', widget.childId)
        .order(
          'milestone_date',
          ascending: false,
        );

    if (!mounted) return;

    setState(() {
      milestones =
          List<Map<String, dynamic>>.from(
        response,
      );

      isLoadingMilestones = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingMilestones = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load milestones: $e',
        ),
      ),
    );
  }
}

Future<void> loadPhotos() async {
  try {
    final response =
        await supabase
            .from('Photos')
            .select()
            .eq(
              'child_id',
              widget.childId,
            )
            .order(
              'created_at',
              ascending: false,
            );

    if (!mounted) return;

    setState(() {
      photos =
          List<Map<String, dynamic>>
              .from(
        response,
      );

      isLoadingPhotos = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingPhotos = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load photos: $e',
        ),
      ),
    );
  }
}

Future<void> loadDocuments() async {
  try {
    final response =
        await supabase
            .from('Documents')
            .select()
            .eq(
              'child_id',
              widget.childId,
            )
            .order(
              'document_date',
              ascending: false,
            );

    if (!mounted) return;

    setState(() {
      documents =
          List<Map<String, dynamic>>
              .from(
        response,
      );

      isLoadingDocuments =
          false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingDocuments =
          false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to load documents: $e',
        ),
      ),
    );
  }
}

Widget buildDocumentsTab() {
  if (isLoadingDocuments) {
    return const Center(
      child:
          CircularProgressIndicator(),
    );
  }

  return Column(
    children: [
      Padding(
        padding:
            const EdgeInsets.all(16),

        child: SizedBox(
          width: double.infinity,

          child: ElevatedButton.icon(
            onPressed:
                () async {
              final result =
                  await context
                      .push<bool>(
                '/family/${child!['family_id']}/child/${widget.childId}/add-document',
              );

              if (result == true) {
                loadDocuments();
              }
            },

            icon:
                const Icon(Icons.upload_file,),

            label:
                const Text('Add Document',),
          ),
        ),
      ),

      if (documents.isEmpty)
        const Expanded(
          child: Center(
            child: Text('No documents added yet.',),
          ),
        )
      else
        Expanded(
          child:
              ListView.separated(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16,),

            itemCount: documents.length,

            separatorBuilder: (context, index,) => const SizedBox(height: 8),

            itemBuilder: (context, index,) {
              final document = documents[index];
              final date = DateTime.tryParse(document['document_date'].toString(),);
              final dateText =
                  date == null
                      ? ''
                      : '${date.month}/${date.day}/${date.year}';

              return Card(
                child:
                    ListTile(
                  leading:
                      const CircleAvatar(
                    child:
                        Icon(Icons.description),
                  ),

                  title:
                      Text(document['title'] ?.toString() ??
                        '',),

                  subtitle:
                      Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(document['category'] ?.toString() ?? '',),

                      if (dateText
                          .isNotEmpty)
                        Text(dateText,),
                    ],
                  ),

                  trailing:
                      const Icon(Icons.chevron_right),

                  onTap:
                      () {
                    // We will add secure
                    // document viewing next.
                  },
                ),
              );
            },
          ),
        ),
    ],
  );
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

Future<void> deleteChild() async {
  final shouldDelete =
      await confirmDelete(
    title: 'Delete Child',
    message:
        'Are you sure you want to delete this child? Their milestones, documents, photos, and other related information may also be permanently deleted.',
  );

  if (!shouldDelete) return;

  try {
    await supabase
        .from('Children')
        .delete()
        .eq(
          'id',
          widget.childId,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Child deleted.',
        ),
      ),
    );

    context.pop(true);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete child: $e',
        ),
      ),
    );
  }
}

Future<void> deleteMilestone(
  String milestoneId,
) async {
  final shouldDelete =
      await confirmDelete(
    title: 'Delete Milestone',
    message:
        'Are you sure you want to delete this milestone?',
  );

  if (!shouldDelete) return;

  try {
    await supabase
        .from('Milestones')
        .delete()
        .eq(
          'id',
          milestoneId,
        );

    await loadMilestones();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Milestone deleted.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete milestone: $e',
        ),
      ),
    );
  }
}

Future<void> deletePhoto(
  String photoId,
) async {
  final shouldDelete =
      await confirmDelete(
    title: 'Delete Photo',
    message:
        'Are you sure you want to permanently delete this photo?',
  );

  if (!shouldDelete) return;

  try {
    await supabase
        .from('Photos')
        .delete()
        .eq(
          'id',
          photoId,
        );

    await loadPhotos();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Photo deleted.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete photo: $e',
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

  if (child == null) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Child not found.',
        ),
      ),
    );
  }

  final firstName =
      child!['first_name'] ?? '';

  final middleName =
      child!['middle_name'] ?? '';

  final lastName =
      child!['last_name'] ?? '';

  final fullName = [
    firstName,
    middleName,
    lastName,
  ]
      .where(
        (name) =>
            name.toString().trim().isNotEmpty,
      )
      .join(' ');

  return DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: Text(fullName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
            if (value == 'delete') {
              deleteChild();
            }
          },

          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline,),
                  SizedBox(width: 8,),
                  Text('Delete Child',),
                ],
              ),
            ),
          ],
        ),
      ],

      bottom: const TabBar(
      tabs: [
        Tab(text: 'Milestones',),
        Tab(text: 'Photos',),
        Tab(text: 'Documents',),
      ],
    ),
      ),
      body: TabBarView(
        // Milestones, Documents, and Photos tabs content
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async{
                      final result = await context.push<bool>(
                        '/family/${child!['family_id']}/child/${widget.childId}/add-milestone',
                      );
                      if (result == true) {
                        loadMilestones();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Milestone'),
                  )
                ),
              ),

              Expanded(
                child: isLoadingMilestones
                    ? const Center(
                      child: CircularProgressIndicator(),
                      )
                      : milestones.isEmpty
                      ? const Center(child: Text("No minestones added yet."),
                      )
                      : ListView.builder(
                        itemCount: milestones.length,
                        itemBuilder: (context, index) {
                          final milestone = milestones[index];

                          return Card(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if(milestone['photo_url'] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          milestone['photo_url'],
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              milestone['title'] ?? '',
                                              style:
                                                Theme.of(context).textTheme.titleLarge,
                                              ),
                                            ),

                                      IconButton(
                                        tooltip: 'Delete Milestone',
                                        icon: const Icon(Icons.delete_outline,),
                                        onPressed: () {
                                          deleteMilestone(milestone['id'].toString(),);
                                        },
                                      ),
                                    ],
                                  ),
                                      const SizedBox(height: 4),
                                      Text(
                                        milestone['milestone_date'].toString(),
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
                              ],
                            ),
                          ),
                        );
                      }
                    )
              ),
            ],
          ),
          // PHOTOS TAB
          Column(
  children: [
    Padding(
      padding:
          const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child:
            ElevatedButton.icon(
          onPressed: () async {
            final result =
                await context
                    .push<bool>(
              '/family/${child!['family_id']}/child/${widget.childId}/add-photo',
            );

            if (result == true) {
              loadPhotos();
            }
          },
          icon:
              const Icon(
            Icons.add_photo_alternate,
          ),
          label:
              const Text(
            'Add Photo',
          ),
        ),
      ),
    ),

    Expanded(
      child:
          isLoadingPhotos
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : photos.isEmpty
                  ? const Center(
                      child: Text(
                        'No photos added yet.',
                      ),
                    )
                  : GridView.builder(
                      padding:
                          const EdgeInsets
                              .all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            3,
                        crossAxisSpacing:
                            4,
                        mainAxisSpacing:
                            4,
                      ),
                      itemCount:
                          photos.length,
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        final photo =
                            photos[
                                index];

                        return Stack(
  children: [
    Positioned.fill(
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          8,
        ),
        child: Image.network(
          photo['photo_url'],
          fit: BoxFit.cover,
        ),
      ),
    ),

    Positioned(
      top: 4,
      right: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            deletePhoto(
              photo['id']
                  .toString(),
            );
          },
        ),
      ),
    ),
  ],
);
                      },
                    ),
    ),
  ],
),
          //DOCUMENTS TAB
          buildDocumentsTab(), //TODO: Update this later to match other sections
        ],
      ),
    ),
  );
}
}