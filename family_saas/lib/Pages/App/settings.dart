import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Styling/folktri_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final supabase = Supabase.instance.client;

  bool isLoggingOut = false;
  bool isDeletingAccount = false;
  bool deleteSharedPhotos = false;

  bool get isProcessing =>
      isLoggingOut || isDeletingAccount;

  // ---------------------------------------------------------
  // LOG OUT
  // ---------------------------------------------------------

  Future<void> confirmLogout() async {
    if (isProcessing) return;

    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              FolktriColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color:
                    FolktriColors.primaryIndigo,
              ),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  color: FolktriColors
                      .midnightIndigo,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of Folktri?',
            style: TextStyle(
              color:
                  FolktriColors.secondaryText,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: FolktriColors
                      .secondaryText,
                ),
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    FolktriColors
                        .primaryIndigo,
                foregroundColor:
                    FolktriColors.surface,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await logout();
    }
  }

  Future<void> logout() async {
    if (isProcessing) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      context.go('/login');
    } on AuthException catch (e) {
      debugPrint(
        'LOGOUT AUTH ERROR: ${e.message}',
      );

      if (!mounted) return;

      showMessage(
        'Unable to log out. Please try again.',
      );
    } catch (e) {
      debugPrint(
        'LOGOUT ERROR: $e',
      );

      if (!mounted) return;

      showMessage(
        'Unable to log out. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // DELETE ACCOUNT
  // ---------------------------------------------------------

  Future<void> deleteAccount() async {
  if (isProcessing) return;

  final shouldContinue = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: FolktriColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Account?',
          style: TextStyle(
            color: FolktriColors.midnightIndigo,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Deleting your Folktri account is permanent. '
          'If you own a family, you must transfer ownership '
          'or delete that family first.\n\n'
          'You will also be able to choose what happens '
          'to photos you have shared with your family.',
          style: TextStyle(
            color: FolktriColors.secondaryText,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Keep Account'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FolktriColors.primaryIndigo,
              foregroundColor: FolktriColors.surface,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );

  if (!mounted || shouldContinue != true) return;

  await chooseSharedPhotoDeletion();
}

Future<void> chooseSharedPhotoDeletion() async {
  // Default to the less destructive choice every time.
  bool selectedDeletePhotos = false;

  final shouldContinue = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: FolktriColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Your Shared Photos',
              style: TextStyle(
                color: FolktriColors.midnightIndigo,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What should happen to photos you uploaded '
                  'to your Folktri families?',
                  style: TextStyle(
                    color: FolktriColors.secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                RadioListTile<bool>(
                  value: false,
                  groupValue: selectedDeletePhotos,
                  activeColor: FolktriColors.primaryIndigo,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Keep my shared photos',
                    style: TextStyle(
                      color: FolktriColors.midnightIndigo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Your uploaded photos and captions will '
                    'remain available to your families.',
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDeletePhotos = value!;
                    });
                  },
                ),

                const SizedBox(height: 12),

                RadioListTile<bool>(
                  value: true,
                  groupValue: selectedDeletePhotos,
                  activeColor: Colors.red,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Delete my shared photos',
                    style: TextStyle(
                      color: FolktriColors.midnightIndigo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Photos you uploaded will be permanently '
                    'removed from your families.',
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDeletePhotos = value!;
                    });
                  },
                ),

                const SizedBox(height: 14),

                const Text(
                  'Your personal profile photo will be '
                  'deleted with your account regardless '
                  'of your selection.',
                  style: TextStyle(
                    color: FolktriColors.secondaryText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FolktriColors.primaryIndigo,
                  foregroundColor: FolktriColors.surface,
                ),
                onPressed: () {
                  deleteSharedPhotos = selectedDeletePhotos;
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    },
  );

  if (!mounted || shouldContinue != true) return;

  await confirmPermanentDeletion();
}

Future<void> confirmPermanentDeletion() async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: FolktriColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Final Confirmation',
          style: TextStyle(
            color: FolktriColors.midnightIndigo,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          deleteSharedPhotos
              ? 'Your account and the photos you uploaded '
                  'to your families will be permanently deleted. '
                  'This cannot be undone.'
              : 'Your account will be permanently deleted. '
                  'Photos you uploaded to your families will remain '
                  'available to them. This cannot be undone.',
          style: const TextStyle(
            color: FolktriColors.secondaryText,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text(
              'Yes, Delete My Account',
            ),
          ),
        ],
      );
    },
  );

  if (!mounted || confirmed != true) return;

  await performAccountDeletion();
}

  Future<void>
      performAccountDeletion() async {
    if (isProcessing) return;

    setState(() {
      isDeletingAccount = true;
    });

    try {
      final response =
          await supabase.functions.invoke(
        'delete-account',
        body: {
          'delete_shared_photos': deleteSharedPhotos,
        }
      );

      if (response.status != 200) {
        final responseData =
            response.data;

        String errorMessage =
            'Unable to delete account.';

        if (responseData is Map &&
            responseData['error'] != null) {
          errorMessage =
              responseData['error']
                  .toString();
        }

        throw Exception(errorMessage);
      }

      // The account has been deleted
      // server-side. Clear any remaining
      // local authentication state.
      try {
        await supabase.auth.signOut();
      } catch (e) {
        debugPrint(
          'POST-DELETE SIGNOUT ERROR: $e',
        );
      }

      if (!mounted) return;

      context.go('/login');
    } on FunctionException catch (e) {
      debugPrint(
        'DELETE ACCOUNT FUNCTION ERROR: '
        '${e.details}',
      );

      if (!mounted) return;

      showMessage(
        'Unable to delete your account. Please make sure any families you own have been transferred or deleted, then try again.',
      );
    } catch (e) {
      debugPrint(
        'DELETE ACCOUNT ERROR: $e',
      );

      if (!mounted) return;

      showMessage(
        'Unable to delete your account. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeletingAccount = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 6,
        bottom: 10,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: FolktriColors
              .midnightIndigo
              .withOpacity(0.65),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.7,
        ),
      ),
    );
  }

  Widget buildSettingsCard({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FolktriColors
                .midnightIndigo
                .withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    final color = isDestructive
        ? Colors.red.shade600
        : FolktriColors.midnightIndigo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap:
            isProcessing ? null : onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red
                          .withOpacity(0.08)
                      : FolktriColors
                          .lightLavender
                          .withOpacity(0.65),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color: FolktriColors
                            .secondaryText,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FolktriColors
                        .primaryIndigo,
                  ),
                )
              else
                Icon(
                  Icons
                      .chevron_right_rounded,
                  color: isDestructive
                      ? Colors.red.shade300
                      : FolktriColors
                          .secondaryText
                          .withOpacity(0.55),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCardDivider() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 74,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: FolktriColors
            .lightLavender
            .withOpacity(0.55),
      ),
    );
  }

  // ---------------------------------------------------------
  // PAGE
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          FolktriColors.background,

      appBar: AppBar(
        backgroundColor:
            FolktriColors.midnightIndigo,
        foregroundColor:
            FolktriColors.surface,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 20,
          ),
          tooltip:
              'Back to Family Dashboard',
          onPressed: isProcessing
              ? null
              : () {
                  context.go('/app');
                },
        ),

        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            22,
            16,
            40,
          ),
          children: [
            // ACCOUNT
            buildSectionTitle('ACCOUNT'),

            buildSettingsCard(
              children: [
                buildSettingsTile(
                  icon:
                      Icons.lock_outline_rounded,
                  title:
                      'Change Password',
                  subtitle:
                      'Update your account password',
                  onTap: () {
                    context.push(
                      '/settings/change-password',
                    );
                  },
                ),

                buildCardDivider(),

                buildSettingsTile(
                  icon:
                      Icons.mail_outline_rounded,
                  title:
                      'Change Email',
                  subtitle:
                      'Update your email address',
                  onTap: () {
                    context.push(
                      '/settings/change-email',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            // FAMILY
            buildSectionTitle('FAMILY'),

            buildSettingsCard(
              children: [
                buildSettingsTile(
                  icon: Icons
                      .family_restroom_rounded,
                  title: 'Family Access',
                  subtitle:
                      'Manage members, roles, and permissions',
                  onTap: () {
                    context.push(
                      '/settings/family-access',
                    );
                  },
                ),

                buildCardDivider(),

                buildSettingsTile(
                  icon:
                      Icons.mail_outline_rounded,
                  title: 'Invitations',
                  subtitle:
                      'Create and manage family invitations',
                  onTap: () {
                    context.push(
                      '/invitations',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            // NOTIFICATIONS
            buildSectionTitle(
              'NOTIFICATIONS',
            ),

            buildSettingsCard(
              children: [
                buildSettingsTile(
                  icon: Icons
                      .notifications_none_rounded,
                  title:
                      'Notification Settings',
                  subtitle:
                      'Choose what you want to be notified about',
                  onTap: () {
                    context.push(
                      '/settings/notifications',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            // SUPPORT
            buildSectionTitle('SUPPORT'),

            buildSettingsCard(
              children: [
                buildSettingsTile(
                  icon: Icons
                      .support_agent_rounded,
                  title:
                      'Contact Support',
                  subtitle:
                      'Email the Folktri support team',
                  onTap: () {
                    context.push(
                      '/settings/support',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            // ACCOUNT ACTIONS
            buildSectionTitle(
              'ACCOUNT ACTIONS',
            ),

            buildSettingsCard(
              children: [
                buildSettingsTile(
                  icon:
                      Icons.logout_rounded,
                  title: 'Log Out',
                  subtitle:
                      'Sign out of Folktri',
                  isLoading:
                      isLoggingOut,
                  onTap: confirmLogout,
                ),

                buildCardDivider(),

                buildSettingsTile(
                  icon: Icons
                      .delete_outline_rounded,
                  title:
                      'Delete Account',
                  subtitle:
                      'Permanently delete your Folktri account',
                  isDestructive: true,
                  isLoading:
                      isDeletingAccount,
                  onTap: deleteAccount,
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Center(
              child: Text(
                'Folktri',
                style: TextStyle(
                  color: FolktriColors
                      .secondaryText,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
