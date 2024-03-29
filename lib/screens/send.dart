import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inzultz/models/contact.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:inzultz/screens/manage_contacts.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  List<Contact> _contacts = [];
  Contact? _selectedContact;

  void getContacts() async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final currentUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final contacts = currentUserData['contacts'];    
    print('contacts: $contacts');

    final contactsData = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', whereIn: contacts)
        .get();
    print('contactsData: ${contactsData.docs}');

    setState(() {
      _contacts = contactsData.docs.map((doc) {
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
    final currentUser = FirebaseAuth.instance.currentUser!;
    Future<void> sendNotification() async {
      if (_selectedContact == null) {
        return;
      }

      final results = await FirebaseFunctions.instance
          .httpsCallable('sendNotification')
          .call({"FCMToken": _selectedContact!.FCMToken});

      print(results.data);
    }

    void addNewContact() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const ManageContacts();
      }));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser.displayName!),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_sharp),
            onPressed: addNewContact,
          ),
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
                  style: TextStyle(fontSize: 20),
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
                          fontSize: 20,
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
                ),
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
                  onPressed: sendNotification,
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
