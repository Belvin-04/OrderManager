import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/utils/table_popup_overlay.dart';
import 'package:order_manager/utils/tap_functions.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';

class TableWidget extends ConsumerStatefulWidget {
  final Table1 table;
  const TableWidget({super.key, required this.table});

  @override
  ConsumerState<TableWidget> createState() => TableWidgetState();
}

class TableWidgetState extends ConsumerState<TableWidget> {
  bool showMenu = false;
  late final Table1 table;
  @override
  void initState() {
    table = widget.table;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final box = context.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero);
        showMenu = !showMenu;

        if (showMenu) {
          TablePopupOverlay.show(
            context: context,
            position: pos,
            child: TablePopupMenu(
              table: table,
              onAction: (action) async {
                TablePopupOverlay.hide();
                switch (action) {
                  case TablePopupAction.takeOrder:
                    takeOrder(context, table);

                  case TablePopupAction.swap:
                    await swapTableOrder(context, ref, table);

                  case TablePopupAction.clear:
                    await clearTable(context, ref, table);
                }
              },
            ),
          );
        } else {
          TablePopupOverlay.hide();
        }
      },
      child: LongPressDraggable<Table1>(
        data: table,
        feedback: Material(
          color: Colors.transparent,
          child: TableIcon(
            table: table,
            color: Colors.blue.withValues(alpha: 0.5),
          ),
        ),
        childWhenDragging: TableIcon(table: table, color: Colors.grey),
        child: TableIcon(table: table, color: Colors.blue),
      ),
    );
  }
}

class TableIcon extends StatelessWidget {
  final Table1 table;
  final Color color;
  const TableIcon({super.key, required this.table, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: 130,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.table_restaurant, size: 40, color: color),
              Text("T${table.tableNo}", style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
