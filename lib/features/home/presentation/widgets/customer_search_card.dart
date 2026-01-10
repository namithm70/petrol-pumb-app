import 'package:flutter/material.dart';

import 'package:bpclpos/features/home/domain/entities/home_entities.dart';
import 'package:bpclpos/features/home/presentation/widgets/home_text_field.dart';

class CustomerSearchCard extends StatelessWidget {
  const CustomerSearchCard({
    super.key,
    required this.controller,
    required this.showCustomerList,
    required this.filteredCustomers,
    required this.selectedCustomer,
    required this.onClearSelection,
    required this.onScanBarcode,
    required this.onSearchTap,
    required this.onCustomerSelected,
  });

  final TextEditingController controller;
  final bool showCustomerList;
  final List<Customer> filteredCustomers;
  final Customer? selectedCustomer;
  final VoidCallback onClearSelection;
  final VoidCallback onScanBarcode;
  final VoidCallback onSearchTap;
  final ValueChanged<Customer> onCustomerSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF1A2E35)),
              const SizedBox(width: 8),
              const Text(
                "Customer Search",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E35),
                ),
              ),
              if (selectedCustomer != null) ...[
                const Spacer(),
                IconButton(
                  onPressed: onClearSelection,
                  icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          HomeTextField(
            controller: controller,
            label: "Search",
            decoration: InputDecoration(
              hintText: "Search by name, mobile or card number",
              prefixIcon: const Icon(Icons.person_search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: onScanBarcode,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            onTap: onSearchTap,
          ),
          if (showCustomerList)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              height: 200,
              child: ListView.builder(
                itemCount: filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = filteredCustomers[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.person,
                      color: Color(0xFF1A2E35),
                    ),
                    title: Text(customer.name),
                    subtitle: Text(
                      "${customer.cardNumber} • ${customer.mobile}",
                    ),
                    trailing: Text(
                      "${customer.points} pts",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => onCustomerSelected(customer),
                  );
                },
              ),
            ),
          if (selectedCustomer != null && !showCustomerList)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2E35).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1A2E35).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedCustomer!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Card: ${selectedCustomer!.cardNumber} • Points: ${selectedCustomer!.points}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
