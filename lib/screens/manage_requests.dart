import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzultz/models/contact.dart';
import 'package:inzultz/models/contact_request.dart';
import 'package:inzultz/providers/app.dart';
import 'package:inzultz/screens/add_contact.dart';
import 'package:inzultz/models/db_collection.dart';
import 'package:logging/logging.dart';

final log = Logger('ManageRequestsScreen');

class ManageRequests extends ConsumerWidget {
  const ManageRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void addNewContact() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const AddContact();
      }));
    }

    // Need a better way at mapping the contact requests to the contact information
    getContactInformation(List<ContactRequest> contactRequests) async {
      List<Contact> contactInformation = [];

      for (var element in contactRequests) {
        try {
          final contactDoc = await FirebaseFirestore.instance
              .doc('users/${element.senderId}')
              .get();

          final contactData = contactDoc.data();
          log.info('contactData: $contactData');

          contactInformation.add(Contact(
            id: contactData!["id"],
            name: contactData["name"],
            FCMToken: contactData['FCMToken'],
            phoneNumber: contactData['phoneNumber'],
          ));
        } catch (e) {
          log.severe(e);
        }
      }

      log.info('contactInformation: $contactInformation');
      return contactInformation;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests Sent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_sharp),
            onPressed: addNewContact,
          ),
        ],
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collectionGroup(DBCollection.contactRequests)
              .where(
                Filter.and(
                  Filter("receiverId",
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid),
                  Filter("status", isEqualTo: "pending"),
                ),
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              log.severe(snapshot.error);
              return const Center(
                child: Text('An error occurred'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: Text('No data'),
              );
            }

            final requestDocs = snapshot.data?.docs ?? [];
            List<ContactRequest> requestsData = [];
            for (var doc in requestDocs) {
              final data = doc.data();
              log.info('data: $data');
              requestsData.add(
                ContactRequest(
                  senderId: data["senderId"],
                  receiverId: data["receiverId"],
                  status: data["status"],
                ),
              );
            }

            log.info('requests: ${requestsData.toList()}');
            return FutureBuilder(
                future: getContactInformation(requestsData.toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    Future(
                        () => ref.read(appProvider.notifier).setLoading(false));
                  }

                  log.info('snapshot: ${snapshot.data}');

                  final contactInformation = snapshot.data ?? [];
                  if (contactInformation.isEmpty) {
                    return const Center(
                      child: Text(
                        'No requests information',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    );
                  }

                  log.info('contactInformation: $contactInformation');

                  return ListView.builder(
                      itemCount: contactInformation.length,
                      itemBuilder: (context, index) {
                        final contact = contactInformation[index];
                        final request = requestDocs[index];
                        final data = requestsData[index];
                        return RequestListItem(
                            contact: contact, data: data, request: request);
                      });
                });
          }),
    );
  }
}

class RequestListItem extends ConsumerWidget {
  const RequestListItem({
    super.key,
    required this.contact,
    required this.data,
    required this.request,
  });

  final Contact contact;
  final ContactRequest data;
  final QueryDocumentSnapshot<Map<String, dynamic>> request;

  acceptRequest(String id) async {
    try {
      FirebaseFunctions.instance.httpsCallable('updateContactRequestStatus')(
          {"contactRequestId": id, "newStatus": "accepted"});
    } catch (e) {
      log.severe(e);
    }
  }

  declineRequest(String id) async {
    try {
      FirebaseFunctions.instance.httpsCallable('updateContactRequestStatus')(
          {"contactRequestId": id, "newStatus": "declined"});
    } catch (e) {
      log.severe(e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
        title: Text(contact.name),
        subtitle: Text(contact.phoneNumber),
        leading: const Icon(Icons.call_received_rounded),
        trailing: PopupMenuButton<String>(
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: "accept",
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextButton.icon(
                      label: const Text("Accept"),
                      icon: const Icon(
                        Icons.check,
                      ),
                      onPressed: () => {
                            Navigator.pop(context),
                            ref.read(appProvider.notifier).setLoading(true),
                            acceptRequest(request.id),
                          }),
                ),
              ),
              PopupMenuItem<String>(
                value: 'decline',
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextButton.icon(
                      label: const Text('decline'),
                      icon: const Icon(Icons.delete),
                      style: TextButton.styleFrom(
                        iconColor: Colors.red,
                      ),
                      onPressed: () => {
                            Navigator.pop(context),
                            ref.read(appProvider.notifier).setLoading(true),
                            declineRequest(request.id),
                          }),
                ),
              ),
            ];
          },
        ));
  }
}
