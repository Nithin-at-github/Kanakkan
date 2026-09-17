import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AppCredit extends StatelessWidget {
  static const _linkedInUrl = 'https://www.linkedin.com/in/nithinjk28/';

  final CrossAxisAlignment alignment;

  const AppCredit({super.key, this.alignment = CrossAxisAlignment.center});

  Future<void> _openLinkedIn() async {
    final uri = Uri.parse(_linkedInUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          "Made with ♥ in Keralam",
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white24
                : Colors.black26,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _openLinkedIn,
          child: Text(
            "by Nithin JK",
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
              decorationColor: AppTheme.accent,
            ),
          ),
        ),
      ],
    );
  }
}
