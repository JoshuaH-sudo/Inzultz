import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inzultz/screens/add_contact.dart';
import 'package:inzultz/screens/auth.dart';
import 'package:logging/logging.dart';

final log = Logger('SettingsScreen');

class ManageSettings extends StatelessWidget {
  const ManageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    void addNewContact() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const AddContact();
      }));
    }

    deleteDBUser() async {
      log.shout('Deleting user');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .delete();
    }

    deleteUsersContactRequests() async {
      log.shout('Deleting users contact requests');
      final contactRequests = await FirebaseFirestore.instance
          .collectionGroup("contact_requests")
          .where(
            Filter.or(
              Filter("senderId",
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid),
              Filter("receiverId",
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid),
            ),
          )
          .get();
      // Delete all contact requests
      for (var contactRequest in contactRequests.docs) {
        await contactRequest.reference.delete();
      }
    }

    login() async {
      final newCredential = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return const AuthScreen(
            mode: AuthMode.LOGIN,
          );
        }),
      );

      if (newCredential == null) {
        log.info('User did not login');
        // TODO: Show error message
        return;
      }
      log.info('User logged in');
    }

    void onDeleteUser() async {
      try {
        await login();
        await deleteDBUser();
        await deleteUsersContactRequests();

        log.shout('Deleting user');
        await FirebaseAuth.instance.currentUser!.delete();
      } catch (error) {
        if (error is FirebaseAuthException) {
          log.severe('Failed to delete user: ${error.message}');
        } else {
          log.severe('Failed to delete user: $error');
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_sharp),
            onPressed: addNewContact,
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: onDeleteUser,
              child: const Text('Delete Account'),
            ),
          ),
        ],
      ),
    );
  }
}
