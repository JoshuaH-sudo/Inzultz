import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzultz/providers/app.dart';
import 'package:inzultz/screens/add_contact.dart';
import 'package:inzultz/screens/auth.dart';
import 'package:inzultz/models/db_collection.dart';
import 'package:logging/logging.dart';

final log = Logger('SettingsScreen');

class ManageSettings extends ConsumerWidget {
  const ManageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void addNewContact() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const AddContact();
      }));
    }

    deleteDBUser() async {
      log.info('Deleting user');
      await FirebaseFirestore.instance
          .collection(DBCollection.users)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .delete();
    }

    deleteUsersContactRequests() async {
      log.info('Deleting users contact requests');
      final contactRequests = await FirebaseFirestore.instance
          .collectionGroup(DBCollection.contactRequests)
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

      return newCredential;
    }

    void onDeleteUser() async {
      try {
        final newCred = await login();
        if (newCred == null) {
          return;
        }
        
        ref.read(appProvider.notifier).setLoading(true);
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
      ref.read(appProvider.notifier).setLoading(false);
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
