import 'package:flutter/material.dart';
import '../../Styling/folktri_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({
    super.key,
  });

  @override
  State<ChangeEmailPage> createState() =>
      _ChangeEmailPageState();
}

class _ChangeEmailPageState
    extends State<ChangeEmailPage> {
  final emailController =
      TextEditingController();

  final confirmEmailController =
      TextEditingController();

  bool isSaving = false;

  String get currentEmail {
    return Supabase
            .instance
            .client
            .auth
            .currentUser
            ?.email ??
        '';
  }

  @override
  void dispose() {
    emailController.dispose();
    confirmEmailController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailPattern = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    return emailPattern.hasMatch(email);
  }

  Future<void> updateEmail() async {
    if (isSaving) return;

    final email = emailController.text
        .trim()
        .toLowerCase();

    final confirmation =
        confirmEmailController.text
            .trim()
            .toLowerCase();

    if (email.isEmpty ||
        confirmation.isEmpty) {
      showMessage(
        'Please enter and confirm your new email address.',
      );
      return;
    }

    if (!isValidEmail(email)) {
      showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    if (email != confirmation) {
      showMessage(
        'The email addresses do not match.',
      );
      return;
    }

    if (email ==
        currentEmail.trim().toLowerCase()) {
      showMessage(
        'Please enter a different email address.',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await Supabase.instance.client.auth
          .updateUser(
        UserAttributes(
          email: email,
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
                  Icons
                      .mark_email_read_outlined,
                  color:
                      FolktriColors.connectionTeal,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Email Change Requested',
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

            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your request to change your Folktri email was submitted.',
                  style: TextStyle(
                    color: FolktriColors
                        .secondaryText,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  email,
                  style: const TextStyle(
                    color: FolktriColors
                        .midnightIndigo,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Depending on your account security settings, you may need to confirm the change by email before the new address becomes active.',
                  style: TextStyle(
                    color: FolktriColors
                        .secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),

            actions: [
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      FolktriColors
                          .primaryIndigo,
                  foregroundColor:
                      FolktriColors.surface,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop();
                },
                child: const Text(
                  'Done',
                  style: TextStyle(
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
        'UPDATE EMAIL ERROR: $e',
      );

      if (!mounted) return;

      showMessage(
        'Unable to update your email. Please try again.',
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

    if (message.contains(
          'already registered',
        ) ||
        message.contains(
          'already been registered',
        ) ||
        message.contains(
          'already exists',
        )) {
      return 'That email address is already associated with another account.';
    }

    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('rate limit')) {
      return 'Too many email change attempts. Please wait a little while and try again.';
    }

    return exception.message;
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
          'Change Email',
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
                    Icons
                        .alternate_email_rounded,
                    size: 32,
                    color:
                        FolktriColors.primaryIndigo,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Center(
                child: Text(
                  'Update your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FolktriColors
                        .midnightIndigo,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  currentEmail.isEmpty
                      ? 'Enter the new email address you want to use for Folktri.'
                      : 'Your current email is\n$currentEmail',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: FolktriColors
                        .secondaryText,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              buildEmailField(
                controller:
                    emailController,
                label:
                    'New email address',
                textInputAction:
                    TextInputAction.next,
              ),

              const SizedBox(height: 14),

              buildEmailField(
                controller:
                    confirmEmailController,
                label:
                    'Confirm new email address',
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  updateEmail();
                },
              ),

              const SizedBox(height: 14),

              const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons
                        .info_outline_rounded,
                    size: 18,
                    color: FolktriColors
                        .secondaryText,
                  ),

                  SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      'You may need access to your email account to confirm this change.',
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
                        FolktriColors
                            .primaryIndigo,
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
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  onPressed: isSaving
                      ? null
                      : updateEmail,

                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                FolktriColors
                                    .surface,
                          ),
                        )
                      : const Text(
                          'Update Email',
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

  Widget buildEmailField({
    required TextEditingController controller,
    required String label,
    required TextInputAction textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,

      keyboardType:
          TextInputType.emailAddress,

      textInputAction:
          textInputAction,

      onSubmitted: onSubmitted,

      autocorrect: false,

      enableSuggestions: false,

      textCapitalization:
          TextCapitalization.none,

      autofillHints: const [
        AutofillHints.email,
      ],

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: const Icon(
          Icons.mail_outline_rounded,
          color:
              FolktriColors.secondaryText,
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
            color:
                FolktriColors.lightLavender,
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