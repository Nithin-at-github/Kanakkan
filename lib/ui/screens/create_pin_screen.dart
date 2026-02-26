import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/security_service.dart';
import 'package:kanakkan/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final controller = TextEditingController();
  final security = SecurityService();

  void savePin() async {
    final pin = controller.text;

    if (pin.length != 4) return;

    await security.savePin(pin);

    if (!mounted) return;
    context.read<AppStateProvider>().pinCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create PIN")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Set a 4-digit PIN"),

            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
            ),

            ElevatedButton(onPressed: savePin, child: const Text("Save PIN")),
          ],
        ),
      ),
    );
  }
}
