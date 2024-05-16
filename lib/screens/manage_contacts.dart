import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inzultz/screens/add_contact.dart';
import 'package:logging/logging.dart';

import '../models/contact.dart';
var currentAuthUser = FirebaseAuth.instance.currentUser!;

final log = Logger('ManageRequestsScreen');
class ManageContacts extends StatelessWidget {
  const ManageContacts({super.key});

  @override
  Widget build(BuildContext context) {
    void addNewContact() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const AddContact();
      }));
    }

    Future<List<Contact>> getContacts(currentUserData) async {
      final contacts = currentUserData?['contacts'] ?? [];

      if (contacts.isEmpty) {
        return [];
      }

      final contactsData = await FirebaseFirestore.instance
          .collection('users')
          .where('id', whereIn: contacts)
          .get();
      log.info('contactsData: ${contactsData.docs}');

      return contactsData.docs.map((doc) {
        return Contact(
          id: doc.id,
          name: doc["name"],
          FCMToken: doc['FCMToken'],
          phoneNumber: doc['phoneNumber'],
        );
      }).toList();
    }

    Future<void> removeContact(String id) async {
      final currentUserData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentAuthUser.uid)
          .get();

      final contacts = currentUserData['contacts'];
      contacts.remove(id);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentAuthUser.uid)
          .update({'contacts': contacts});
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_sharp),
            onPressed: addNewContact,
          ),
        ],
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .doc('users/${currentAuthUser.uid}')
              .snapshots(),
          builder: (context, currentUserSnapshot) {
            if (currentUserSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (currentUserSnapshot.hasError) {
              log.info('CurrentUserSnapshot Error: ${currentUserSnapshot.error}');
              return const Center(
                child: Text(
                  'An error occurred!',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                  ),
                ),
              );
            }

            if (!currentUserSnapshot.hasData) {
              return const Center(
                child: Text(
                  'No contacts found',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
              );
            }

            return FutureBuilder(
                future: getContacts(currentUserSnapshot.data?.data()),
                builder: (context, contactsSnapshot) {
                  if (contactsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (contactsSnapshot.hasError) {
                    log.info('contactsSnapshot Error: ${contactsSnapshot.error}');
                    return const Center(
                      child: Text(
                        'An error occurred!',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                        ),
                      ),
                    );
                  }

                  if (contactsSnapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No contacts found',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: contactsSnapshot.hasData
                        ? contactsSnapshot.data?.length
                        : 0,
                    itemBuilder: (context, index) {
                      if (contactsSnapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No contacts information found',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                        );
                      }

                      return Dismissible(
                        key: Key(contactsSnapshot.data![index].id),
                        background: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          removeContact(contactsSnapshot.data![index].id);
                        },
                        child: ListTile(
                          title: Text(contactsSnapshot.data![index].name),
                          subtitle:
                              Text(contactsSnapshot.data![index].phoneNumber),
                        ),
                      );
                    },
                  );
                });
          }),
    );
  }
}
