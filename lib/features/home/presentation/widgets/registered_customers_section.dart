import 'package:flutter/material.dart';

import 'package:bpclpos/features/home/domain/entities/home_entities.dart';

class RegisteredCustomersSection extends StatelessWidget {
  const RegisteredCustomersSection({
    super.key,
    required this.customers,
    required this.itemBuilder,
  });

  final List<Customer> customers;
  final Widget Function(Customer customer) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Registered Customers",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E35),
            ),
          ),
          const SizedBox(height: 16),
          ...customers.map(itemBuilder).toList(),
        ],
      ),
    );
  }
}
