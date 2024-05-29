import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:inzultz/main.dart';
import 'package:logging/logging.dart';

final log = Logger('AuthScreen');

// ignore: constant_identifier_names
enum AuthMode { LOGIN, SIGNUP }

class AuthScreen extends StatefulWidget {
  final AuthMode? mode;
  const AuthScreen({super.key, this.mode});

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

  @override
  void initState() {
    super.initState();
    if (widget.mode != null) {
      if (widget.mode == AuthMode.SIGNUP) {
        setState(() {
          _isSignup = true;
        });
      }
    }
  }

  _onSubmit() async {
    log.info('Submitting');
    setState(() {
      _isLoading = true;
    });
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      log.info('Invalid');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    _formKey.currentState!.save();
    log.info('Form saved $_enteredPhoneNumber');

    if (_isSignup) {
      final response = await FirebaseFunctions.instance
          .httpsCallable('checkPhoneNumberIsUsed')
          .call({'phoneNumber': _enteredPhoneNumber});

      if (response.data['error'] != null) {
        log.info('Error: ${response.data['error']}');
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
        log.info('Phone number is used');
        _showMessage('Phone number is already in use', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      log.info('Phone number is not used');
    }

    _login();
  }

  _login() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      forceResendingToken: _resendToken,
      phoneNumber: _enteredPhoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android only: if the sms code is automatically detected
        log.info('Verification completed');

        if (_isSignup) {
          await analytics.logSignUp(
            signUpMethod: "phone",
            parameters: {
              'phone': _enteredPhoneNumber,
              'name': _enteredName,
            },
          );
        } else {
          await analytics.logLogin(
            loginMethod: 'phone',
            parameters: {
              'phone': _enteredPhoneNumber,
              'name': _enteredName,
            },
          );
        }

        final userCredentials =
            await FirebaseAuth.instance.signInWithCredential(credential);

        _returnToPreviousScreen(userCredentials);
      },
      verificationFailed: (FirebaseAuthException e) {
        log.info('Failed to verify phone number: ${e.message}');
        setState(() {
          _isVerifying = false;
          _isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        log.info('Code sent');
        setState(() {
          _isVerifying = true;
          _isLoading = false;
          _verificationCode = verificationId;
          _resendToken = resendToken;
        });
        _formKey.currentState!.reset();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _isVerifying = true;
          _isLoading = false;
          _verificationCode = verificationId;
        });
      },
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

    final userCreds =
        await FirebaseAuth.instance.signInWithCredential(credential);

    if (_isSignup) {
      try {
        await _createUser();
      } catch (error) {
        log.severe('Unable to add user $error');
        _showMessage(
          'Unexpected error occurred, please try again.',
          isError: true,
        );
      }
    }

    _formKey.currentState!.reset();
    setState(() {
      _isVerifying = false;
      _isLoading = false;
    });

    _returnToPreviousScreen(userCreds);
  }

  _createUser() async {
    final fcm = FirebaseMessaging.instance;
    final notificationSettings = await fcm.requestPermission();
    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.denied) {
      return;
    }

    final token = await fcm.getToken();
    log.info('TOKEN: $token');

    final uid = FirebaseAuth.instance.currentUser!.uid;
    log.info('Adding user');
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'id': uid,
      'name': _enteredName,
      'phoneNumber': _enteredPhoneNumber,
      'FCMToken': token,
    });
  }

  _returnToPreviousScreen(credential) {
    if (widget.mode == null) return;

    log.info('Returning to previous screen');
    Navigator.of(context).pop(credential);
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
        validator: (phone) {
          if (phone == null || phone.completeNumber.isEmpty) {
            return 'Please enter a phone number';
          }
          return null;
        },
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
      // If mode as been defined, do not allow the user to switch.
      if (widget.mode == null)
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
      TextButton(
        onPressed: _login,
        child: const Text("Resend code"),
      ),
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
