import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ledger_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<LedgerProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Kanakkan")),
      body: ListView.builder(
        itemCount: provider.accounts.length,
        itemBuilder: (context, index) {
          final acc = provider.accounts[index];

          return ListTile(
            title: Text(acc.name),
            subtitle: Text("${acc.entityType} - ${acc.mediumType}"),
          );
        },
      ),
    );
  }
}
