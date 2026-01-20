import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/utils/table_popup_overlay.dart';
import 'package:order_manager/utils/tap_functions.dart';

class TablePopupMenu extends ConsumerWidget {
  final Table1 table;
  const TablePopupMenu({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                TablePopupOverlay.hide();
                takeOrder(context, table);
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Tooltip(
                  message: "Take Order",
                  child: Icon(Icons.event_note_outlined, color: Colors.green),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                TablePopupOverlay.hide();
                swapTableOrder(context, ref, table);
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Tooltip(
                  message: "Swap Table Order",
                  child: Icon(Icons.swap_vert, color: Colors.yellow),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                TablePopupOverlay.hide();
                clearTable(context, ref, table);
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Tooltip(
                  message: "Clear Table",
                  child: Icon(Icons.clear, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
