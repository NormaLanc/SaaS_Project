//TODO: Allow user to select profile picture
//TODO: Allow user to edit profile information (name, email, password)
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final supabase =
      Supabase.instance.client;

  final firstNameController =
      TextEditingController();

  final lastNameController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final ImagePicker imagePicker =
      ImagePicker();

  XFile? selectedImage;

  Uint8List? selectedImageBytes;

  String? existingPhotoPath;

  String? existingPhotoUrl;

  bool isLoading = true;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  Future<void> loadProfile() async {
    final user =
        supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      return;
    }

    try {
      final response =
          await supabase
              .from('Profiles')
              .select()
              .eq(
                'user_id',
                user.id,
              )
              .maybeSingle();

      if (response != null) {
        firstNameController.text =
            response['first_name']
                    ?.toString() ??
                '';

        lastNameController.text =
            response['last_name']
                    ?.toString() ??
                '';

        phoneController.text =
            response['phone_number']
                    ?.toString() ??
                '';

        existingPhotoPath =
            response[
                    'profile_photo_path']
                ?.toString();

        if (existingPhotoPath != null &&
            existingPhotoPath!
                .isNotEmpty) {
          await loadProfilePhoto();
        }
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load profile: $e',
          ),
        ),
      );
    }
  }

  Future<void> loadProfilePhoto() async {
    if (existingPhotoPath == null ||
        existingPhotoPath!.isEmpty) {
      return;
    }

    try {
      final signedUrl =
          await supabase.storage
              .from('profile-photos')
              .createSignedUrl(
                existingPhotoPath!,
                3600,
              );

      if (!mounted) return;

      setState(() {
        existingPhotoUrl =
            signedUrl;
      });
    } catch (e) {
      debugPrint(
        'Unable to load profile photo: $e',
      );
    }
  }

  Future<void> selectProfilePhoto() async {
    try {
      final image =
          await imagePicker.pickImage(
        source:
            ImageSource.gallery,
        imageQuality:
            80,
      );

      if (image == null) {
        return;
      }

      final bytes =
          await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage =
            image;

        selectedImageBytes =
            bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select photo: $e',
          ),
        ),
      );
    }
  }

  Future<void> saveProfile() async {
    final user =
        supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    if (firstNameController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your first name.',
          ),
        ),
      );

      return;
    }

    if (lastNameController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your last name.',
          ),
        ),
      );

      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      String? photoPath =
          existingPhotoPath;

      if (selectedImage != null &&
          selectedImageBytes != null) {
        final extension =
            selectedImage!.name
                    .contains('.')
                ? selectedImage!.name
                    .split('.')
                    .last
                    .toLowerCase()
                : 'jpg';

        photoPath =
            '${user.id}/'
            'profile.$extension';

        await supabase.storage
            .from('profile-photos')
            .uploadBinary(
              photoPath,
              selectedImageBytes!,
              fileOptions:
                  const FileOptions(
                upsert: true,
              ),
            );
      }

      await supabase
          .from('Profiles')
          .upsert(
        {
          'user_id':
              user.id,

          'first_name':
              firstNameController.text
                  .trim(),

          'last_name':
              lastNameController.text
                  .trim(),

          'phone_number':
              phoneController.text
                      .trim()
                      .isEmpty
                  ? null
                  : phoneController.text
                      .trim(),

          'profile_photo_path':
              photoPath,

          'updated_at':
              DateTime.now()
                  .toUtc()
                  .toIso8601String(),
        },
        onConflict:
            'user_id',
      );

      existingPhotoPath =
          photoPath;

      selectedImage =
          null;

      selectedImageBytes =
          null;

      if (photoPath != null) {
        await loadProfilePhoto();
      }

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile saved.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save profile: $e',
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
      icon: const Icon(Icons.arrow_back,),
      tooltip: 'Back to Family Dashboard',
      onPressed: () {
        context.go('/app');
      },
    ),
        title: const Text('Profile'),
      ),
      body: isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child:
                      Column(
                    children: [
                      GestureDetector(
                        onTap:
                            selectProfilePhoto,

                        child:
                            CircleAvatar(
                          radius:
                              55,

                          backgroundImage:
                              selectedImageBytes !=
                                      null
                                  ? MemoryImage(
                                      selectedImageBytes!,
                                    )
                                  : existingPhotoUrl !=
                                          null
                                      ? NetworkImage(
                                          existingPhotoUrl!,
                                        )
                                      : null,

                          child:
                              selectedImageBytes ==
                                          null &&
                                      existingPhotoUrl ==
                                          null
                                  ? const Icon(
                                      Icons.person,
                                      size:
                                          55,
                                    )
                                  : null,
                        ),
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      TextButton.icon(
                        onPressed:
                            selectProfilePhoto,

                        icon:
                            const Icon(
                          Icons.photo_camera,
                        ),

                        label:
                            const Text(
                          'Add Profile Photo',
                        ),
                      ),

                      const SizedBox(
                        height:
                            24,
                      ),

                      TextField(
                        controller:
                            firstNameController,

                        textCapitalization:
                            TextCapitalization
                                .words,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'First Name',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),

                      TextField(
                        controller:
                            lastNameController,

                        textCapitalization:
                            TextCapitalization
                                .words,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Last Name',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),

                      TextField(
                        controller:
                            phoneController,

                        keyboardType:
                            TextInputType.phone,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Phone Number',
                          hintText:
                              '(555) 555-1234',
                          prefixIcon:
                              Icon(
                            Icons.phone,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height:
                            28,
                      ),

                      SizedBox(
                        width:
                            double.infinity,

                        child:
                            ElevatedButton(
                          onPressed:
                              isSaving
                                  ? null
                                  : saveProfile,

                          child:
                              isSaving
                                  ? const SizedBox(
                                      height:
                                          20,
                                      width:
                                          20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Text(
                                      'Save Profile',
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}