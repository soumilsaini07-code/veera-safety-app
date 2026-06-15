import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/realtime_database_service.dart';
import '../models/emergency_contact_model.dart';
import '../core/theme.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dbService = RealtimeDatabaseService();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('AUTHORIZATION REQUIRED', style: TextStyle(color: AppTheme.error, letterSpacing: 2))),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('EMERGENCY CONTACTS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.5),
            radius: 1.5,
            colors: [Color(0xFF252238), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<EmergencyContactModel>>(
                  stream: dbService.getContacts(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'NO CONTACTS CONFIGURED',
                          style: TextStyle(color: AppTheme.outline, fontWeight: FontWeight.w800, letterSpacing: 2),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (_, __) => const Divider(color: AppTheme.surfaceVariant, height: 32, thickness: 1),
                      itemBuilder: (context, index) {
                        final contact = snapshot.data![index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.5), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(contact.name.toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1.5)),
                                  const SizedBox(height: 4),
                                  Text(contact.phone, style: const TextStyle(color: AppTheme.onSurface, fontSize: 14, letterSpacing: 1.2)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 28),
                                onPressed: () {
                                  dbService.deleteContact(userId, contact.contactId);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: () {
                  _showAddContactDialog(context, userId, dbService);
                },
                child: const Text('ADD NEW CONTACT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showAddContactDialog(BuildContext context, String userId, RealtimeDatabaseService dbService) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.5), width: 1)),
          title: const Text('CONFIGURE CONTACT', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController, 
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'IDENTIFIER (NAME)',
                  labelStyle: const TextStyle(color: AppTheme.outline),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.outline, width: 1), borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primary, width: 2), borderRadius: BorderRadius.circular(8)),
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController, 
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'TELEMETRY (PHONE)',
                  labelStyle: const TextStyle(color: AppTheme.outline),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.outline, width: 1), borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primary, width: 2), borderRadius: BorderRadius.circular(8)),
                )
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('ABORT', style: TextStyle(color: AppTheme.outline, fontWeight: FontWeight.w800))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () {
                dbService.addContact(userId, nameController.text.trim(), phoneController.text.trim());
                Navigator.pop(context);
              },
              child: const Text('COMMIT', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }
}
