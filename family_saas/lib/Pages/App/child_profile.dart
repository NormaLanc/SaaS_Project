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

  @override
  void initState() {
    super.initState();
    loadChild();
    loadMilestones();
    loadPhotos();
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
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Milestones'),
            Tab(text: 'Photos'),
            Tab(text: 'Documents'),
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
                                      Text(
                                        milestone['title'] ?? '', 
                                        style: Theme.of(context).textTheme.titleLarge,
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

                        return ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                          child:
                              Image.network(
                            photo[
                                'photo_url'],
                            fit:
                                BoxFit.cover,
                          ),
                        );
                      },
                    ),
    ),
  ],
),
          //DOCUMENTS TAB
           const Center(
            child: Text('Documents'),
          ),
        ],
      ),
    ),
  );
}
}