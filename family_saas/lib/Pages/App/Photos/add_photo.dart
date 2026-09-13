import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPhotoPage extends StatefulWidget {
  final String familyId;
  final String? childId;

  const AddPhotoPage({
    super.key,
    required this.familyId,
    this.childId,
  });

  @override
  State<AddPhotoPage> createState() =>
      _AddPhotoPageState();
}

class _AddPhotoPageState
    extends State<AddPhotoPage> {

  final supabase =
      Supabase.instance.client;

  final ImagePicker imagePicker =
      ImagePicker();

  final captionController =
      TextEditingController();

  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  bool isSaving = false;

  Future<void> pickImage() async {
    final image =
        await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes =
        await image.readAsBytes();

    if (!mounted) return;

    setState(() {
      selectedImage = image;
      selectedImageBytes = bytes;
    });
  }

  Future<String> uploadPhoto({
    required String photoId,
  }) async {
    final extension =
        selectedImage!.name
            .split('.')
            .last;

    final filePath =
        '${widget.familyId}/$photoId/photo.$extension';

    await supabase.storage
        .from('family-photos')
        .uploadBinary(
          filePath,
          selectedImageBytes!,
          fileOptions:
              const FileOptions(
            upsert: true,
          ),
        );

    return supabase.storage
        .from('family-photos')
        .getPublicUrl(filePath);
  }

  Future<void> savePhoto() async {
    final user =
        supabase.auth.currentUser;

    if (user == null) return;

    if (selectedImage == null ||
        selectedImageBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a photo.',
          ),
        ),
      );

      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      // Create the database row first.
      final createdPhoto =
          await supabase
              .from('Photos')
              .insert({
                'family_id':
                    widget.familyId,

                'child_id':
                    widget.childId,

                'photo_url': '',

                'caption':
                    captionController
                            .text
                            .trim()
                            .isEmpty
                        ? null
                        : captionController
                            .text
                            .trim(),

                'created_by':
                    user.id,
              })
              .select()
              .single();

      final photoId =
          createdPhoto['id']
              .toString();

      // Upload the actual image.
      final photoUrl =
          await uploadPhoto(
        photoId: photoId,
      );

      // Save its URL.
      await supabase
          .from('Photos')
          .update({
            'photo_url':
                photoUrl,
          })
          .eq(
            'id',
            photoId,
          );

      if (!mounted) return;

      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to post photo: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Add Photo',
        ),
      ),
      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (selectedImageBytes !=
                null)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                child: Image.memory(
                  selectedImageBytes!,
                  width:
                      double.infinity,
                  height: 300,
                  fit:
                      BoxFit.cover,
                ),
              )
            else
              Container(
                width:
                    double.infinity,
                height: 250,
                decoration:
                    BoxDecoration(
                  border:
                      Border.all(),
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),
                child:
                    const Center(
                  child: Icon(
                    Icons
                        .add_photo_alternate,
                    size: 60,
                  ),
                ),
              ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    pickImage,
                icon:
                    const Icon(
                  Icons.photo_library,
                ),
                label: Text(
                  selectedImage == null
                      ? 'Choose Photo'
                      : 'Change Photo',
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
                  captionController,
              maxLines: 3,
              decoration:
                  const InputDecoration(
                labelText:
                    'Caption (optional)',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    isSaving
                        ? null
                        : savePhoto,
                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Post Photo',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}