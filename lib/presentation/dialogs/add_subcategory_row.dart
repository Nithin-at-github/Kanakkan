import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/validators/category_validator.dart';

class AddSubcategoryRow extends StatefulWidget {
  final Category parent;
  final Color accent;

  const AddSubcategoryRow({
    super.key,
    required this.parent,
    required this.accent,
  });

  @override
  State<AddSubcategoryRow> createState() => _AddSubcategoryRowState();
}

class _AddSubcategoryRowState extends State<AddSubcategoryRow> {
  final _controller = TextEditingController();

  bool _saving = false;
  String? _errorText;

  Future<void> _save(BuildContext context) async {
    final name = _controller.text.trim();

    final validationError = validateSubcategoryName(name);

    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    setState(() {
      _errorText = null;
      _saving = true;
    });

    final provider = context.read<CategoryProvider>();
    provider.clearError();

    await provider.addSubcategory(name: name, parentId: widget.parent.id!);

    if (!mounted) return;

    setState(() => _saving = false);

    if (provider.lastError == null) {
      _controller.clear();
    } else {
      setState(() => _errorText = provider.lastError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Subcategory name",
              errorText: _errorText,
            ),
            onSubmitted: (_) => _save(context),
          ),
        ),

        const SizedBox(width: 8),

        _saving
            ? const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: Icon(Icons.add_circle, color: widget.accent, size: 32),
                onPressed: () => _save(context),
              ),
      ],
    );
  }
}
