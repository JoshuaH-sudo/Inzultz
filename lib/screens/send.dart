import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inzultz/models/contact.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  List<Contact> _contacts = [];
  Contact? _selectedContact;

  void getContacts() async {
    final contacts = await FirebaseFirestore.instance.collection('users').get();

    setState(() {
      _contacts = contacts.docs.map((doc) {
        return Contact(
          id: doc.id,
          name: doc["name"],
          FCMToken: doc['FCMToken'],
          phoneNumber: doc['phoneNumber'],
        );
      }).toList();
    });
  }

  @override
  void initState() {
    getContacts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> helloWorld() async {
      if (_selectedContact == null) {
        return;
      }

      final results = await FirebaseFunctions.instance
          .httpsCallable('helloWorld')
          .call({"FCMToken": _selectedContact!.FCMToken});

      print(results.data);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Tell,",
                  style: TextStyle(fontSize: 28),
                ),
                const SizedBox(
                  width: 8,
                ),
                MenuAnchor(
                  builder: (context, controller, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 50),
                      ),
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: Text(
                        _selectedContact?.name ?? "Select a contact",
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 28,
                        ),
                      ),
                    );
                  },
                  menuChildren: _contacts.map((contact) {
                    return MenuItemButton(
                      onPressed: () {
                        setState(() {
                          _selectedContact = contact;
                        });
                      },
                      child: Text(contact.name),
                    );
                  }).toList(),
                )
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: helloWorld,
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(5),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100000),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                  ),
                  child: const Center(
                    child: Text(
                      "FUCK YOU",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
