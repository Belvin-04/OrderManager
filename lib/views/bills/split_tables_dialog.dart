import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/providers/utils_provider.dart';

class SplitTablesDialog extends ConsumerWidget {
  final int totalSplit;
  final void Function(int) onTap;
  const SplitTablesDialog({
    super.key,
    required this.totalSplit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return AlertDialog(
      title: const Text("Select Split No to Split"),
      content: SizedBox(
        height: 200,
        width: 200,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: totalSplit,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                onTap(index + 1);
                Navigator.pop(context);
              },
              child: Card(
                color: themeMode == ThemeMode.dark
                    ? Colors.grey.shade900
                    : Colors.white,
                child: ListTile(title: Text("Split No.: ${index + 1}")),
              ),
            );
          },
        ),
      ),
    );
  }
}
