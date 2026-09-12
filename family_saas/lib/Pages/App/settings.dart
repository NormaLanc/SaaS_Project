import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//The details to send invites will be on this page.
//TODO: Link to Invites Page

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Family Dashboard",
          onPressed: () {
            context.go('/app');
          },
        ),
        title: const Text("Settings"),
      ),

      //Invite new family members using one-time invite codes
     
      body: Center(
        child: ListTile(
          leading: const Icon(Icons.mail_outline),

          title: const Text(
            'Invitations',
          ),

          subtitle: const Text(
            'Create and manage family invitations',
          ),

          trailing: const Icon(
            Icons.chevron_right,
          ),

          onTap: () {
          context.push('/invitations');
          },
),//Column(
          
          // mainAxisAlignment: MainAxisAlignment.center,
          // children: const [
          //   Text('Settings Page'),
          //   // Add your settings options here
          // ],
       // ),
      ),
    );
  }
}
