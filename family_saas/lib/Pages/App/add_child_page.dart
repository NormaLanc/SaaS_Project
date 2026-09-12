import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class AddChildrenPage extends StatefulWidget {
   final String familyId;

  const AddChildrenPage({
    super.key,
    required this.familyId,
  });

  @override
  State<AddChildrenPage> createState() =>
      _AddChildrenPageState();
}

class _AddChildrenPageState
    extends State<AddChildrenPage> {

  final supabase = Supabase.instance.client;

  final ImagePicker imagePicker = ImagePicker();


  // =============================
  // CHILDREN
  // =============================

  final List<ChildFormData> children = [
    ChildFormData(),
  ];

  bool isSaving = false;

  
  // =============================
  // ADD ANOTHER CHILD FORM
  // =============================

  void addAnotherChild() {
    setState(() {
      children.add(
        ChildFormData(),
      );
    });
  }

  // =============================
  // REMOVE CHILD FORM
  // =============================

  void removeChild(int index) {
    if (children.length == 1) {
      return;
    }

    setState(() {
      children[index].dispose();

      children.removeAt(index);
    });
  }

  // =============================
  // PICK PROFILE IMAGE
  // =============================

  Future<void> pickImage(int index) async {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();

    if (!mounted) return;

    setState(() {
      children[index].image = image;
      children[index].imageBytes = bytes;
    });
  }

  // =============================
  // UPLOAD PROFILE IMAGE
  // =============================

  Future<String?> uploadProfileImage({
    required XFile image,
    required Uint8List bytes,
    required String childId,
  }) async {

    final extension =
        image.name.split('.').last;

    final filePath =
        '$childId/profile.$extension';

    await supabase.storage
        .from('child-profile-images')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    return supabase.storage
        .from('child-profile-images')
        .getPublicUrl(filePath);
  }

  // =============================
  // SAVE ALL CHILDREN
  // =============================

  Future<void> saveChildren() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    for (final child in children) {
      if (child.firstNameController.text.trim().isEmpty ||
        child.lastNameController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a first and last name for every child.",
          ),
        ),
      );

      return;
    }

      // Date of birth is required
      if (child.dateOfBirth == null) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please select a date of birth for every child.",
            ),
          ),
        );

        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      for (final child in children) {

        final createdChild =
            await supabase
                .from('Children')
                .insert({
                  'family_id': widget.familyId,
                  'created_by': user.id,
                  'first_name': child.firstNameController.text.trim(),
                  'middle_name': child.middleNameController.text.trim().isEmpty
                    ? null
                    : child.middleNameController.text.trim(),
                  'last_name': child.lastNameController.text.trim(),
                  'date_of_birth': child.dateOfBirth!.toIso8601String(),
                  // 'profile_photo_path': null,
                  
    })
                .select()
                .single();

        final childId =
            createdChild['id']
                .toString();

        // Upload image if selected.
        if (child.image != null &&
            child.imageBytes != null) {

          final profilePhotoUrl =
              await uploadProfileImage(
            image: child.image!,
            bytes:
                child.imageBytes!,
            childId: childId,
          );

          await supabase
              .from('Children')
              .update({
                'profile_photo_path':
                    profilePhotoUrl,
              })
              .eq(
                'id',
                childId,
              );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Children added successfully!",
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Unable to add children: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

Future<void> selectDateOfBirth(int index) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  if (pickedDate == null) return;

  setState(() {
    children[index].dateOfBirth = pickedDate;
  });
}


  // =============================
  // BUILD
  // =============================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Children",
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                "Add Children",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Add children to one of your existing families.",
              ),

              const SizedBox(height: 30),

              // ========================
              // CHILD FORMS
              // ========================

              ...List.generate(
                children.length,
                (index) {

                  final child =
                      children[index];

                  return Card(
                    margin:
                        const EdgeInsets
                            .only(
                      bottom: 20,
                    ),

                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(18),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            children: [

                              Text(
                                "Child ${index + 1}",
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              if (children
                                      .length >
                                  1)
                                IconButton(
                                  onPressed:
                                      () =>
                                          removeChild(
                                    index,
                                  ),

                                  icon:
                                      const Icon(
                                    Icons.delete_outline,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          Center(
                            child:
                                GestureDetector(
                              onTap: () =>
                                  pickImage(
                                index,
                              ),

                              child:
                                  CircleAvatar(
                                radius: 50,

                                backgroundImage:
                                    child.imageBytes !=
                                            null
                                        ? MemoryImage(
                                            child.imageBytes!,
                                          )
                                        : null,

                                child:
                                    child.imageBytes ==
                                            null
                                        ? const Icon(
                                            Icons
                                                .add_a_photo,
                                            size:
                                                30,
                                          )
                                        : null,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          const Center(
                            child: Text(
                              "Add profile picture",
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          TextField(
  controller: child.firstNameController,
  decoration: const InputDecoration(
    labelText: "First Name",
    border: OutlineInputBorder(),
  ),
),

    const SizedBox(height: 16),

    TextField(
      controller: child.middleNameController,
      decoration: const InputDecoration(
        labelText: "Middle Name (Optional)",
        border: OutlineInputBorder(),
      ),
    ),

    const SizedBox(height: 16),

    TextField(
      controller: child.lastNameController,
      decoration: const InputDecoration(
        labelText: "Last Name",
        border: OutlineInputBorder(),
      ),
    ),

    const SizedBox(height: 16),

    InkWell(
      onTap: () {
        selectDateOfBirth(index);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Date of Birth",
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
      child: Text(
        child.dateOfBirth == null
          ? "Select date"
          : "${child.dateOfBirth!.month}/${child.dateOfBirth!.day}/${child.dateOfBirth!.year}",
      ),
    ),
  ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ========================
              // ADD ANOTHER CHILD
              // ========================

              SizedBox(
                width: double.infinity,

                child:
                    OutlinedButton.icon(
                  onPressed:
                      addAnotherChild,

                  icon: const Icon(
                    Icons.add,
                  ),

                  label: const Text(
                    "Add Another Child",
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ========================
              // SAVE
              // ========================

              SizedBox(
                width: double.infinity,

                child:
                    ElevatedButton(
                  onPressed:
                      isSaving
                          ? null
                          : saveChildren,

                  child:
                      isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Text(
                              "Save Children",
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {

    for (final child
        in children) {
      child.dispose();
    }

    super.dispose();
  }
}

// ===================================
// CHILD FORM DATA
// ===================================

class ChildFormData {

  final TextEditingController firstNameController =
      TextEditingController();

  final TextEditingController middleNameController =
      TextEditingController();

  final TextEditingController lastNameController =
      TextEditingController();

  DateTime? dateOfBirth;

  XFile? image;
  Uint8List? imageBytes;

  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
  }
}