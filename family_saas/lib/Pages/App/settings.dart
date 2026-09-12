import 'package:flutter/material.dart';
//The details to send invites will be on this page.
//TODO: Generate one-time invite codes for inviting new family members
//TODO: Invite permissions are tied to unique one-time invite codes
//TODO: Family role is tied to unique one-time invite codes

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),

      //Invite new family members using one-time invite codes
     
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Settings Page'),
            // Add your settings options here
          ],
        ),
      ),
    );
  }
}
