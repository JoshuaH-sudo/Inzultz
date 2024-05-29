import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final log = Logger('AuthScreen');

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  var _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  String? _verificationCode;
  int? _resendToken;
  String? _smsCode;


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

    setState(() {
      _isLoading = true;
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
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            onPressed: _sendSMSCode,
                            child: const Text("Verify"),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                              onPressed: () {},
                              child: const Text("Resend code")),
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
