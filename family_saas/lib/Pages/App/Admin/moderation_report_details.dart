import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Styling/folktri_colors.dart';

class ModerationReportDetailsPage extends StatefulWidget {
  final Map<String, dynamic> report;

  const ModerationReportDetailsPage({
    super.key,
    required this.report,
  });

  @override
  State<ModerationReportDetailsPage> createState() =>
      _ModerationReportDetailsPageState();
}

class _ModerationReportDetailsPageState
    extends State<ModerationReportDetailsPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool isAdmin = false;
  bool isUpdatingReport = false;

  String? errorMessage;

  late Map<String, dynamic> currentReport;

  Map<String, dynamic>? reportedContent;
  Map<String, dynamic>? reportedUserProfile;
  Map<String, dynamic>? reporterProfile;

  @override
  void initState() {
    super.initState();

     currentReport = Map<String, dynamic>.from(widget.report,);

    initializePage();
  }

  Future<void> initializePage() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to verify your account.';
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

      isAdmin = true;

      // -----------------------------------------
      // Load reported content
      // -----------------------------------------

      await loadReportedContent();

      // -----------------------------------------
      // Load internal user information
      // -----------------------------------------

      await loadProfiles();

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = null;
      });
    } on PostgrestException catch (e) {
      debugPrint(
        'LOAD MODERATION REPORT DETAILS ERROR: ${e.message}',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load this moderation report.';
      });
    } catch (e) {
      debugPrint(
        'LOAD MODERATION REPORT DETAILS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load this moderation report.';
      });
    }
  }

  Future<void> loadReportedContent() async {
    final contentType =
        currentReport['content_type']?.toString() ?? '';

    final contentId =
        currentReport['content_id']?.toString() ?? '';

    if (contentId.isEmpty) {
      return;
    }

    if (contentType == 'family_post') {
      final response = await supabase
          .from('Family_Posts')
          .select(
            'id, '
            'family_id, '
            'created_by, '
            'post_text, '
            'created_at, '
            'updated_at',
          )
          .eq('id', contentId)
          .maybeSingle();

      reportedContent = response;
    }

    if (contentType == 'post_comment') {
      final response = await supabase
        .from('Family_Post_Comments')
        .select(
          'id, '
          'post_id, '
          'user_id, '
          'comment_text, '
          'created_at, '
          'updated_at, '
          'parent_comment_id',
        )
        .eq('id', contentId)
        .maybeSingle();

      reportedContent = response;
    }

    if (contentType == 'photo_comment') {
      final response = await supabase
        .from('Photo_Comments')
        .select(
          'id, '
          'photo_id, '
          'user_id, '
          'comment_text, '
          'created_at, '
          'parent_comment_id',
        )
        .eq('id', contentId)
        .maybeSingle();

  reportedContent = response;
    }

    if (contentType == 'photo') {
      final response = await supabase
        .from('Photos')
        .select(
          '''
          id,
          family_id,
          child_id,
          created_by,
          media_type,
          photo_url,
          caption,
          created_at
          ''',
        )
        .eq(
          'id',
          contentId,
        )
        .maybeSingle();

        reportedContent = response;
    }
  }

  Future<void> loadProfiles() async {
    final reportedUserId =
        currentReport['reported_user_id']
            ?.toString();

    final reporterUserId =
        currentReport['reporter_user_id']
            ?.toString();

    if (reportedUserId != null &&
        reportedUserId.isNotEmpty) {
      final response = await supabase
          .from('Profiles')
          .select(
            'user_id, '
            'first_name, '
            'last_name, '
            'profile_photo_path',
          )
          .eq(
            'user_id',
            reportedUserId,
          )
          .maybeSingle();

      reportedUserProfile = response;
    }

    if (reporterUserId != null &&
        reporterUserId.isNotEmpty) {
      final response = await supabase
          .from('Profiles')
          .select(
            'user_id, '
            'first_name, '
            'last_name, '
            'profile_photo_path',
          )
          .eq(
            'user_id',
            reporterUserId,
          )
          .maybeSingle();

      reporterProfile = response;
    }
  }

  Future<bool> removeReportedFamilyPost({
  required String adminNotes,
}) async {
  if (isUpdatingReport) {
    return false;
  }

  final user = supabase.auth.currentUser;

  if (user == null) {
    return false;
  }

  final reportId =
      currentReport['id']?.toString() ?? '';

  final contentId =
      currentReport['content_id']?.toString() ?? '';

  final contentType =
      currentReport['content_type']?.toString() ?? '';

  if (reportId.isEmpty ||
      contentId.isEmpty ||
      contentType != 'family_post') {
    return false;
  }

  setState(() {
    isUpdatingReport = true;
  });

  try {
    // Delete only the exact reported Family Post.
    await supabase
        .from('Family_Posts')
        .delete()
        .eq('id', contentId);

    // Verify that the reported post is no longer
    // visible/existing before recording action_taken.
    final remainingPost = await supabase
        .from('Family_Posts')
        .select('id')
        .eq('id', contentId)
        .maybeSingle();

    if (remainingPost != null) {
      throw Exception(
        'Reported Family Post still exists after deletion.',
      );
    }

    final completedAt =
        DateTime.now().toUtc().toIso8601String();

    final finalNotes = adminNotes.trim().isEmpty
        ? 'Reported Family Post removed by moderator.'
        : 'Reported Family Post removed by moderator.\n\n'
            '${adminNotes.trim()}';

    final updates = <String, dynamic>{
      'status': 'action_taken',
      'reviewed_by': user.id,
      'reviewed_at': completedAt,
      'admin_notes': finalNotes,
    };

    await supabase
        .from('Content_Reports')
        .update(updates)
        .eq('id', reportId);

    if (!mounted) {
      return true;
    }

    setState(() {
      currentReport = {
        ...currentReport,
        ...updates,
      };

      reportedContent = null;
      isUpdatingReport = false;
    });

    return true;
  } on PostgrestException catch (e) {
    debugPrint(
      'REMOVE REPORTED FAMILY POST ERROR: '
      '${e.message}',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to remove the reported post: '
          '${e.message}',
        ),
      ),
    );

    return false;
  } catch (e) {
    debugPrint(
      'REMOVE REPORTED FAMILY POST ERROR: $e',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to remove the reported post.',
        ),
      ),
    );

    return false;
  }
}

  Future<bool> removeReportedPostComment({
  required String adminNotes,
}) async {
  if (isUpdatingReport) {
    return false;
  }

  final user = supabase.auth.currentUser;

  if (user == null) {
    return false;
  }

  final reportId =
      currentReport['id']?.toString() ?? '';

  final contentId =
      currentReport['content_id']
              ?.toString() ??
          '';

  final contentType =
      currentReport['content_type']
              ?.toString() ??
          '';

  if (reportId.isEmpty ||
      contentId.isEmpty ||
      contentType != 'post_comment') {
    return false;
  }

  setState(() {
    isUpdatingReport = true;
  });

  try {
    await supabase
        .from('Family_Post_Comments')
        .delete()
        .eq('id', contentId);

    // Confirm the reported comment is gone before
    // recording a successful moderation action.
    final remainingComment = await supabase
        .from('Family_Post_Comments')
        .select('id')
        .eq('id', contentId)
        .maybeSingle();

    if (remainingComment != null) {
      throw Exception(
        'Reported comment still exists after deletion.',
      );
    }

    final completedAt =
        DateTime.now()
            .toUtc()
            .toIso8601String();

    final finalNotes =
        adminNotes.trim().isEmpty
            ? 'Reported Family Post comment '
                'removed by moderator.'
            : 'Reported Family Post comment '
                'removed by moderator.\n\n'
                '${adminNotes.trim()}';

    final updates = <String, dynamic>{
      'status': 'action_taken',
      'reviewed_by': user.id,
      'reviewed_at': completedAt,
      'admin_notes': finalNotes,
    };

    await supabase
        .from('Content_Reports')
        .update(updates)
        .eq('id', reportId);

    if (!mounted) {
      return true;
    }

    setState(() {
      currentReport = {
        ...currentReport,
        ...updates,
      };

      reportedContent = null;
      isUpdatingReport = false;
    });

    return true;
  } on PostgrestException catch (e) {
    debugPrint(
      'REMOVE REPORTED COMMENT ERROR: '
      '${e.message}',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to remove the reported '
          'comment: ${e.message}',
        ),
      ),
    );

    return false;
  } catch (e) {
    debugPrint(
      'REMOVE REPORTED COMMENT ERROR: $e',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to remove the reported comment.',
        ),
      ),
    );

    return false;
  }
}

  Future<bool> removeReportedPhoto({
  required String adminNotes,
}) async {
  if (isUpdatingReport) {
    return false;
  }

  final user = supabase.auth.currentUser;

  if (user == null) {
    return false;
  }

  final reportId =
      currentReport['id']?.toString() ?? '';

  final contentId =
      currentReport['content_id']
              ?.toString() ??
          '';

  final contentType =
      currentReport['content_type']
              ?.toString() ??
          '';

  if (reportId.isEmpty ||
      contentId.isEmpty ||
      contentType != 'photo') {
    return false;
  }

  setState(() {
    isUpdatingReport = true;
  });

  try {
    // Delete ONLY the reported Photos database row.
    //
    // Do not delete the underlying Storage object here.
    // The same image may also be referenced by a
    // Milestone.
    await supabase
        .from('Photos')
        .delete()
        .eq('id', contentId);

    // Confirm the Photos row is actually gone before
    // recording a successful moderation action.
    final remainingPhoto = await supabase
        .from('Photos')
        .select('id')
        .eq('id', contentId)
        .maybeSingle();

    if (remainingPhoto != null) {
      throw Exception(
        'Reported photo still exists after deletion.',
      );
    }

    final completedAt =
        DateTime.now()
            .toUtc()
            .toIso8601String();

    final finalNotes =
        adminNotes.trim().isEmpty
            ? 'Reported photo removed by moderator.'
            : 'Reported photo removed by moderator.\n\n'
                '${adminNotes.trim()}';

    final updates = <String, dynamic>{
      'status': 'action_taken',
      'reviewed_by': user.id,
      'reviewed_at': completedAt,
      'admin_notes': finalNotes,
    };

    await supabase
        .from('Content_Reports')
        .update(updates)
        .eq('id', reportId);

    if (!mounted) {
      return true;
    }

    setState(() {
      currentReport = {
        ...currentReport,
        ...updates,
      };

      reportedContent = null;
      isUpdatingReport = false;
    });

    return true;
  } on PostgrestException catch (e) {
    debugPrint(
      'REMOVE REPORTED PHOTO ERROR: '
      '${e.message}',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to remove the reported photo: '
          '${e.message}',
        ),
      ),
    );

    return false;
  } catch (e) {
    debugPrint(
      'REMOVE REPORTED PHOTO ERROR: $e',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to remove the reported photo.',
        ),
      ),
    );

    return false;
  }
}

  Future<bool> removeReportedPhotoComment({
  required String adminNotes,
}) async {
  if (isUpdatingReport) {
    return false;
  }

  final user = supabase.auth.currentUser;

  if (user == null) {
    return false;
  }

  final reportId =
      currentReport['id']?.toString() ?? '';

  final contentId =
      currentReport['content_id']
              ?.toString() ??
          '';

  final contentType =
      currentReport['content_type']
              ?.toString() ??
          '';

  if (reportId.isEmpty ||
      contentId.isEmpty ||
      contentType != 'photo_comment') {
    return false;
  }

  setState(() {
    isUpdatingReport = true;
  });

  try {
    // Delete only the exact reported photo comment.
    await supabase
        .from('Photo_Comments')
        .delete()
        .eq('id', contentId);

    // Confirm that the reported comment is actually gone
    // before recording a successful moderation action.
    final remainingComment = await supabase
        .from('Photo_Comments')
        .select('id')
        .eq('id', contentId)
        .maybeSingle();

    if (remainingComment != null) {
      throw Exception(
        'Reported photo comment still exists after deletion.',
      );
    }

    final completedAt =
        DateTime.now()
            .toUtc()
            .toIso8601String();

    final finalNotes =
        adminNotes.trim().isEmpty
            ? 'Reported photo comment removed by moderator.'
            : 'Reported photo comment removed by moderator.\n\n'
                '${adminNotes.trim()}';

    final updates = <String, dynamic>{
      'status': 'action_taken',
      'reviewed_by': user.id,
      'reviewed_at': completedAt,
      'admin_notes': finalNotes,
    };

    await supabase
        .from('Content_Reports')
        .update(updates)
        .eq('id', reportId);

    if (!mounted) {
      return true;
    }

    setState(() {
      currentReport = {
        ...currentReport,
        ...updates,
      };

      reportedContent = null;
      isUpdatingReport = false;
    });

    return true;
  } on PostgrestException catch (e) {
    debugPrint(
      'REMOVE REPORTED PHOTO COMMENT ERROR: '
      '${e.message}',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to remove the reported '
          'photo comment: ${e.message}',
        ),
      ),
    );

    return false;
  } catch (e) {
    debugPrint(
      'REMOVE REPORTED PHOTO COMMENT ERROR: $e',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to remove the reported photo comment.',
        ),
      ),
    );

    return false;
  }
}

  Future<void> confirmRemoveReportedPhoto() async {
  String draftNotes = '';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor:
            FolktriColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(22),
        ),
        title: const Text(
          'Remove reported photo?',
          style: TextStyle(
            color:
                FolktriColors.midnightIndigo,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'This will remove the reported photo '
              'from Folktri\'s photo feed.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'The underlying stored image will not be '
              'deleted during this moderation action. '
              'This helps prevent a shared milestone '
              'image from being broken.',
              style: TextStyle(
                color:
                    FolktriColors.dustyRose,
                fontSize: 13,
                height: 1.4,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'The moderation report will remain as '
              'an internal record. This does not '
              'suspend the member or remove them '
              'from the family.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              initialValue: '',
              maxLength: 1800,
              maxLines: 4,
              onChanged: (value) {
                draftNotes = value;
              },
              decoration: InputDecoration(
                labelText:
                    'Additional admin notes (optional)',
                alignLabelWithHint: true,
                filled: true,
                fillColor:
                    FolktriColors.background,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(false);
            },
            child:
                const Text('Cancel'),
          ),

          FilledButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(true);
            },
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  FolktriColors.dustyRose,
              foregroundColor:
                  FolktriColors.surface,
            ),
            child: const Text(
              'Remove Photo',
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true ||
      !mounted) {
    return;
  }

  final success =
      await removeReportedPhoto(
    adminNotes: draftNotes.trim(),
  );

  if (!success || !mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
      .showSnackBar(
    const SnackBar(
      content: Text(
        'Reported photo removed.',
      ),
    ),
  );
}

  Future<void> confirmRemoveReportedPhotoComment() async {
  String draftNotes = '';

  final isReply =
      reportedContent?['parent_comment_id']
                  ?.toString()
                  .isNotEmpty ==
              true;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: FolktriColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          isReply
              ? 'Remove reported photo reply?'
              : 'Remove reported photo comment?',
          style: const TextStyle(
            color: FolktriColors.midnightIndigo,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              isReply
                  ? 'This will permanently remove this '
                      'reported reply from the photo.'
                  : 'This will permanently remove this '
                      'reported comment from the photo.',
              style: const TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            if (!isReply) ...[
              const SizedBox(height: 12),
              const Text(
                'If this comment has replies, those '
                'replies may also be removed with the '
                'comment thread.',
                style: TextStyle(
                  color: FolktriColors.dustyRose,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 12),

            const Text(
              'The moderation report will remain as '
              'an internal record. This does not '
              'suspend the member or remove them '
              'from the family.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              initialValue: '',
              maxLength: 1800,
              maxLines: 4,
              onChanged: (value) {
                draftNotes = value;
              },
              decoration: InputDecoration(
                labelText:
                    'Additional admin notes (optional)',
                alignLabelWithHint: true,
                filled: true,
                fillColor:
                    FolktriColors.background,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext)
                  .pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext)
                  .pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  FolktriColors.dustyRose,
              foregroundColor:
                  FolktriColors.surface,
            ),
            child: Text(
              isReply
                  ? 'Remove Reply'
                  : 'Remove Comment',
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !mounted) {
    return;
  }

  final success =
      await removeReportedPhotoComment(
    adminNotes: draftNotes.trim(),
  );

  if (!success || !mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        isReply
            ? 'Reported photo reply removed.'
            : 'Reported photo comment removed.',
      ),
    ),
  );
}

  Future<void> confirmRemoveReportedComment() async {
    String draftNotes = '';

    final isReply =
      reportedContent?['parent_comment_id']
                  ?.toString()
                  .isNotEmpty ==
              true;

  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor:
            FolktriColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(22),
        ),
        title: Text(
          isReply
              ? 'Remove reported reply?'
              : 'Remove reported comment?',
          style: const TextStyle(
            color:
                FolktriColors.midnightIndigo,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              isReply
                  ? 'This will permanently remove this '
                      'reported reply.'
                  : 'This will permanently remove this '
                      'reported comment.',
              style: const TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            if (!isReply) ...[
              const SizedBox(height: 12),

              const Text(
                'If this comment has replies, those '
                'replies will also be removed because '
                'they belong to this comment thread.',
                style: TextStyle(
                  color:
                      FolktriColors.dustyRose,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 12),

            const Text(
              'The moderation report will remain as '
              'an internal record. This does not '
              'suspend the member or remove them '
              'from the family.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              initialValue: '',
              maxLength: 1800,
              maxLines: 4,
              onChanged: (value) {
                draftNotes = value;
              },
              decoration: InputDecoration(
                labelText:
                    'Additional admin notes (optional)',
                alignLabelWithHint: true,
                filled: true,
                fillColor:
                    FolktriColors.background,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(false);
            },
            child: const Text('Cancel'),
          ),

          FilledButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(true);
            },
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  FolktriColors.dustyRose,
              foregroundColor:
                  FolktriColors.surface,
            ),
            child: Text(
              isReply
                  ? 'Remove Reply'
                  : 'Remove Comment',
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true ||
      !mounted) {
    return;
  }

  final success =
      await removeReportedPostComment(
    adminNotes: draftNotes.trim(),
  );

  if (!success || !mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      content: Text(
        isReply
            ? 'Reported reply removed.'
            : 'Reported comment removed.',
      ),
    ),
  );
}

  Future<void> confirmRemoveReportedPost() async {
  String draftNotes = '';

  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor:
            FolktriColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(22),
        ),
        title: const Text(
          'Remove reported post?',
          style: TextStyle(
            color:
                FolktriColors.midnightIndigo,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently remove this Family Post '
              'from the family feed. The moderation report '
              'will remain as an internal record.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'This does not suspend the member or remove '
              'them from the family.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              initialValue: '',
              maxLength: 1800,
              maxLines: 4,
              onChanged: (value) {
                draftNotes = value;
              },
              decoration: InputDecoration(
                labelText:
                    'Additional admin notes (optional)',
                alignLabelWithHint: true,
                filled: true,
                fillColor:
                    FolktriColors.background,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(false);
            },
            child: const Text(
              'Cancel',
            ),
          ),

          FilledButton(
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  FolktriColors.dustyRose,
              foregroundColor:
                  FolktriColors.surface,
            ),
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(true);
            },
            child: const Text(
              'Remove Post',
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true ||
      !mounted) {
    return;
  }

  final success =
      await removeReportedFamilyPost(
    adminNotes: draftNotes.trim(),
  );

  if (!success || !mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
      .showSnackBar(
    const SnackBar(
      content: Text(
        'Reported Family Post removed.',
      ),
    ),
  );
}

  Future<bool> updateReportStatus({required String newStatus, String? adminNotes}) async {
    if (isUpdatingReport) {
      return false;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final reportId = currentReport['id']?.toString();

    if (reportId == null || reportId.isEmpty) {
      return false;
    }

    setState(() {
      isUpdatingReport = true;
    });

    try {
      final updates = <String, dynamic>{
        'status': newStatus,
      };

    // Starting review records who began
    // reviewing the report.
      if (newStatus == 'under_review') {
        updates['reviewed_by'] = user.id;
        updates['reviewed_at'] = DateTime.now().toUtc().toIso8601String();
      }

    // A final moderation decision also records
    // the reviewing admin and completion time.
    if (newStatus == 'dismissed' || newStatus == 'action_taken') {
      updates['reviewed_by'] = user.id;
      updates['reviewed_at'] = DateTime.now().toUtc().toIso8601String();

      if (adminNotes != null && adminNotes.trim().isNotEmpty) {
        updates['admin_notes'] = adminNotes.trim();
      }
    }

    await supabase
        .from('Content_Reports')
        .update(updates)
        .eq('id', reportId);

    if (!mounted) {
      return true;
    }

    setState(() {
      currentReport = {
        ...currentReport,
        ...updates,
      };

      isUpdatingReport = false;
    });

    return true;
  } on PostgrestException catch (e) {
    debugPrint(
      'UPDATE MODERATION REPORT ERROR: '
      '${e.message}',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to update this report.',
        ),
      ),
    );

    return false;
  } catch (e) {
    debugPrint(
      'UPDATE MODERATION REPORT ERROR: $e',
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      isUpdatingReport = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to update this report.',
        ),
      ),
    );

    return false;
  }
}

  Future<void> showDecisionDialog({
  required String decision,
}) async {
  final isDismissal =
      decision == 'dismissed';

  final existingNotes =
      currentReport['admin_notes']
              ?.toString() ??
          '';

  String draftNotes = existingNotes;

  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor:
            FolktriColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(22),
        ),
        title: Text(
          isDismissal
              ? 'Dismiss report?'
              : 'Record action taken?',
          style: const TextStyle(
            color:
                FolktriColors.midnightIndigo,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              isDismissal
                  ? 'This will close the report as dismissed.'
                  : 'This records that moderation action was taken. '
                      'It does not automatically suspend the user '
                      'or delete their content.',
              style: const TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              initialValue: existingNotes,
              maxLength: 2000,
              maxLines: 5,
              onChanged: (value) {
                draftNotes = value;
              },
              decoration: InputDecoration(
                labelText:
                    'Internal admin notes (optional)',
                alignLabelWithHint: true,
                filled: true,
                fillColor:
                    FolktriColors.background,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(false);
            },
            child: const Text(
              'Cancel',
            ),
          ),

          FilledButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(true);
            },
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  isDismissal
                      ? FolktriColors
                          .secondaryText
                      : FolktriColors
                          .connectionTeal,
            ),
            child: Text(
              isDismissal
                  ? 'Dismiss'
                  : 'Record Action',
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true ||
      !mounted) {
    return;
  }

  final success =
      await updateReportStatus(
    newStatus: decision,
    adminNotes: draftNotes.trim(),
  );

  if (!success || !mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      content: Text(
        isDismissal
            ? 'Report dismissed.'
            : 'Moderation action recorded.',
      ),
    ),
  );
}

  String getProfileName(
    Map<String, dynamic>? profile,
  ) {
    if (profile == null) {
      return 'Unavailable';
    }

    final firstName =
        profile['first_name']?.toString().trim() ?? '';

    final lastName =
        profile['last_name']?.toString().trim() ?? '';

    final fullName = [
      firstName,
      lastName,
    ].where((name) => name.isNotEmpty).join(' ');

    if (fullName.isEmpty) {
      return 'Family member';
    }

    return fullName;
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
      case 'photo_comment':
        return 'Photo Comment';
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

  Widget buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: FolktriColors.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
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
          child: child,
        ),
      ],
    );
  }

  Widget buildLabelValue({
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FolktriColors.secondaryText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value,
            style: const TextStyle(
              color: FolktriColors.primaryText,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReportedContent() {
  final contentType =
      currentReport['content_type']?.toString() ?? '';

  final status =
      currentReport['status']?.toString() ?? '';

  // --------------------------------------------------
  // FAMILY POST
  // --------------------------------------------------

  if (contentType == 'family_post') {
    if (reportedContent == null) {
      if (status == 'action_taken') {
        return const Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color:
                  FolktriColors.connectionTeal,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This reported Family Post was removed '
                'through moderation.',
                style: TextStyle(
                  color:
                      FolktriColors.secondaryText,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      }

      return const Text(
        'The reported Family Post could not be loaded. '
        'It may no longer exist.',
        style: TextStyle(
          color:
              FolktriColors.secondaryText,
          fontSize: 13.5,
          height: 1.4,
        ),
      );
    }

    final postText =
        reportedContent!['post_text']
                ?.toString()
                .trim() ??
            '';

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FolktriColors
                    .lightLavender
                    .withValues(alpha: 0.65),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color:
                    FolktriColors.primaryIndigo,
                size: 19,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                getProfileName(
                  reportedUserProfile,
                ),
                style: const TextStyle(
                  color:
                      FolktriColors.midnightIndigo,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          postText.isEmpty
              ? 'No post text available.'
              : postText,
          style: const TextStyle(
            color:
                FolktriColors.primaryText,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // FAMILY POST COMMENT / REPLY
  // --------------------------------------------------

  if (contentType == 'post_comment') {
  if (reportedContent == null) {
    final status =
        currentReport['status']?.toString() ?? '';

    if (status == 'action_taken') {
      return const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color:
                FolktriColors.connectionTeal,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This reported comment was removed '
              'through moderation.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    }

    return const Text(
      'The reported comment could not be loaded. '
      'It may no longer exist.',
      style: TextStyle(
        color:
            FolktriColors.secondaryText,
        fontSize: 13.5,
        height: 1.4,
      ),
    );
  }

  final commentText =
      reportedContent!['comment_text']
              ?.toString()
              .trim() ??
          '';

  final parentCommentId =
      reportedContent!['parent_comment_id']
          ?.toString();

  final isReply =
      parentCommentId != null &&
      parentCommentId.isNotEmpty;

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FolktriColors
                  .lightLavender
                  .withValues(alpha: 0.65),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              isReply
                  ? Icons.reply_rounded
                  : Icons
                      .chat_bubble_outline_rounded,
              color:
                  FolktriColors.primaryIndigo,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  getProfileName(
                    reportedUserProfile,
                  ),
                  style: const TextStyle(
                    color: FolktriColors
                        .midnightIndigo,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                if (isReply)
                  const Text(
                    'Reply',
                    style: TextStyle(
                      color: FolktriColors
                          .secondaryText,
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 14),

      Text(
        commentText.isEmpty
            ? 'No comment text available.'
            : commentText,
        style: const TextStyle(
          color: FolktriColors.primaryText,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    ],
  );
}

// --------------------------------------------------
// PHOTO COMMENT / REPLY
// --------------------------------------------------

if (contentType == 'photo_comment') {
  if (reportedContent == null) {
    if (status == 'action_taken') {
      return const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color:
                FolktriColors.connectionTeal,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This reported photo comment was removed '
              'through moderation.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    }

    return const Text(
      'The reported photo comment could not be loaded. '
      'It may no longer exist.',
      style: TextStyle(
        color:
            FolktriColors.secondaryText,
        fontSize: 13.5,
        height: 1.4,
      ),
    );
  }

  final commentText =
      reportedContent!['comment_text']
              ?.toString()
              .trim() ??
          '';

  final parentCommentId =
      reportedContent!['parent_comment_id']
          ?.toString();

  final isReply =
      parentCommentId != null &&
      parentCommentId.isNotEmpty;

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FolktriColors
                  .lightLavender
                  .withValues(alpha: 0.65),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              isReply
                  ? Icons.reply_rounded
                  : Icons
                      .chat_bubble_outline_rounded,
              color:
                  FolktriColors.primaryIndigo,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  getProfileName(
                    reportedUserProfile,
                  ),
                  style: const TextStyle(
                    color: FolktriColors
                        .midnightIndigo,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                Text(
                  isReply
                      ? 'Reply on photo'
                      : 'Comment on photo',
                  style: const TextStyle(
                    color: FolktriColors
                        .secondaryText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 14),

      Text(
        commentText.isEmpty
            ? 'No comment text available.'
            : commentText,
        style: const TextStyle(
          color:
              FolktriColors.primaryText,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    ],
  );
}

// --------------------------------------------------
// PHOTO
// --------------------------------------------------

if (contentType == 'photo') {
  if (reportedContent == null) {
    if (status == 'action_taken') {
      return const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color:
                FolktriColors.connectionTeal,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This reported photo was removed '
              'through moderation.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    }

    return const Text(
      'The reported photo could not be loaded. '
      'It may no longer exist.',
      style: TextStyle(
        color:
            FolktriColors.secondaryText,
        fontSize: 13.5,
        height: 1.4,
      ),
    );
  }

  final photoUrl =
      reportedContent!['photo_url']
              ?.toString()
              .trim() ??
          '';

  final caption =
      reportedContent!['caption']
              ?.toString()
              .trim() ??
          '';

  final createdAt =
      DateTime.tryParse(
    reportedContent!['created_at']
            ?.toString() ??
        '',
  )?.toLocal();

  final dateLabel =
      createdAt == null
          ? 'Date unavailable'
          : '${createdAt.month}/'
              '${createdAt.day}/'
              '${createdAt.year}';

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FolktriColors
                  .lightLavender
                  .withValues(alpha: 0.65),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_outlined,
              color:
                  FolktriColors.primaryIndigo,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  getProfileName(
                    reportedUserProfile,
                  ),
                  style: const TextStyle(
                    color:
                        FolktriColors.midnightIndigo,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                Text(
                  dateLabel,
                  style: const TextStyle(
                    color:
                        FolktriColors.secondaryText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      if (caption.isNotEmpty) ...[
        const SizedBox(height: 14),

        Text(
          caption,
          style: const TextStyle(
            color:
                FolktriColors.primaryText,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],

      if (photoUrl.isNotEmpty) ...[
        const SizedBox(height: 14),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(14),
          child: Image.network(
            photoUrl,
            width: double.infinity,
            height: 260,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                width: double.infinity,
                height: 180,
                alignment:
                    Alignment.center,
                color:
                    FolktriColors.lightLavender,
                child: const Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color:
                          FolktriColors.primaryIndigo,
                      size: 36,
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Photo unavailable',
                      style: TextStyle(
                        color:
                            FolktriColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],

      if (photoUrl.isEmpty) ...[
        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                FolktriColors.background,
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color:
                    FolktriColors.secondaryText,
                size: 30,
              ),

              SizedBox(height: 8),

              Text(
                'No photo URL available.',
                style: TextStyle(
                  color:
                      FolktriColors.secondaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

  // --------------------------------------------------
  // OTHER REPORT TYPES
  // --------------------------------------------------

  return Text(
    'Review support for '
    '${formatContentType(contentType)} '
    'reports will be added separately.',
    style: const TextStyle(
      color:
          FolktriColors.secondaryText,
      fontSize: 13.5,
      height: 1.4,
    ),
  );
}

  Widget buildModerationActions() {
  final status =
      currentReport['status']?.toString() ??
          'pending';

  if (status == 'dismissed' ||
      status == 'action_taken') {
    final adminNotes =
        currentReport['admin_notes']
                ?.toString()
                .trim() ??
            '';

    return buildSection(
      title: 'Review Decision',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'dismissed'
                    ? Icons.cancel_outlined
                    : Icons
                        .verified_user_outlined,
                color: status == 'dismissed'
                    ? FolktriColors
                        .secondaryText
                    : FolktriColors
                        .connectionTeal,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  formatStatus(status),
                  style: const TextStyle(
                    color: FolktriColors
                        .midnightIndigo,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          if (adminNotes.isNotEmpty) ...[
            const SizedBox(height: 16),

            const Text(
              'Internal notes',
              style: TextStyle(
                color: FolktriColors
                    .secondaryText,
                fontSize: 11.5,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              adminNotes,
              style: const TextStyle(
                color:
                    FolktriColors.primaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  return buildSection(
    title: 'Moderation',
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        if (status == 'pending')
          FilledButton.icon(
            onPressed: isUpdatingReport
                ? null
                : () async {
                    final success =
                        await updateReportStatus(
                      newStatus:
                          'under_review',
                    );

                    if (!success ||
                        !mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Report marked as under review.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(
              Icons.visibility_outlined,
            ),
            label: const Text(
              'Start Review',
            ),
            style: FilledButton.styleFrom(
              backgroundColor:
                  FolktriColors.primaryIndigo,
              foregroundColor:
                  FolktriColors.surface,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 14,
              ),
            ),
          ),

        if (status == 'under_review') ...[
  // ---------------------------------------------
  // FAMILY POST MODERATION ACTION
  // ---------------------------------------------
  if (currentReport['content_type']
          ?.toString() ==
      'family_post')
    FilledButton.icon(
      onPressed: isUpdatingReport
          ? null
          : confirmRemoveReportedPost,
      icon: const Icon(
        Icons.delete_outline_rounded,
      ),
      label: const Text(
        'Remove Reported Post',
      ),
      style: FilledButton.styleFrom(
        backgroundColor:
            FolktriColors.dustyRose,
        foregroundColor:
            FolktriColors.surface,
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
      ),
    ),

  if (currentReport['content_type']
          ?.toString() ==
      'family_post')
    const SizedBox(height: 10),

  // ---------------------------------------------
  // COMMENT / REPLY MODERATION ACTION
  // ---------------------------------------------
  if (currentReport['content_type']
          ?.toString() ==
      'post_comment')
    FilledButton.icon(
      onPressed: isUpdatingReport
          ? null
          : confirmRemoveReportedComment,
      icon: const Icon(
        Icons.delete_outline_rounded,
      ),
      label: const Text(
        'Remove Reported Comment',
      ),
      style: FilledButton.styleFrom(
        backgroundColor:
            FolktriColors.dustyRose,
        foregroundColor:
            FolktriColors.surface,
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
      ),
    ),

  if (currentReport['content_type']
          ?.toString() ==
      'post_comment')
    const SizedBox(height: 10),

    // ---------------------------------------------
// PHOTO COMMENT / REPLY MODERATION ACTION
// ---------------------------------------------

if (currentReport['content_type']
        ?.toString() ==
    'photo_comment')
  FilledButton.icon(
    onPressed: isUpdatingReport
        ? null
        : confirmRemoveReportedPhotoComment,
    icon: const Icon(
      Icons.delete_outline_rounded,
    ),
    label: const Text(
      'Remove Reported Comment',
    ),
    style: FilledButton.styleFrom(
      backgroundColor:
          FolktriColors.dustyRose,
      foregroundColor:
          FolktriColors.surface,
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
    ),
  ),

if (currentReport['content_type']
        ?.toString() ==
    'photo_comment')
  const SizedBox(height: 10),

  if (currentReport['content_type']
        ?.toString() ==
    'photo')
  FilledButton.icon(
    onPressed: isUpdatingReport
        ? null
        : confirmRemoveReportedPhoto,
    icon: const Icon(
      Icons.delete_outline_rounded,
    ),
    label: const Text(
      'Remove Reported Photo',
    ),
    style: FilledButton.styleFrom(
      backgroundColor:
          FolktriColors.dustyRose,
      foregroundColor:
          FolktriColors.surface,
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
      ),
    ),
  ),

if (currentReport['content_type']
        ?.toString() ==
    'photo')
  const SizedBox(height: 10),

  // ---------------------------------------------
  // AVAILABLE FOR ALL UNDER-REVIEW REPORTS
  // ---------------------------------------------
  OutlinedButton.icon(
    onPressed: isUpdatingReport
        ? null
        : () {
            showDecisionDialog(
              decision: 'dismissed',
            );
          },
    icon: const Icon(
      Icons.close_rounded,
    ),
    label: const Text(
      'Dismiss Report',
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor:
          FolktriColors.secondaryText,
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
      ),
    ),
  ),
],

        if (isUpdatingReport) ...[
          const SizedBox(height: 14),

          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.4,
                color: FolktriColors
                    .primaryIndigo,
              ),
            ),
          ),
        ],
      ],
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
            'You do not have access to this moderation report.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FolktriColors.secondaryText,
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FolktriColors.secondaryText,
            ),
          ),
        ),
      );
    }

    final reason =
        currentReport['reason']?.toString() ?? '';

    final status =
        currentReport['status']?.toString() ?? '';

    final contentType =
        currentReport['content_type']?.toString() ?? '';

    final details =
        currentReport['details']
                ?.toString()
                .trim() ??
            '';

    return RefreshIndicator(
      color: FolktriColors.primaryIndigo,
      onRefresh: initializePage,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          40,
        ),
        children: [
          buildSection(
            title: 'Report',
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                buildLabelValue(
                  label: 'Reason',
                  value: formatReason(reason),
                ),
                buildLabelValue(
                  label: 'Content type',
                  value:
                      formatContentType(contentType),
                ),
                buildLabelValue(
                  label: 'Status',
                  value: formatStatus(status),
                ),
                buildLabelValue(
                  label: 'Details',
                  value: details.isEmpty
                      ? 'No additional details provided.'
                      : details,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          buildSection(
            title: 'Reported Content',
            child: buildReportedContent(),
          ),

          const SizedBox(height: 22),

          buildSection(
            title: 'People',
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                buildLabelValue(
                  label: 'Reported user',
                  value: getProfileName(
                    reportedUserProfile,
                  ),
                ),
                buildLabelValue(
                  label: 'Reporter',
                  value: getProfileName(
                    reporterProfile,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          buildSection(
            title: 'Internal Reference',
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                buildLabelValue(
                  label: 'Report ID',
                  value:
                      currentReport['id']?.toString() ??
                          '',
                ),
                buildLabelValue(
                  label: 'Content ID',
                  value:
                      currentReport['content_id']
                              ?.toString() ??
                          '',
                ),
                buildLabelValue(
                  label: 'Family ID',
                  value:
                      currentReport['family_id']
                              ?.toString() ??
                          '',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          buildModerationActions(),
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
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          'Report Details',
          style: TextStyle(
            fontSize: 21,
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