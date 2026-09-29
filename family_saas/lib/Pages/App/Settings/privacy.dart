import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Styling/folktri_colors.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({
    super.key,
  });

  @override
  State<PrivacyPage> createState() =>
      _PrivacyPageState();
}

class _PrivacyPageState
    extends State<PrivacyPage> {
  final supabase =
      Supabase.instance.client;

  bool isLoading = true;

  String? unblockingUserId;

  List<Map<String, dynamic>>
      blockedPeople = [];

  @override
  void initState() {
    super.initState();

    loadBlockedPeople();
  }

  // ---------------------------------------------------------
  // LOAD BLOCKED PEOPLE
  // ---------------------------------------------------------

  Future<void> loadBlockedPeople() async {
    final user =
        supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        blockedPeople = [];
        isLoading = false;
      });

      return;
    }

    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final blockResponse =
          await supabase
              .from('User_Blocks')
              .select(
                '''
                id,
                blocked_user_id,
                created_at
                ''',
              )
              .eq(
                'blocker_user_id',
                user.id,
              )
              .order(
                'created_at',
                ascending: false,
              );

      final blocks =
          List<Map<String, dynamic>>
              .from(
        blockResponse,
      );

      if (blocks.isEmpty) {
        if (!mounted) return;

        setState(() {
          blockedPeople = [];
          isLoading = false;
        });

        return;
      }

      final blockedUserIds =
          blocks
              .map(
                (block) =>
                    block[
                            'blocked_user_id']
                        ?.toString(),
              )
              .whereType<String>()
              .where(
                (id) =>
                    id.isNotEmpty,
              )
              .toSet()
              .toList();

      if (blockedUserIds.isEmpty) {
        if (!mounted) return;

        setState(() {
          blockedPeople = [];
          isLoading = false;
        });

        return;
      }

      final profileResponse =
          await supabase
              .from('Profiles')
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
                blockedUserIds,
              );

      final profiles =
          List<Map<String, dynamic>>
              .from(
        profileResponse,
      );

      final profilesByUserId =
          <String,
              Map<String, dynamic>>{};

      for (final profile
          in profiles) {
        final userId =
            profile['user_id']
                ?.toString();

        if (userId != null &&
            userId.isNotEmpty) {
          profilesByUserId[userId] =
              profile;
        }
      }

      final people =
          <Map<String, dynamic>>[];

      for (final block in blocks) {
        final blockedUserId =
            block['blocked_user_id']
                ?.toString();

        if (blockedUserId == null ||
            blockedUserId.isEmpty) {
          continue;
        }

        final profile =
            profilesByUserId[
                blockedUserId];

        people.add({
          'block_id':
              block['id'],
          'blocked_user_id':
              blockedUserId,
          'created_at':
              block['created_at'],
          'first_name':
              profile?['first_name'],
          'last_name':
              profile?['last_name'],
          'profile_photo_path':
              profile?[
                  'profile_photo_path'],
        });
      }

      if (!mounted) return;

      setState(() {
        blockedPeople = people;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Unable to load blocked people: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load blocked people. Please try again.',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // CONFIRM UNBLOCK
  // ---------------------------------------------------------

  Future<void> confirmUnblock({
    required String blockedUserId,
    required String displayName,
  }) async {
    if (unblockingUserId != null) {
      return;
    }

    final shouldUnblock =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              FolktriColors.surface,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons
                    .person_add_alt_1_rounded,
                color: FolktriColors
                    .primaryIndigo,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Unblock this person?',
                  style: TextStyle(
                    color: FolktriColors
                        .primaryText,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            displayName.isEmpty
                ? 'You will be able to see this person’s social activity in Folktri again.'
                : 'You will be able to see $displayName’s social activity in Folktri again.',
            style: const TextStyle(
              color: FolktriColors
                  .secondaryText,
              height: 1.4,
            ),
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
            ElevatedButton(
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    FolktriColors
                        .primaryIndigo,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Unblock',
              ),
            ),
          ],
        );
      },
    );

    if (shouldUnblock != true ||
        !mounted) {
      return;
    }

    await unblockUser(
      blockedUserId:
          blockedUserId,
      displayName:
          displayName,
    );
  }

  // ---------------------------------------------------------
  // UNBLOCK
  // ---------------------------------------------------------

  Future<void> unblockUser({
    required String blockedUserId,
    required String displayName,
  }) async {
    final user =
        supabase.auth.currentUser;

    if (user == null ||
        blockedUserId.isEmpty) {
      return;
    }

    setState(() {
      unblockingUserId =
          blockedUserId;
    });

    try {
      await supabase
          .from('User_Blocks')
          .delete()
          .eq(
            'blocker_user_id',
            user.id,
          )
          .eq(
            'blocked_user_id',
            blockedUserId,
          );

      if (!mounted) return;

      setState(() {
        blockedPeople.removeWhere(
          (person) =>
              person[
                      'blocked_user_id']
                  ?.toString() ==
              blockedUserId,
        );

        unblockingUserId = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            displayName.isEmpty
                ? 'Person unblocked.'
                : '$displayName has been unblocked.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Unable to unblock user: $e',
      );

      if (!mounted) return;

      setState(() {
        unblockingUserId = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to unblock this person. Please try again.',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // BLOCKED PERSON CARD
  // ---------------------------------------------------------

  Widget buildBlockedPersonCard(
    Map<String, dynamic> person,
  ) {
    final blockedUserId =
        person['blocked_user_id']
            ?.toString() ??
        '';

    final firstName =
        person['first_name']
            ?.toString()
            .trim() ??
        '';

    final lastName =
        person['last_name']
            ?.toString()
            .trim() ??
        '';

    final fullName = [
      firstName,
      lastName,
    ]
        .where(
          (part) =>
              part.isNotEmpty,
        )
        .join(' ');

    final displayName =
        fullName.isEmpty
            ? 'Family member'
            : fullName;

    final profilePhotoPath =
        person['profile_photo_path']
            ?.toString();

    final isUnblocking =
        unblockingUserId ==
            blockedUserId;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: FolktriColors
              .lightLavender,
        ),
        boxShadow: [
          BoxShadow(
            color: FolktriColors
                .midnightIndigo
                .withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor:
                FolktriColors
                    .lightLavender,
            backgroundImage:
                profilePhotoPath !=
                            null &&
                        profilePhotoPath
                            .isNotEmpty
                    ? NetworkImage(
                        profilePhotoPath,
                      )
                    : null,
            child:
                profilePhotoPath ==
                            null ||
                        profilePhotoPath
                            .isEmpty
                    ? const Icon(
                        Icons
                            .person_rounded,
                        color:
                            FolktriColors
                                .primaryIndigo,
                      )
                    : null,
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  displayName,
                  style:
                      const TextStyle(
                    color:
                        FolktriColors
                            .primaryText,
                    fontSize: 15,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                const Text(
                  'Blocked',
                  style: TextStyle(
                    color:
                        FolktriColors
                            .secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          OutlinedButton(
            onPressed:
                isUnblocking
                    ? null
                    : () {
                        confirmUnblock(
                          blockedUserId:
                              blockedUserId,
                          displayName:
                              displayName,
                        );
                      },
            style:
                OutlinedButton
                    .styleFrom(
              foregroundColor:
                  FolktriColors
                      .primaryIndigo,
              side: const BorderSide(
                color:
                    FolktriColors
                        .primaryIndigo,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
              ),
            ),
            child: isUnblocking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Unblock',
                    style: TextStyle(
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // PAGE
  // ---------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          FolktriColors.background,

      appBar: AppBar(
        backgroundColor:
            FolktriColors
                .midnightIndigo,
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
              'Back to Settings',
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'Privacy & Safety',
          style: TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh:
              loadBlockedPeople,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets
                    .fromLTRB(
              16,
              22,
              16,
              40,
            ),
            children: [
              const Text(
                'BLOCKED PEOPLE',
                style: TextStyle(
                  color:
                      FolktriColors
                          .secondaryText,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'People you block remain members of shared families, but their social activity is hidden from you.',
                style: TextStyle(
                  color:
                      FolktriColors
                          .secondaryText,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              if (isLoading)
                const Padding(
                  padding:
                      EdgeInsets.all(
                    30,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          FolktriColors
                              .primaryIndigo,
                    ),
                  ),
                )
              else if (
                  blockedPeople
                      .isEmpty)
                Container(
                  padding:
                      const EdgeInsets
                          .all(
                    24,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        FolktriColors
                            .surface,
                    borderRadius:
                        BorderRadius
                            .circular(
                      18,
                    ),
                    border:
                        Border.all(
                      color:
                          FolktriColors
                              .lightLavender,
                    ),
                  ),
                  child:
                      const Column(
                    children: [
                      Icon(
                        Icons
                            .shield_outlined,
                        size: 38,
                        color:
                            FolktriColors
                                .primaryIndigo,
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Text(
                        'No blocked people',
                        style:
                            TextStyle(
                          color:
                              FolktriColors
                                  .primaryText,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                      SizedBox(
                        height: 6,
                      ),
                      Text(
                        'People you block will appear here.',
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
                )
              else
                ...blockedPeople.map(
                  buildBlockedPersonCard,
                ),
            ],
          ),
        ),
      ),
    );
  }
}