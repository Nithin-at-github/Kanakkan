import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/security_service.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final TextEditingController _pinController = TextEditingController();

  final TextEditingController _confirmController = TextEditingController();

  final SecurityService _security = SecurityService();

  bool _isSaving = false;

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length != 4) {
      _showMessage("PIN must be 4 digits");
      return;
    }

    if (pin != confirm) {
      _showMessage("PINs do not match");
      return;
    }

    setState(() => _isSaving = true);

    await _security.savePin(pin);

    if (!mounted) return;

    setState(() => _isSaving = false);

    context.read<AppStateProvider>().pinCreated();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Create Your PIN",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 30),

              /// PIN
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(fontSize: 24, letterSpacing: 6),
                decoration: const InputDecoration(
                  hintText: "Enter 4-digit PIN",
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// Confirm PIN
              TextField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(fontSize: 24, letterSpacing: 6),
                decoration: const InputDecoration(
                  hintText: "Confirm PIN",
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save PIN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
