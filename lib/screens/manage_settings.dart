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

    authCompleteCallback() async {
      Navigator.of(context).pop();
    }

    loginUser() async {
      final newCredential = await Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) {
        return AuthScreen(
          authCompleteCallback: authCompleteCallback,
          mode: AuthMode.LOGIN,
        );
      }));

      if (newCredential == null) {
        log.info('User did not login');
        // TODO: Show error message
        return;
      }
      log.info('User logged in');

      await FirebaseAuth.instance.currentUser!.delete();
    }

    void deleteUser() async {
      try {
        await FirebaseAuth.instance.currentUser!.delete();
      } catch (error) {
        if (error is FirebaseAuthException) {
          log.severe('Failed to delete user: ${error.message}');

          if (error.code == 'requires-recent-login') {
            log.severe('User needs to reauthenticate');
            loginUser();
          }
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
              onPressed: deleteUser,
              child: const Text('Delete Account'),
            ),
          ),
        ],
      ),
    );
  }
}
