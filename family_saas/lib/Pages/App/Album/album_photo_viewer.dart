import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Styling/folktri_colors.dart';

class AlbumPhotoViewerPage
    extends StatefulWidget {
  final String albumId;

  final List<Map<String, dynamic>> photos;

  final int initialIndex;

  const AlbumPhotoViewerPage({
    super.key,
    required this.albumId,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<AlbumPhotoViewerPage> createState() =>
      _AlbumPhotoViewerPageState();
}

class _AlbumPhotoViewerPageState
    extends State<AlbumPhotoViewerPage> {
  final supabase =
      Supabase.instance.client;

  late PageController pageController;

  late List<Map<String, dynamic>>
      viewerPhotos;

  late int currentIndex;

  @override
  void initState() {
    super.initState();

    viewerPhotos =
        List<Map<String, dynamic>>.from(
      widget.photos,
    );

    currentIndex =
        widget.initialIndex;

    pageController =
        PageController(
      initialPage: currentIndex,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,

        title: Text(
          '${currentIndex + 1} of '
          '${viewerPhotos.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),

        centerTitle: true,
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
          final photo =
              viewerPhotos[index];

          final photoUrl =
              photo['photo_url']
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

                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons
                        .broken_image_outlined,
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