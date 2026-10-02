import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Styling/folktri_colors.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _ViewAlbumPageState
    extends State<ViewAlbumPage> {
  final supabase =
      Supabase.instance.client;

  List<Map<String, dynamic>> photos = [];

  bool isLoading = true;

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

        title: Text(
          widget.albumName,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color:
                FolktriColors.surface,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    FolktriColors
                        .primaryIndigo,
              ),
            )
          : photos.isEmpty
              ? Center(
                  child: Text(
                    'No photos in this album.',
                    style:
                        GoogleFonts.poppins(
                      color:
                          FolktriColors
                              .secondaryText,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        16,
                        16,
                        16,
                        12,
                      ),
                      child: Text(
                        '${photos.length} '
                        '${photos.length == 1 ? 'photo' : 'photos'}',
                        style:
                            GoogleFonts
                                .poppins(
                          color:
                              FolktriColors
                                  .secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    Expanded(
                      child:
                          GridView.builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          4,
                          0,
                          4,
                          16,
                        ),
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
                        itemCount:
                            photos.length,
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final photo =
                              photos[index];

                          final photoUrl =
                              photo['photo_url']
                                      ?.toString()
                                      .trim() ??
                                  '';

                          return Container(
                            color:
                                FolktriColors
                                    .lightLavender,
                            child:
                                photoUrl.isEmpty
                                    ? const Center(
                                        child:
                                            Icon(
                                          Icons
                                              .broken_image_outlined,
                                          color:
                                              FolktriColors.secondaryText,
                                        ),
                                      )
                                    : Image.network(
                                        photoUrl,
                                        fit:
                                            BoxFit.cover,
                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Center(
                                            child:
                                                Icon(
                                              Icons
                                                  .broken_image_outlined,
                                              color:
                                                  FolktriColors.secondaryText,
                                            ),
                                          );
                                        },
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