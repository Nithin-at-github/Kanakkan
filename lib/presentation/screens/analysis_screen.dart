import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/widgets/custom_app_bar.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusableAppBar(),
      body: Center(child: Text("Analysis Screen")));
  }
}
