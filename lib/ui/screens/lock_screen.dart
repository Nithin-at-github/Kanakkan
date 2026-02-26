import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/security_service.dart';
import 'package:kanakkan/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final controller = TextEditingController();
  final security = SecurityService();

  void verify() async {
    final ok = await security.verifyPin(controller.text);

    if (ok) {
      if (!mounted) return;
      context.read<AppStateProvider>().unlockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter PIN"),

            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
            ),

            ElevatedButton(onPressed: verify, child: const Text("Unlock")),
          ],
        ),
      ),
    );
  }
}
