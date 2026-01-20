import 'package:flutter/material.dart';

class TablePopupOverlay {
  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required Offset position,
    required Widget child,
  }) {
    hide();
    _entry = OverlayEntry(
      builder: (_) =>
          Positioned(left: position.dx, top: position.dy, child: child),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
