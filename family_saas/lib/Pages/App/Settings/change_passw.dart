import 'package:flutter/material.dart';
import '../../Styling/folktri_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({
    super.key,
  });

  @override
  State<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends State<ChangePasswordPage> {
  final newPasswordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmation = true;

  // This should start false.
  bool isSaving = false;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> updatePassword() async {
    if (isSaving) return;

    final newPassword =
        newPasswordController.text;

    final confirmPassword =
        confirmPasswordController.text;

    if (newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage(
        'Please enter and confirm your new password.',
      );
      return;
    }

    if (newPassword.trim() != newPassword ||
        confirmPassword.trim() !=
            confirmPassword) {
      showMessage(
        'Your password cannot begin or end with spaces.',
      );
      return;
    }

    if (newPassword.length < 8) {
      showMessage(
        'Your password must be at least 8 characters.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage(
        'The passwords do not match.',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor:
                FolktriColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color:
                      FolktriColors.connectionTeal,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Password Updated',
                    style: TextStyle(
                      color: FolktriColors
                          .midnightIndigo,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Your Folktri password has been updated successfully.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color:
                        FolktriColors.primaryIndigo,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      context.pop();
    } on AuthException catch (e) {
      if (!mounted) return;

      showMessage(
        getFriendlyAuthMessage(e),
      );
    } catch (e) {
      debugPrint(
        'UPDATE PASSWORD ERROR: $e',
      );

      if (!mounted) return;

      showMessage(
        'Unable to update your password. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  String getFriendlyAuthMessage(
    AuthException exception,
  ) {
    final message =
        exception.message.toLowerCase();

    if (message.contains('same password') ||
        message.contains(
          'different from the old password',
        )) {
      return 'Please choose a password different from your current password.';
    }

    if (message.contains('weak') ||
        message.contains('password')) {
      return exception.message;
    }

    return 'Unable to update your password. Please try again.';
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: isSaving
              ? null
              : () {
                  context.pop();
                },
        ),

        title: const Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color:
                        FolktriColors.lightLavender,
                    borderRadius:
                        BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 32,
                    color:
                        FolktriColors.primaryIndigo,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Center(
                child: Text(
                  'Create a new password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        FolktriColors.midnightIndigo,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Choose a strong password to keep your Folktri account secure.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        FolktriColors.secondaryText,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              buildPasswordField(
                controller:
                    newPasswordController,
                label: 'New password',
                obscure: obscurePassword,
                autofillHints: const [
                  AutofillHints.newPassword,
                ],
                textInputAction:
                    TextInputAction.next,
                onToggle: () {
                  setState(() {
                    obscurePassword =
                        !obscurePassword;
                  });
                },
              ),

              const SizedBox(height: 14),

              buildPasswordField(
                controller:
                    confirmPasswordController,
                label:
                    'Confirm new password',
                obscure:
                    obscureConfirmation,
                autofillHints: const [
                  AutofillHints.newPassword,
                ],
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  updatePassword();
                },
                onToggle: () {
                  setState(() {
                    obscureConfirmation =
                        !obscureConfirmation;
                  });
                },
              ),

              const SizedBox(height: 12),

              const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 17,
                    color:
                        FolktriColors.secondaryText,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Use at least 8 characters. A longer, unique password is more secure.',
                      style: TextStyle(
                        color: FolktriColors
                            .secondaryText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        FolktriColors.primaryIndigo,
                    foregroundColor:
                        FolktriColors.surface,
                    disabledBackgroundColor:
                        FolktriColors
                            .primaryIndigo
                            .withOpacity(0.55),
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : updatePassword,
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                FolktriColors.surface,
                          ),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required Iterable<String> autofillHints,
    required TextInputAction textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color:
              FolktriColors.secondaryText,
        ),

        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons
                    .visibility_off_outlined,
          ),
        ),

        filled: true,
        fillColor:
            FolktriColors.surface,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide(
            color: FolktriColors
                .lightLavender
                .withOpacity(0.7),
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: const BorderSide(
            color:
                FolktriColors.primaryIndigo,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}