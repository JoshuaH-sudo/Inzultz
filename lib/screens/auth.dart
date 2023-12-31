import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  var _isLoading = false;
  var _isVerifying = false;
  var _isSignup = false;

  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredPhoneNumber = '';

  String? _verificationCode;
  int? _resendToken;
  String? _smsCode;

  _onSubmit() async {
    print('Submitting');
    setState(() {
      _isLoading = true;
    });
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      print('Invalid');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    _formKey.currentState!.save();
    print('Form saved $_enteredPhoneNumber');

    final response = await FirebaseFunctions.instance
        .httpsCallable('checkPhoneNumberIsUsed')
        .call({'phoneNumber': _enteredPhoneNumber});

    if (response.data['error'] != null) {
      print('Error: ${response.data['error']}');
      _showMessage(
        'Unexpected error occurred, please try again.',
        isError: true,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (response.data['isUsed']) {
      print('Phone number is used');
      _showMessage('Phone number is already in use', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    print('Phone number is not used');

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _enteredPhoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        print('Verification completed');
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Failed to verify phone number: ${e.message}');
        setState(() {
          _isVerifying = false;
          _isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        print('Code sent');
        setState(() {
          _isVerifying = true;
          _isLoading = false;
          _verificationCode = verificationId;
          _resendToken = resendToken;
        });
        _formKey.currentState!.reset();
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  _sendSMSCode() async {
    setState(() {
      _isLoading = true;
    });
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationCode!,
      smsCode: _smsCode!,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    try {
      final fcm = FirebaseMessaging.instance;
      final notificationSettings = await fcm.requestPermission();
      if (notificationSettings.authorizationStatus ==
          AuthorizationStatus.denied) {
        return;
      }

      final token = await fcm.getToken();
      print('TOKEN: $token');

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!user.exists) {
        print('Adding user');
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'id': uid,
          'name': _enteredName,
          'phoneNumber': _enteredPhoneNumber,
          'FCMToken': token,
        });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'FCMToken': token,
        });
      }
    } catch (error) {
      print('Unable to add user $error');
      _showMessage(
        'Unexpected error occurred, please try again.',
        isError: true,
      );
    }

    _formKey.currentState!.reset();
    setState(() {
      _isVerifying = false;
      _isLoading = false;
    });
  }

  _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var signupContext = [
      TextFormField(
        maxLength: 25,
        maxLines: 1,
        decoration: const InputDecoration(
          labelText: 'Name',
          border: OutlineInputBorder(
            borderSide: BorderSide(),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a name';
          }
          return null;
        },
        initialValue: '',
        onSaved: (value) {
          setState(() {
            _enteredName = value!;
          });
        },
      ),
      const SizedBox(height: 12),
    ];

    var loginContent = [
      if (_isSignup) ...signupContext,
      IntlPhoneField(
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          border: OutlineInputBorder(
            borderSide: BorderSide(),
          ),
        ),
        initialCountryCode: 'AU',
        onSaved: (phone) {
          setState(() {
            _enteredPhoneNumber = phone!.completeNumber;
          });
        },
      ),
      const SizedBox(height: 12),
      if (_isLoading)
        const CircularProgressIndicator()
      else
        ElevatedButton(
          onPressed: _onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Text(_isSignup ? "Create Account" : "Login"),
        ),
      TextButton(
          onPressed: () {
            if (_isLoading) return;

            setState(() {
              _isSignup = !_isSignup;
            });
          },
          child: Text(
            _isSignup ? "I have an account?" : "Sign up",
            style: TextStyle(
              color: _isLoading ? Colors.grey : Colors.black,
            ),
          ))
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
        initialValue: '',
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
      // TextButton(onPressed: () {}, child: const Text("Resend code")),
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
