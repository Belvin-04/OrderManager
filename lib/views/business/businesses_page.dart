import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/views/business/add_business_dialog.dart';
import 'package:order_manager/views/business/delete_business_dialog.dart';
import 'package:order_manager/views/startup/preferred_startup_screen.dart';
import 'package:order_manager/views/ui_utils.dart';

class BusinessGate extends ConsumerWidget {
  const BusinessGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBusiness = ref.watch(selectedBusinessProvider);

    if (selectedBusiness == null) {
      return const BusinessesPage();
    }
    return const PreferredStartupScreen();
  }
}

class BusinessesPage extends ConsumerWidget {
  const BusinessesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesState = ref.watch(businessesProvider);
    final employedBusinessesState = ref.watch(employedBusinessesProvider);
    final businessActionState = ref.watch(businessViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Businesses'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: businessActionState.isLoading
                ? null
                : () async {
                    ref
                        .read(businessViewModelProvider.notifier)
                        .clearSelectedBusiness();
                    await ref.read(authControllerProvider.notifier).signOut();
                  },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Business',
        onPressed: businessActionState.isLoading
            ? null
            : () {
                _showAddBusinessDialog(
                  context,
                  ref,
                  const Business(id: "", name: ""),
                );
              },
        child: const Icon(Icons.add_business),
      ),
      body: Column(
        children: [
          Expanded(
            child: businessesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (businesses) {
                if (businesses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        '''No businesses found.\nCreate one to start managing orders.''',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Owned Businesses",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: businesses.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final business = businesses[index];
                          return ListTile(
                            leading: const Icon(Icons.store),
                            title: Text(business.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit Business',
                                  onPressed: () {
                                    _showAddBusinessDialog(
                                      context,
                                      ref,
                                      business,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete Business',
                                  onPressed: () {
                                    _showDeleteBusinessDialog(
                                      context,
                                      ref,
                                      business,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              ref
                                  .read(selectedBusinessProvider.notifier)
                                  .setSelectedBusiness(business);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 2),
          Expanded(
            child: employedBusinessesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (employedBusinesses) {
                if (employedBusinesses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No businesses found.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Employed Businesses",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: employedBusinesses.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final employedBusiness = employedBusinesses[index];
                          return ListTile(
                            leading: const Icon(Icons.store),
                            title: Text(employedBusiness.businessName),
                            subtitle: Text(
                              '''${employedBusiness.employeeName} - ${employedBusiness.employeeRole}''',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ref
                                  .read(selectedBusinessProvider.notifier)
                                  .setSelectedBusiness(
                                    employedBusiness.toBusiness(),
                                  );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteBusinessDialog(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return DeleteBusinessDialog(
          initialBusiness: business,
          onDelete: (business) async {
            try {
              await ref
                  .read(businessViewModelProvider.notifier)
                  .deleteBusiness(business);
              if (!context.mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              showSnackBar('Business deleted successfully.', messenger);
            } catch (_) {
              if (!context.mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              showSnackBar('Unable to delete business.', messenger);
            }
          },
        );
      },
    );
  }

  void _showAddBusinessDialog(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AddBusinessDialog(
          initalBusiness: business,
          onSave: (business) async {
            try {
              await ref
                  .read(businessViewModelProvider.notifier)
                  .saveBusiness(business);
              if (!context.mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              showSnackBar('Business saved successfully.', messenger);
            } catch (_) {
              if (!context.mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              showSnackBar('Unable to save business.', messenger);
            }
          },
        );
      },
    );
  }
}
