import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddMilestonePage extends StatefulWidget {
  final String childId;
  final String familyId;

  const AddMilestonePage({
    super.key,
    required this.childId,
    required this.familyId,
  });

  @override
  State<AddMilestonePage> createState() =>
      _AddMilestonePageState();
}

class _AddMilestonePageState
    extends State<AddMilestonePage> {
  final supabase = Supabase.instance.client;
  final ImagePicker imagePicker = ImagePicker();

  final titleController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  DateTime? milestoneDate;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  bool isSaving = false;

  Future<void> pickImage() async {
    final image =
        await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
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

  Future<void> selectMilestoneDate() async {
    final pickedDate =
        await showDatePicker(
      context: context,
      initialDate:
          milestoneDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    setState(() {
      milestoneDate = pickedDate;
    });
  }

  Future<String?> uploadPhoto(
    String milestoneId,
  ) async {
    if (selectedImage == null ||
        selectedImageBytes == null) {
      return null;
    }

    final extension =
        selectedImage!.name
            .split('.')
            .last;

    final filePath =
        '${widget.familyId}/${widget.childId}/$milestoneId/photo.$extension';

    await supabase.storage
        .from('milestone-images')
        .uploadBinary(
          filePath,
          selectedImageBytes!,
          fileOptions:
              const FileOptions(
            upsert: true,
          ),
        );

    return supabase.storage
        .from('milestone-images')
        .getPublicUrl(filePath);
  }

  Future<void> saveMilestone() async {
    final user =
        supabase.auth.currentUser;

    if (user == null) return;

    if (titleController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a milestone title.',
          ),
        ),
      );

      return;
    }

    if (milestoneDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the milestone date.',
          ),
        ),
      );

      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final milestone =
          await supabase
              .from('Milestones')
              .insert({
                'family_id':
                    widget.familyId,
                'child_id':
                    widget.childId,
                'title':
                    titleController.text
                        .trim(),
                'description':
                    descriptionController
                            .text
                            .trim()
                            .isEmpty
                        ? null
                        : descriptionController
                            .text
                            .trim(),
                'milestone_date':
                    milestoneDate!
                        .toIso8601String(),
                'created_by':
                    user.id,
              })
              .select()
              .single();

      final milestoneId =
          milestone['id'].toString();

      if (selectedImage != null) {
        final photoUrl =
            await uploadPhoto(
          milestoneId,
        );

        if (photoUrl != null) {
          await supabase
              .from('Milestones')
              .update({
                'photo_url':
                    photoUrl,
              })
              .eq(
                'id',
                milestoneId,
              );
        }
      }

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
            'Unable to add milestone: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Add Milestone'),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller:
                  titleController,
              decoration:
                  const InputDecoration(
                labelText: 'Title',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  descriptionController,
              maxLines: 4,
              decoration:
                  const InputDecoration(
                labelText:
                    'Description',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            ListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: Text(
                milestoneDate == null
                    ? 'Select milestone date'
                    : '${milestoneDate!.month}/${milestoneDate!.day}/${milestoneDate!.year}',
              ),
              trailing:
                  const Icon(
                Icons.calendar_month,
              ),
              onTap:
                  selectMilestoneDate,
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: pickImage,
              icon:
                  const Icon(
                Icons.photo,
              ),
              label: Text(
                selectedImage == null
                    ? 'Add Optional Photo'
                    : 'Change Photo',
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    isSaving
                        ? null
                        : saveMilestone,
                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Save Milestone',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}