import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/models/table.dart';

class SplitBillDialog extends StatefulWidget {
  final Table1 table;
  final void Function(int) onSplit;
  const SplitBillDialog({
    super.key,
    required this.table,
    required this.onSplit,
  });

  @override
  State<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends State<SplitBillDialog> {
  late TextEditingController personCountController;
  final GlobalKey<FormState> _formGlobalKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    personCountController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Split Bill for how many persons?"),
      content: Form(
        key: _formGlobalKey,
        child: TextFormField(
          controller: personCountController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please Enter Quantity";
            }
            if (int.tryParse(value) == null) return "Invalid number";
            if (int.tryParse(value)! < 2) {
              return "Bill should be split for at least 2 persons";
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: "Number of Persons",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_formGlobalKey.currentState!.validate()) {
              widget.onSplit(int.parse(personCountController.text));
            }
          },
          child: const Text("Split"),
        ),
      ],
    );
  }
}
