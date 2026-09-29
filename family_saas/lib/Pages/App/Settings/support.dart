import 'package:flutter/material.dart';
import '../../Styling/folktri_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportPage extends StatefulWidget {

    const ContactSupportPage({super.key});


  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {

  final subjectController = TextEditingController();
  final messageController = TextEditingController();

  final supabase = Supabase.instance.client;

  bool isOpeningEmail = false;

  static const String supportEmail =
      'customer_support@folktri.com';

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> openEmailApp() async {
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (subject.isEmpty) {
      showMessage(
        'Please enter a subject.',
      );
      return;
    }

    if (message.isEmpty) {
      showMessage(
        'Please describe how we can help.',
      );
      return;
    }

    setState(() {
      isOpeningEmail = true;
    });

    try {
      final userEmail =
          supabase.auth.currentUser?.email ?? '';

      final body = '''
$message

---
Folktri Support

Account email: ${userEmail.isNotEmpty ? userEmail : 'Not available'}
''';

      final encodedSubject = Uri.encodeComponent(subject);
      final encodedBody = Uri.encodeComponent(body);

      final emailUri = Uri.parse(
        // scheme: 'mailto',
        // path: supportEmail,
        //queryParameters: {
          'mailto: $supportEmail'
          '?subject=$encodedSubject'
          '&body=$encodedBody',
       // },
      );

      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        showMessage(
          'No email app could be opened. '
          'You can email us directly at $supportEmail.',
        );
      }
    } catch (e) {
      debugPrint(
        'OPEN SUPPORT EMAIL ERROR: $e',
      );

      if (!mounted) return;

      showMessage(
        'Unable to open your email app. '
        'You can email us directly at $supportEmail.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningEmail = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(
      
      backgroundColor: FolktriColors.background,

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
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'Contact Support',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            24,
            16,
            40,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              buildHeader(),

              const SizedBox(height: 30),

              buildSectionTitle(
                'HOW CAN WE HELP?',
              ),

              buildSupportCard(),

              const SizedBox(height: 24),

              buildResponseNotice(),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        FolktriColors.primaryIndigo,
                    foregroundColor:
                        FolktriColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),

                  onPressed: isOpeningEmail
                      ? null
                      : openEmailApp,

                  icon: isOpeningEmail
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                FolktriColors.surface,
                          ),
                        )
                      : const Icon(
                          Icons.mail_outline_rounded,
                        ),

                  label: Text(
                    isOpeningEmail
                        ? 'Opening Email...'
                        : 'Open Email App',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: Text(
                  supportEmail,
                  style: const TextStyle(
                    color:
                        FolktriColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget buildHeader() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color:
                  FolktriColors.lightLavender,
              borderRadius:
                  BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              size: 34,
              color:
                  FolktriColors.primaryIndigo,
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'We\'re here to help',
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                FolktriColors.midnightIndigo,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'Tell us what you need help with and '
          'we\'ll prepare an email for the Folktri support team.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                FolktriColors.secondaryText,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FolktriColors.surface,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FolktriColors
                .midnightIndigo
                .withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject',
            style: TextStyle(
              color:
                  FolktriColors.midnightIndigo,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: subjectController,
            textCapitalization:
                TextCapitalization.sentences,
            decoration: buildInputDecoration(
              hintText:
                  'What can we help with?',
              icon:
                  Icons.subject_rounded,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Message',
            style: TextStyle(
              color:
                  FolktriColors.midnightIndigo,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: messageController,
            minLines: 6,
            maxLines: 10,
            textCapitalization:
                TextCapitalization.sentences,
            decoration: buildInputDecoration(
              hintText:
                  'Describe the issue you\'re experiencing...',
              icon:
                  Icons.chat_bubble_outline_rounded,
              alignIconTop: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResponseNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: FolktriColors.lightLavender
            .withValues(alpha: 0.45),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color:
                FolktriColors.primaryIndigo,
          ),

          SizedBox(width: 11),

          Expanded(
            child: Text(
              'Your email app will open with your message '
              'already prepared. Review it and press Send '
              'when you\'re ready.',
              style: TextStyle(
                color:
                    FolktriColors.secondaryText,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration buildInputDecoration({
    required String hintText,
    required IconData icon,
    bool alignIconTop = false,
  }) {
    return InputDecoration(
      hintText: hintText,

      hintStyle: const TextStyle(
        color: FolktriColors.secondaryText,
        fontSize: 13,
      ),

      prefixIcon: Padding(
        padding: EdgeInsets.only(
          bottom: alignIconTop ? 100 : 0,
        ),
        child: Icon(
          icon,
          color:
              FolktriColors.secondaryText,
          size: 20,
        ),
      ),

      filled: true,
      fillColor: FolktriColors.background,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: FolktriColors.lightLavender,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color:
              FolktriColors.primaryIndigo,
          width: 1.5,
        ),
      ),
    );
  }

  Widget buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 5,
        bottom: 9,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: FolktriColors
              .midnightIndigo
              .withValues(alpha: 0.62),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}