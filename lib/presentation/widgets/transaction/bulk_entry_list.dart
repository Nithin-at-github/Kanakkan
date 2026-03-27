import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/data/models/bulk_transaction_item.dart';

class BulkEntryList extends StatelessWidget {
  final List<BulkTransactionItem> items;
  final List<FocusNode> amountFocusNodes;
  final List<FocusNode> noteFocusNodes;

  final Function(int, String) onAmountChanged;
  final Function(int, String) onNoteChanged;
  final Function(int) onDelete;
  final Function(int) onSubmitNote;

  final VoidCallback onSaveAll;
  final VoidCallback onCancel;

  final double total;

  const BulkEntryList({
    super.key,
    required this.items,
    required this.amountFocusNodes,
    required this.noteFocusNodes,
    required this.onAmountChanged,
    required this.onNoteChanged,
    required this.onDelete,
    required this.onSubmitNote,
    required this.onSaveAll,
    required this.onCancel,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    /// AMOUNT
                    SizedBox(
                      width: 110,
                      child: TextField(
                        focusNode: amountFocusNodes[index],
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: AppTheme.accent,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: "Amount",
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixText: "₹ ",
                          prefixStyle: const TextStyle(color: Colors.white),
                          isDense: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.accent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.accent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (v) => onAmountChanged(index, v),
                        onSubmitted: (_) {
                          FocusScope.of(
                            context,
                          ).requestFocus(noteFocusNodes[index]);
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// NOTE
                    Expanded(
                      child: TextField(
                        focusNode: noteFocusNodes[index],
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: AppTheme.accent,
                        decoration: InputDecoration(
                          hintText: "Note",
                          hintStyle: const TextStyle(color: Colors.white54),
                          isDense: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.accent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.accent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (v) => onNoteChanged(index, v),
                        onSubmitted: (_) => onSubmitNote(index),
                      ),
                    ),

                    /// DELETE
                    if (items.length > 1)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppTheme.error),
                        onPressed: () => onDelete(index),
                      ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "₹${formatAmt(total, decimals: false)}",
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.accent),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: AppTheme.accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSaveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                  ),
                  child: Text(
                    "Save All",
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
