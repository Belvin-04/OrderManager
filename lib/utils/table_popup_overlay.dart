import 'package:flutter/material.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';

class TablePopupOverlay {
  static OverlayEntry? _entry;
  static bool isOpen = false;

  static void show({
    required BuildContext context,
    required Offset position,
    required TablePopupMenu child,
  }) {
    hide();
    isOpen = true;
    _entry = OverlayEntry(
      builder: (_) =>
          Positioned(left: position.dx, top: position.dy, child: child),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    isOpen = false;
    _entry?.remove();
    _entry = null;
  }
}
