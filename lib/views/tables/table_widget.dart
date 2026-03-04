import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/utils/table_popup_overlay.dart';
import 'package:order_manager/utils/tap_functions.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';
import 'package:order_manager/views/ui_utils.dart';

class TableWidget extends ConsumerStatefulWidget {
  final Table1 table;
  const TableWidget({super.key, required this.table});

  @override
  ConsumerState<TableWidget> createState() => TableWidgetState();
}

class TableWidgetState extends ConsumerState<TableWidget> {
  late final Table1 table;
  @override
  void initState() {
    table = widget.table;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tableOrderStatusState = ref.watch(
      tableOrderStatus(table.tableNo.toString()),
    );
    return GestureDetector(
      onTap: () {
        final box = context.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero);
        final popupTable = ref.watch(tablePopupProvider);

        if (popupTable == table.tableNo) {
          TablePopupOverlay.hide();
          ref.read(tablePopupProvider.notifier).close();
          return;
        }

        TablePopupOverlay.show(
          context: context,
          position: pos,
          child: TablePopupMenu(
            table: table,
            onAction: (action) async {
              TablePopupOverlay.hide();
              ref.read(tablePopupProvider.notifier).close();
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
        ref.read(tablePopupProvider.notifier).open = table.tableNo;
      },
      child: tableOrderStatusState.when(
        loading: () {
          return const SizedBox(
            height: 110,
            width: 130,
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        error: (e, _) {
          return const SizedBox(
            height: 110,
            width: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(height: 4),
                Text(
                  "Error",
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          );
        },
        data: (data) {
          Color? color = getBackgroundColor(data);
          color ??= Colors.blue;
          return LongPressDraggable<Table1>(
            data: table,
            feedback: Material(
              color: Colors.transparent,
              child: TableIcon(
                table: table,
                color: color.withValues(alpha: 0.5),
              ),
            ),
            childWhenDragging: TableIcon(table: table, color: Colors.grey),
            child: TableIcon(table: table, color: color),
          );
        },
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
