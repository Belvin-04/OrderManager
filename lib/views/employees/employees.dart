import 'package:flutter/material.dart';

class Employees extends StatelessWidget {
  const Employees({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Employees")),
      body: const Center(child: Text("Employees")),
    );
  }
}
