import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inzultz/models/contact.dart';
import 'package:inzultz/models/contact_request.dart';
import 'package:inzultz/screens/add_contact.dart';

final currentUser = FirebaseAuth.instance.currentUser!;

class ManageRequests extends StatelessWidget {
  const ManageRequests({super.key});

  @override
  Widget build(BuildContext context) {
    void addNewContact() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const AddContact();
      }));
    }

    getContactInformation(List<ContactRequest> contactRequests) async {
      List<Contact> contactInformation = [];
      for (var element in contactRequests) {
        final contactDoc =
            await FirebaseFirestore.instance.doc('users/${element.from}').get();
        final contactData = contactDoc.data();
        print('contactData: $contactData');
        contactInformation.add(Contact(
          id: contactData!["uid"],
          name: contactData["name"],
          FCMToken: contactData['FCMToken'],
          phoneNumber: contactData['phoneNumber'],
        ));
      }

      return contactInformation.toList();
    }

    acceptRequest(String id) async {
      try {
        FirebaseFunctions.instance.httpsCallable('updateContactRequestStatus')({
          "contactRequestId": id,
          "newStatus": "accepted"
        });
      } catch (e) {
        print(e);
      }
    }

    declineRequest(String id) async {
      try {
        FirebaseFunctions.instance.httpsCallable('updateContactRequestStatus')({
          "contactRequestId": id,
          "newStatus": "declined"
        });
      } catch (e) {
        print(e);
      }
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
              .collectionGroup("contact_requests")
              .where(
                Filter.and(
                  Filter.or(
                    Filter("from", isEqualTo: currentUser.uid),
                    Filter("to", isEqualTo: currentUser.uid),
                  ),
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

            final requestDocs = snapshot.data?.docs ?? [];
            final requestsData = requestDocs
                .map((e) => ContactRequest(
                      from: e["from"],
                      to: e["to"],
                      status: e["status"],
                    ))
                .toList();
            if (requestsData.isEmpty) {
              return const Center(
                child: Text('No requests'),
              );
            }

            print('requests: $requestsData');
            return FutureBuilder(
                future: getContactInformation(requestsData),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final contactInformation = snapshot.data ?? [];
                  if (contactInformation.isEmpty) {
                    return const Center(
                      child: Text('No requests information'),
                    );
                  }

                  print('contactInformation: $contactInformation');

                  return ListView.builder(
                      itemCount: contactInformation.length,
                      itemBuilder: (context, index) {
                        final contact = contactInformation[index];
                        final request = requestDocs[index];
                        final data = requestsData[index];
                        return ListTile(
                            title: Text(contact.name),
                            subtitle: Text(contact.phoneNumber),
                            leading: data.to == currentUser.uid
                                ? const Icon(Icons.call_received_rounded)
                                : const Icon(Icons.call_made_rounded),
                            trailing: data.to == currentUser.uid
                                ? PopupMenuButton<String>(
                                    itemBuilder: (BuildContext context) {
                                      return <PopupMenuEntry<String>>[
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
                                              onPressed: () =>
                                                  declineRequest(request.id),
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: "accept",
                                          child: Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: TextButton.icon(
                                              label: const Text("Accept"),
                                              icon: const Icon(
                                                Icons.check,
                                              ),
                                              onPressed: () =>
                                                  acceptRequest(request.id),
                                            ),
                                          ),
                                        )
                                      ];
                                    },
                                    onSelected: (String value) {
                                      // Handle dropdown item selection here
                                      print('Selected: $value');
                                    },
                                  )
                                : null);
                      });
                });
          }),
    );
  }
}
