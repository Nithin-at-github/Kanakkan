import 'package:flutter/material.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<LedgerProvider>();
      provider.loadAccounts();
      provider.calculateBalances();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Kanakkan Dashboard")),
      body: ListView.builder(
        itemCount: provider.accounts.length,
        itemBuilder: (context, index) {
          final acc = provider.accounts[index];
          final balance = provider.accountBalances[acc.id] ?? 0;

          return Card(
            child: ListTile(
              title: Text(acc.name),
              subtitle: Text("${acc.entityType} - ${acc.mediumType}"),
              trailing: Text("₹ $balance"),
            ),
          );
        },
      ),
    );
  }
}
