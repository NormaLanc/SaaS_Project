import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//The details to send invites will be on this page.

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  Future<void> logout() async {
  try {
    final supabase =
        Supabase.instance.client;

    await supabase.auth.signOut();

    final sessionAfterLogout =
        supabase.auth.currentSession;

    debugPrint(
      'SESSION AFTER LOGOUT: ${sessionAfterLogout?.user.id}',
    );

    if (!mounted) return;

    context.go('/login');
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to log out: $e',
        ),
      ),
    );
  }
}

  Future<void> deleteAccount() async {
  final shouldDelete =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Delete Account',
        ),

        content: const Text(
          'Are you sure you want to permanently delete your account? If you own a family, you will need to transfer ownership or delete that family first. This cannot be undone.',
        ),

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
              'Delete Account',
            ),
          ),
        ],
      );
    },
  );

  if (shouldDelete != true) {
    return;
  }

  try {
    final response =
        await Supabase.instance.client.functions
            .invoke(
      'delete-account',
    );

    if (response.status != 200) {
      throw Exception(
        response.data?['error'] ??
            'Unable to delete account.',
      );
    }

    // Clear the local session.
    await Supabase.instance.client.auth
        .signOut();

    if (!mounted) return;

    context.go('/login');
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete account: $e',
        ),
      ),
    );
  }
}

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
     
      body: ListView(
        children: [
          ListTile(
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
        ),
          const Divider(),
  
          ListTile(
            leading: const Icon(
              Icons.logout,
            ),
            title: const Text(
              'Log Out',
            ),
            onTap: () async {
  final shouldLogout =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Log Out',
        ),
        content: const Text(
          'Are you sure you want to log out?',
        ),
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
              'Log Out',
            ),
          ),

        ],
      );
    },
  );

  if (shouldLogout == true) {
    await logout();
  }
},
          ),

          const Divider(),

ListTile(
  leading: const Icon(
    Icons.delete_forever,
    color: Colors.red,
  ),

  title: const Text(
    'Delete Account',
    style: TextStyle(
      color: Colors.red,
    ),
  ),

  subtitle: const Text(
    'Permanently delete your Folktri account',
  ),

  onTap: deleteAccount,
),
        ]
//Column(
          
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
