import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class AddContact extends StatefulWidget {
  const AddContact({super.key});

  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  final _formKey = GlobalKey<FormState>();
  String _enteredPhoneNumber = '';

  void onSubmit() async {
    try {
      final isValid = _formKey.currentState!.validate();
      if (!isValid) {
        return;
      }
      _formKey.currentState!.save();

      final currentUser = FirebaseAuth.instance!.currentUser;
      final currentUserData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (_enteredPhoneNumber.isEmpty) {
        return showMessage("Please enter a phone number", isError: true);
      }

      if (_enteredPhoneNumber == currentUserData['phoneNumber']) {
        return showMessage("You cannot add yourself as a contact", isError: true);
      }

      final foundContacts = await FirebaseFirestore.instance
          .collection('users')
          .where("phoneNumber", isEqualTo: _enteredPhoneNumber)
          .get();

      if (foundContacts.docs.isEmpty) {
        return showMessage("No contact found with that phone number", isError: true);
      }
      final foundContact = foundContacts.docs.first;

      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        "contacts": FieldValue.arrayUnion([foundContact.id])
      });

      returnToPreviousScreen();
    } catch (error) {
      showMessage("Something went wrong", isError: true);
      print(error);
    }
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
                            onPressed: onSubmit,
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
