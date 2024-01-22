import 'package:cloud_firestore/cloud_firestore.dart';
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
            await FirebaseFirestore.instance.doc('users/${element.to}').get();
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
              .doc("users/${currentUser.uid}")
              .collection("contact_requests")
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
                      child: Text('No requests'),
                    );
                  }

                  print('contactInformation: $contactInformation');

                  return ListView.builder(
                      itemCount: contactInformation.length,
                      itemBuilder: (context, index) {
                        final contact = contactInformation[index];
                        final request = requestDocs[index];
                        return ListTile(
                          title: Text(contact.name),
                          subtitle: Text(contact.phoneNumber),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .doc("users/${currentUser.uid}")
                                  .collection("contact_requests")
                                  .doc(request["id"])
                                  .delete();
                            },
                          ),
                        );
                      });
                });
          }),
    );
  }
}
