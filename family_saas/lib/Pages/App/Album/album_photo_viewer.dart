import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import '../../Styling/folktri_colors.dart';

class AlbumPhotoViewerPage extends StatefulWidget {
  final String? albumId;

  final List<Map<String, dynamic>> photos;

  final int initialIndex;

  const AlbumPhotoViewerPage({
    super.key,
    this.albumId,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<AlbumPhotoViewerPage> createState() =>
      _AlbumPhotoViewerPageState();
}

class _AlbumPhotoViewerPageState extends State<AlbumPhotoViewerPage> {
  final supabase = Supabase.instance.client;

  late PageController pageController;

  late List<Map<String, dynamic>> viewerPhotos;

  late int currentIndex;

  bool albumChanged = false;

  @override
  void initState() {
    super.initState();

    viewerPhotos = List<Map<String, dynamic>>.from(widget.photos,);

    currentIndex = widget.initialIndex;

    pageController = PageController(initialPage: currentIndex,);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> removeCurrentPhoto() async {
    final albumId = widget.albumId;

    if (albumId == null) {
      return;
    }

    if (viewerPhotos.isEmpty) {
      return;
    }

    final photo = viewerPhotos[currentIndex];

    final photoId = photo['id']?.toString() ?? '';

    if (photoId.isEmpty) {
      return;
    }

  final shouldRemove = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Remove photo?',),
        content: const Text(
          'This photo will be removed from '
          'this album, but it will remain '
          'in All Photos.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(false);
            },
            child: const Text('Cancel',),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(true);
            },
            child: const Text(
              'Remove',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (shouldRemove != true) {
    return;
  }

  try {
    await supabase
        .from('Photo_Album_Items')
        .delete()
        .eq(
          'album_id',
          albumId,
        )
        .eq(
          'photo_id',
          photoId,
        );

    albumChanged = true;

    if (!mounted) {
      return;
    }

    setState(() {
      viewerPhotos.removeAt(currentIndex,);

      if (viewerPhotos.isNotEmpty && currentIndex >= viewerPhotos.length) {
        currentIndex = viewerPhotos.length - 1;
      }
    });

    // If that was the last photo,
    // return to the album.
    if (viewerPhotos.isEmpty) {
      context.pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo removed from album.',),
      ),
    );
  } catch (e) {
    debugPrint(
      'REMOVE ALBUM PHOTO ERROR: $e',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to remove photo.',),
      ),
    );
  }
}

  Future<void> deleteCurrentPhoto() async {
  if (viewerPhotos.isEmpty) {
    return;
  }

  final photo =
      viewerPhotos[currentIndex];

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
    // Delete Photos row.
    // Photo_Album_Items will be cleaned up
    // automatically by ON DELETE CASCADE.
    await supabase
        .from('Photos')
        .delete()
        .eq(
          'id',
          photoId,
        );

    // Try to remove the actual Storage object.
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

    albumChanged = true;

    setState(() {
      viewerPhotos.removeAt(
        currentIndex,
      );

      if (viewerPhotos.isNotEmpty &&
          currentIndex >=
              viewerPhotos.length) {
        currentIndex =
            viewerPhotos.length - 1;
      }
    });

    // If there are no photos left,
    // return to All Photos.
    if (viewerPhotos.isEmpty) {
      context.pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            context.pop(albumChanged);
          },
        ),

        title: Text(
          '${currentIndex + 1} of '
          '${viewerPhotos.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),

        centerTitle: true,

       actions: [
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Colors.white,
        ),

        onSelected: (value) async {
          if (value == 'remove') {
            await removeCurrentPhoto();
          }

          if (value == 'delete') {
            await deleteCurrentPhoto();
          }
        },

        itemBuilder: (context) {
      // Viewer was opened from an album.
          if (widget.albumId != null) {
            return const [
              PopupMenuItem<String>(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Remove from album',),
              ],
            ),
          ),
        ];
      }

      // Viewer was opened from All Photos.
      return const [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons
                    .delete_outline_rounded,
                color: Colors.red,
                size: 20,
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
],
      ),

      body: PageView.builder(
        controller: pageController,
        itemCount: viewerPhotos.length,

        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        itemBuilder: (
          context,
          index,
        ) {
          final photo = viewerPhotos[index];

          final photoUrl = photo['photo_url']
                      ?.toString()
                      .trim() ??
                  '';

          return Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,

                errorBuilder: (context, error, stackTrace,) {
                  return const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 42,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}