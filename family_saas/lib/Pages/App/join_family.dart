//TODO: Implement one-time code field for joining a family
//TODO: Owner is sent a notification to approve the new member
//TODO: Once approved, the new member is added to the family and can access the family dashboard
//TODO: If the owner rejects the request, the new member is notified and cannot access the family dashboard
//TODO: If the owner does not respond within a certain time frame, the request is automatically rejected and the new member is notified
//TODO: Permission levels for family members: view photos, edit child information, view documents, manage schedule, manage members
//TODO: Only the owner can manage members and approve/reject new members or change permissions
//TODO: Temporary permissions for family members can be set by the owner (future feature)

import 'package:flutter/material.dart';

class JoinFamilyPage extends StatefulWidget {
  const JoinFamilyPage({super.key});

  @override
  State<JoinFamilyPage> createState() => _JoinFamilyPageState();
}

class _JoinFamilyPageState extends State<JoinFamilyPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Family"),
      ),
      body: const Center(
        child: Text("Join Family Page"),
      ),
    );
  }
}