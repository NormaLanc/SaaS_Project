import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Styling/folktri_colors.dart';

class AddPhotoPage extends StatefulWidget {
  final String familyId;
  final String? childId;
  final String? mediaType;

  const AddPhotoPage({
    super.key,
    required this.familyId,
    this.childId,
    this.mediaType = 'photo',
  });

  bool get isVideo => mediaType == 'video';

  @override
  State<AddPhotoPage> createState() => _AddPhotoPageState();
}

class _AddPhotoPageState extends State<AddPhotoPage> {

  final supabase = Supabase.instance.client;

  final ImagePicker imagePicker = ImagePicker();

  final captionController = TextEditingController();

  XFile? selectedMedia;
  Uint8List? selectedMediaBytes;

  bool isSaving = false;

  Future<void> pickMedia() async {
  try {
    XFile? media;

    if (widget.isVideo) {
      media =
          await imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
    } else {
      media =
          await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    }

    if (media == null) return;

    final bytes =
        await media.readAsBytes();

    if (!mounted) return;

    setState(() {
      selectedMedia = media;
      selectedMediaBytes = bytes;
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          widget.isVideo
              ? 'Unable to select video: $e'
              : 'Unable to select photo: $e',
        ),
      ),
    );
  }
}

  Future<String> uploadMedia({
  required String photoId,
}) async {
  final media = selectedMedia;
  final bytes = selectedMediaBytes;

  if (media == null ||
      bytes == null) {
    throw Exception(
      'No media selected.',
    );
  }

  final fileName =
      media.name;

  final extension =
      fileName.contains('.')
          ? fileName
              .split('.')
              .last
              .toLowerCase()
          : widget.isVideo
              ? 'mp4'
              : 'jpg';

  final mediaFileName =
      widget.isVideo
          ? 'video.$extension'
          : 'photo.$extension';

  final filePath =
      '${widget.familyId}/'
      '$photoId/'
      '$mediaFileName';

  await supabase.storage
      .from('family_photos')
      .uploadBinary(
        filePath,
        bytes,
      );

  return supabase.storage
      .from('family_photos')
      .getPublicUrl(
        filePath,
      );
}

  Future<void> saveMedia() async {
  final user =
      supabase.auth.currentUser;

  if (user == null) return;

  if (selectedMedia == null ||
      selectedMediaBytes == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          widget.isVideo
              ? 'Please select a video.'
              : 'Please select a photo.',
        ),
      ),
    );

    return;
  }

  try {
    setState(() {
      isSaving = true;
    });

    final createdPhoto =
        await supabase
            .from('Photos')
            .insert({
              'family_id':
                  widget.familyId,

              'child_id':
                  widget.childId,

              'photo_url':
                  '',

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

              // Your Photos table already
              // contains this column.
              'media_type':
                  widget.isVideo
                      ? 'video'
                      : 'photo',
            })
            .select()
            .single();

    final photoId =
        createdPhoto['id']
            .toString();

    final mediaUrl =
        await uploadMedia(
      photoId: photoId,
    );

    await supabase
        .from('Photos')
        .update({
          // Keep using the existing column.
          // For videos it will contain the
          // video's URL.
          'photo_url':
              mediaUrl,
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
          widget.isVideo
              ? 'Unable to post video: $e'
              : 'Unable to post photo: $e',
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

  Future<bool> confirmDelete({
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child: const Text(
              'Cancel',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            child: const Text(
              'Delete',
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
              widget.isVideo
                ? 'Add Video'
                : 'Add Photo',
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
            if (selectedMediaBytes != null)
               widget.isVideo
      ? Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color:
                FolktriColors.midnightIndigo,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                size: 72,
                color: Colors.white,
              ),

              const SizedBox(height: 12),

              const Text(
                'Video selected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Text(
                  selectedMedia?.name ??
                      'Video',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        )
      : ClipRRect(
          borderRadius:
              BorderRadius.circular(12),
          child: Image.memory(
            selectedMediaBytes!,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        )
else
  Container(
    width: double.infinity,
    height: 250,
    decoration: BoxDecoration(
      color: FolktriColors.background,
      border: Border.all(
        color:
            FolktriColors.lightLavender,
      ),
      borderRadius:
          BorderRadius.circular(12),
    ),
    child: Center(
      child: Icon(
        widget.isVideo
            ? Icons.video_library_outlined
            : Icons.add_photo_alternate_outlined,
        size: 60,
        color:
            FolktriColors.primaryIndigo,
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
                      isSaving
                        ? null
                        : pickMedia,
                    icon: Icon(
                      widget.isVideo
                        ? Icons.video_library_outlined
                        : Icons.photo_library_outlined,
                    ),
                    label: Text(
                      selectedMedia == null
                        ? widget.isVideo
                          ? 'Choose Video'
                          : 'Choose Photo'
                        : widget.isVideo
                          ? 'Change Video'
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
                        : saveMedia,
                child: isSaving
                    ? const CircularProgressIndicator()
                    :  Text(
                      widget.isVideo
                        ? 'Post Video'
                        :  'Post Photo',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}