import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/security_service.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/app_state_provider.dart';
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

  /// ================= BIOMETRIC =================
  Future<void> _tryBiometric() async {
    final success = await _security.authenticateBiometric();

    if (!mounted) return;

    if (success) {
      context.read<AppStateProvider>().unlockApp();
    }
  }

  /// ================= VERIFY PIN =================
  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    final valid = await _security.verifyPin(_pinController.text.trim());

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (valid) {
      context.read<AppStateProvider>().unlockApp();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid PIN"),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ));
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: "••••",
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.accent.withOpacity(.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.accent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,

      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// ================= LOGO =================
                  const Text(
                    "I-W-¡-³-",
                    style: TextStyle(
                      fontFamily: 'Ravivarma',
                      fontSize: 64,
                      color: AppTheme.accent,
                    ),
                  ),

                  const Text(
                    "Unlock your finances",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  /// ================= CARD =================
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        /// PIN INPUT
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          maxLength: 4,
                          style: const TextStyle(
                            fontSize: 26,
                            letterSpacing: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: _inputDecoration(),
                          onSubmitted: (_) => _verifyPin(),
                        ),

                        const SizedBox(height: 12),

                        /// UNLOCK BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyPin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Unlock",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// BIOMETRIC BUTTON
                        TextButton.icon(
                          onPressed: _tryBiometric,
                          icon: const Icon(
                            Icons.fingerprint,
                            size: 26,
                            color: AppTheme.accent,
                          ),
                          label: const Text(
                            "Unlock with biometric",
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    "Authentication keeps your financial data secure",
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
