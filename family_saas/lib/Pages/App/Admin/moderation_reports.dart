import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Styling/folktri_colors.dart';

class ModerationReportsPage extends StatefulWidget {
  const ModerationReportsPage({
    super.key,
  });

  @override
  State<ModerationReportsPage> createState() =>
      _ModerationReportsPageState();
}

class _ModerationReportsPageState
    extends State<ModerationReportsPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool isAdmin = false;

  String? errorMessage;

  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  Future<void> initializePage() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isAdmin = false;
        errorMessage =
            'Unable to verify your account.';
      });

      return;
    }

    try {
      // -----------------------------------------
      // Verify App Admin
      // -----------------------------------------

      final adminResponse = await supabase
          .from('App_Admins')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (adminResponse == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isAdmin = false;
        });

        return;
      }

      // -----------------------------------------
      // Load Reports
      // -----------------------------------------

      final reportResponse = await supabase
          .from('Content_Reports')
          .select(
            'id, '
            'reporter_user_id, '
            'reported_user_id, '
            'family_id, '
            'content_type, '
            'content_id, '
            'reason, '
            'details, '
            'status, '
            'created_at, '
            'reviewed_at, '
            'reviewed_by, '
            'admin_notes',
          )
          .order(
            'created_at',
            ascending: false,
          );

      final loadedReports =
          List<Map<String, dynamic>>.from(
        reportResponse,
      );

      if (!mounted) return;

      setState(() {
        isAdmin = true;
        reports = loadedReports;
        isLoading = false;
        errorMessage = null;
      });
    } on PostgrestException catch (e) {
      debugPrint(
        'LOAD MODERATION REPORTS ERROR: ${e.message}',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load moderation reports.';
      });
    } catch (e) {
      debugPrint(
        'LOAD MODERATION REPORTS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load moderation reports.';
      });
    }
  }

  String formatReason(String reason) {
    switch (reason) {
      case 'inappropriate_content':
        return 'Inappropriate content';

      case 'harassment_bullying':
        return 'Harassment or bullying';

      case 'sexual_content':
        return 'Sexual content';

      case 'child_safety':
        return 'Child safety';

      case 'spam':
        return 'Spam';

      case 'impersonation':
        return 'Impersonation';

      case 'other':
        return 'Other';

      default:
        return reason;
    }
  }

  String formatContentType(String type) {
    switch (type) {
      case 'family_post':
        return 'Family Post';

      case 'post_comment':
        return 'Comment';

      case 'photo':
        return 'Photo';

      default:
        return type;
    }
  }

  String formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';

      case 'under_review':
        return 'Under Review';

      case 'action_taken':
        return 'Action Taken';

      case 'dismissed':
        return 'Dismissed';

      default:
        return status;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return FolktriColors.dustyRose;

      case 'under_review':
        return FolktriColors.primaryIndigo;

      case 'action_taken':
        return FolktriColors.connectionTeal;

      case 'dismissed':
        return FolktriColors.secondaryText;

      default:
        return FolktriColors.secondaryText;
    }
  }

  Widget buildReportCard(
    Map<String, dynamic> report,
  ) {
    final contentType =
        report['content_type']?.toString() ?? '';

    final reason =
        report['reason']?.toString() ?? '';

    final status =
        report['status']?.toString() ?? 'pending';

    final details =
        report['details']?.toString().trim() ?? '';

    return InkWell(
  borderRadius: BorderRadius.circular(20),
  onTap: () async {
  await context.push(
    '/settings/moderation/report',
    extra: report,
  );

  if (!mounted) return;

  await initializePage();
},
    
    child: Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FolktriColors.midnightIndigo
                .withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FolktriColors
                      .lightLavender
                      .withValues(alpha: 0.65),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color:
                      FolktriColors.primaryIndigo,
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
                      formatReason(reason),
                      style: const TextStyle(
                        color: FolktriColors
                            .midnightIndigo,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      formatContentType(
                        contentType,
                      ),
                      style: const TextStyle(
                        color: FolktriColors
                            .secondaryText,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor(status)
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  formatStatus(status),
                  style: TextStyle(
                    color: statusColor(status),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          if (details.isNotEmpty) ...[
            const SizedBox(height: 14),

            Text(
              details,
              style: const TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 14),

          Text(
            'Report ID: ${report['id']}',
            style: TextStyle(
              color: FolktriColors.secondaryText
                  .withValues(alpha: 0.75),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: FolktriColors.primaryIndigo,
        ),
      );
    }

    if (!isAdmin) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'You do not have access to Folktri moderation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  FolktriColors.secondaryText,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color:
                    FolktriColors.dustyRose,
                size: 34,
              ),

              const SizedBox(height: 12),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FolktriColors
                      .secondaryText,
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                  initializePage();
                },
                child: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color:
                    FolktriColors.connectionTeal,
                size: 42,
              ),

              SizedBox(height: 14),

              Text(
                'No reports to review',
                style: TextStyle(
                  color:
                      FolktriColors.midnightIndigo,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'New safety reports will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      FolktriColors.secondaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: FolktriColors.primaryIndigo,
      onRefresh: initializePage,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          40,
        ),
        children: [
          Text(
            '${reports.length} '
            '${reports.length == 1 ? 'report' : 'reports'}',
            style: const TextStyle(
              color:
                  FolktriColors.secondaryText,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          ...reports.map(
            buildReportCard,
          ),
        ],
      ),
    );
  }

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
          tooltip: 'Back to Settings',
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          'Moderation',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: buildBody(),
      ),
    );
  }
}