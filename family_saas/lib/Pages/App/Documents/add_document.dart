//This page is for parents to add documents for their children. It will be a form that allows them to upload a document and select which child it belongs to.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddDocumentPage extends StatefulWidget {
  final String familyId;
  final String childId;

  const AddDocumentPage({
    super.key,
    required this.familyId,
    required this.childId,
  });

  @override
  State<AddDocumentPage> createState() =>
      _AddDocumentPageState();
}

class _AddDocumentPageState
    extends State<AddDocumentPage> {
  final supabase = Supabase.instance.client;

  final titleController =
      TextEditingController();

  String selectedCategory = 'Medical';

  DateTime? documentDate;

  PlatformFile? selectedFile;

  bool isSaving = false;

  final List<String> categories = [
    'Medical',
    'School',
    'Identification',
    'Legal',
    'Sports',
    'Activity',
    'Other',
  ];

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> selectDocumentDate() async {
    final selectedDate =
        await showDatePicker(
      context: context,
      initialDate:
          documentDate ?? DateTime.now(),
      firstDate:
          DateTime(1900),
      lastDate:
          DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      documentDate = selectedDate;
    });
  }

  Future<void> selectFile() async {
    try {
      final file =
          await FilePicker.pickFile();

      if (file == null) {
        return;
      }

      setState(() {
        selectedFile = file;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select file: $e',
          ),
        ),
      );
    }
  }

  Future<void> saveDocument() async {
    final user =
        supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    if (titleController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a document title.',
          ),
        ),
      );

      return;
    }

    if (documentDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the document date.',
          ),
        ),
      );

      return;
    }

    if (selectedFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a document.',
          ),
        ),
      );

      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final documentRow =
    await supabase
        .from('Documents')
        .insert({
          'family_id': widget.familyId,
          'child_id': widget.childId,
          'title': titleController.text.trim(),
          'category': selectedCategory,
          'document_date': documentDate!.toIso8601String().split('T').first,
          'file_path': '',
          'file_name': selectedFile!.name,
          'created_by': user.id,
        })
        .select('id')
        .single();

      final documentId = documentRow['id'].toString();

      final file = selectedFile!;

      final bytes = await file.readAsBytes();

      final originalFileName = file.name;

      final extension = originalFileName.contains('.')
              ? originalFileName.split('.').last.toLowerCase()
              : 'file';

      final storagePath = '${widget.familyId}/'
          '${widget.childId}/'
          '$documentId/'
          'document.$extension';

      await supabase.storage
          .from('child-documents')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions:
                const FileOptions(
              upsert: false,
            ),
          );

          await supabase
            .from('Documents')
            .update({
              'file_path': storagePath,
            })
            .eq(
              'id',
              documentId,
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
            'Unable to upload document: $e',
          ),
        ),
      );
    }
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
    final dateText =
        documentDate == null
            ? 'Select document date'
            : '${documentDate!.month}/'
                '${documentDate!.day}/'
                '${documentDate!.year}';

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Add Document'),
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            TextField(
              controller:
                  titleController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Document title',
                hintText:
                    'Example: Annual Physical',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            DropdownButtonFormField<
                String>(
              initialValue:
                  selectedCategory,
              decoration:
                  const InputDecoration(
                labelText:
                    'Category',
                border:
                    OutlineInputBorder(),
              ),
              items:
                  categories.map(
                (category) {
                  return DropdownMenuItem(
                    value:
                        category,
                    child:
                        Text(category),
                  );
                },
              ).toList(),
              onChanged:
                  (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  selectedCategory =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 16,
            ),

            ListTile(
              contentPadding:
                  EdgeInsets.zero,

              leading:
                  const Icon(
                Icons.calendar_today,
              ),

              title:
                  const Text(
                'Document Date',
              ),

              subtitle:
                  Text(dateText),

              trailing:
                  const Icon(
                Icons.chevron_right,
              ),

              onTap:
                  selectDocumentDate,
            ),

            const Divider(),

            const SizedBox(
              height: 8,
            ),

            OutlinedButton.icon(
              onPressed:
                  selectFile,
              icon:
                  const Icon(
                Icons.upload_file,
              ),
              label:
                  const Text(
                'Choose Document',
              ),
            ),

            if (selectedFile !=
                null) ...[
              const SizedBox(
                height: 12,
              ),

              Card(
                child: ListTile(
                  leading:
                      const Icon(
                    Icons.description,
                  ),

                  title:
                      Text(
                    selectedFile!.name,
                  ),

                  subtitle:
                      Text(
                    'Ready to upload',
                  ),

                  trailing:
                      IconButton(
                    icon:
                        const Icon(
                      Icons.close,
                    ),
                    onPressed:
                        () {
                      setState(() {
                        selectedFile =
                            null;
                      });
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(
              height: 24,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton.icon(
                onPressed:
                    isSaving
                        ? null
                        : saveDocument,

                icon:
                    const Icon(
                  Icons.cloud_upload,
                ),

                label:
                    isSaving
                        ? const SizedBox(
                            width:
                                20,
                            height:
                                20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Text(
                            'Upload Document',
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}