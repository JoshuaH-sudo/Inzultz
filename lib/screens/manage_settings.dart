import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:inzultz/components/consent_manager.dart';
import 'package:inzultz/providers/ads.dart';
import 'package:inzultz/providers/app.dart';
import 'package:inzultz/screens/add_contact.dart';
import 'package:inzultz/screens/auth.dart';
import 'package:inzultz/models/db_collection.dart';
import 'package:logging/logging.dart';

final log = Logger('SettingsScreen');

class ManageSettings extends ConsumerStatefulWidget {
  const ManageSettings({super.key});

  @override
  ConsumerState<ManageSettings> createState() => _ManageSettingsState();
}

class _ManageSettingsState extends ConsumerState<ManageSettings> {
  static const privacySettingsText = 'Privacy Settings';
  final _consentManager = ConsentManager();
  var _isMobileAdsInitializeCalled = false;

  @override
  void initState() {
    super.initState();

    _consentManager.gatherConsent((consentGatheringError) {
      if (consentGatheringError != null) {
        // Consent not obtained in current session.
        debugPrint(
            "${consentGatheringError.errorCode}: ${consentGatheringError.message}");
      }

      // Attempt to initialize the Mobile Ads SDK.
      initializeMobileAdsSDK();
    });

    // This sample attempts to load ads using consent obtained in the previous session.
    initializeMobileAdsSDK();
  }

  /// Initialize the Mobile Ads SDK if the SDK has gathered consent aligned with
  /// the app's configured messages.
  void initializeMobileAdsSDK() async {
    if (_isMobileAdsInitializeCalled) {
      return;
    }

    var canRequestAds = await _consentManager.canRequestAds();
    if (canRequestAds) {
      setState(() {
        _isMobileAdsInitializeCalled = true;
      });

      // Initialize the Mobile Ads SDK.
      MobileAds.instance.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    void addNewContact() async {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const AddContact();
      }));
    }

    deleteDBUser() async {
      log.info('Deleting user');
      await FirebaseFirestore.instance
          .collection(DBCollection.users)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .delete();
    }

    deleteUsersContactRequests() async {
      log.info('Deleting users contact requests');
      final contactRequests = await FirebaseFirestore.instance
          .collectionGroup(DBCollection.contactRequests)
          .where(
            Filter.or(
              Filter("senderId",
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid),
              Filter("receiverId",
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid),
            ),
          )
          .get();
      // Delete all contact requests
      for (var contactRequest in contactRequests.docs) {
        await contactRequest.reference.delete();
      }
    }

    login() async {
      final newCredential = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return const AuthScreen(
            mode: AuthMode.LOGIN,
          );
        }),
      );

      return newCredential;
    }

    void onDeleteUser() async {
      try {
        final newCred = await login();
        if (newCred == null) {
          return;
        }

        ref.read(appProvider.notifier).setLoading(true);
        await deleteDBUser();
        await deleteUsersContactRequests();

        log.shout('Deleting user');
        await FirebaseAuth.instance.currentUser!.delete();
      } catch (error) {
        if (error is FirebaseAuthException) {
          log.severe('Failed to delete user: ${error.message}');
        } else {
          log.severe('Failed to delete user: $error');
        }
      }
      ref.read(appProvider.notifier).setLoading(false);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_sharp),
            onPressed: addNewContact,
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                ref
                    .watch(googleAdsProvider.notifier)
                    .consentManager
                    .showPrivacyOptionsForm((formError) {
                  if (formError != null) {
                    log.severe("${formError.errorCode}: ${formError.message}");
                  }
                });
              },
              child: const Text('Update Privacy Settings'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: onDeleteUser,
              child: const Text('Delete Account'),
            ),
          ),
        ],
      ),
    );
  }
}
