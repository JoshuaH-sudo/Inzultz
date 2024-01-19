import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inzultz/screens/add_contact.dart';

import '../models/contact.dart';

class ManageContacts extends StatelessWidget {
  const ManageContacts({super.key});

  @override
  Widget build(BuildContext context) {
    void addNewContact() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const AddContact();
      }));
    }

    Future<List<Contact>> getContacts() async {
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
      final currentUser = FirebaseAuth.instance.currentUser!;
      final currentUserData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final contacts = currentUserData['contacts'];
      contacts.remove(id);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
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
        body: FutureBuilder(
          future: getContacts(),
          initialData: const [],
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ListView.builder(
                itemCount: snapshot.data == null ? 0 : snapshot.data!.length,
                itemBuilder: (context, index) {
                  if (snapshot.data == null) {
                    return const Center(
                        child: Center(
                      child: Text(
                        'No contacts found',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ));
                  }

                  return Dismissible(
                    key: Key(snapshot.data![index].id),
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
                      removeContact(snapshot.data![index].id);
                    },
                    child: ListTile(
                      title: Text(snapshot.data![index].name),
                      subtitle: Text(snapshot.data![index].phoneNumber),
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ));
  }
}
