import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inzultz/models/contact.dart';
import 'package:logging/logging.dart';

final _log = Logger('Utils');

var currentAuthUser = FirebaseAuth.instance.currentUser!;
Future<List<Contact>> getContacts(
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? contactRequests,
) async {
  if (contactRequests == null) {
    return [];
  }

  final contactIds = contactRequests.map((doc) {
    final data = doc.data();
    if (data['senderId'] == currentAuthUser.uid) {
      return data['receiverId'];
    } else if (data['receiverId'] == currentAuthUser.uid) {
      return data['senderId'];
    }
  });

  if (contactIds.isEmpty) {
    return [];
  }

  final contactsData = await FirebaseFirestore.instance
      .collection('users')
      .where('id', whereIn: contactIds.toList())
      .get();

  _log.info('contactsData: ${contactsData.docs}');

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
  // find the contract_request where the senderId or receiverId is the current user or the user being removed
  // and delete it to allow either user to re-add each other again
  final contractRequests = await FirebaseFirestore.instance
      .collection('contact_requests')
      .where(
        Filter.or(
          Filter.and(
            Filter(
              "senderId",
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            ),
            Filter(
              "receiverId",
              isEqualTo: id,
            ),
          ),
          Filter.and(
            Filter(
              "senderId",
              isEqualTo: id,
            ),
            Filter(
              "receiverId",
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            ),
          ),
        ),
      )
      .get();

  _log.info('contractRequests to delete: ${contractRequests.docs}');

  for (var doc in contractRequests.docs) {
    _log.info('Deleting contract request: ${doc.reference.path}');
    await doc.reference.delete();
  }
}
