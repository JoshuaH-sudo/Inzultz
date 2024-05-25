import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inzultz/models/contact.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:inzultz/screens/manage_contacts.dart';
import 'package:inzultz/screens/manage_requests.dart';
import 'package:inzultz/screens/manage_settings.dart';
import 'package:inzultz/utils.dart';
import 'package:logging/logging.dart';
import 'package:fluttertoast/fluttertoast.dart';

final _log = Logger('SendScreen');

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

    void settings() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const ManageSettings();
      }));
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title;
      final body = message.notification?.body;

      if (title == null || body == null) {
        return;
      }

      Fluttertoast.cancel();
      Fluttertoast.showToast(
        msg: title,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        // Random background color
        backgroundColor:
            Colors.primaries[Random().nextInt(Colors.primaries.length)],
        textColor: Colors.white,
        fontSize: 16.0,
      );
    });

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
            icon: const Icon(Icons.settings),
            onPressed: () {
              settings();
            },
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
                        .collection('contact_requests')
                        .where(
                          Filter.and(
                            Filter.or(
                              Filter(
                                "senderId",
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser!.uid,
                              ),
                              Filter(
                                "receiverId",
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser!.uid,
                              ),
                            ),
                            Filter("status", isEqualTo: "accepted"),
                          ),
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (snapshot.hasError) {
                        _log.severe(snapshot.error);
                      }

                      _log.info(snapshot.data!.docs);

                      var contactRequests = snapshot.data!.docs;

                      if (contactRequests.isEmpty) {
                        return const Text("No contacts found");
                      }

                      return FutureBuilder(
                          future: getContacts(contactRequests),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (snapshot.hasError) {
                              _log.severe(snapshot.error);
                            }

                            final contacts = snapshot.data;

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
    _log.info("sending notification to ${selectedContact!.FCMToken}");

    final results = await FirebaseFunctions.instance
        .httpsCallable('sendNotification')
        .call({"FCMToken": selectedContact!.FCMToken});

    _log.info(results.data);
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
            elevation: WidgetStateProperty.all(5),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100000),
              ),
            ),
            backgroundColor: WidgetStateProperty.all(Colors.red),
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
