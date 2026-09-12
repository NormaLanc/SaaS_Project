import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import '../Services/auth_service.dart';


class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});


  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}


class _FamilyDashboardState extends State<FamilyDashboard> {

  bool isLoading = true;
  bool hasApprovedFamily = false;

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> families = [];

  String? selectedFamilyId;

  @override
  void initState() {
    super.initState();
    checkFamilyMembership();
  }

Future<void> checkFamilyMembership() async {
  try {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      return;
    }

    // Get all approved family memberships for this user.
    final membershipResponse = await supabase
        .from('Family_Members')
        .select('family_id')
        .eq('user_id', user.id)
        .eq('status', 'approved');

    final memberships =
        List<Map<String, dynamic>>.from(membershipResponse);

    // If user does not belong to any approved families.
    if (memberships.isEmpty) {
      if (!mounted) return;

      setState(() {
        hasApprovedFamily = false;
        families = [];
        selectedFamilyId = null;
        isLoading = false;
      });

      return;
    }

    // Get all of the family IDs.
    final familyIds = memberships
        .map((membership) => membership['family_id'])
        .where((id) => id != null)
        .toList();

    // Load the actual family records.
    final familyResponse = await supabase
        .from('Families')
        .select('id, family_name')
        .inFilter('id', familyIds)
        .order('family_name');

    if (!mounted) return;

    setState(() {
      families =
          List<Map<String, dynamic>>.from(familyResponse);

      hasApprovedFamily = families.isNotEmpty;

      if (families.isNotEmpty) {
        selectedFamilyId =
            families.first['id'].toString();
      }

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
          'Error loading families: $e',
        ),
      ),
    );
  }
}

//Dialog box to ask the user if they want to join an existing family or create a new one
  void showFamilyOptions() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Add a Family"),

          content: const Text(
            "Would you like to join an existing family or create a new one?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                context.push('/join-family');
              },
              child: const Text("Join Existing Family"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                context.push('/create-family');
              },
              child: const Text("Create New Family"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(

      
      appBar: AppBar(
        title: const Text("Family Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Family",
            onPressed: showFamilyOptions,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text('Menu'),
            ),
            if (families.isNotEmpty)
  Padding(
    padding: const EdgeInsets.fromLTRB(
      16,
      16,
      16,
      8,
    ),
    child: DropdownButtonFormField<String>(
      value: selectedFamilyId,

      decoration: const InputDecoration(
        labelText: "Family",
        prefixIcon: Icon(Icons.family_restroom),
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

      onChanged: (familyId) {
        if (familyId == null) return;

        setState(() {
          selectedFamilyId = familyId;
        });

        // Close the menu.
        Navigator.pop(context);

        // Open the selected family's page.
        context.push(
          '/family/$familyId',
        );
      },
    ),
  ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                // Navigate to the home page
                Navigator.pop(context);
                context.go('/app');
                //context.go('/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Calendar'),
              onTap: () {
                Navigator.pop(context);
                context.go('/calendar');
              },
            ),

            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photos'),
              onTap: () {
                Navigator.pop(context);
                context.go('/photos');
              },
            ),

            ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text('Children'),
              onTap: () {
                Navigator.pop(context);
                context.go('/children');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                // Navigate to the profile page
                context.go('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                //Close the drawer before navigating to the settings page
                Navigator.pop(context);
                // Navigate to the settings page
                context.push('/settings');
              },
            ),
          ],
        ),
      ),

      
      body: isLoading
        ? const Center(
          child: CircularProgressIndicator(),
        )
      : hasApprovedFamily
          ? const Center(
              child: Text("Family Dashboard Content"),
            )
          : const Center(
              child: Text(
                "Create a family or join an existing family to get started.",
              ),
            ),
    );
  }
}
