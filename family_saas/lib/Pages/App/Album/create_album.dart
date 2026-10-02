import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Styling/folktri_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAlbumPage
    extends StatefulWidget {
  final String familyId;

  const CreateAlbumPage({
    super.key,
    required this.familyId,
  });

  @override
  State<CreateAlbumPage> createState() =>
      _CreateAlbumPageState();
}

class _CreateAlbumPageState
    extends State<CreateAlbumPage> {
  final supabase =
      Supabase.instance.client;

  final albumNameController =
      TextEditingController();

  List<Map<String, dynamic>> photos = [];

  final Set<String> selectedPhotoIds =
      {};

  bool isLoading = true;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  @override
  void dispose() {
    albumNameController.dispose();
    super.dispose();
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

          // Some older Folktri photos
          // have a null media_type.
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
        'CREATE ALBUM LOAD PHOTOS ERROR: $e',
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

  void togglePhoto(
    String photoId,
  ) {
    setState(() {
      if (selectedPhotoIds.contains(
        photoId,
      )) {
        selectedPhotoIds.remove(
          photoId,
        );
      } else {
        selectedPhotoIds.add(
          photoId,
        );
      }
    });
  }

  Future<void> createAlbum() async {
    if (isCreating) {
      return;
    }

    final albumName =
        albumNameController.text.trim();

    if (albumName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter an album name.',
          ),
        ),
      );

      return;
    }

    if (selectedPhotoIds.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one photo.',
          ),
        ),
      );

      return;
    }

    final currentUser =
        supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in again.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isCreating = true;
    });

    String? createdAlbumId;

    try {
      final albumResponse =
          await supabase
              .from('Photo_Albums')
              .insert({
                'family_id':
                    widget.familyId,
                'name': albumName,
                'created_by':
                    currentUser.id,
              })
              .select('id')
              .single();

      createdAlbumId =
          albumResponse['id']
              ?.toString();

      if (createdAlbumId == null ||
          createdAlbumId.isEmpty) {
        throw Exception(
          'Album ID was not returned.',
        );
      }

      final albumItems =
          selectedPhotoIds
              .map(
                (photoId) => {
                  'album_id':
                      createdAlbumId,
                  'photo_id':
                      photoId,
                  'added_by':
                      currentUser.id,
                },
              )
              .toList();

      await supabase
          .from('Photo_Album_Items')
          .insert(albumItems);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Album created.',
          ),
        ),
      );

      context.pop(true);
    } catch (e) {
      debugPrint(
        'CREATE ALBUM ERROR: $e',
      );

      // If the album itself was created
      // but adding its photos failed,
      // remove the empty/partial album.
      if (createdAlbumId != null &&
          createdAlbumId.isNotEmpty) {
        try {
          await supabase
              .from('Photo_Albums')
              .delete()
              .eq(
                'id',
                createdAlbumId,
              );
        } catch (cleanupError) {
          debugPrint(
            'CREATE ALBUM CLEANUP ERROR: '
            '$cleanupError',
          );
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to create album.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }
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

        title: Text(
          'Create Album',
          style: GoogleFonts.poppins(
            color:
                FolktriColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),

        centerTitle: true,
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
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    16,
                    20,
                    16,
                    12,
                  ),
                  child: TextField(
                    controller:
                        albumNameController,
                    maxLength: 60,
                    textCapitalization:
                        TextCapitalization
                            .words,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Album name',
                      hintText:
                          'e.g. Summer Vacation',
                      counterText: '',
                      filled: true,
                      fillColor:
                          FolktriColors
                              .surface,
                      prefixIcon:
                          const Icon(
                        Icons
                            .photo_album_outlined,
                        color:
                            FolktriColors
                                .primaryIndigo,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    16,
                    6,
                    16,
                    12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Photos',
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
                      ),

                      Text(
                        '${selectedPhotoIds.length} selected',
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

                Expanded(
                  child: photos.isEmpty
                      ? Center(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(
                              32,
                            ),
                            child: Text(
                              'There are no family photos to add yet.',
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  GoogleFonts
                                      .poppins(
                                color:
                                    FolktriColors
                                        .secondaryText,
                                fontSize:
                                    14,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
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
                                photos[
                                    index];

                            final photoId =
                                photo['id']
                                        ?.toString() ??
                                    '';

                            final photoUrl =
                                photo['photo_url']
                                        ?.toString()
                                        .trim() ??
                                    '';

                            final isSelected =
                                selectedPhotoIds
                                    .contains(
                              photoId,
                            );

                            return GestureDetector(
                              onTap:
                                  photoId.isEmpty
                                      ? null
                                      : () {
                                          togglePhoto(
                                            photoId,
                                          );
                                        },
                              child: Stack(
                                fit:
                                    StackFit
                                        .expand,
                                children: [
                                  Container(
                                    color:
                                        FolktriColors
                                            .lightLavender,
                                    child:
                                        photoUrl
                                                .isEmpty
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
                                                      Icons.broken_image_outlined,
                                                      color:
                                                          FolktriColors.secondaryText,
                                                    ),
                                                  );
                                                },
                                              ),
                                  ),

                                  if (isSelected)
                                    Container(
                                      color: FolktriColors
                                          .primaryIndigo
                                          .withValues(
                                        alpha:
                                            0.28,
                                      ),
                                    ),

                                  Positioned(
                                    top: 7,
                                    right: 7,
                                    child:
                                        AnimatedContainer(
                                      duration:
                                          const Duration(
                                        milliseconds:
                                            150,
                                      ),
                                      width: 25,
                                      height:
                                          25,
                                      decoration:
                                          BoxDecoration(
                                        shape:
                                            BoxShape
                                                .circle,
                                        color: isSelected
                                            ? FolktriColors
                                                .primaryIndigo
                                            : Colors
                                                .black
                                                .withValues(
                                              alpha:
                                                  0.35,
                                            ),
                                        border:
                                            Border.all(
                                          color:
                                              Colors.white,
                                          width:
                                              2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons
                                                  .check_rounded,
                                              size:
                                                  16,
                                              color:
                                                  Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      10,
                      16,
                      14,
                    ),
                    child:
                        SizedBox(
                      width:
                          double.infinity,
                      height: 50,
                      child:
                          ElevatedButton(
                        onPressed:
                            isCreating
                                ? null
                                : createAlbum,
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              FolktriColors
                                  .primaryIndigo,
                          foregroundColor:
                              FolktriColors
                                  .surface,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),
                        child: isCreating
                            ? const SizedBox(
                                width:
                                    20,
                                height:
                                    20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : Text(
                                'Create Album',
                                style:
                                    GoogleFonts
                                        .poppins(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}