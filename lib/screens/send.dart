import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzultz/main.dart';
import 'package:inzultz/models/contact.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:inzultz/providers/app.dart';
import 'package:inzultz/screens/banner_example.dart';
import 'package:inzultz/screens/manage_contacts.dart';
import 'package:inzultz/screens/manage_requests.dart';
import 'package:inzultz/screens/manage_settings.dart';
import 'package:inzultz/models/db_collection.dart';
import 'package:inzultz/utils.dart';
import 'package:logging/logging.dart';
import 'package:fluttertoast/fluttertoast.dart';

final _log = Logger('SendScreen');

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  Contact? _selectedContact;

  void getConsent() async {
     await analytics.setConsent(
      adStorageConsentGranted: true,
      adUserDataConsentGranted: true,
      adPersonalizationSignalsConsentGranted: true,
    );
    _log.info("Consent set");
  }

  @override
  void initState() {
    super.initState();
    getConsent();
  }

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

    getContactRequest() {
      return FirebaseFirestore.instance
          .collection(DBCollection.contactRequests)
          .where(
            Filter.and(
              Filter.or(
                Filter(
                  "senderId",
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                ),
                Filter(
                  "receiverId",
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                ),
              ),
              Filter("status", isEqualTo: "accepted"),
            ),
          )
          .snapshots();
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              settings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(name: "logout");
              FirebaseAuth.instance.signOut();
            },
          ),
          IconButton(
            icon: const Icon(Icons.abc),
            onPressed: () => {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return const BannerExample();
              }))
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => throw Exception(),
                child: const Text("Throw Test Exception"),
              ),
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
                      stream: getContactRequest(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const Text("You have no contacts");
                        }

                        if (snapshot.hasError) {
                          _log.severe(snapshot.error);
                        }

                        _log.info(snapshot.data!.docs);

                        var contactRequests = snapshot.data!.docs;

                        return FutureBuilder(
                            future: getContacts(contactRequests),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data == null) {
                                return const Text("You have no contacts");
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
      ),
    );
  }
}

class SendButton extends ConsumerWidget {
  final Contact? selectedContact;
  const SendButton({
    super.key,
    required this.selectedContact,
  });

  Future<void> sendNotification(ref) async {
    if (selectedContact == null) {
      return;
    }
    ref.read(appProvider.notifier).setLoading(true);

    _log.info("sending notification to ${selectedContact!.FCMToken}");

    final results = await FirebaseFunctions.instance
        .httpsCallable('sendNotification')
        .call({"FCMToken": selectedContact!.FCMToken});

    _log.info(results.data);
    ref.read(appProvider.notifier).setLoading(false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width,
        child: ElevatedButton(
          onPressed: () => {sendNotification(ref)},
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
