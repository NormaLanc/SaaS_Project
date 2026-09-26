import 'package:flutter/material.dart';
import '../../Styling/folktri_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsPage extends StatefulWidget {

    const NotificationSettingsPage({super.key});


  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {


  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool isSaving = false;

  // FAMILY ACTIVITY
  bool newMilestones = true;
  bool newPhotos = true;
  bool newPosts = true;

  // CALENDAR
  bool eventReminders = true;
  bool eventUpdates = true;

  // FAMILY ACCESS
  bool membershipRequests = true;
  bool invitationUpdates = true;

  // DELIVERY
  bool pushNotifications = true;
  bool emailNotifications = false;

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await supabase
          .from('Notification_Preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      // No preferences exist yet.
      // Create the default record.
      if (response == null) {
        await createDefaultPreferences(
          user.id,
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        newMilestones =
            response['new_milestones'] ?? true;

        newPhotos =
            response['new_photos'] ?? true;

        newPosts =
            response['new_posts'] ?? true;

        eventReminders =
            response['event_reminders'] ?? true;

        eventUpdates =
            response['event_updates'] ?? true;

        membershipRequests =
            response['membership_requests'] ??
                true;

        invitationUpdates =
            response['invitation_updates'] ??
                true;

        pushNotifications =
            response['push_notifications'] ??
                true;

        emailNotifications =
            response['email_notifications'] ??
                false;

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'LOAD NOTIFICATION PREFERENCES ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Unable to load notification settings.',
      );
    }
  }

  Future<void> createDefaultPreferences(
    String userId,
  ) async {
    try {
      await supabase
          .from('Notification_Preferences')
          .insert({
        'user_id': userId,
      });

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'CREATE NOTIFICATION PREFERENCES ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Unable to create notification settings.',
      );
    }
  }

  Future<void> savePreferences() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage(
        'You must be signed in to update notifications.',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await supabase
          .from('Notification_Preferences')
          .upsert(
        {
          'user_id': user.id,

          'new_milestones': newMilestones,
          'new_photos': newPhotos,
          'new_posts': newPosts,

          'event_reminders': eventReminders,
          'event_updates': eventUpdates,

          'membership_requests':
              membershipRequests,

          'invitation_updates':
              invitationUpdates,

          'push_notifications':
              pushNotifications,

          'email_notifications':
              emailNotifications,

          'updated_at':
              DateTime.now()
                  .toUtc()
                  .toIso8601String(),
        },
        onConflict: 'user_id',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification settings saved.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'SAVE NOTIFICATION PREFERENCES ERROR: $e',
      );

      if (!mounted) return;

      showMessage(
        'Unable to save notification settings.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context){


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
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : buildContent(),
    );
  }

  Widget buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        22,
        16,
        40,
      ),
      children: [
        const Text(
          'Notification Settings',
          style: TextStyle(
            color:
                FolktriColors.midnightIndigo,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Choose which Folktri updates you want to hear about.',
          style: TextStyle(
            color:
                FolktriColors.secondaryText,
            fontSize: 14,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 28),

        buildSectionTitle(
          'FAMILY ACTIVITY',
        ),

        buildSettingsCard(
          children: [
            buildNotificationSwitch(
              icon:
                  Icons.emoji_events_outlined,
              title: 'New Milestones',
              subtitle:
                  'Milestones shared with your family',
              value: newMilestones,
              onChanged: (value) {
                setState(() {
                  newMilestones = value;
                });
              },
            ),

            buildDivider(),

            buildNotificationSwitch(
              icon: Icons.photo_outlined,
              title: 'New Photos',
              subtitle:
                  'Photos added to your family',
              value: newPhotos,
              onChanged: (value) {
                setState(() {
                  newPhotos = value;
                });
              },
            ),

            buildDivider(),

            buildNotificationSwitch(
              icon:
                  Icons.dynamic_feed_outlined,
              title: 'New Posts',
              subtitle:
                  'New family activity and posts',
              value: newPosts,
              onChanged: (value) {
                setState(() {
                  newPosts = value;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 26),

        buildSectionTitle('CALENDAR'),

        buildSettingsCard(
          children: [
            buildNotificationSwitch(
              icon:
                  Icons.alarm_outlined,
              title: 'Event Reminders',
              subtitle:
                  'Reminders for upcoming family events',
              value: eventReminders,
              onChanged: (value) {
                setState(() {
                  eventReminders = value;
                });
              },
            ),

            buildDivider(),

            buildNotificationSwitch(
              icon:
                  Icons.event_note_outlined,
              title: 'Event Updates',
              subtitle:
                  'New and updated family events',
              value: eventUpdates,
              onChanged: (value) {
                setState(() {
                  eventUpdates = value;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 26),

        buildSectionTitle(
          'FAMILY ACCESS',
        ),

        buildSettingsCard(
          children: [
            buildNotificationSwitch(
              icon:
                  Icons.person_add_alt_1_outlined,
              title: 'Membership Requests',
              subtitle:
                  'When someone requests access to a family you manage',
              value: membershipRequests,
              onChanged: (value) {
                setState(() {
                  membershipRequests =
                      value;
                });
              },
            ),

            buildDivider(),

            buildNotificationSwitch(
              icon:
                  Icons.mark_email_unread_outlined,
              title: 'Invitation Updates',
              subtitle:
                  'Updates about family invitations',
              value: invitationUpdates,
              onChanged: (value) {
                setState(() {
                  invitationUpdates =
                      value;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 26),

        buildSectionTitle(
          'DELIVERY',
        ),

        buildSettingsCard(
          children: [
            buildNotificationSwitch(
              icon:
                  Icons.notifications_active_outlined,
              title: 'Push Notifications',
              subtitle:
                  'Receive notifications on your device',
              value: pushNotifications,
              onChanged: (value) {
                setState(() {
                  pushNotifications =
                      value;
                });
              },
            ),

            buildDivider(),

            buildNotificationSwitch(
              icon:
                  Icons.email_outlined,
              title: 'Email Notifications',
              subtitle:
                  'Receive selected Folktri updates by email',
              value: emailNotifications,
              onChanged: (value) {
                setState(() {
                  emailNotifications =
                      value;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  FolktriColors.primaryIndigo,
              foregroundColor:
                  FolktriColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),

            onPressed:
                isSaving
                    ? null
                    : savePreferences,

            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          FolktriColors.surface,
                    ),
                  )
                : const Text(
                    'Save Preferences',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

   Widget buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 5,
        bottom: 9,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: FolktriColors
              .midnightIndigo
              .withOpacity(0.62),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
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
                .withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget buildNotificationSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor:
          FolktriColors.primaryIndigo,

      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color:
              FolktriColors.lightLavender,
          borderRadius:
              BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          size: 21,
          color:
              FolktriColors.primaryIndigo,
        ),
      ),

      title: Text(
        title,
        style: const TextStyle(
          color:
              FolktriColors.midnightIndigo,
          fontWeight: FontWeight.w600,
        ),
      ),

      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color:
              FolktriColors.secondaryText,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildDivider() {
    return Padding(
      padding:
          const EdgeInsets.only(left: 72),
      child: Divider(
        height: 1,
        color:
            FolktriColors.lightLavender,
      ),
    );
  }
}