import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvitesPage extends StatefulWidget {
  const InvitesPage({super.key});

  @override
  State<InvitesPage> createState() => _InvitesPageState();
}

class _InvitesPageState extends State<InvitesPage> {


  final supabase = Supabase.instance.client;

  // -----------------------
  // FAMILY DATA
  // -----------------------
  List<Map<String, dynamic>> families = [];

  bool isLoadingFamilies = true;


  // These will eventually come from your UI
  String? selectedFamilyId;

  // ------------------------
  // ROLE
  // ------------------------

  String selectedRole = 'Parent';

  final List<String> roles = [
    'Parent',
    'Grandparent',
    'Sibling',
    'Aunt',
    'Uncle',
    'Cousin',
    'Guardian',
    'Caregiver',
    'Extended Family',
    'Other',
  ];

  // -----------------------
  // PERMISSIONS
  // -----------------------

  bool canViewPhotos = true;
  bool canUploadPhotos = false;
  bool canViewCalendar = true;
  bool canViewDocuments = false;
  bool canEditCalendar = false;
  bool canManageSchedule = false;
  bool canManageMembers = false;
  bool canViewChildren = true;
  bool canPost = false;

// -----------------------
// INVITE
// -----------------------
  String? generatedCode;
  bool isGeneratingInvite = false;

  //INIT
  @override
void initState() {
  super.initState();

  loadFamilies();
}

Future<void> loadFamilies() async {
  final user = supabase.auth.currentUser;

  if (user == null) {
    if (mounted) {
      setState(() {
        isLoadingFamilies = false;
      });
    }

    return;
  }

  try {
    final response = await supabase
        .from('Families')
        .select('id, name')
        .eq('created_by', user.id)
        .order('name');

    if (!mounted) return;

    setState(() {
      families =
          List<Map<String, dynamic>>.from(response);

      if (families.isNotEmpty) {
        selectedFamilyId =
            families.first['id'].toString();
      }

      isLoadingFamilies = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingFamilies = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Unable to load families: $e",
        ),
      ),
    );
  }
}

  // Generates the random one-time code
  String generateInviteCode() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    String generatePart(int length) {
      return List.generate(
        length,
        (_) => characters[random.nextInt(characters.length)],
      ).join();
    }

    return '${generatePart(4)}-${generatePart(4)}-${generatePart(4)}';
  }

//==========================
//CREATE INVITE
//==========================
  // Runs when owner presses "Generate Invite"
  Future<void> createInvite() async {

    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    if (selectedFamilyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a family."),
        ),
      );

      return;
    }

     setState(() {
    isGeneratingInvite = true;
    });

  try{
    // Generate one-time code
    final code = generateInviteCode();


    // Code expires 24 hours from now
    final expiresAt = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 24));


    // Save invitation to Supabase
    await supabase
        .from('Family_Invitations')
        .insert({
          'family_id': selectedFamilyId,
          'created_by': user.id,
          'invite_code': code,

          'role': selectedRole,

          'can_view_photos': canViewPhotos,
          'can_upload_photos': canUploadPhotos,
          'can_view_calendar': canViewCalendar,
          'can_view_documents': canViewDocuments,
          'can_edit_calendar': canEditCalendar,
          'can_manage_schedule': canManageSchedule,
          'can_manage_members': canManageMembers,
          'can_view_children': canViewChildren,
          'can_post': canPost,

          'expires_at': expiresAt.toIso8601String(),
        });


    if (!mounted) return;

    setState(() {
      generatedCode = code;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Invite created successfully!",
        ),
      ),
    );

  }catch(e){
    if(!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Unable to create invite: $e"),
      ),
    );
  } finally {
    if(mounted) {
      setState(() {
        isGeneratingInvite = false;
      });
    }
  }
}
    
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invite a family member."),
      ),
      body: const Center(
        //child: Text("Join Family Page"),
      ),
    );
  }
}

