import 'package:flutter/material.dart';

class ChildProfilePage
    extends StatelessWidget {

  final Map<String, dynamic> child;

  const ChildProfilePage({
    super.key,
    required this.child,
  });

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


  @override
  Widget build(BuildContext context) {

    // ==========================================
    // CHILD NAME
    // ==========================================

    final firstName = child['first_name'] ?? '';
    final middleName = child['middle_name'] ?? '';
    final lastName = child['last_name'] ?? '';

    final fullName = [
      firstName,
      middleName,
      lastName,
    ]
        .where(
          (name) => name.toString().trim().isNotEmpty,
        )
        .join(' ');

    // Convert the Supabase date_of_birth into a DateTime
    final dateOfBirth = DateTime.parse(
      child['date_of_birth'].toString(),
    );

    // Calculate the child's current age
    final age = calculateAge(dateOfBirth);



    return DefaultTabController(
      length: 3,

      child: Scaffold(
        appBar: AppBar(
          title: Text(
            fullName,
          ),

          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(
                  Icons.star_outline,
                ),
                text: "Milestones",
              ),

              Tab(
                icon: Icon(
                  Icons.description_outlined,
                ),
                text: "Documents",
              ),

              Tab(
                icon: Icon(
                  Icons.photo_library_outlined,
                ),
                text: "Photos",
              ),
            ],
          ),
        ),

        body: Column(
          children: [

            const SizedBox(
              height: 20,
            ),

            CircleAvatar(
              radius: 55,

              backgroundImage:
                  child['profile_photo_path'] !=
                          null
                      ? NetworkImage(
                          child[
                              'profile_photo_path'],
                        )
                      : null,

              child:
                  child['profile_photo_path'] ==
                          null
                      ? const Icon(
                          Icons.child_care,
                          size: 40,
                        )
                      : null,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              fullName,

              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              "Age $age",
            ),

            const SizedBox(
              height: 20,
            ),

            const Divider(),

            const Expanded(
              child: TabBarView(
                children: [

                  // Milestones
                  Center(
                    child: Text(
                      "Milestones",
                    ),
                  ),

                  // Documents
                  Center(
                    child: Text(
                      "Documents",
                    ),
                  ),

                  // Photos
                  Center(
                    child: Text(
                      "Photos",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}