import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/security_service.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();

  final SecurityService _security = SecurityService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () => _tryBiometric());
  }

  /// Attempt biometric authentication
  Future<void> _tryBiometric() async {
    final success = await _security.authenticateBiometric();

    if (!mounted) return;
    if (success) {
      context.read<AppStateProvider>().unlockApp();
    }
  }

  /// Verify PIN fallback
  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    final valid = await _security.verifyPin(_pinController.text);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (valid) {
      context.read<AppStateProvider>().unlockApp();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid PIN")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      /// Prevent back button bypass
      onWillPop: () async => false,

      child: Scaffold(
        backgroundColor: AppTheme.background,

        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Title
                const Text(
                  "Unlock Kanakkan",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),

                const SizedBox(height: 30),

                /// PIN input
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 6),
                  decoration: const InputDecoration(
                    hintText: "••••",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                /// Unlock button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Unlock"),
                  ),
                ),

                const SizedBox(height: 20),

                /// Manual biometric retry button
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint, color: AppTheme.accent),
                  label: const Text(
                    "Use biometric",
                    style: TextStyle(color: AppTheme.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
