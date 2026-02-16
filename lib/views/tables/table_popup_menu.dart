import 'package:flutter/material.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/utils/tap_functions.dart';

class TablePopupMenu extends StatelessWidget {
  final Table1 table;
  final void Function(TablePopupAction action) onAction;
  const TablePopupMenu({
    super.key,
    required this.table,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
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
              onTap: () => onAction(TablePopupAction.takeOrder),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Tooltip(
                  message: "Take Order",
                  child: Icon(Icons.event_note_outlined, color: Colors.green),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => onAction(TablePopupAction.swap),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Tooltip(
                  message: "Swap Table Order",
                  child: Icon(Icons.swap_vert, color: Colors.yellow),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => onAction(TablePopupAction.clear),
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
