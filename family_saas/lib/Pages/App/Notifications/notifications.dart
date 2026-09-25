import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../Styling/folktri_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key,});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> notifications = [];

  bool isLoading = true;
  String? errorMessage;

    // Prevent repeated approval/denial taps while
  // a request is being processed.
  final Set<String> processingNotificationIds = {};

  @override
  void initState() {
    super.initState();

    loadNotifications();
  }

  Future<void> loadNotifications() async {

    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        notifications = [];
        isLoading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
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
        notifications = List<Map<String, dynamic>>.from(data);

        isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD NOTIFICATIONS ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('Unable to load notifications: $e',),
        ),
      );
    }
  }

  Future<void> approveRequest(
    Map<String, dynamic> notification,
  ) async {

    final user = supabase.auth.currentUser;

    if (user == null) return;

    final notificationId = notification['id']?.toString() ?? '';

    final membershipId = notification['membership_id']?.toString() ?? '';

    if (notificationId.isEmpty || membershipId.isEmpty) {
      _showMessage('This request is missing required information.');
      return;
    }

    if (processingNotificationIds.contains(notificationId)) {
      return;
    }

    setState(() {
      processingNotificationIds.add(notificationId);
    });


    try {
      // await supabase
      //     .from('Family_Members')
      //     .update({
      //       'status':
      //           'approved',

      //       'approved_by':
      //           user.id,
      //     })
      //     .eq(
      //       'id',
      //       notification['membership_id'],
      //     );

    final updatedMembership = await supabase
      .from('Family_Members')
      .update({
        'status': 'approved',
        'approved_by': user.id,
      })
      .eq(
        'id',
        notification['membership_id'],
      )
      .select()
      .maybeSingle();

    debugPrint('APPROVED MEMBERSHIP: $updatedMembership',);

    if (updatedMembership == null) {
      throw Exception('The membership could not be approved.',);
    }

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

      _showMessage('Family access approved.');

      // ScaffoldMessenger.of(context)
      //     .showSnackBar(
      //   const SnackBar(
      //     content: Text(
      //       'Family access approved.',
      //     ),
      //   ),
      // );
    } catch (e) {
      debugPrint('APPROVE REQUEST ERROR: $e');
      if (!mounted) return;

      _showMessage('Unable to approve access: $e');
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       'Unable to approve access: $e',
      //     ),
      //   ),
      // );
    } finally {
      if (mounted){
        setState(() {
          processingNotificationIds.remove(notificationId);
        });
      }
    }
  }

  Future<void> denyRequest(
    Map<String, dynamic> notification,
  ) async {

    final notificationId =
        notification['id']?.toString() ?? '';

    final membershipId =
        notification['membership_id']?.toString() ?? '';

    if (notificationId.isEmpty || membershipId.isEmpty) {
      _showMessage('This request is missing required information.');
      return;
    }

    if (processingNotificationIds.contains(notificationId)) {
      return;
    }

    setState(() {
      processingNotificationIds.add(notificationId);
    });


    try {
      final updatedMembership = await supabase
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

        if (updatedMembership == null) {
          throw Exception(
          'The membership could not be denied.',
        );
      }

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

      _showMessage('Family access denied.');

      // ScaffoldMessenger.of(context)
      //     .showSnackBar(
      //   const SnackBar(
      //     content:
      //         Text(
      //       'Family access denied.',
      //     ),
      //   ),
      // );
    } catch (e) {
      debugPrint('DENY REQUEST ERROR: $e');

      if (!mounted) return;

      _showMessage('Unable to deny access: $e');

      // ScaffoldMessenger.of(context)
      //     .showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       'Unable to deny access: $e',
      //     ),
      //   ),
      // );
    }
  }

    void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ==========================================
  // DATE LABEL
  // ==========================================

  String _formatNotificationDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(
      value.toString(),
    )?.toLocal();

    if (date == null) return '';

    final difference = DateTime.now().difference(date);

    if (difference.isNegative ||
        difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.month}/${date.day}/${date.year}';
  }

  // ==========================================
  // NOTIFICATION CARD
  // ==========================================

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
  ) {
    final type =
        notification['type']?.toString() ?? '';

    final actionStatus =
        notification['action_status']?.toString() ?? '';

    final notificationId =
        notification['id']?.toString() ?? '';

    final title =
        notification['title']?.toString() ?? 'Notification';

    final message =
        notification['message']?.toString() ?? '';

    final isRead = notification['is_read'] == true;

    final isJoinRequest = type == 'family_join_request';

    final isPending =
        isJoinRequest && actionStatus == 'pending';

    final isProcessing =
        processingNotificationIds.contains(notificationId);

    final dateLabel = _formatNotificationDate(
      notification['created_at'],
    );

    final IconData notificationIcon = isJoinRequest
        ? Icons.group_add_rounded
        : Icons.notifications_none_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? FolktriColors.lightLavender
              : FolktriColors.background,
        ),
        boxShadow: [
          BoxShadow(
            color: FolktriColors.midnightIndigo
                .withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------
            // NOTIFICATION HEADER
            // ----------------------------------

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor:
                      FolktriColors.lightLavender,
                  child: Icon(
                    notificationIcon,
                    color: FolktriColors.primaryIndigo,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: FolktriColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (dateLabel.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color:
                                FolktriColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (!isRead)
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: FolktriColors.primaryIndigo,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),

            // ----------------------------------
            // NOTIFICATION MESSAGE
            // ----------------------------------

            if (message.isNotEmpty) ...[
              const SizedBox(height: 14),

              Text(
                message,
                style: const TextStyle(
                  color: FolktriColors.primaryText,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],

            // ----------------------------------
            // PENDING JOIN REQUEST
            // ----------------------------------

            if (isPending) ...[
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FolktriColors.lightLavender
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Would you like to approve this person '
                  'to join your family?',
                  style: TextStyle(
                    color: FolktriColors.midnightIndigo,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => approveRequest(notification),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            FolktriColors.primaryIndigo,
                        foregroundColor:
                            FolktriColors.surface,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: FolktriColors.surface,
                              ),
                            )
                          : const Icon(
                              Icons.check_rounded,
                              size: 18,
                            ),
                      label: const Text('Approve'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => denyRequest(notification),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            FolktriColors.secondaryText,
                        side: const BorderSide(
                          color: FolktriColors.lightLavender,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                      ),
                      label: const Text('Deny'),
                    ),
                  ),
                ],
              ),
            ],

            // ----------------------------------
            // COMPLETED JOIN REQUEST
            // ----------------------------------

            if (isJoinRequest &&
                (actionStatus == 'approved' ||
                    actionStatus == 'denied')) ...[
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: actionStatus == 'approved'
                      ? FolktriColors.connectionTeal
                          .withValues(alpha: 0.12)
                      : FolktriColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      actionStatus == 'approved'
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      size: 15,
                      color: actionStatus == 'approved'
                          ? FolktriColors.connectionTeal
                          : FolktriColors.secondaryText,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      actionStatus == 'approved'
                          ? 'Access approved'
                          : 'Access denied',
                      style: TextStyle(
                        color: actionStatus == 'approved'
                            ? FolktriColors.connectionTeal
                            : FolktriColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 85),

        CircleAvatar(
          radius: 38,
          backgroundColor: FolktriColors.lightLavender,
          child: Icon(
            Icons.notifications_none_rounded,
            size: 36,
            color: FolktriColors.primaryIndigo,
          ),
        ),

        SizedBox(height: 20),

        Text(
          'All caught up!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FolktriColors.primaryText,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 8),

        Text(
          'Family updates and invitations '
          'will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FolktriColors.secondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    final unreadCount = notifications
        .where((notification) =>
            notification['is_read'] != true)
        .length;

    return Scaffold(
      backgroundColor: FolktriColors.background,

      appBar: AppBar(
        backgroundColor: FolktriColors.midnightIndigo,
        foregroundColor: FolktriColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,

        leading: IconButton(
          tooltip: 'Back to Family Dashboard',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            context.go('/app');
          },
        ),

        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh notifications',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            onPressed: loadNotifications,
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: FolktriColors.primaryIndigo,
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 42,
                          color: FolktriColors.dustyRose,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color:
                                FolktriColors.secondaryText,
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: loadNotifications,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: FolktriColors.primaryIndigo,
                  onRefresh: loadNotifications,

                  child: notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            16, 20, 16, 24,
                          ),
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Your updates',
                                  style: TextStyle(
                                    color:
                                        FolktriColors.primaryText,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const Spacer(),

                                if (unreadCount > 0)
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          FolktriColors.lightLavender,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$unreadCount unread',
                                      style: const TextStyle(
                                        color:
                                            FolktriColors.primaryIndigo,
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            ...notifications.map(
                              _buildNotificationCard,
                            ),
                          ],
                        ),
                ),
    );
  }
}