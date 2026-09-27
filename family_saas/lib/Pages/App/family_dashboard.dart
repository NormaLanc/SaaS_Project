import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Styling/folktri_colors.dart';
import 'package:google_fonts/google_fonts.dart';



class FamilyDashboard extends StatefulWidget {
  final String? targetPhotoId;

  const FamilyDashboard({
    super.key,
    this.targetPhotoId,
  });


  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}


class _FamilyDashboardState extends State<FamilyDashboard> {

  bool isLoading = true;
  bool hasApprovedFamily = false;

  List<Map<String, dynamic>> feedItems = [];
  bool isLoadingFeed = true;

  final Map<String, GlobalKey> photoCardKeys = {};

  String? highlightedPhotoId;

  bool hasScrolledToTargetPhoto = false;

  Map<String, int> photoLikeCounts = {};
  Set<String> likedPhotoIds = {};

  bool isUpdatingLike = false;

  Map<String, int> photoCommentCounts = {};

  List<Map<String, dynamic>> upcomingEvents = [];
  bool isLoadingEvents = true;

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> families = [];

  String? selectedFamilyId;

  Map<String, dynamic>? userProfile;

  String? profilePhotoUrl;

  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    checkFamilyMembership();
    loadFeed();
    loadUpcomingEvents();
    loadUserProfile();
  }

Future<void> checkFamilyMembership() async {
  try {
    final user =
        supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        families = [];
        selectedFamilyId = null;
        hasApprovedFamily = false;
        isLoading = false;
      });

      return;
    }

    // ==========================================
    // FAMILIES CREATED BY THE USER
    // ==========================================

    final createdFamiliesResponse =
        await supabase
            .from('Families')
            .select(
              'id, family_name',
            )
            .eq(
              'created_by',
              user.id,
            );

    final createdFamilies =
        List<Map<String, dynamic>>.from(
      createdFamiliesResponse,
    );

    // ==========================================
    // FAMILIES THE USER JOINED
    // ==========================================

    final membershipResponse =
        await supabase
            .from('Family_Members')
            .select(
              'family_id',
            )
            .eq(
              'user_id',
              user.id,
            )
            .eq(
              'status',
              'approved',
            );

    final memberships =
        List<Map<String, dynamic>>.from(
      membershipResponse,
    );

    debugPrint('APPROVED MEMBERSHIPS: $memberships',);

    final joinedFamilyIds =
        memberships.map(
              (membership) => membership['family_id']
                      ?.toString(),
            )
            .whereType<String>()
            .toList();

    List<Map<String, dynamic>> joinedFamilies = [];

    if (joinedFamilyIds.isNotEmpty) {
      final joinedFamiliesResponse =
          await supabase
              .from('Families')
              .select(
                'id, family_name',
              )
              .inFilter(
                'id',
                joinedFamilyIds,
              );

      joinedFamilies =
          List<Map<String, dynamic>>.from(
        joinedFamiliesResponse,
      );

      debugPrint('JOINED FAMILIES: $joinedFamilies',);
    }

    // ==========================================
    // COMBINE BOTH LISTS
    // ==========================================

    final combinedFamilies = [
      ...createdFamilies,
      ...joinedFamilies,
    ];

    // Remove duplicates.
    final uniqueFamilies =
        <String, Map<String, dynamic>>{};

    for (final family
        in combinedFamilies) {
      final familyId =
          family['id'].toString();

      uniqueFamilies[familyId] =
          family;
    }

    final finalFamilies =
        uniqueFamilies.values.toList();

    finalFamilies.sort(
      (a, b) {
        final aName =
            a['family_name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final bName =
            b['family_name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return aName.compareTo(
          bName,
        );
      },
    );

    if (!mounted) return;

    setState(() {
      families = finalFamilies;

      hasApprovedFamily =
          finalFamilies.isNotEmpty;

      // IMPORTANT:
      // Make sure the selected family
      // still actually exists.
      final selectedStillExists =
          selectedFamilyId != null &&
          finalFamilies.any(
            (family) =>
                family['id']
                    .toString() ==
                selectedFamilyId,
          );

      if (selectedStillExists) {
        // Keep the current selection.
      } else if (finalFamilies.isNotEmpty) {
        selectedFamilyId =
            finalFamilies.first['id']
                .toString();
      } else {
        selectedFamilyId = null;
      }

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
          'Error loading families: $e',
        ),
      ),
    );
  }
}

//Dialog box to ask the user if they want to join an existing family or create a new one
void showFamilyOptions() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Add a Family"),

          content: const Text(
            "Would you like to join an existing family or create a new one?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                context.push('/join-family');
              },
              child: const Text("Join Existing Family"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                context.push('/create-family');
              },
              child: const Text("Create New Family"),
            ),
          ],
        );
      },
    );
  }

Future<void> loadFeed() async {
  try {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final membershipResponse = await supabase
        .from('Family_Members')
        .select('family_id')
        .eq('user_id', user.id)
        .eq('status', 'approved');

    final memberships =
        List<Map<String, dynamic>>.from(
      membershipResponse,
    );

    final familyIds = memberships
        .map(
          (membership) =>
              membership['family_id'],
        )
        .where(
          (id) => id != null,
        )
        .toList();

    if (familyIds.isEmpty) {
      if (!mounted) return;

      setState(() {
        feedItems = [];
        isLoadingFeed = false;
      });

      return;
    }

    final milestoneResponse = await supabase
        .from('Milestones')
        .select(
          '''
          id,
          family_id,
          child_id,
          title,
          description,
          milestone_date,
          photo_url,
          created_at,
          Children(
            first_name,
            middle_name,
            last_name
          )
          ''',
        )
        .inFilter(
          'family_id',
          familyIds,
        )
        .order(
          'created_at',
          ascending: false,
        );

    final photoResponse = await supabase
    .from('Photos')
    .select(
      '''
      id,
      family_id,
      child_id,
      photo_url,
      caption,
      created_at,
      Children(
        first_name,
        middle_name,
        last_name
      )
      ''',
    )
    .inFilter(
      'family_id',
      familyIds,
    )
    .order(
      'created_at',
      ascending: false,
    );


    final photos =
        List<Map<String, dynamic>>.from(
      photoResponse,
    );

    final milestones =
        List<Map<String, dynamic>>.from(
      milestoneResponse,
    );

    final milestoneFeed = milestones.map(
      (milestone) {
        return {
          'type': 'milestone',
          'id': milestone['id'],
          'family_id': milestone['family_id'],
          'child_id': milestone['child_id'],
          'title': milestone['title'],
          'description': milestone['description'],
          'photo_url': milestone['photo_url'],
          'event_date': milestone['milestone_date'],
          'created_at': milestone['created_at'],
          'child': milestone['Children'],
        };
      },
    ).toList();

    final photoFeed = photos.map(
      (photo) {
        return {
          'type': 'photo',
          'id': photo['id'],
          'family_id': photo['family_id'],
          'child_id': photo['child_id'],
          'photo_url': photo['photo_url'],
          'caption': photo['caption'],
          'created_at': photo['created_at'],
          'child': photo['Children'],
        };
      },
    ).toList();
    
    final combinedFeed = [
      ...milestoneFeed,
      ...photoFeed,
    ];

    combinedFeed.sort(
      (a, b) {
        final aDate =
          DateTime.parse(
            a['created_at']
              .toString(),
          );

        final bDate =
          DateTime.parse(
            b['created_at']
              .toString(),
          );

    return bDate.compareTo(
      aDate,
    );
  },
);

    if (!mounted) return;

    setState(() {
      feedItems = combinedFeed;
      isLoadingFeed = false;
    });

    await loadPhotoLikes();
    await loadPhotoCommentCounts();

    await scrollToTargetPhoto();
  } catch (e) {
    debugPrint(
      'Unable to load dashboard feed: $e',
    );

    if (!mounted) return;

    setState(() {
      isLoadingFeed = false;
    });
  }
}

Future<void> scrollToTargetPhoto() async {
  final targetPhotoId =
      widget.targetPhotoId;

  if (targetPhotoId == null ||
      targetPhotoId.isEmpty ||
      hasScrolledToTargetPhoto) {
    return;
  }

  final targetExists = feedItems.any(
    (item) =>
        item['type'] == 'photo' &&
        item['id']?.toString() ==
            targetPhotoId,
  );

  if (!targetExists) {
    debugPrint(
      'Target photo is not in the dashboard feed: '
      '$targetPhotoId',
    );
    return;
  }

  hasScrolledToTargetPhoto = true;

  // Wait for Flutter to actually build the feed cards.
  WidgetsBinding.instance
      .addPostFrameCallback((_) async {
    if (!mounted) return;

    final targetKey =
        photoCardKeys[targetPhotoId];

    final targetContext =
        targetKey?.currentContext;

    if (targetContext == null) {
      // The feed may still be laying itself out.
      hasScrolledToTargetPhoto = false;

      await Future.delayed(
        const Duration(
          milliseconds: 250,
        ),
      );

      if (!mounted) return;

      await scrollToTargetPhoto();

      return;
    }

    setState(() {
      highlightedPhotoId =
          targetPhotoId;
    });

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(
        milliseconds: 650,
      ),
      curve: Curves.easeInOut,
      alignment: 0.15,
    );

    await Future.delayed(
      const Duration(
        seconds: 2,
      ),
    );

    if (!mounted) return;

    if (highlightedPhotoId ==
        targetPhotoId) {
      setState(() {
        highlightedPhotoId = null;
      });
    }
  });
}

Future<void> loadPhotoLikes() async {
  final user = supabase.auth.currentUser;

  if (user == null) return;

  try {
    final photoIds = feedItems
        .where(
          (item) => item['type'] == 'photo',
        )
        .map(
          (item) => item['id']?.toString(),
        )
        .whereType<String>()
        .where(
          (id) => id.isNotEmpty,
        )
        .toList();

    if (photoIds.isEmpty) {
      if (!mounted) return;

      setState(() {
        photoLikeCounts = {};
        likedPhotoIds = {};
      });

      return;
    }

    final response = await supabase
        .from('Photo_Likes')
        .select(
          'photo_id, user_id',
        )
        .inFilter(
          'photo_id',
          photoIds,
        );

    final likes =
        List<Map<String, dynamic>>.from(
      response,
    );

    final counts = <String, int>{};
    final currentUserLikes = <String>{};

    for (final like in likes) {
      final photoId =
          like['photo_id']?.toString();

      final userId =
          like['user_id']?.toString();

      if (photoId == null) {
        continue;
      }

      counts[photoId] =
          (counts[photoId] ?? 0) + 1;

      if (userId == user.id) {
        currentUserLikes.add(photoId);
      }
    }

    if (!mounted) return;

    setState(() {
      photoLikeCounts = counts;
      likedPhotoIds = currentUserLikes;
    });
  } catch (e) {
    debugPrint(
      'Unable to load photo likes: $e',
    );
  }
}

Future<void> loadPhotoCommentCounts() async {
  try {
    final photoIds = feedItems
        .where(
          (item) => item['type'] == 'photo',
        )
        .map(
          (item) => item['id']?.toString(),
        )
        .whereType<String>()
        .where(
          (id) => id.isNotEmpty,
        )
        .toList();

    if (photoIds.isEmpty) {
      if (!mounted) return;

      setState(() {
        photoCommentCounts = {};
      });

      return;
    }

    final response = await supabase
        .from('Photo_Comments')
        .select('photo_id')
        .inFilter(
          'photo_id',
          photoIds,
        );

    final comments =
        List<Map<String, dynamic>>.from(
      response,
    );

    final counts = <String, int>{};

    for (final comment in comments) {
      final photoId =
          comment['photo_id']?.toString();

      if (photoId == null ||
          photoId.isEmpty) {
        continue;
      }

      counts[photoId] =
          (counts[photoId] ?? 0) + 1;
    }

    if (!mounted) return;

    setState(() {
      photoCommentCounts = counts;
    });
  } catch (e) {
    debugPrint(
      'Unable to load photo comment counts: $e',
    );
  }
}

Future<void> createPhotoLikeNotification({
  required String photoId,
}) async {
  final currentUser =
      supabase.auth.currentUser;

  if (currentUser == null) return;

  try {
    // Get the photo so we know who created it
    // and which family it belongs to.
    final photo = await supabase
        .from('Photos')
        .select(
          '''
          id,
          family_id,
          created_by
          ''',
        )
        .eq(
          'id',
          photoId,
        )
        .maybeSingle();

    if (photo == null) return;

    final recipientUserId =
        photo['created_by']?.toString();

    final familyId =
        photo['family_id']?.toString();

    if (recipientUserId == null ||
        recipientUserId.isEmpty ||
        familyId == null ||
        familyId.isEmpty) {
      return;
    }

    // Never notify somebody that they liked
    // their own photo.
    if (recipientUserId ==
        currentUser.id) {
      return;
    }

    // Get the name of the person who liked it.
    final profile = await supabase
        .from('Profiles')
        .select(
          '''
          first_name,
          last_name
          ''',
        )
        .eq(
          'user_id',
          currentUser.id,
        )
        .maybeSingle();

    final firstName =
        profile?['first_name']
                ?.toString()
                .trim() ??
            '';

    final lastName =
        profile?['last_name']
                ?.toString()
                .trim() ??
            '';

    final actorName = [
      firstName,
      lastName,
    ].where(
      (name) => name.isNotEmpty,
    ).join(' ');

    final displayName =
        actorName.isEmpty
            ? 'A family member'
            : actorName;

    await supabase
        .from('Notifications')
        .insert({
      'recipient_user_id':
          recipientUserId,
      'requested_user_id':
          currentUser.id,
      'family_id':
          familyId,
      'type':
          'photo_like',
      'title':
          'New photo like',
      'message':
          '$displayName liked your photo.',
      'is_read':
          false,
      'status':
          'active',
      'reference_type':
          'photo',
      'reference_id': photoId,
      'action_required':
          false,
    });
  } catch (e) {
    debugPrint(
      'Unable to create photo like notification: $e',
    );
  }
}

Future<void> togglePhotoLike(String photoId,) async {
  final user = supabase.auth.currentUser;

  if (user == null ||
      isUpdatingLike) {
    return;
  }

  final isLiked =
      likedPhotoIds.contains(photoId);

  try {
    setState(() {
      isUpdatingLike = true;
    });

    if (isLiked) {
      await supabase
          .from('Photo_Likes')
          .delete()
          .eq(
            'photo_id',
            photoId,
          )
          .eq(
            'user_id',
            user.id,
          );
    } else {
      await supabase
          .from('Photo_Likes')
          .insert({
        'photo_id': photoId,
        'user_id': user.id,
      });

      await createPhotoLikeNotification(
        photoId: photoId,
      );
    }

    await loadPhotoLikes();
  } catch (e) {
    debugPrint(
      'Unable to update photo like: $e',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Unable to update like: $e',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isUpdatingLike = false;
      });
    }
  }
}

Future<void> createCommentReplyNotification({
  required String photoId,
  required String parentCommentId,
}) async {
  final currentUser =
      supabase.auth.currentUser;

  if (currentUser == null) return;

  try {
    // ==========================================
    // GET PARENT COMMENT
    // ==========================================

    final parentComment = await supabase
        .from('Photo_Comments')
        .select(
          '''
          id,
          user_id,
          photo_id
          ''',
        )
        .eq(
          'id',
          parentCommentId,
        )
        .maybeSingle();

    if (parentComment == null) {
      return;
    }

    final recipientUserId =
        parentComment['user_id']
            ?.toString();

    if (recipientUserId == null ||
        recipientUserId.isEmpty) {
      return;
    }

    // Never notify someone about replying
    // to their own comment.
    if (recipientUserId ==
        currentUser.id) {
      return;
    }

    // ==========================================
    // GET PHOTO / FAMILY
    // ==========================================

    final photo = await supabase
        .from('Photos')
        .select(
          '''
          id,
          family_id
          ''',
        )
        .eq(
          'id',
          photoId,
        )
        .maybeSingle();

    if (photo == null) {
      return;
    }

    final familyId =
        photo['family_id']
            ?.toString();

    if (familyId == null ||
        familyId.isEmpty) {
      return;
    }

    // ==========================================
    // GET REPLY AUTHOR'S NAME
    // ==========================================

    final profile = await supabase
        .from('Profiles')
        .select(
          '''
          first_name,
          last_name
          ''',
        )
        .eq(
          'user_id',
          currentUser.id,
        )
        .maybeSingle();

    final firstName =
        profile?['first_name']
                ?.toString()
                .trim() ??
            '';

    final lastName =
        profile?['last_name']
                ?.toString()
                .trim() ??
            '';

    final actorName = [
      firstName,
      lastName,
    ].where(
      (name) => name.isNotEmpty,
    ).join(' ');

    final displayName =
        actorName.isEmpty
            ? 'A family member'
            : actorName;

    // ==========================================
    // CREATE NOTIFICATION
    // ==========================================

    await supabase
        .from('Notifications')
        .insert({
      'recipient_user_id':
          recipientUserId,

      'requested_user_id':
          currentUser.id,

      'family_id':
          familyId,

      'type':
          'comment_reply',

      'title':
          'New reply',

      'message':
          '$displayName replied to your comment.',

      'is_read':
          false,

      'status':
          'active',

      // We still target the photo because that
      // is where the comment thread is displayed.
      'reference_type':
          'photo',

      'reference_id':
          photoId,

      'action_required':
          false,
    });
  } catch (e) {
    debugPrint(
      'Unable to create reply notification: $e',
    );
  }
}

Future<void> createCommentLikeNotification({
  required String commentId,
  required String photoId,
}) async {
  final currentUser =
      supabase.auth.currentUser;

  if (currentUser == null) return;

  try {
    // ==========================================
    // FIND THE EXACT COMMENT / REPLY THAT
    // RECEIVED THE LIKE
    // ==========================================

    final comment = await supabase
        .from('Photo_Comments')
        .select(
          '''
          id,
          user_id,
          photo_id
          ''',
        )
        .eq(
          'id',
          commentId,
        )
        .maybeSingle();

    if (comment == null) {
      return;
    }

    final recipientUserId =
        comment['user_id']?.toString();

    if (recipientUserId == null ||
        recipientUserId.isEmpty) {
      return;
    }

    // Don't notify someone for liking
    // their own comment.
    if (recipientUserId ==
        currentUser.id) {
      return;
    }

    // ==========================================
    // GET THE PHOTO'S FAMILY
    // ==========================================

    final photo = await supabase
        .from('Photos')
        .select(
          '''
          id,
          family_id
          ''',
        )
        .eq(
          'id',
          photoId,
        )
        .maybeSingle();

    if (photo == null) {
      return;
    }

    final familyId =
        photo['family_id']?.toString();

    if (familyId == null ||
        familyId.isEmpty) {
      return;
    }

    // ==========================================
    // GET THE PERSON WHO LIKED THE COMMENT
    // ==========================================

    final profile = await supabase
        .from('Profiles')
        .select(
          '''
          first_name,
          last_name
          ''',
        )
        .eq(
          'user_id',
          currentUser.id,
        )
        .maybeSingle();

    final firstName =
        profile?['first_name']
                ?.toString()
                .trim() ??
            '';

    final lastName =
        profile?['last_name']
                ?.toString()
                .trim() ??
            '';

    final actorName = [
      firstName,
      lastName,
    ].where(
      (name) => name.isNotEmpty,
    ).join(' ');

    final displayName =
        actorName.isEmpty
            ? 'A family member'
            : actorName;

    // ==========================================
    // CREATE NOTIFICATION
    // ==========================================

    await supabase
        .from('Notifications')
        .insert({
      'recipient_user_id':
          recipientUserId,

      'requested_user_id':
          currentUser.id,

      'family_id':
          familyId,

      'type':
          'comment_like',

      'title':
          'New comment like',

      'message':
          '$displayName liked your comment.',

      'is_read':
          false,

      'status':
          'active',

      // Navigate back to the photo containing
      // this comment/reply.
      'reference_type':
          'photo',

      'reference_id':
          photoId,

      'action_required':
          false,
    });
  } catch (e) {
    debugPrint(
      'Unable to create comment like '
      'notification: $e',
    );
  }
}

Future<void> showPhotoComments(String photoId) async {
  final currentUser = supabase.auth.currentUser;

  if (currentUser == null) return;

  final commentController = TextEditingController();

  final commentFocusNode = FocusNode();

  List<Map<String, dynamic>> comments = [];

  bool isLoadingComments = true;
  bool isPostingComment = false;

  Map<String, int> commentLikeCounts = {};
  Set<String> likedCommentIds = {};
  Set<String> updatingCommentLikeIds = {};

  String? replyingToCommentId;
  String? replyingToName;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor:FolktriColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (
          context,
          setSheetState,
        ) {
          Future<void> loadCommentLikes() async {
            try {
              final commentIds = comments
                .map(
                  (comment) => comment['id']?.toString(),
                )
                .whereType<String>()
                .where((id) => id.isNotEmpty,).toList();

              if (commentIds.isEmpty) {
                if (!sheetContext.mounted) {
                  return;
                }

              setSheetState(() {
                commentLikeCounts = {};
                likedCommentIds = {};
              });

                return;
              }

              final response = await supabase
                .from('Comment_Likes')
                .select('comment_id, user_id',)
                .inFilter(
                  'comment_id',
                  commentIds,
                );

              final likes = List<Map<String, dynamic>>.from(response,);

              final counts = <String, int>{};
              final currentUserLikes = <String>{};

              for (final like in likes) {
                final commentId = like['comment_id']?.toString();

                final userId = like['user_id']?.toString();

                if (commentId == null || commentId.isEmpty) {
                  continue;
                }

                counts[commentId] = (counts[commentId] ?? 0) + 1;

                if (userId == currentUser.id) {
                  currentUserLikes.add(commentId,);
                }
              }

              if (!sheetContext.mounted) {
                return;
              }

              setSheetState(() {
                commentLikeCounts = counts;
                likedCommentIds =
                currentUserLikes;
              });
              } catch (e) {
                debugPrint('Unable to load comment likes: $e',);
              }
            }

            Future<void> toggleCommentLike(String commentId,) async {
  if (commentId.isEmpty ||
      updatingCommentLikeIds
          .contains(commentId)) {
    return;
  }

  final isLiked =
      likedCommentIds.contains(
    commentId,
  );

  try {
    setSheetState(() {
      updatingCommentLikeIds.add(
        commentId,
      );
    });

    if (isLiked) {
      await supabase
          .from('Comment_Likes')
          .delete()
          .eq(
            'comment_id',
            commentId,
          )
          .eq(
            'user_id',
            currentUser.id,
          );
    } else {
      await supabase
          .from('Comment_Likes')
          .insert({
        'comment_id': commentId,
        'user_id': currentUser.id,
      });

      await createCommentLikeNotification(
        commentId: commentId,
        photoId: photoId,
  );
    }

    await loadCommentLikes();
  } catch (e) {
    debugPrint(
      'Unable to update comment like: $e',
    );

    if (!sheetContext.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      sheetContext,
    ).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to update comment like: $e',
        ),
      ),
    );
  } finally {
    if (sheetContext.mounted) {
      setSheetState(() {
        updatingCommentLikeIds.remove(
          commentId,
        );
      });
    }
  }
}

          Future<void> loadComments() async {
            try {
              final response =
                  await supabase
                      .from('Photo_Comments',)
                      .select(
                        '''
                        id,
                        photo_id,
                        user_id,
                        comment_text,
                        created_at,
                        parent_comment_id
                        ''',
                      )
                      .eq(
                        'photo_id',
                        photoId,
                      )
                      .order(
                        'created_at',
                        ascending: true,
                      );

              final loadedComments = List<Map<String, dynamic>>
                      .from(response,);

              final userIds = loadedComments.map(
                        (comment) => comment['user_id']?.toString(),
                      )
                      .whereType<String>()
                      .where(
                        (id) => id.isNotEmpty,
                      )
                      .toSet()
                      .toList();

              final profilesByUserId = <String, Map<String, dynamic>>{};

              if (userIds.isNotEmpty) {
                final profileResponse = await supabase
                        .from('Profiles',)
                        .select(
                          '''
                          user_id,
                          first_name,
                          last_name,
                          profile_photo_path
                          ''',
                        )
                        .inFilter(
                          'user_id',
                          userIds,
                        );

                final profiles = List<Map<String,dynamic>>.from(profileResponse,);

                for (final profile in profiles) {
                  final userId = profile['user_id']?.toString();

                  if (userId == null || userId.isEmpty) {
                    continue;
                  }

                final profilePhotoPath = profile['profile_photo_path']
                  ?.toString()
                  .trim();

  String? signedPhotoUrl;

  if (profilePhotoPath != null && profilePhotoPath.isNotEmpty) {
    try {
      signedPhotoUrl =
          await supabase.storage
              .from('profile-photos')
              .createSignedUrl(
                profilePhotoPath,
                3600,
              );
    } catch (e) {
      debugPrint(
        'Unable to load commenter profile photo: $e',
      );
    }
  }

  profile['signed_photo_url'] =
      signedPhotoUrl;

  profilesByUserId[userId] =
      profile;
                }
              }

              for (final comment
                  in loadedComments) {
                final userId =
                    comment['user_id']
                        ?.toString();

                comment['profile'] =
                    userId == null
                        ? null
                        : profilesByUserId[
                            userId];
              }

              if (!sheetContext.mounted) {
                return;
              }

              setSheetState(() {
                comments = loadedComments;

                isLoadingComments = false;
              });

              await loadCommentLikes();

            } catch (e) {
              debugPrint(
                'Unable to load comments: $e',
              );

              if (!sheetContext.mounted) {
                return;
              }

              setSheetState(() {
                isLoadingComments =
                    false;
              });
            }
          }

          Future<void> postComment() async {
            final commentText =
                commentController.text
                    .trim();

            if (commentText.isEmpty ||
                isPostingComment) {
              return;
            }

            try {
              setSheetState(() {
                isPostingComment = true;
              });

              final parentCommentId = replyingToCommentId;

              await supabase
                  .from(
                    'Photo_Comments',
                  )
                  .insert({
                'photo_id': photoId,
                'user_id':
                    currentUser.id,
                'comment_text': commentText,
                'parent_comment_id': replyingToCommentId,
              });

              if (parentCommentId != null && parentCommentId.isNotEmpty) {
                await createCommentReplyNotification(
                  photoId: photoId,
                  parentCommentId: parentCommentId,
                );
              }

              commentController.clear();

              setSheetState(() {
                replyingToCommentId = null;
                replyingToName = null;
              });

              await loadComments();
              await loadPhotoCommentCounts();
            } catch (e) {
              debugPrint(
                'Unable to post comment: $e',
              );

              if (!sheetContext.mounted) {
                return;
              }

              ScaffoldMessenger.of(
                sheetContext,
              ).showSnackBar(
                SnackBar(
                  content: Text(
                    'Unable to post comment: $e',
                  ),
                ),
              );
            } finally {
              if (sheetContext.mounted) {
                setSheetState(() {
                  isPostingComment =
                      false;
                });
              }
            }
          }

          Future<void> deleteComment(
            String commentId,
          ) async {
            try {
              await supabase
                  .from(
                    'Photo_Comments',
                  )
                  .delete()
                  .eq(
                    'id',
                    commentId,
                  )
                  .eq(
                    'user_id',
                    currentUser.id,
                  );

              await loadComments();
              await loadPhotoCommentCounts();
            } catch (e) {
              debugPrint(
                'Unable to delete comment: $e',
              );
            }
          }

          if (isLoadingComments) {
            loadComments();
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(context)
                      .viewInsets
                      .bottom,
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height:
                    MediaQuery.of(context)
                            .size
                            .height *
                        0.72,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        20,
                        16,
                        12,
                        12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Comments',
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  TextStyle(
                                color:
                                    FolktriColors
                                        .primaryText,
                                fontSize:
                                    18,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),

                          IconButton(
  tooltip: 'Close comments',
  onPressed: () {
    FocusScope.of(
      sheetContext,
    ).unfocus();

    Navigator.of(
      sheetContext,
    ).pop();
  },
  icon: const Icon(
    Icons.close_rounded,
    color: FolktriColors.secondaryText,
  ),
),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color:
                          FolktriColors
                              .lightLavender,
                    ),

                    Expanded(
                      child:
                          isLoadingComments
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(),
                                )
                              : comments
                                      .isEmpty
                                  ? const Center(
                                      child:
                                          Padding(
                                        padding:
                                            EdgeInsets
                                                .all(
                                          30,
                                        ),
                                        child:
                                            Column(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                          children: [
                                            Icon(
                                              Icons
                                                  .chat_bubble_outline_rounded,
                                              size:
                                                  38,
                                              color:
                                                  FolktriColors
                                                      .primaryIndigo,
                                            ),
                                            SizedBox(
                                              height:
                                                  10,
                                            ),
                                            Text(
                                              'No comments yet',
                                              style:
                                                  TextStyle(
                                                color:
                                                    FolktriColors
                                                        .primaryText,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                              ),
                                            ),
                                            SizedBox(
                                              height:
                                                  4,
                                            ),
                                            Text(
                                              'Be the first to leave a family comment.',
                                              textAlign:
                                                  TextAlign
                                                      .center,
                                              style:
                                                  TextStyle(
                                                color:
                                                    FolktriColors
                                                        .secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Builder(
    builder: (context) {
      final topLevelComments =
          comments.where(
        (comment) =>
            comment['parent_comment_id'] ==
                null,
      ).toList();

      return ListView.builder(
        padding:
            const EdgeInsets.symmetric(
          vertical: 10,
        ),
        itemCount:
            topLevelComments.length,
        itemBuilder: (
          context,
          index,
        ) {
          final comment =
              topLevelComments[index];

          final commentId =
              comment['id']
                      ?.toString() ??
                  '';

          final replies = comments.where(
            (candidate) =>
                candidate[
                        'parent_comment_id']
                    ?.toString() ==
                commentId,
          ).toList();

          return buildPhotoCommentThread(
            comment: comment,
            replies: replies,
            currentUserId:
                currentUser.id,
            commentLikeCounts:
                commentLikeCounts,
            likedCommentIds:
                likedCommentIds,
            updatingCommentLikeIds:
                updatingCommentLikeIds,
            onLike:
                toggleCommentLike,
            onReply: (
              parentCommentId,
              displayName,
            ) {
              setSheetState(() {
                replyingToCommentId =
                    parentCommentId;

                replyingToName =
                    displayName;
              });

              commentFocusNode.requestFocus();
            },
            onDelete:
                deleteComment,
          );
        },
      );
    },
  ),
                    ),

                    const Divider(
                      height: 1,
                      color: FolktriColors.lightLavender,
                    ),

                    Padding(
  padding: const EdgeInsets.fromLTRB(
    14,
    8,
    14,
    12,
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Shows only when replying to someone.
      if (replyingToCommentId != null)
        Container(
          margin: const EdgeInsets.only(
            bottom: 8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: FolktriColors.lightLavender,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.reply_rounded,
                size: 17,
                color: FolktriColors.primaryIndigo,
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child: Text(
                  'Replying to '
                  '${replyingToName ?? 'family member'}',
                  style: const TextStyle(
                    color: FolktriColors.primaryIndigo,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setSheetState(() {
                    replyingToCommentId = null;
                    replyingToName = null;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: FolktriColors.primaryIndigo,
                  ),
                ),
              ),
            ],
          ),
        ),

      // This is your ORIGINAL avatar + TextField + Send row.
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                FolktriColors.lightLavender,
            backgroundImage:
                profilePhotoUrl != null
                    ? NetworkImage(
                        profilePhotoUrl!,
                      )
                    : null,
            child: profilePhotoUrl == null
                ? const Icon(
                    Icons.person_rounded,
                    color:
                        FolktriColors.primaryIndigo,
                    size: 19,
                  )
                : null,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: TextField(
              controller: commentController,
              focusNode: commentFocusNode,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    replyingToCommentId != null
                        ? 'Add a reply...'
                        : 'Add a comment...',
                counterText: '',
                filled: true,
                fillColor:
                    FolktriColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          IconButton(
            tooltip: replyingToCommentId != null
                ? 'Post reply'
                : 'Post comment',
            onPressed:
                isPostingComment
                    ? null
                    : postComment,
            icon: isPostingComment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.send_rounded,
                    color:
                        FolktriColors.primaryIndigo,
                  ),
          ),
        ],
      ),
    ],
  ),
),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  // commentController.dispose();

  // await loadPhotoCommentCounts();
}

Widget buildPhotoCommentThread({
  required Map<String, dynamic>
      comment,
  required List<Map<String, dynamic>>
      replies,
  required String currentUserId,
  required Map<String, int>
      commentLikeCounts,
  required Set<String>
      likedCommentIds,
  required Set<String>
      updatingCommentLikeIds,
  required Future<void> Function(
    String commentId,
  ) onLike,
  required void Function(
    String parentCommentId,
    String displayName,
  ) onReply,
  required Future<void> Function(
    String commentId,
  ) onDelete,
}) {
  final commentId =
      comment['id']?.toString() ?? '';

  final profile =
      comment['profile'];

  final firstName =
      profile is Map
          ? profile['first_name']
                  ?.toString()
                  .trim() ??
              ''
          : '';

  final lastName =
      profile is Map
          ? profile['last_name']
                  ?.toString()
                  .trim() ??
              ''
          : '';

  final displayName = [
    firstName,
    lastName,
  ].where(
    (name) => name.isNotEmpty,
  ).join(' ');

  final safeDisplayName =
      displayName.isEmpty
          ? 'Family member'
          : displayName;

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      buildPhotoCommentTile(
        comment: comment,
        currentUserId:
            currentUserId,
        likeCount:
            commentLikeCounts[
                    commentId] ??
                0,
        isLiked:
            likedCommentIds.contains(
          commentId,
        ),
        isUpdatingLike:
            updatingCommentLikeIds
                .contains(
          commentId,
        ),
        onLike: () {
          onLike(commentId);
        },
        onReply: () {
          onReply(
            commentId,
            safeDisplayName,
          );
        },
        onDelete:
            onDelete,
      ),

      if (replies.isNotEmpty)
        Padding(
          padding:
              const EdgeInsets.only(
            left: 38,
          ),
          child: Column(
            children:
                replies.map(
              (reply) {
                final replyId =
                    reply['id']
                            ?.toString() ??
                        '';

                return buildPhotoCommentTile(
                  comment:
                      reply,
                  currentUserId:
                      currentUserId,
                  likeCount:
                      commentLikeCounts[
                              replyId] ??
                          0,
                  isLiked:
                      likedCommentIds
                          .contains(
                    replyId,
                  ),
                  isUpdatingLike:
                      updatingCommentLikeIds
                          .contains(
                    replyId,
                  ),
                  onLike: () {
                    onLike(
                      replyId,
                    );
                  },

                  // Replying to a reply still
                  // belongs to the parent thread.
                  onReply: () {
                    onReply(
                      commentId,
                      safeDisplayName,
                    );
                  },
                  onDelete:
                      onDelete,
                  isReply: true,
                );
              },
            ).toList(),
          ),
        ),
    ],
  );
}

Widget buildPhotoCommentTile({
  required Map<String, dynamic> comment,
  required String currentUserId,
  required int likeCount,
  required bool isLiked,
  required bool isUpdatingLike,
  required VoidCallback onLike,
  required VoidCallback onReply,

  required Future<void> Function(
    String commentId,
  ) onDelete,

   bool isReply = false,
}) {
  final profile = comment['profile'];

  final signedPhotoUrl =
    profile is Map
        ? profile['signed_photo_url']
            ?.toString()
        : null;

  final firstName =
      profile is Map
          ? profile['first_name']
                  ?.toString()
                  .trim() ??
              ''
          : '';

  final lastName =
      profile is Map
          ? profile['last_name']
                  ?.toString()
                  .trim() ??
              ''
          : '';

  final fullName = [
    firstName,
    lastName,
  ].where(
    (name) => name.isNotEmpty,
  ).join(' ');

  final displayName =
      fullName.isEmpty
          ? 'Family member'
          : fullName;

  final commentText =
      comment['comment_text']
              ?.toString() ??
          '';

  final commentUserId =
      comment['user_id']
              ?.toString() ??
          '';

  final isOwnComment =
      commentUserId == currentUserId;

  final createdAt =
      DateTime.tryParse(
    comment['created_at']
            ?.toString() ??
        '',
  )?.toLocal();

  String timeLabel = '';

  if (createdAt != null) {
    final difference =
        DateTime.now()
            .difference(createdAt);

    if (difference.inMinutes < 1) {
      timeLabel = 'Just now';
    } else if (
        difference.inMinutes < 60) {
      timeLabel =
          '${difference.inMinutes}m';
    } else if (
        difference.inHours < 24) {
      timeLabel =
          '${difference.inHours}h';
    } else if (
        difference.inDays < 7) {
      timeLabel =
          '${difference.inDays}d';
    } else {
      timeLabel =
          '${createdAt.month}/'
          '${createdAt.day}/'
          '${createdAt.year}';
    }
  }

  return Padding(
    padding:
        const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    child: Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        CircleAvatar(
  radius: 18,
  backgroundColor:
      FolktriColors.lightLavender,
  backgroundImage:
      signedPhotoUrl != null &&
              signedPhotoUrl.isNotEmpty
          ? NetworkImage(
              signedPhotoUrl,
            )
          : null,
  child: signedPhotoUrl == null ||
          signedPhotoUrl.isEmpty
      ? Text(
          firstName.isNotEmpty
              ? firstName[0]
                  .toUpperCase()
              : '?',
          style: const TextStyle(
            color:
                FolktriColors.primaryIndigo,
            fontWeight:
                FontWeight.bold,
          ),
        )
      : null,
),

        const SizedBox(width: 10),

        Expanded(
          child: Container(
            padding:
                const EdgeInsets
                    .fromLTRB(
              12,
              9,
              12,
              9,
            ),
            decoration:
                BoxDecoration(
              color:
                  FolktriColors
                      .background,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style:
                            const TextStyle(
                          color:
                              FolktriColors
                                  .primaryText,
                          fontSize:
                              12,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    if (timeLabel
                        .isNotEmpty)
                      Text(
                        timeLabel,
                        style:
                            const TextStyle(
                          color:
                              FolktriColors
                                  .secondaryText,
                          fontSize:
                              10,
                        ),
                      ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  commentText,
                  style:
                      const TextStyle(
                    color:
                        FolktriColors
                            .primaryText,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),

                const SizedBox(
  height: 8,
),

Row(
  mainAxisSize:
      MainAxisSize.min,
  children: [
    InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap:
          isUpdatingLike
              ? null
              : onLike,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            if (isUpdatingLike)
              const SizedBox(
                width: 14,
                height: 14,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 1.5,
                ),
              )
            else
              Icon(
                isLiked
                    ? Icons
                        .favorite_rounded
                    : Icons
                        .favorite_border_rounded,
                size: 16,
                color: isLiked
                    ? FolktriColors
                        .dustyRose
                    : FolktriColors
                        .secondaryText,
              ),

            const SizedBox(
              width: 5,
            ),

            Text(
              likeCount == 0
                  ? 'Like'
                  : likeCount == 1
                      ? '1 like'
                      : '$likeCount likes',
              style: TextStyle(
                color: isLiked
                    ? FolktriColors
                        .dustyRose
                    : FolktriColors
                        .secondaryText,
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),

    const SizedBox(
      width: 14,
    ),

    InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: onReply,
      child: const Padding(
        padding:
            EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.reply_rounded,
              size: 16,
              color:
                  FolktriColors
                      .secondaryText,
            ),

            SizedBox(
              width: 4,
            ),

            Text(
              'Reply',
              style: TextStyle(
                color:
                    FolktriColors
                        .secondaryText,
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
              ],
            ),
          ),
        ),

        if (isOwnComment)
          PopupMenuButton<String>(
            padding:
                EdgeInsets.zero,
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 19,
              color:
                  FolktriColors
                      .secondaryText,
            ),
            onSelected:
                (value) async {
              if (value ==
                  'delete') {
                await onDelete(
                  comment['id']
                      .toString(),
                );
              }
            },
            itemBuilder:
                (context) => const [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .delete_outline_rounded,
                      size: 19,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Delete comment',
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

Widget buildFeedItem(
  Map<String, dynamic> item,
) {
  final type =
      item['type']?.toString();

  if (type == 'milestone') {
    return buildMilestoneFeedCard(
      item,
    );
  }

  if (type == 'photo') {
    return buildPhotoFeedCard(
      item,
    );
  }

  return const SizedBox.shrink();
}

Widget buildPhotoFeedCard( Map<String, dynamic> photo) {
  final childData = photo['child'];

String childName = '';

  if (childData is Map) {
    childName = [
      childData['first_name'],
      childData['middle_name'],
      childData['last_name'],
    ]
        .where(
          (value) =>
              value != null &&
              value.toString().trim().isNotEmpty,
        )
        .join(' ');
  }

  final caption =
      photo['caption']?.toString().trim() ?? '';

  final photoUrl =
      photo['photo_url']?.toString() ?? '';

  final photoId =
    photo['id']?.toString() ?? '';

  final photoCardKey = 
    photoCardKeys.putIfAbsent(photoId, () => GlobalKey(),);

  final isHighlighted = highlightedPhotoId == photoId;

  final likeCount =
    photoLikeCounts[photoId] ?? 0;

  final isLiked =
    likedPhotoIds.contains(photoId);

  final commentCount =
    photoCommentCounts[photoId] ?? 0;

  final createdAt = DateTime.tryParse(
    photo['created_at']?.toString() ?? '',
  )?.toLocal();

  final dateLabel = createdAt == null
      ? 'Family photo'
      : '${createdAt.month}/${createdAt.day}/${createdAt.year}';

  return AnimatedContainer(

    key: photoCardKey,
    duration: const Duration(
      milliseconds: 300,
    ),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: 
        isHighlighted
        ? FolktriColors.lightLavender
            .withValues(alpha: 0.35)
        : FolktriColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: isHighlighted
        ? Border.all(
            color:
                FolktriColors.primaryIndigo,
            width: 2,
          )
        : null,
      boxShadow: [
        BoxShadow(
          color: FolktriColors.midnightIndigo
              .withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor:
                    FolktriColors.lightLavender,
                child: Icon(
                  Icons.family_restroom_rounded,
                  color: FolktriColors.primaryIndigo,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName.isNotEmpty
                          ? 'A moment with $childName'
                          : 'Family photo',
                      style: const TextStyle(
                        color: FolktriColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '$dateLabel · Family only',
                      style: const TextStyle(
                        color:
                            FolktriColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: FolktriColors.secondaryText,
              ),
            ],
          ),
        ),

        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              14, 0, 14, 12,
            ),
            child: Text(
              caption,
              style: const TextStyle(
                color: FolktriColors.primaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

        if (photoUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.zero,
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
                  height: 180,
                  alignment: Alignment.center,
                  color: FolktriColors.lightLavender,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: FolktriColors.primaryIndigo,
                    size: 36,
                  ),
                );
              },

        
            ),
          ),

          Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  ),
  child: Row(
    children: [
      InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: photoId.isEmpty
            ? null
            : () {
                togglePhotoLike(
                  photoId,
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),
          child: Row(
            children: [
              Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 22,
                color: isLiked
                    ? FolktriColors.dustyRose
                    : FolktriColors
                        .secondaryText,
              ),

              const SizedBox(width: 6,),

              Text(
                likeCount == 1
                    ? '1 like'
                    : '$likeCount likes',
                style: TextStyle(
                  color: isLiked
                      ? FolktriColors
                          .dustyRose
                      : FolktriColors
                          .secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(width: 18,),

      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showPhotoComments(photoId);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 21,
                color: FolktriColors.secondaryText,
              ),

              SizedBox(width: 6),

              Text(
                commentCount == 0
                  ? 'Comment'
                : commentCount == 1
                  ? '1 comment'
                  : '$commentCount comments',
                style: const TextStyle(
                  color: FolktriColors.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),

      const Spacer(),

      const Icon(
        Icons.lock_outline_rounded,
        size: 15,
        color: FolktriColors.secondaryText,
      ),
    ],
  ),
),
      ],
    ),
  );
}

Widget buildMilestoneFeedCard(Map<String, dynamic> milestone,) {
  final childData = milestone['child'];

  String childName = 'A child';

  if (childData is Map) {
    final name = [
      childData['first_name'],
      childData['middle_name'],
      childData['last_name'],
    ]
        .where(
          (value) =>
              value != null &&
              value.toString().trim().isNotEmpty,
        )
        .map((value) => value.toString().trim())
        .join(' ');

    if (name.isNotEmpty) {
      childName = name;
    }
  }

  final title = milestone['title']?.toString().trim() ?? '';

  final description = milestone['description']?.toString().trim() ?? '';

  final photoUrl = milestone['photo_url']?.toString().trim() ?? '';

  final childId = milestone['child_id']?.toString();

  final milestoneDate = DateTime.tryParse( milestone['event_date']?.toString() ?? '',);

  final createdAt = DateTime.tryParse(
    milestone['created_at']?.toString() ?? '',
  )?.toLocal();

  // Display the date when the milestone occurred.
  final dateLabel = milestoneDate == null
      ? 'Milestone'
      : '${milestoneDate.month}/'
        '${milestoneDate.day}/'
        '${milestoneDate.year}';

  // Display when the milestone was shared.
  String sharedLabel = 'Family milestone';

  if (createdAt != null) {
    final difference =
        DateTime.now().difference(createdAt);

    if (difference.isNegative ||
        difference.inMinutes < 1) {
      sharedLabel = 'Just now';
    } else if (difference.inMinutes < 60) {
      sharedLabel =
          '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      sharedLabel =
          '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      sharedLabel =
          '${difference.inDays}d ago';
    } else {
      sharedLabel =
          '${createdAt.month}/'
          '${createdAt.day}/'
          '${createdAt.year}';
    }
  }

  // ==========================================
  // MILESTONE CARD
  // ==========================================

  return Container(
    margin: const EdgeInsets.only(bottom: 16,),

    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: FolktriColors.midnightIndigo.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),

    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: childId == null || childId.isEmpty
            ? null
            : () {
                context.push(
                  '/child/$childId',
                );
              },

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================
            // HEADER
            // ==================================

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12,),
              child: Row(
                children: [
                  // Milestone avatar
                  const CircleAvatar(
                    radius: 21,
                    backgroundColor: FolktriColors.lightLavender,

                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: FolktriColors.primaryIndigo,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          '$childName reached a milestone',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: FolktriColors.primaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sharedLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: FolktriColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            const Text(
                              '·',
                              style: TextStyle(
                                color: FolktriColors.secondaryText,
                              ),
                            ),

                            const SizedBox(width: 5),

                            const Icon(
                              Icons.lock_outline_rounded,
                              color: FolktriColors.secondaryText,
                              size: 12,
                            ),

                            const SizedBox(width: 3),

                            const Text(
                              'Family only',
                              style: TextStyle(
                                color: FolktriColors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Decorative milestone indicator
                  const Icon(
                    Icons.stars_rounded,
                    color: FolktriColors.dustyRose,
                    size: 23,
                  ),
                ],
              ),
            ),

            // ==================================
            // MILESTONE TITLE AND DESCRIPTION
            // ==================================

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12,),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,

                      style: const TextStyle(
                        color: FolktriColors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 7),

                    Text(
                      description,

                      style: const TextStyle(
                        color: FolktriColors.primaryText,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Date of the milestone
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: FolktriColors.lightLavender.withValues(alpha: 0.55),

                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        const Icon(
                          Icons.event_available_outlined,
                          size: 14,
                          color: FolktriColors.primaryIndigo,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          'Milestone date: $dateLabel',

                          style: const TextStyle(
                            color: FolktriColors.midnightIndigo,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================================
            // MILESTONE PHOTO
            // ==================================

            if (photoUrl.isNotEmpty)
              Image.network(
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

                    color: FolktriColors.lightLavender,

                    alignment: Alignment.center,

                    child: const Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: FolktriColors.primaryIndigo,
                          size: 34,
                        ),

                        SizedBox(height: 8),

                        Text(
                          'Unable to load milestone photo',
                          style: TextStyle(
                            color: FolktriColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ==================================
            // CARD FOOTER
            // ==================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: FolktriColors.dustyRose,
                    size: 20,
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    'A special family moment',
                    style: TextStyle(
                      color: FolktriColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),

                  if (childId != null &&
                      childId.isNotEmpty) ...[
                    const Text(
                      'View profile',
                      style: TextStyle(
                        color: FolktriColors.primaryIndigo,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 4),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: FolktriColors.primaryIndigo,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> loadUpcomingEvents() async {
  try {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final createdFamiliesResponse =
        await supabase
            .from('Families')
            .select('id')
            .eq(
              'created_by',
              user.id,
            );

    final createdFamilies =
        List<Map<String, dynamic>>.from(
      createdFamiliesResponse,
    );

    final membershipResponse =
        await supabase
            .from('Family_Members')
            .select(
              'family_id, can_view_calendar',
            )
            .eq(
              'user_id',
              user.id,
            )
            .eq(
              'status',
              'approved',
            )
            .eq(
              'can_view_calendar',
              true,
            );

    final memberships =
        List<Map<String, dynamic>>.from(
      membershipResponse,
    );

    final familyIds = <String>{
      ...createdFamilies.map(
        (family) =>
            family['id'].toString(),
      ),
      ...memberships.map(
        (membership) =>
            membership['family_id']
                .toString(),
      ),
    }.toList();

    if (familyIds.isEmpty) {
      if (!mounted) return;

      setState(() {
        upcomingEvents = [];
        isLoadingEvents = false;
      });

      return;
    }

    final now =
        DateTime.now().toUtc();

    final response =
        await supabase
            .from('Calendar_Events')
            .select(
              '''
              id,
              family_id,
              child_id,
              title,
              description,
              event_type,
              start_at,
              end_at,
              all_day,
              location,
              assigned_to,
              Children(
                first_name,
                middle_name,
                last_name
              )
              ''',
            )
            .inFilter(
              'family_id',
              familyIds,
            )
            .gte(
              'start_at',
              now.toIso8601String(),
            )
            .order(
              'start_at',
              ascending: true,
            )
            .limit(5);

    if (!mounted) return;

    setState(() {
      upcomingEvents =
          List<Map<String, dynamic>>.from(
        response,
      );

      isLoadingEvents = false;
    });
  } catch (e) {
    debugPrint(
      'Unable to load upcoming events: $e',
    );

    if (!mounted) return;

    setState(() {
      isLoadingEvents = false;
    });
  }
}
  
Widget buildUpcomingEventCard(
  Map<String, dynamic> event,
) {
  final startDate =
      DateTime.parse(
    event['start_at'].toString(),
  ).toLocal();

  final childData =
      event['Children'];

  String? childName;

  if (childData != null) {
    final firstName =
        childData['first_name'] ?? '';

    final middleName =
        childData['middle_name'] ?? '';

    final lastName =
        childData['last_name'] ?? '';

    final fullName = [
      firstName,
      middleName,
      lastName,
    ]
        .where(
          (name) =>
              name
                  .toString()
                  .trim()
                  .isNotEmpty,
        )
        .join(' ');

    if (fullName.isNotEmpty) {
      childName = fullName;
    }
  }

  final dateText =
      '${startDate.month}/${startDate.day}/${startDate.year}';

  final timeText =
      TimeOfDay.fromDateTime(
    startDate,
  ).format(context);

  return Card(
    margin:
        const EdgeInsets.only(
      right: 12,
    ),
    child: SizedBox(
      width: 260,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    event['event_type'] ??
                        'Event',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              event['title'] ?? '',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              '$dateText • $timeText',
            ),

            if (childName != null) ...[
              const SizedBox(
                height: 6,
              ),
              Text(
                'For: $childName',
              ),
            ],

            if (event['location'] !=
                null) ...[
              const SizedBox(
                height: 6,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    child: Text(
                      event['location']
                          .toString(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<void> loadUserProfile() async {
  final user =
      supabase.auth.currentUser;

  if (user == null) {
    return;
  }

  try {
    final response =
        await supabase
            .from('Profiles')
            .select(
              '''
              first_name,
              last_name,
              profile_photo_path
              ''',
            )
            .eq(
              'user_id',
              user.id,
            )
            .maybeSingle();

    String? signedPhotoUrl;

    if (response != null) {
      final photoPath =
          response[
                  'profile_photo_path']
              ?.toString();

      if (photoPath != null &&
          photoPath.isNotEmpty) {
        signedPhotoUrl =
            await supabase.storage
                .from('profile-photos')
                .createSignedUrl(
                  photoPath,
                  3600,
                );
      }
    }

    if (!mounted) return;

    setState(() {
      userProfile = response;

      profilePhotoUrl =
          signedPhotoUrl;

      isLoadingProfile =
          false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingProfile =
          false;
    });

    debugPrint(
      'Unable to load user profile: $e',
    );
  }
}

Widget buildProfileHeader() {
  if (isLoadingProfile) {
    return const SizedBox.shrink();
  }

  final firstName =
      userProfile?['first_name']
          ?.toString() ??
      '';

  final lastName =
      userProfile?['last_name']
          ?.toString() ??
      '';

  final fullName = [
    firstName,
    lastName,
  ]
      .where(
        (name) =>
            name.trim().isNotEmpty,
      )
      .join(' ');

  return InkWell(
    borderRadius:
        BorderRadius.circular(30),

    onTap: () {
      context.go('/profile');
    },

    child: Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          CircleAvatar(
            radius: 18,

            backgroundImage:
                profilePhotoUrl != null
                    ? NetworkImage(
                        profilePhotoUrl!,
                      )
                    : null,

            child:
                profilePhotoUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 20,
                      )
                    : null,
          ),

          const SizedBox(
            width: 8,
          ),

          if (fullName.isNotEmpty)
            Text(
              fullName,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
        ],
      ),
    ),
  );
}

Widget buildFamilySelector() {
  final selectedFamily = families.where(
    (family) =>
        family['id']?.toString() == selectedFamilyId,
  );

  final familyName = selectedFamily.isNotEmpty
      ? selectedFamily.first['family_name']
              ?.toString() ??
          'My Family'
      : 'My Family';

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: FolktriColors.midnightIndigo
              .withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: FolktriColors.lightLavender,
          child: const Icon(
            Icons.family_restroom_rounded,
            color: FolktriColors.primaryIndigo,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                familyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FolktriColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: FolktriColors.secondaryText,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Private family space',
                    style: TextStyle(
                      color: FolktriColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        PopupMenuButton<String>(
          tooltip: 'Choose family',
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: FolktriColors.midnightIndigo,
          ),
          onSelected: (value) {
            if (value == 'add') {
              showFamilyOptions();
              return;
            }

            setState(() {
              selectedFamilyId = value;
            });
          },
          itemBuilder: (context) => [
            ...families.map(
              (family) => PopupMenuItem<String>(
                value: family['id'].toString(),
                child: Text(
                  family['family_name']?.toString() ??
                      'Unnamed Family',
                ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'add',
              child: Text('Add or join a family'),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildQuickPostCard() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FolktriColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: FolktriColors.lightLavender,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: FolktriColors.lightLavender,
              backgroundImage: profilePhotoUrl != null
                  ? NetworkImage(profilePhotoUrl!)
                  : null,
              child: profilePhotoUrl == null
                  ? const Icon(
                      Icons.person_rounded,
                      color: FolktriColors.primaryIndigo,
                    )
                  : null,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  _showPostOptions();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: FolktriColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: FolktriColors.lightLavender,
                    ),
                  ),
                  child: const Text(
                    'Share a moment with your family...',
                    style: TextStyle(
                      color: FolktriColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        const Divider(
          height: 1,
          color: FolktriColors.lightLavender,
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _postAction(
              Icons.photo_library_outlined,
              'Photo',
              FolktriColors.primaryIndigo,
            ),
            _postAction(
              Icons.videocam_outlined,
              'Video',
              FolktriColors.primaryIndigo,
            ),
            _postAction(
              Icons.event_outlined,
              'Event',
              FolktriColors.primaryIndigo,
            ),
            _postAction(
              Icons.star_outline_rounded,
              'Milestone',
              FolktriColors.dustyRose,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _postAction(
  IconData icon,
  String label,
  Color color,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: _showPostOptions,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FolktriColors.primaryText,
            ),
          ),
        ],
      ),
    ),
  );
}

void _showPostOptions() {
  final familyId = selectedFamilyId;

  if (familyId == null) {
    showFamilyOptions();
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20, 8, 20, 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share with your family',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FolktriColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(
                Icons.family_restroom_rounded,
                color: FolktriColors.primaryIndigo,
              ),
              title: const Text('Open family page'),
              subtitle: const Text(
                'Share photos, milestones, and more.',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/family/$familyId');
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildTodaySection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Today',
            style: TextStyle(
              color: FolktriColors.primaryText,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          TextButton(
            onPressed: () {
              final familyId = selectedFamilyId;
              if (familyId != null) {
                context.push(
                  '/family/$familyId/calendar',
                );
              }
            },
            child: const Text(
              'See all',
              style: TextStyle(
                color: FolktriColors.primaryIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 4),

      Row(
        children: [
          Expanded(
            child: _todayCard(
              icon: Icons.calendar_month_rounded,
              title: 'Upcoming\nEvents',
              detail: isLoadingEvents
                  ? 'Loading...'
                  : '${upcomingEvents.length} coming up',
              background: FolktriColors.lightLavender,
              accent: FolktriColors.primaryIndigo,
              onTap: () {
                final familyId = selectedFamilyId;
                if (familyId != null) {
                  context.push(
                    '/family/$familyId/calendar',
                  );
                }
              },
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _todayCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Family\nMoments',
              detail: isLoadingFeed
                  ? 'Loading...'
                  : '${feedItems.length} shared',
              background: FolktriColors.dustyRose
                  .withValues(alpha: 0.17),
              accent: FolktriColors.dustyRose,
              onTap: () {
                _showPostOptions();
              },
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _todayCard(
              icon: Icons.photo_library_outlined,
              title: 'Family\nPhotos',
              detail: isLoadingFeed
                  ? 'Loading...'
                  : '${feedItems.where(
                      (item) => item['type'] == 'photo',
                    ).length} shared',
              background: FolktriColors.lightLavender
                  .withValues(alpha: 0.55),
              accent: FolktriColors.primaryIndigo,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Family Albums is coming soon!',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _todayCard({
  required IconData icon,
  required String title,
  required String detail,
  required Color background,
  required Color accent,
  required VoidCallback onTap,
}) {
  return Material(
    color: background,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 128,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 12,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: FolktriColors.surface,
                child: Icon(
                  icon,
                  color: accent,
                  size: 19,
                ),
              ),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FolktriColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),

              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FolktriColors.secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context){

    return Scaffold(
      backgroundColor: FolktriColors.background,
      
      appBar: AppBar(
        backgroundColor: FolktriColors.midnightIndigo,
        elevation: 0,
        toolbarHeight: 64,
        title:  Text("Folktri", 
          style: GoogleFonts.marckScript(
            fontWeight: FontWeight.w400,
            color: FolktriColors.surface,
            fontSize: 34,
          ),
        ),
        actions: [
            // ==========================================
            // PROFILE
            // ==========================================
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              context.go('/profile');
            },
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: FolktriColors.lightLavender,
              backgroundImage:
                profilePhotoUrl != null
                ? NetworkImage(profilePhotoUrl!,)
                : null,
              child: profilePhotoUrl == null
                ? const Icon(
                    Icons.person_rounded,
                    color: FolktriColors.primaryIndigo,
                    size: 20,
                  )
                : null,
              ),
            ),

          // ==========================================
          // ADD FAMILY
          // ==========================================

          IconButton(
            icon: const Icon(
              Icons.add,
              color: FolktriColors.surface,
              ),
            tooltip: "Add Family",
            onPressed: showFamilyOptions,
          ),

           const SizedBox(width: 6,),
        ],
      ),

  bottomNavigationBar: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,

  backgroundColor: FolktriColors.surface,

  selectedItemColor: FolktriColors.primaryIndigo,

  unselectedItemColor: FolktriColors.secondaryText,

  selectedLabelStyle: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12,
  ),

  unselectedLabelStyle: const TextStyle(
    fontSize: 12,
  ),

  showSelectedLabels: true,
  showUnselectedLabels: true,

  currentIndex: 0,

  onTap: (index) {
    switch (index) {
      case 0:
        // Already on the Family Dashboard.
        break;

      case 1:
        // Open the selected family's calendar.
        final familyId = selectedFamilyId;

        if (familyId != null) {
          context.go(
            '/family/$familyId/calendar',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please create or join a family first.',
              ),
            ),
          );
        }
        break;

      case 2:
        // Open the selected family.
        context.go('/families');
        break;

      case 3:
        // Open family albums.
        // Add this route when your Albums page is ready.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Family Albums is coming soon!',
            ),
          ),
        );
        break;

      case 4:
        // Open the user's profile.
        context.go('/notifications');//.then((_) {
        //   if (mounted) {
        //     loadUserProfile();
        //   }
        // });
        break;
    }
  },

  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_month_outlined),
      activeIcon: Icon(Icons.calendar_month),
      label: 'Calendar',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.family_restroom_outlined),
      activeIcon: Icon(Icons.family_restroom),
      label: 'Family',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.photo_library_outlined),
      activeIcon: Icon(Icons.photo_library),
      label: 'Albums',
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.notifications_outlined),
      activeIcon: Icon(Icons.notifications_rounded),
      label: 'Notifications',
    ),
  ],
),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: FolktriColors.primaryIndigo,
              ),
            )
          : !hasApprovedFamily
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.family_restroom_rounded, 
                            size: 64,
                            color: FolktriColors.primaryIndigo
                            ),

                          const SizedBox(height: 16,),

                          const Text("Create a family or join an existing family",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              color: FolktriColors.primaryText,
                              fontWeight: FontWeight.bold,
                            )
                          ),

                          const SizedBox(height: 20,),

              //             ElevatedButton.icon(
              //               onPressed: () async {
              //                 setState(() {
              //                   isLoading = true;
              //               });

              //               await checkFamilyMembership();

              //               await Future.wait([
              //                 loadFeed(),
              //                 loadUpcomingEvents(),
              //               ]);
              //             },
              //   icon: const Icon(Icons.refresh,),
              //   label: const Text('Check for Family Access',),
              // ),
                                    ElevatedButton(
                        onPressed: showFamilyOptions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              FolktriColors.primaryIndigo,
                          foregroundColor:
                              FolktriColors.surface,
                        ),
                        child: const Text(
                          'Get Started',
                        ),
                      ),

                      TextButton(
                        onPressed: () async {
                          await checkFamilyMembership();
                          await Future.wait([
                            loadFeed(),
                            loadUpcomingEvents(),
                          ]);
                        },
                        child: const Text(
                          'Check for Family Access',
                        ),
                      ),
            ],
          ),
        ),
      )
              : RefreshIndicator(
                onRefresh: () async {
                  await checkFamilyMembership();

                  await Future.wait([
                    loadFeed(),
                    loadUpcomingEvents(),
                    loadUserProfile(),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                  children: [
    //                 Row(
    //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                   children: [
    //                     Text('Upcoming',
    //                     style:
    //                       Theme.of(context).textTheme.titleLarge,
    //                     ),

    //     if (families.isNotEmpty)
    //       TextButton(
    //         onPressed: () {
    //           final familyId = selectedFamilyId;

    //           if (familyId == null) {
    //             return;
    //           }

    //           context.push('/family/$familyId/calendar',);
    //         },
    //         child:
    //             const Text('View Calendar',),
    //       ),
    //   ],
    // ),

    // const SizedBox(height: 8,),

    // if (isLoadingEvents)
    //   const Center(
    //     child:
    //         CircularProgressIndicator(),
    //   )
    // else if (upcomingEvents.isEmpty)
    //   const Padding(
    //     padding:
    //         EdgeInsets.symmetric(vertical: 24,),
    //     child: Text('No upcoming events.',),
    //   )
    // else
    //   SizedBox(
    //     height: 190,
    //     child:
    //         ListView.builder(
    //       scrollDirection: Axis.horizontal,
    //       itemCount: upcomingEvents.length,
    //       itemBuilder:
    //           (
    //         context,
    //         index,
    //       ) {
    //         final event = upcomingEvents[index];

    //         return buildUpcomingEventCard(
    //           event,
    //         );
    //       },
    //     ),
    //   ),

    buildFamilySelector(),

    const SizedBox(height: 12),

    buildQuickPostCard(),

    const SizedBox(height: 18,),

    buildTodaySection(),

    const SizedBox(height: 22,),

    Text('Family Feed',
      style:
          TextStyle(
            color: FolktriColors.primaryText,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
    ),

    const SizedBox(height: 12,),

    if (isLoadingFeed)
      const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
           child: CircularProgressIndicator(
            color: FolktriColors.primaryIndigo,
            ),
          ),
        )
    else if (feedItems.isEmpty)
      Container( 
        
        padding: EdgeInsets.all(24,),
        decoration: BoxDecoration(
          color: FolktriColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 38,
              color:FolktriColors.primaryIndigo,
            ),

            SizedBox(height: 12,),

            Text('No family activity yet.',
              style: TextStyle(
                color: FolktriColors.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 6,),

            Text('Share a moment with your family to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FolktriColors.secondaryText,
              ),
            ),
          ],
        )
      
      )   
    else
      ...feedItems.map(
        (item) {
          return buildFeedItem(
            item,
          );
        },
      ),
  ],
),
      ),
    );
  }
}
