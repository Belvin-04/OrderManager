import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/utils/table_popup_overlay.dart';
import 'package:order_manager/views/tables/table_widget.dart';

class TableLayoutScreen extends ConsumerWidget {
  final _canvasKey = GlobalKey();
  TableLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if(TablePopupOverlay.isOpen){
          TablePopupOverlay.hide();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Table Layout Editor")),
        body: tablesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (tables) {
            return DragTarget<Table1>(
              onAcceptWithDetails: (details) {
                final box =
                    _canvasKey.currentContext!.findRenderObject() as RenderBox;
                final localOffset = box.globalToLocal(details.offset);
      
                ref
                    .read(tablesViewmodelProvider.notifier)
                    .updateTablePosition(details.data.id, localOffset);
              },
              builder: (_, __, ___) {
                return Stack(
                  key: _canvasKey,
                  children: [
                    Positioned.fill(child: Container(color: Colors.grey[40])),
                    for (final table in tables)
                      Positioned(
                        left: table.position.dx,
                        top: table.position.dy,
                        child: TableWidget(table: table),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
