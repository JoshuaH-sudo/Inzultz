import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isVerifying = false;

  var _enteredPhoneNumber = '';

  String? _verificationCode;
  int? _resendToken;
  var _smsCode = '';

  _onSubmit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    _formKey.currentState!.save();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _enteredPhoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {},
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isVerifying = true;
          _verificationCode = verificationId;
          _resendToken = resendToken;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  _sendSMSCode() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    _formKey.currentState!.save();

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationCode!,
      smsCode: _smsCode,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final fcm = FirebaseMessaging.instance;
      final notificationSettings = await fcm.requestPermission();
      if (notificationSettings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await fcm.getToken();
      print('TOKEN: ${token}');

      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      final user = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!user.exists) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'phoneNumber': _enteredPhoneNumber,
          'FCMToken': token,
        });
      }
      // Ensure the correct FCMToken is stored in the database.
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'FCMToken': token,
      });
    } catch (error) {
      print('Unable to add user $error');
    }

    setState(() {
      _isVerifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var loginContent = [
      IntlPhoneField(
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          border: OutlineInputBorder(
            borderSide: BorderSide(),
          ),
        ),
        initialCountryCode: 'AU',
        onChanged: (phone) {
          setState(() {
            _enteredPhoneNumber = phone.completeNumber;
          });
        },
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: const Text("Login"),
      ),
    ];

    var verifyingContent = [
      TextFormField(
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Verification Code',
          border: OutlineInputBorder(
            borderSide: BorderSide(),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a verification code';
          }
          return null;
        },
        onSaved: (value) {
          setState(() {
            _smsCode = value!;
          });
        },
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        onPressed: _sendSMSCode,
        child: const Text("Verify"),
      ),
      const SizedBox(height: 6),
      TextButton(onPressed: () {}, child: const Text("Resend code")),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isVerifying)
                            ...verifyingContent
                          else
                            ...loginContent,
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
