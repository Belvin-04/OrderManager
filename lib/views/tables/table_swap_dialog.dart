import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/providers/providers.dart';

class TableSwapDialog extends ConsumerWidget {
  final List<int> availableTables;
  final void Function(int tableNo) onSelect;

  const TableSwapDialog({
    super.key,
    required this.availableTables,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return AlertDialog(
      title: Text("Select Table No. to swap the order"),
      content: SizedBox(
        width: 200,
        height: 200,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableTables.length,
          itemBuilder: (context, index) {
            final tableNo = availableTables[index];
            return Card(
              color: themeMode == ThemeMode.dark
                  ? Colors.grey.shade900
                  : Colors.white,
              child: ListTile(
                title: Text("Table No. : ${availableTables[index]}"),
                onTap: () {
                  onSelect(tableNo);
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
