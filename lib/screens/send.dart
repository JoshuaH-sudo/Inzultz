import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inzultz/models/contact.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:inzultz/screens/manage_contacts.dart';
import 'package:inzultz/screens/manage_requests.dart';
import 'package:logging/logging.dart';

final log = Logger('SendScreen');

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  Contact? _selectedContact;

  @override
  Widget build(BuildContext context) {
    var currentAuthUser = FirebaseAuth.instance.currentUser!;

    void manageContacts() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const ManageContacts();
      }));
    }

    void manageRequests() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const ManageRequests();
      }));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Home ${currentAuthUser.phoneNumber}"),
        actions: [
          IconButton(
            onPressed: manageRequests,
            icon: const Icon(Icons.contact_mail),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded),
            onPressed: manageContacts,
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
                StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .doc('users/${currentAuthUser.uid}')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (snapshot.hasError) {
                        log.severe(snapshot.error);
                      }

                      log.info(snapshot.data!.data());

                      var userData = snapshot.data!.data();
                      log.info(
                          "user's data contacts: ${userData?['contacts']}");

                      return StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where(
                                'id',
                                whereIn: userData?['contacts'],
                              )
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (snapshot.hasError) {
                              log.severe(snapshot.error);
                            }

                            var contactDocs = snapshot.data?.docs;
                            log.info("contact docs $contactDocs");
                            var contacts = contactDocs?.map((doc) {
                              final data = doc.data();
                              return Contact(
                                id: doc.id,
                                name: data["name"],
                                FCMToken: doc['FCMToken'],
                                phoneNumber: doc['phoneNumber'],
                              );
                            }).toList();

                            log.info(contacts);

                            return MenuAnchor(
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
                                    _selectedContact?.name ??
                                        "Select a contact",
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                );
                              },
                              menuChildren: contacts!.map((contact) {
                                return MenuItemButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedContact = contact;
                                    });
                                  },
                                  child: Text(contact.name),
                                );
                              }).toList(),
                            );
                          });
                    }),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            SendButton(selectedContact: _selectedContact),
          ],
        ),
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  final Contact? selectedContact;
  const SendButton({
    super.key,
    required this.selectedContact,
  });

  Future<void> sendNotification() async {
    if (selectedContact == null) {
      return;
    }
    log.info("sending notification to ${selectedContact!.FCMToken}");
    
    final results = await FirebaseFunctions.instance
        .httpsCallable('sendNotification')
        .call({"FCMToken": selectedContact!.FCMToken});

    log.info(results.data);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
