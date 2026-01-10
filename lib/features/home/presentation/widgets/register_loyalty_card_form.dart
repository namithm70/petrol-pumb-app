import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bpclpos/features/home/presentation/widgets/home_text_field.dart';

class RegisterLoyaltyCardForm extends StatelessWidget {
  const RegisterLoyaltyCardForm({
    super.key,
    required this.barcodeController,
    required this.cardNumberController,
    required this.customerNameController,
    required this.mobileController,
    required this.onScanBarcode,
    required this.onRegister,
    required this.onCardNumberSubmitted,
  });

  final TextEditingController barcodeController;
  final TextEditingController cardNumberController;
  final TextEditingController customerNameController;
  final TextEditingController mobileController;
  final VoidCallback onScanBarcode;
  final VoidCallback onRegister;
  final ValueChanged<String> onCardNumberSubmitted;

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
            "Register Loyalty Card",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E35),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: HomeTextField(
                  controller: barcodeController,
                  label: "Barcode",
                  prefixIcon: Icons.qr_code_scanner,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onScanBarcode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2E35),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text("SCAN"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HomeTextField(
            controller: cardNumberController,
            label: "Card Number",
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
            ],
            onSubmitted: onCardNumberSubmitted,
          ),
          const SizedBox(height: 16),
          HomeTextField(
            controller: customerNameController,
            label: "Customer Name",
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: 16),
          HomeTextField(
            controller: mobileController,
            label: "Mobile Number",
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2E35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("REGISTER CARD"),
            ),
          ),
        ],
      ),
    );
  }
}
