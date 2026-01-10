class Product {
  String name;
  double pricePerUnit;
  String unit;
  double purchasePrice;
  int stock;

  Product({
    required this.name,
    required this.pricePerUnit,
    required this.unit,
    required this.purchasePrice,
    required this.stock,
  });
}

class Customer {
  String name;
  String cardNumber;
  String? barcode;
  String mobile;
  int points;

  Customer({
    required this.name,
    required this.cardNumber,
    this.barcode,
    required this.mobile,
    required this.points,
  });
}

class SaleRecord {
  final String product;
  final int units;
  final double amount;
  final double purchaseCost;
  final String customer;
  final DateTime date;
  final int pointsEarned;
  final double? profit;

  SaleRecord({
    required this.product,
    required this.units,
    required this.amount,
    required this.purchaseCost,
    required this.customer,
    required this.date,
    required this.pointsEarned,
    this.profit,
  });
}

class RedeemableProduct {
  String name;
  int pointsRequired;
  int stock;

  RedeemableProduct({
    required this.name,
    required this.pointsRequired,
    required this.stock,
  });
}

class RedemptionItem {
  RedeemableProduct product;
  int quantity;

  RedemptionItem({
    required this.product,
    required this.quantity,
  });
}

class PushNotificationMessage {
  int? id;
  String title;
  String message;

  PushNotificationMessage({
    this.id,
    required this.title,
    required this.message,
  });
}
