import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Styling/folktri_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ViewAlbumPage extends StatefulWidget {
  final String albumId;
  final String albumName;

  const ViewAlbumPage({
    super.key,
    required this.albumId,
    required this.albumName,
  });

  @override
  State<ViewAlbumPage> createState() =>
      _ViewAlbumPageState();
}

class _ViewAlbumPageState extends State<ViewAlbumPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> photos = [];

  bool isLoading = true;

  bool albumChanged = false;

  @override
  void initState() {
    super.initState();
    loadAlbumPhotos();
  }

  Future<void> loadAlbumPhotos() async {
    try {
      final response = await supabase
          .from('Photo_Album_Items')
          .select('''
            id,
            photo_id,
            Photos (
              id,
              photo_url
            )
          ''')
          .eq(
            'album_id',
            widget.albumId,
          )
          .order(
            'created_at',
            ascending: true,
          );

      final items =
          List<Map<String, dynamic>>.from(
        response,
      );

      final loadedPhotos =
          <Map<String, dynamic>>[];

      for (final item in items) {
        final photo = item['Photos'];

        if (photo is Map) {
          loadedPhotos.add(
            Map<String, dynamic>.from(
              photo,
            ),
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        photos = loadedPhotos;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'LOAD ALBUM PHOTOS ERROR: $e',
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
            'Unable to load album photos.',
          ),
        ),
      );
    }
  }

  Future<void> deleteAlbum() async {
  try {
    // Remove the photo-to-album associations first.
    // This does NOT delete the actual Photos rows.
    await supabase
        .from('Photo_Album_Items')
        .delete()
        .eq(
          'album_id',
          widget.albumId,
        );

    // Now delete the album itself.
    await supabase
        .from('Photo_Albums')
        .delete()
        .eq(
          'id',
          widget.albumId,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Album deleted.',
        ),
      ),
    );

    context.pop(true);
  } catch (e) {
    debugPrint(
      'DELETE ALBUM ERROR: $e',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to delete album.',
        ),
      ),
    );
  }
}

  Future<void> showDeleteAlbumDialog() async {
  final shouldDelete =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Delete album?',
        ),
        content: Text(
          'Delete "${widget.albumName}"? '
          'The photos will remain in your '
          'Family Album.',
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

  if (shouldDelete == true) {
    await deleteAlbum();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolktriColors.background,

      appBar: AppBar(
        backgroundColor: FolktriColors.midnightIndigo,
        foregroundColor:FolktriColors.surface,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            context.pop(albumChanged);
          },
        ),

        title: Text(
          widget.albumName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: FolktriColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: FolktriColors.surface,
            ),
            onSelected: (value) {
              if (value == 'delete') {
                showDeleteAlbumDialog();
              }
            },
        itemBuilder: (context) {
          return const [
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text('Delete album',),
            ],
          ),
        ),
      ];
    },
  ),
],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: FolktriColors.primaryIndigo,
              ),
            )
          : photos.isEmpty
              ? Center(
                  child: Text(
                    'No photos in this album.',
                    style: GoogleFonts.poppins(
                      color:FolktriColors.secondaryText,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12,),
                      child: Text(
                        '${photos.length} '
                        '${photos.length == 1 ? 'photo' : 'photos'}',
                        style: GoogleFonts.poppins(
                          color: FolktriColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    Expanded(
                      child:
                          GridView.builder(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 16,),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:3,
                          crossAxisSpacing: 3,
                          mainAxisSpacing: 3,
                          childAspectRatio: 1,
                        ),
                        itemCount: photos.length,
                        itemBuilder:
                            (context, index,) {
                          final photo = photos[index];

                          final photoUrl =
                              photo['photo_url']
                                      ?.toString()
                                      .trim() ??
                                  '';

                          return GestureDetector(
                            onTap: () async {
                                final changed =
                                  await context.push<bool>(
                                    '/family/familyId/albums/${widget.albumId}/photo',
                                    extra: {
                                      'photos': photos,
                                      'initialIndex': index,
                                    },
                                  );

                              if (changed == true && mounted) {
                                albumChanged = true;

                                await loadAlbumPhotos();
                              }
                            },
                          
                            child: Container(
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
                                        errorBuilder: (context, error, stackTrace,) {
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}