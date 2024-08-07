import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:inzultz/main.dart';
import 'package:inzultz/screens/sms_login_screen.dart';
import 'package:logging/logging.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

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
  var _isSignup = false;

  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredPhoneNumber = '';
  Country? _countryCode;

  String? _verificationCode;
  int? _resendToken;

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

  _goToVerify() {
    setState(() {
      _isLoading = false;
    });

    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      _showMessage('Invalid data entered', isError: true);
      log.severe('Invalid form ${_formKey.currentState.toString()}');
      return;
    }
    _formKey.currentState!.save();

    return Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return SMSCodeLoginScreen(
          onSendSMSCode: _sendSMSCode,
          onResendCode: _startAuthProcess,
          onCancel: () async {
            Navigator.of(context).pop();
            await FirebaseAuth.instance.signOut();
          },
        );
      }),
    );
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

    try {
      await _validateData();
    } catch (error) {
      log.severe('Error: $error');
      FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
      );
      if (error
          .toString()
          .contains("[firebase_functions/unavailable] UNAVAILABLE")) {
        _showMessage("Applications servers maybe down. Please try again later");
      } else {
        _showMessage(error.toString(), isError: true);
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await _startAuthProcess();
  }

  _validateData() async {
    final response = await FirebaseFunctions.instance
        .httpsCallable('checkPhoneNumberIsUsed')
        .call({'phoneNumber': _enteredPhoneNumber});

    if (response.data['error'] != null) {
      log.info('Error: ${response.data['error']}');
      FirebaseCrashlytics.instance.recordError(
        response.data['error'],
        StackTrace.current,
      );
      throw 'Unexpected error occurred, please try again.';
    }

    final isUsed = response.data['isUsed'];
    // If the user is trying to sign up and the phone number is used, proceed to login.
    if (_isSignup && isUsed) {
      setState(() {
        _isSignup = false;
        _isLoading = false;
      });
      throw 'Phone number is already in use, please login.';
    }

    // If the user is trying to login and the phone number is not used, prompt to sign up.
    if (!_isSignup && !isUsed) {
      setState(() {
        _isSignup = true;
        _isLoading = false;
      });
      throw 'You do not have an account, sign up first.';
    }
  }

  _startAuthProcess() async {
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
              'auto': true
            },
          );

          await _createUser();
        } else {
          await analytics.logLogin(
            loginMethod: 'phone',
            parameters: {
              'phone': _enteredPhoneNumber,
              'name': _enteredName,
              'auto': true
            },
          );
        }

        final userCredentials =
            await FirebaseAuth.instance.signInWithCredential(credential);

        Posthog().identify(userId: userCredentials.user!.uid, userProperties: {
          'phone': userCredentials.user!.phoneNumber!,
          'name': userCredentials.user!.displayName ?? 'unknown',
        });

        _returnToPreviousScreen(userCredentials);
      },
      verificationFailed: (FirebaseAuthException e) {
        log.severe('Failed to verify phone number: $_enteredPhoneNumber, error: ${e.message}');
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
        );
        setState(() {
          _isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        log.info('Code sent');
        setState(() {
          _isLoading = false;
          _verificationCode = verificationId;
          _resendToken = resendToken;
        });
        _formKey.currentState!.reset();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _isLoading = false;
          _verificationCode = verificationId;
        });
      },
    );

    _goToVerify();
  }

  _sendSMSCode(String smsCode) async {
    log.info('Sending SMS code');
    setState(() {
      _isLoading = true;
    });

    log.info('Getting credential');
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationCode!,
      smsCode: smsCode,
    );

    print('CREDENTIAL: $credential');
    print('entered phone number: $_enteredPhoneNumber');

    UserCredential userCredentials;
    try {
      userCredentials =
          await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (error) {
      log.severe('Failed to sign in with credential: $error');
      _showMessage('Failed to sign in with credential', isError: true);

      setState(() {
        _isLoading = false;
      });
      return;
    }

    log.info('User signed in: ${userCredentials.user}');
    Posthog().identify(userId: userCredentials.user!.uid, userProperties: {
      'phone': userCredentials.user!.phoneNumber!,
      'name': userCredentials.user!.displayName ?? 'unknown',
    });

    if (_isSignup) {
      try {
        await _createUser();
      } catch (error) {
        log.severe('Unable to add user $error');
        _showMessage(
          'Unexpected error occurred, please try again.',
          isError: true,
        );
        await FirebaseAuth.instance.signOut();
      }
    }

    _formKey.currentState!.reset();
    setState(() {
      _isLoading = false;
    });

    // Need to return to the previous screen before the sms code is sent.
    // To ensure that the next pop() will return to the manage settings screen.
    if (mounted) GoRouter.of(context).pop();
    _returnToPreviousScreen(userCredentials);
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

    await FirebaseAuth.instance.currentUser!.updateDisplayName(_enteredName);
  }

  _returnToPreviousScreen(credential) {
    if (widget.mode == null) return GoRouter.of(context).replace('/');

    log.info('Returning to previous screen');
    try {
      GoRouter.of(context).pop(credential);
    } catch (error) {
      log.severe('Failed to return to previous screen: $error');
      FirebaseCrashlytics.instance.recordError(
        error,
        StackTrace.current,
      );
    }
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
  void dispose() {
    super.dispose();
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
          // Check if this screen is on top of the stack
          if (value == null || value.trim().isEmpty) {
            log.severe('Name is empty');
            return 'Please enter a name';
          }
          return null;
        },
        initialValue: '',
        onChanged: (value) => {
          setState(() {
            _enteredName = value;
          })
        },
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
        initialCountryCode: _countryCode != null ? _countryCode!.code : 'US',
        initialValue: _enteredPhoneNumber,
        onCountryChanged: (value) {
          setState(() {
            _countryCode = value;
          });
        },
        languageCode: "en",
        validator: (phone) {
          if (phone == null || phone.completeNumber.isEmpty) {
            log.severe('Phone number is empty');
            return 'Please enter a phone number';
          }
          return null;
        },
        onChanged: (value) {
          setState(() {
            _enteredPhoneNumber = value.completeNumber;
          });
        },
        onSaved: (phone) {
          setState(() {
            _enteredPhoneNumber =
                "${phone!.countryCode}${phone.number.replaceFirst(RegExp(r'^0+'), '')}";
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
