import 'package:flutter/material.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';

class TablePopupOverlay {
  static OverlayEntry? _entry;
  static Table1? _openForTable;

  static void show({
    required BuildContext context,
    required Offset position,
    required TablePopupMenu child,
  }) {
    final table = child.table;
    final bool clickedOnSameTable = table == _openForTable;
    if (_openForTable != null) {
      hide();
      if (clickedOnSameTable) {
        return;
      }
    }
    _showPopup(context, position, table, child);
  }

  static void _showPopup(
    BuildContext context,
    Offset position,
    Table1 table,
    TablePopupMenu child,
  ) {
    _openForTable = table;
    _entry = OverlayEntry(
      builder: (_) =>
          Positioned(left: position.dx, top: position.dy, child: child),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    _openForTable = null;
    _entry?.remove();
    _entry = null;
  }
}
