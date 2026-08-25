import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import '../Services/auth_service.dart';


class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});


  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}


class _FamilyDashboardState extends State<FamilyDashboard> {

  

  @override
  Widget build(BuildContext context){

    return Scaffold(

      //TODO: Add icon for users to create new families
      appBar: AppBar(
        title: const Text("Family Dashboard"),
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

      body: const Center(
        child: Text('Family Dashboard'),
      ),
    );
  }
}
