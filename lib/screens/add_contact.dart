import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:inzultz/models/db_collection.dart';
import 'package:inzultz/providers/app.dart';
import 'package:logging/logging.dart';

final log = Logger('AddContactScreen');

class AddContact extends ConsumerStatefulWidget {
  const AddContact({super.key});

  @override
  ConsumerState<AddContact> createState() => _AddContactState();
}

class _AddContactState extends ConsumerState<AddContact> {
  final _formKey = GlobalKey<FormState>();
  String _enteredPhoneNumber = '';

  void onSubmit(WidgetRef ref) async {
    ref.read(appProvider).setLoading(true);
    try {
      final isValid = _formKey.currentState!.validate();
      if (!isValid) {
        return;
      }
      _formKey.currentState!.save();

      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserData = await FirebaseFirestore.instance
          .collection(DBCollection.users)
          .doc(currentUser!.uid)
          .get();

      if (_enteredPhoneNumber.isEmpty) {
        return showMessage("Please enter a phone number", isError: true);
      }
      if (_enteredPhoneNumber == currentUserData['phoneNumber']) {
        return showMessage("You cannot add yourself as a contact",
            isError: true);
      }

      final response = await FirebaseFunctions.instance
          .httpsCallable('sendContactRequest')
          .call({'phoneNumber': _enteredPhoneNumber});

      if (response.data['error'] != null) {
        log.severe('Error: ${response.data['error']}');
        showMessage(
          response.data['error'],
          isError: true,
        );
        return;
      }

      returnToPreviousScreen();
    } catch (error) {
      showMessage("Something went wrong", isError: true);
      log.severe(error);
    }
    ref.read(appProvider).setLoading(false);
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : Colors.green,
        content: Text(message),
      ),
    );
  }

  void returnToPreviousScreen() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IntlPhoneField(
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(),
                              ),
                            ),
                            initialCountryCode: 'AU',
                            onChanged: (phone) {
                              setState(() {
                                _enteredPhoneNumber = phone.completeNumber;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => onSubmit(ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            child: const Text("Add Contact"),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
