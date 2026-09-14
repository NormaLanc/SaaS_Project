import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key,});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> notifications = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadNotifications();
  }

  Future<void> loadNotifications() async {

    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });

      return;
    }

    try {
      final data = await supabase
          .from('Notifications')
          .select()
          .eq(
            'recipient_user_id',
            user.id,
          )
          .order(
            'created_at',
            ascending: false,
          );

      if (!mounted) return;

      setState(() {
        notifications =
            List<
                Map<String, dynamic>>
                .from(data);

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load notifications: $e',
          ),
        ),
      );
    }
  }

  Future<void> approveRequest(
    Map<String, dynamic> notification,
  ) async {

    final user =
        supabase.auth.currentUser;

    if (user == null) return;

    try {
      await supabase
          .from('Family_Members')
          .update({
            'status':
                'approved',

            'approved_by':
                user.id,
          })
          .eq(
            'id',
            notification[
                'membership_id'],
          );

      await supabase
          .from('Notifications')
          .update({
            'is_read': true,
            'action_status':
                'approved',
          })
          .eq(
            'id',
            notification['id'],
          );

      await loadNotifications();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Family access approved.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to approve access: $e',
          ),
        ),
      );
    }
  }

  Future<void> denyRequest(
    Map<String, dynamic> notification,
  ) async {

    try {
      await supabase
          .from('Family_Members')
          .update({
            'status':
                'denied',
          })
          .eq(
            'id',
            notification[
                'membership_id'],
          );

      await supabase
          .from('Notifications')
          .update({
            'is_read': true,
            'action_status':
                'denied',
          })
          .eq(
            'id',
            notification['id'],
          );

      await loadNotifications();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text(
            'Family access denied.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to deny access: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Notifications',
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : notifications.isEmpty

              ? const Center(
                  child: Text(
                    'No notifications yet.',
                  ),
                )

              : RefreshIndicator(
                  onRefresh:
                      loadNotifications,

                  child:
                      ListView.builder(
                    padding:
                        const EdgeInsets
                            .all(16),

                    itemCount:
                        notifications
                            .length,

                    itemBuilder:
                        (
                      context,
                      index,
                    ) {

                      final notification =
                          notifications[
                              index];

                      final type =
                          notification[
                                  'type']
                              ?.toString();

                      final actionStatus =
                          notification[
                                  'action_status']
                              ?.toString();

                      return Card(
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 16,
                        ),

                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(16),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                notification[
                                            'title']
                                        ?.toString() ??
                                    'Notification',

                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                notification['message']
                                        ?.toString() ??
                                    '',
                              ),

                              if (type == 'family_join_request' && actionStatus == 'pending') ...[

                                const SizedBox(height: 12,),

                                const Text('Do you want to approve access? Select yes or no.',),

                                const SizedBox(height: 16,),

                                Row(
                                  children: [

                                    ElevatedButton(
                                      onPressed:
                                          () {
                                        approveRequest(notification,);
                                      },

                                      child:
                                          const Text('Yes',),
                                    ),

                                    const SizedBox(width: 12,),

                                    OutlinedButton(
                                      onPressed:
                                          () {
                                        denyRequest(notification,);
                                      },

                                      child:
                                          const Text('No',),
                                    ),

                                  ],
                                ),
                              ],

                              if (type == 'family_join_request' && actionStatus == 'approved') ...[

                                const SizedBox(height: 12,),

                                const Text('Access approved.',),
                              ],

                              if (type == 'family_join_request' && actionStatus == 'denied') ...[

                                const SizedBox(height: 12,),

                                const Text('Access denied.',),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}