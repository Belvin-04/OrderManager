import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/employee_provider.dart';
import 'package:order_manager/views/employees/delete_employee_dialog.dart';
import 'package:order_manager/views/employees/save_employee_dialog.dart';
import 'package:order_manager/views/ui_utils.dart';

class Employees extends ConsumerWidget {
  const Employees({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBusinessId = ref.watch(currentBusinessIdProvider);
    final employeesState = ref.watch(employeesProvider(currentBusinessId));

    return Scaffold(
      appBar: AppBar(title: const Text("Employees")),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Employee",
        child: const Icon(Icons.add),
        onPressed: () {
          showAddEmployeeDialog(
            context,
            ref,
            const AppUser(id: "", name: "", email: ""),
          );
        },
      ),
      body: employeesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(child: Text("No Employees"));
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: employees.length,
            itemBuilder: (BuildContext context, int index) {
              AppUser employee = employees[index];
              return Card(
                child: ListTile(
                  title: Text("Name: ${employee.name}"),
                  subtitle: Text("Email: ${employee.email}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        child: const Tooltip(
                          message: "Edit Employee",
                          child: Icon(Icons.edit, color: Colors.blue),
                        ),
                        onTap: () {
                          showAddEmployeeDialog(context, ref, employee);
                        },
                      ),
                      Container(margin: const EdgeInsets.only(right: 10.0)),
                      GestureDetector(
                        child: const Tooltip(
                          message: "Delete Employee",
                          child: Icon(Icons.delete, color: Colors.red),
                        ),
                        onTap: () {
                          showDeleteEmployeeDialog(context, ref, employee);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void showAddEmployeeDialog(
    BuildContext context,
    WidgetRef ref,
    AppUser employee,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => SaveEmployeeDialog(
        initialEmployee: employee,
        onSave: (employee) async {
          final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
            context,
          );
          showSnackBar("Employee Saved Successfully...", messenger);
        },
      ),
    );
  }

  void showDeleteEmployeeDialog(
    BuildContext context,
    WidgetRef ref,
    AppUser employee,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => EmployeeDeleteDialog(
        initialEmployee: employee,
        onDelete: (employee) async {
          final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
            context,
          );
          showSnackBar("Employee Deleted Successfully", messenger);
        },
      ),
    );
  }
}
