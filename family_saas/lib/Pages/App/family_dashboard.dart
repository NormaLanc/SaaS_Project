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

  @override
  void initState() {
    super.initState();
    checkFamilyMembership();
  }

  Future<void> checkFamilyMembership() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        return;
      }

      final response = await Supabase.instance.client
          .from('Family_Members')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'approved');

      if (!mounted) return;

      setState(() {
        hasApprovedFamily = response.isNotEmpty;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading families: $e'),
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
              title: const Text('Settings'),
              onTap: () {
                // Navigate to the settings page
                context.go('/settings');
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
