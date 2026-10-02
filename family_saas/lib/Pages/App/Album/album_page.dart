import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Styling/folktri_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AlbumPage extends StatefulWidget {
  final String familyId;

  const AlbumPage({
    super.key,
    required this.familyId,
  });

  @override
  State<AlbumPage> createState() =>
      _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;

  List<Map<String, dynamic>> photos = [];
  List<Map<String, dynamic>> albums = [];

  @override
  void initState() {
    super.initState();
    loadPhotos();
    loadAlbums();
  }

  Future<void> loadPhotos() async {
  try {
    setState(() {
      isLoading = true;
    });

    final response = await supabase
        .from('Photos')
        .select()
        .eq(
          'family_id',
          widget.familyId,
        )
        .order(
          'created_at',
          ascending: false,
        );

    final loadedPhotos =
        List<Map<String, dynamic>>.from(
      response,
    ).where(
      (photo) {
        final mediaType =
            photo['media_type']
                    ?.toString()
                    .toLowerCase();

        // Older photo rows may have a null
        // media_type, so only exclude rows
        // explicitly identified as videos.
        return mediaType != 'video';
      },
    ).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      photos = loadedPhotos;
      isLoading = false;
    });
  } catch (e) {
    debugPrint(
      'ALBUM LOAD PHOTOS ERROR: $e',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to load family photos.',
        ),
      ),
    );
  }
}

  Future<void> loadAlbums() async {
  try {
    final response = await supabase
        .from('Photo_Albums')
        .select('''
          id,
          name,
          created_at,
          Photo_Album_Items (
            id,
            photo_id,
            Photos (
              id,
              photo_url
            )
          )
        ''')
        .eq(
          'family_id',
          widget.familyId,
        )
        .order(
          'created_at',
          ascending: false,
        );

        debugPrint(
  'ALBUMS RESPONSE: $response',
);

    if (!mounted) {
      return;
    }

    setState(() {
      albums =
          List<Map<String, dynamic>>.from(
        response,
      );
    });
  } catch (e) {
    debugPrint(
      'LOAD ALBUMS ERROR: $e',
    );
  }
}

  Future<void> addPhotoToAlbum({
  required String photoId,
  required String albumId,
  required String albumName,
}) async {
  try {
    final user =
        supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    // Check whether this photo is
    // already in this album.
    final existing = await supabase
        .from('Photo_Album_Items')
        .select('id')
        .eq(
          'album_id',
          albumId,
        )
        .eq(
          'photo_id',
          photoId,
        )
        .maybeSingle();

    if (existing != null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'This photo is already in '
            '$albumName.',
          ),
        ),
      );

      return;
    }

    await supabase
        .from('Photo_Album_Items')
        .insert({
      'album_id': albumId,
      'photo_id': photoId,
      'added_by': user.id,
    });

    await loadAlbums();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Added to $albumName.',
        ),
      ),
    );
  } catch (e) {
    debugPrint(
      'ADD PHOTO TO ALBUM ERROR: $e',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to add photo to album.',
        ),
      ),
    );
  }
}

  Future<void> deletePhoto(
  Map<String, dynamic> photo,
) async {
  final photoId =
      photo['id']?.toString() ?? '';

  final photoUrl =
      photo['photo_url']
              ?.toString()
              .trim() ??
          '';

  if (photoId.isEmpty) {
    return;
  }

  final shouldDelete =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Delete photo?',
        ),
        content: const Text(
          'This photo will be permanently deleted '
          'from Folktri and removed from any albums '
          'that contain it. This cannot be undone.',
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
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
              ),
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
    // Delete the database row first.
    //
    // Photo_Album_Items.photo_id uses
    // ON DELETE CASCADE, so Supabase will
    // automatically remove this photo from
    // every album containing it.
    await supabase
        .from('Photos')
        .delete()
        .eq(
          'id',
          photoId,
        );

    // Attempt to remove the actual image
    // from the family_photos Storage bucket.
    if (photoUrl.isNotEmpty) {
      try {
        final uri =
            Uri.parse(photoUrl);

        const marker =
            '/family_photos/';

        final markerIndex =
            uri.path.indexOf(marker);

        if (markerIndex != -1) {
          final storagePath =
              Uri.decodeComponent(
            uri.path.substring(
              markerIndex +
                  marker.length,
            ),
          );

          if (storagePath.isNotEmpty) {
            await supabase.storage
                .from('family_photos')
                .remove([
              storagePath,
            ]);
          }
        }
      } catch (storageError) {
        debugPrint(
          'DELETE PHOTO STORAGE ERROR: '
          '$storageError',
        );
      }
    }

    if (!mounted) {
      return;
    }

    // Reload All Photos.
    await loadPhotos();

    // Reload albums so their cover/count
    // immediately reflects the deletion.
    await loadAlbums();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Photo deleted.',
        ),
      ),
    );
  } catch (e) {
    debugPrint(
      'DELETE PHOTO ERROR: $e',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to delete photo.',
        ),
      ),
    );
  }
}

  Future<void> showAddToAlbumDialog(
  Map<String, dynamic> photo,
) async {
  final photoId =
      photo['id']?.toString() ?? '';

  if (photoId.isEmpty) {
    return;
  }

  if (albums.isEmpty) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Create an album first.',
        ),
      ),
    );

    return;
  }

  await showModalBottomSheet(
    context: context,
    backgroundColor:
        FolktriColors.surface,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                12,
              ),
              child: Text(
                'Add to album',
                style:
                    GoogleFonts.poppins(
                  color:
                      FolktriColors
                          .primaryText,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount:
                    albums.length,
                itemBuilder:
                    (context, index) {
                  final album =
                      albums[index];

                  final albumId =
                      album['id']
                              ?.toString() ??
                          '';

                  final albumName =
                      album['name']
                              ?.toString() ??
                          'Album';

                  return ListTile(
                    leading: const Icon(
                      Icons
                          .photo_album_outlined,
                      color:
                          FolktriColors
                              .primaryIndigo,
                    ),

                    title: Text(
                      albumName,
                    ),

                    onTap: () async {
                      Navigator.of(
                        sheetContext,
                      ).pop();

                      await addPhotoToAlbum(
                        photoId:
                            photoId,
                        albumId:
                            albumId,
                        albumName:
                            albumName,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          FolktriColors.background,

      appBar: AppBar(
        backgroundColor: FolktriColors.midnightIndigo,
        elevation: 0,

        automaticallyImplyLeading: false,

        title: Text(
          'Family Album',
          style: GoogleFonts.poppins(
            color:
                FolktriColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),



        actions: [
          IconButton(
            tooltip: 'Create album',
            onPressed: () async {
              final created =
                await context.push<bool>(
                  '/family/${widget.familyId}/albums/create',
                );

              if (created == true && mounted) {
               // await loadPhotos();
                await loadAlbums();
              }
            },
            icon: const Icon(
              Icons.add_rounded,
              color: FolktriColors.surface,
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadPhotos,
              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (albums.isNotEmpty) ...[
  SliverToBoxAdapter(
    child: Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        12,
      ),
      child: Text(
        'Albums',
        style: GoogleFonts.poppins(
          color:
              FolktriColors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
  if (albums.isNotEmpty)

  SliverToBoxAdapter(
    child: SizedBox(
      height: 185,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder:
            (context, index) =>
                const SizedBox(
          width: 12,
        ),
        itemBuilder:
            (context, index) {
          final album =
              albums[index];

          final albumName =
              album['name']
                      ?.toString() ??
                  'Album';

          final albumItems =
              album[
                  'Photo_Album_Items'];

          final items =
              albumItems is List
                  ? albumItems
                  : [];
          
          String coverUrl = '';

          if (items.isNotEmpty) {
            final firstItem =
                items.first;

            if (firstItem is Map) {
              final photo =
                  firstItem['Photos'];

              if (photo is Map) {
                coverUrl =
                    photo['photo_url']
                            ?.toString()
                            .trim() ??
                        '';
              }
            }
          }

          final photoCount =
              items.length;

          return SizedBox(
            width: 145,
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              // We'll connect this to
              // the individual album
              // page next.
              onTap: () async {
                final albumId = album['id']?.toString() ?? '';

                if (albumId.isEmpty) {
                  return;
                }

                final deleted = await context.push<bool>(
                  '/family/${widget.familyId}/albums/$albumId'
                  '?name=${Uri.encodeComponent(albumName)}',
                );

                if (deleted == true && mounted) {
                  await loadAlbums();
                }
              },

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14,),
                    child: Container(
                      width: 145,
                      height: 130,
                      color: FolktriColors.lightLavender,
                      child:
                          coverUrl.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.photo_album_outlined,
                                    size: 36,
                                    color: FolktriColors.secondaryText,
                                  ),
                                )
                              : Image.network(
                                  coverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Center(
                                      child:
                                          Icon(
                                            Icons.broken_image_outlined,
                                        color: FolktriColors.secondaryText,
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    albumName,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        GoogleFonts
                            .poppins(
                      color:
                          FolktriColors
                              .primaryText,
                      fontSize: 13,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),

                  Text(
                    '$photoCount '
                    '${photoCount == 1 ? 'photo' : 'photos'}',
                    style:
                        GoogleFonts
                            .poppins(
                      color:
                          FolktriColors
                              .secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  ),

  const SliverToBoxAdapter(
    child: SizedBox(
      height: 10,
    ),
  ),
],

                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        16,
                        18,
                        16,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'All Photos',
                              style:
                                  GoogleFonts
                                      .poppins(
                                color:
                                    FolktriColors
                                        .primaryText,
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),

                          Text(
                            '${photos.length} '
                            '${photos.length == 1 ? 'photo' : 'photos'}',
                            style:
                                GoogleFonts
                                    .poppins(
                              color:
                                  FolktriColors
                                      .secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (photos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(32),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              const Icon(
                                Icons
                                    .photo_library_outlined,
                                size: 54,
                                color:
                                    FolktriColors
                                        .secondaryText,
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              Text(
                                'No photos yet',
                                style:
                                    GoogleFonts
                                        .poppins(
                                  color:
                                      FolktriColors
                                          .primaryText,
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                'Photos shared with this family will appear here.',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    GoogleFonts
                                        .poppins(
                                  color:
                                      FolktriColors
                                          .secondaryText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        4,
                        0,
                        4,
                        24,
                      ),
                      sliver:
                          SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              3,
                          crossAxisSpacing:
                              3,
                          mainAxisSpacing:
                              3,
                          childAspectRatio:
                              1,
                        ),
                        delegate:
                            SliverChildBuilderDelegate(
                          (
                            context,
                            index,
                          ) {
                            final photo =
                                photos[
                                    index];

                            final photoUrl =
                              photo['photo_url']
                              ?.toString()
                                .trim() ??
                              '';

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final changed =
                                      await context.push<bool>(
                                        '/all-photos/view',
                                        extra: {
                                          'photos': photos,
                                          'initialIndex': index,
                                        },
                                      );

                                  if (changed == true && mounted) {
                                    await loadPhotos();
                                    await loadAlbums();
                                  }
                                },

                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3,),
                              child:
                                  Container(
                                color: FolktriColors.lightLavender,
                                child: photoUrl.isEmpty
                                    ? const Center(
                                        child:
                                            Icon(
                                          Icons.broken_image_outlined,
                                          color: FolktriColors.secondaryText,
                                        ),
                                      )
                                    : Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace,) {
                                          return const Center(
                                            child:
                                                Icon(
                                              Icons.broken_image_outlined,
                                              color:FolktriColors.secondaryText,
                                            ),
                                          );
                                        },
                                      ),
                                  ),
                                ),
                                ),

                                Positioned(
                                  top: 3,
                                  right: 3,
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,

                                    icon: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.55,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ),

                                  onSelected: (value) async {
                                    if (value == 'album') {
                                      await showAddToAlbumDialog(photo,);
                                      return;
                                }

      if (value == 'delete') {
        await deletePhoto(
          photo,
        );
      }
    },

    itemBuilder: (context) {
      return const [
        PopupMenuItem<String>(
          value: 'album',
          child: Row(
            children: [
              Icon(
                Icons
                    .photo_album_outlined,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Add to album',
              ),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons
                    .delete_outline_rounded,
                size: 20,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text(
                'Delete photo',
              ),
            ],
          ),
        ),
      ];
    },
  ),
),
                                
                              ],
                            );
                          },
                          childCount:
                              photos.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            bottomNavigationBar: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,

  backgroundColor:
      FolktriColors.surface,

  selectedItemColor:
      FolktriColors.primaryIndigo,

  unselectedItemColor:
      FolktriColors.secondaryText,

  selectedLabelStyle:
      const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12,
  ),

  unselectedLabelStyle:
      const TextStyle(
    fontSize: 12,
  ),

  showSelectedLabels: true,
  showUnselectedLabels: true,

  // Albums is the fourth item.
  currentIndex: 3,

  onTap: (index) {
    switch (index) {
      case 0:
        // Home / Family Dashboard
        context.go('/app');
        break;

      case 1:
        // Calendar for the current family.
        context.go(
          '/family/${widget.familyId}/calendar',
        );
        break;

      case 2:
        // Family area.
        context.go('/families');
        break;

      case 3:
        // Already on Albums.
        break;

      case 4:
        // Notifications.
        context.go('/notifications');
        break;
    }
  },

  items: const [
    BottomNavigationBarItem(
      icon: Icon(
        Icons.home_outlined,
      ),
      activeIcon: Icon(
        Icons.home,
      ),
      label: 'Home',
    ),

    BottomNavigationBarItem(
      icon: Icon(
        Icons.calendar_month_outlined,
      ),
      activeIcon: Icon(
        Icons.calendar_month,
      ),
      label: 'Calendar',
    ),

    BottomNavigationBarItem(
      icon: Icon(
        Icons.family_restroom_outlined,
      ),
      activeIcon: Icon(
        Icons.family_restroom,
      ),
      label: 'Family',
    ),

    BottomNavigationBarItem(
      icon: Icon(
        Icons.photo_library_outlined,
      ),
      activeIcon: Icon(
        Icons.photo_library,
      ),
      label: 'Albums',
    ),

    BottomNavigationBarItem(
      icon: Icon(
        Icons.notifications_outlined,
      ),
      activeIcon: Icon(
        Icons.notifications_rounded,
      ),
      label: 'Notifications',
    ),
  ],
),
    );
  }
}