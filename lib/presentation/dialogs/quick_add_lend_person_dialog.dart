import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/lend_person.dart';
import 'package:kanakkan/presentation/providers/lend_provider.dart';
import 'package:provider/provider.dart';

class QuickAddLendPersonDialog {
  static Future<LendPerson?> show(BuildContext context, {LendPerson? person}) async {
    final nameController = TextEditingController(text: person?.name ?? '');
    final phoneController = TextEditingController(text: person?.phoneNumber ?? '');

    String? nameError;

    return showDialog<LendPerson?>(
      context: context,
      builder: (context) {
        final lendProvider = context.read<LendProvider>();

        return StatefulBuilder(
          builder: (context, setState) {
            final isEdit = person != null;

            return Dialog(
              backgroundColor: AppTheme.dialogSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEdit ? "Edit Contact" : "Add Contact",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // NAME FIELD
                      TextField(
                        controller: nameController,
                        style: TextStyle(color: AppTheme.onSurface),
                        decoration: InputDecoration(
                          labelText: "Contact Name",
                          labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                          errorText: nameError,
                          filled: true,
                          fillColor: AppTheme.surface,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.accent, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.error),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.error, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) {
                          if (nameError != null) {
                            setState(() => nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // PHONE FIELD
                      TextField(
                        controller: phoneController,
                        style: TextStyle(color: AppTheme.onSurface),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone Number (Optional)",
                          labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                          filled: true,
                          fillColor: AppTheme.surface,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.accent, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ACTIONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, null),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppTheme.divider),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: AppTheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  setState(() => nameError = "Name cannot be empty");
                                  return;
                                }

                                // Check uniqueness (excluding current person if editing)
                                final exists = lendProvider.people.any((p) =>
                                    p.person.name.toLowerCase() == name.toLowerCase() &&
                                    p.person.id != person?.id);
                                if (exists) {
                                  setState(() => nameError = "A contact with this name already exists");
                                  return;
                                }

                                final phone = phoneController.text.trim();

                                if (isEdit) {
                                  final updated = person.copyWith(
                                    name: name,
                                    phoneNumber: phone.isEmpty ? null : phone,
                                  );
                                  await lendProvider.editPerson(updated);
                                  if (context.mounted) Navigator.pop(context, updated);
                                } else {
                                  await lendProvider.addPerson(name, phone);
                                  if (context.mounted) Navigator.pop(context, null);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: AppTheme.background,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isEdit ? "Save" : "Add",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
