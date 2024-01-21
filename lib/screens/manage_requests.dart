import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

    return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Requests'),
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
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final requests = snapshot.data?.docs ?? [];
            if (requests.isEmpty) {
              return const Center(
                child: Text('No requests'),
              );
            }

            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return ListTile(
                  title: Text(request['to']),
                  subtitle: Text(request['from']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .doc("users/${currentUser.uid}")
                          .collection("contact_requests")
                          .doc(request.id)
                          .delete();
                    },
                  ),
                );
              },
            );
          },
        ));
  }
}
