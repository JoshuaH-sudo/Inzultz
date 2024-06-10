import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SMSCodeLoginScreen extends StatefulWidget {
  final Function(String) onSendSMSCode;
  final VoidCallback onResendCode;
  final VoidCallback onCancel;

  const SMSCodeLoginScreen({
    super.key,
    required this.onSendSMSCode,
    required this.onResendCode,
    required this.onCancel,
  });

  @override
  State<SMSCodeLoginScreen> createState() => _SMSCodeLoginScreenState();
}

class _SMSCodeLoginScreenState extends State<SMSCodeLoginScreen> {
  String _smsCode = '';

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
                          onChanged: (value) {
                            setState(() {
                              _smsCode = value;
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
                          onPressed: () => {
                            widget.onSendSMSCode(_smsCode)
                          },
                          child: const Text("Verify"),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: widget.onResendCode,
                          child: const Text("Resend code"),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: widget.onCancel,
                          child: const Text("Cancel"),
                        ),
                      ],
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
