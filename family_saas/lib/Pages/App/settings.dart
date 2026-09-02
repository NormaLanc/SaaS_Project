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
        title: const Text('Settings'),
      ),
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
