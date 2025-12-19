import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class MyFormCard extends StatefulWidget {
  const MyFormCard({super.key});

  @override
  State<MyFormCard> createState() => _MyFormCardState();
}

class _MyFormCardState extends State<MyFormCard> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _reportsTabController;
  late TabController _settingsTabController;
  
  // Form controllers for Sale tab
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  // Redemption cart
  List<RedemptionItem> _redemptionCart = [];
  
  // Form controllers for Loyalty tab
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  
  // Customer search in sales
  final TextEditingController _customerSearchController = TextEditingController();
  
  // Settings controllers
  final TextEditingController _petrolPointsController = TextEditingController(text: "1");
  final TextEditingController _dieselPointsController = TextEditingController(text: "1");
  final TextEditingController _oilPointsController = TextEditingController(text: "2");
  final TextEditingController _amountPointsController = TextEditingController(text: "10");
  
  // Product price controllers
  final Map<String, TextEditingController> _purchasePriceControllers = {};
  final Map<String, TextEditingController> _sellingPriceControllers = {};
  
  // Stock controllers
  final Map<String, TextEditingController> _stockControllers = {};
  
  // State variables
  String _selectedProduct = "Petrol";
  double _pricePerUnit = 100.0;
  double _purchasePrice = 90.0;
  double _totalAmount = 0.0;
  int _units = 0;
  Customer? _selectedCustomer;
  bool _showCustomerList = false;
  List<Customer> _filteredCustomers = [];

  // Backend sync (prices)
  static const String _backendBaseUrl = "https://bpclpos-backend.onrender.com";
  Timer? _priceSyncTimer;
  DateTime? _pricesLastSyncedAt;
  bool _priceSyncInProgress = false;
  String? _priceSyncError;
  
  List<Product> products = [
    Product(name: "Petrol", pricePerUnit: 100.0, unit: "L", purchasePrice: 90.0, stock: 5000),
    Product(name: "Diesel", pricePerUnit: 90.0, unit: "L", purchasePrice: 80.0, stock: 4000),
    Product(name: "Engine Oil", pricePerUnit: 500.0, unit: "L", purchasePrice: 400.0, stock: 200),
    Product(name: "Gear Oil", pricePerUnit: 450.0, unit: "L", purchasePrice: 350.0, stock: 150),
    Product(name: "Brake Oil", pricePerUnit: 300.0, unit: "L", purchasePrice: 250.0, stock: 100),
    Product(name: "Coolant", pricePerUnit: 250.0, unit: "L", purchasePrice: 200.0, stock: 80),
  ];
  
  // Redeemable products (Grocery & Trending)
  List<RedeemableProduct> redeemableProducts = [
    RedeemableProduct(name: "Coffee 500g", pointsRequired: 250, stock: 30),
    RedeemableProduct(name: "Tea Bag 100pcs", pointsRequired: 150, stock: 50),
    RedeemableProduct(name: "Energy Drink", pointsRequired: 100, stock: 40),
    RedeemableProduct(name: "Snack Pack", pointsRequired: 80, stock: 60),
    RedeemableProduct(name: "Water Bottle", pointsRequired: 120, stock: 25),
    RedeemableProduct(name: "Air Freshener", pointsRequired: 90, stock: 35),
    RedeemableProduct(name: "Premium Pen Set", pointsRequired: 200, stock: 20),
    RedeemableProduct(name: "Charger Cable", pointsRequired: 300, stock: 15),
    RedeemableProduct(name: "Phone Stand", pointsRequired: 180, stock: 10),
    RedeemableProduct(name: "Sunscreen 100ml", pointsRequired: 220, stock: 12),
  ];
  
  // Push notifications messages
  List<PushNotificationMessage> pushNotifications = [
    PushNotificationMessage(title: "Welcome Back!", message: "Thank you for your loyalty!"),
    PushNotificationMessage(title: "Special Offer", message: "Earn double points today!"),
  ];
  
  List<Customer> customers = [
    Customer(name: "Rajesh Kumar", cardNumber: "BPCL12345678", mobile: "9876543210", points: 1250),
    Customer(name: "Priya Sharma", cardNumber: "BPCL87654321", mobile: "8765432109", points: 850),
    Customer(name: "Amit Patel", cardNumber: "BPCL98765432", mobile: "7654321098", points: 2100),
    Customer(name: "Sneha Reddy", cardNumber: "BPCL45678901", mobile: "6543210987", points: 450),
    Customer(name: "Vikram Singh", cardNumber: "BPCL23456789", mobile: "9432109876", points: 1800),
  ];
  
  List<SaleRecord> salesRecords = [
    SaleRecord(product: "Petrol", units: 10, amount: 1000, purchaseCost: 900, customer: "Rajesh Kumar", date: DateTime.now().subtract(Duration(days: 1)), pointsEarned: 10),
    SaleRecord(product: "Diesel", units: 15, amount: 1350, purchaseCost: 1200, customer: "Priya Sharma", date: DateTime.now().subtract(Duration(days: 2)), pointsEarned: 15),
    SaleRecord(product: "Engine Oil", units: 2, amount: 1000, purchaseCost: 800, customer: "Amit Patel", date: DateTime.now().subtract(Duration(days: 3)), pointsEarned: 4),
    SaleRecord(product: "Petrol", units: 5, amount: 500, purchaseCost: 450, customer: "Rajesh Kumar", date: DateTime.now().subtract(Duration(days: 4)), pointsEarned: 5),
    SaleRecord(product: "Diesel", units: 8, amount: 720, purchaseCost: 640, customer: "Priya Sharma", date: DateTime.now().subtract(Duration(days: 5)), pointsEarned: 8),
  ];
  
  // Points settings
  Map<String, int> pointsSettings = {
    'petrol': 1,
    'diesel': 1,
    'oil': 2,
    'amount': 10,
  };
  
  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);
    _reportsTabController = TabController(length: 4, vsync: this);
    _settingsTabController = TabController(length: 4, vsync: this);
    _filteredCustomers = List.from(customers);
    
    // Initialize price and stock controllers
    for (var product in products) {
      _purchasePriceControllers[product.name] = TextEditingController(text: product.purchasePrice.toString());
      _sellingPriceControllers[product.name] = TextEditingController(text: product.pricePerUnit.toString());
      _stockControllers[product.name] = TextEditingController(text: product.stock.toString());
    }
    
    // Add listeners for auto-calculation
    _unitsController.addListener(_calculateAmount);
    _amountController.addListener(_calculateUnits);
    
    // Add listener for customer search
    _customerSearchController.addListener(_filterCustomers);

    // Initial data load from backend
    unawaited(_loadBootstrapFromBackend(showErrorSnackbar: false));

    // Auto-sync latest prices from backend
    unawaited(_syncPricesFromBackend(showErrorSnackbar: false));
    _priceSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_syncPricesFromBackend(showErrorSnackbar: false));
    });
  }
  
  @override
  void dispose() {
    _mainTabController.dispose();
    _reportsTabController.dispose();
    _unitsController.dispose();
    _amountController.dispose();
    _customerNameController.dispose();
    _cardNumberController.dispose();
    _mobileController.dispose();
    _barcodeController.dispose();
    _customerSearchController.dispose();
    _petrolPointsController.dispose();
    _dieselPointsController.dispose();
    _oilPointsController.dispose();
    _amountPointsController.dispose();
    _settingsTabController.dispose();
    
    // Dispose all price and stock controllers
    for (var controller in _purchasePriceControllers.values) {
      controller.dispose();
    }
    for (var controller in _sellingPriceControllers.values) {
      controller.dispose();
    }
    for (var controller in _stockControllers.values) {
      controller.dispose();
    }

    _priceSyncTimer?.cancel();
    
    super.dispose();
  }

  Future<void> _syncPricesFromBackend({required bool showErrorSnackbar}) async {
    if (_priceSyncInProgress) return;
    _priceSyncInProgress = true;
    _priceSyncError = null;

    try {
      final uri = Uri.parse("$_backendBaseUrl/api/products");
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) {
        String detail = "HTTP ${resp.statusCode}";
        try {
          final decodedError = jsonDecode(resp.body) as Map<String, dynamic>;
          final errorMessage = decodedError["error"] as String?;
          if (errorMessage != null && errorMessage.isNotEmpty) {
            detail = errorMessage;
          }
        } catch (_) {}
        throw Exception(detail);
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final productsPayload = (decoded["products"] as List?)?.cast<dynamic>() ?? [];

      final Map<String, Product> byName = {
        for (final p in products) p.name: p,
      };

      for (final item in productsPayload) {
        final map = (item as Map).cast<String, dynamic>();
        final name = map["name"] as String;
        final pricePerUnit = (map["pricePerUnit"] as num).toDouble();
        final unit = (map["unit"] as String?) ?? "L";
        final purchasePrice = (map["purchasePrice"] as num?)?.toDouble() ?? 0.0;
        final stock = (map["stock"] as num?)?.toInt() ?? 0;

        final product = byName[name];
        if (product == null) continue;

        product.pricePerUnit = pricePerUnit;
        product.unit = unit;
        if (purchasePrice > 0) {
          product.purchasePrice = purchasePrice;
        }
        product.stock = stock;

        // Update UI controllers where applicable
        final controller = _sellingPriceControllers[name];
        if (controller != null) {
          controller.text = pricePerUnit.toStringAsFixed(2);
        }
        final purchaseController = _purchasePriceControllers[name];
        if (purchaseController != null && purchasePrice > 0) {
          purchaseController.text = purchasePrice.toStringAsFixed(2);
        }
        final stockController = _stockControllers[name];
        if (stockController != null) {
          stockController.text = stock.toString();
        }
      }

      // If currently selected product got updated, reflect it in calculation
      final selected = byName[_selectedProduct];
      if (selected != null) {
        _pricePerUnit = selected.pricePerUnit;
        _purchasePrice = selected.purchasePrice;
      }

      _pricesLastSyncedAt = DateTime.now();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _priceSyncError = e.toString();
      if (mounted && showErrorSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Price sync failed: $_priceSyncError")),
        );
      }
    } finally {
      _priceSyncInProgress = false;
    }
  }

  Future<void> _loadBootstrapFromBackend({required bool showErrorSnackbar}) async {
    try {
      final uri = Uri.parse("$_backendBaseUrl/api/bootstrap");
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) {
        throw Exception("HTTP ${resp.statusCode}");
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final productsPayload = (decoded["products"] as List?)?.cast<dynamic>() ?? [];
      final customersPayload = (decoded["customers"] as List?)?.cast<dynamic>() ?? [];
      final redeemablesPayload = (decoded["redeemables"] as List?)?.cast<dynamic>() ?? [];
      final settingsPayload = (decoded["settings"] as Map?)?.cast<String, dynamic>() ?? {};
      final salesPayload = (decoded["sales"] as List?)?.cast<dynamic>() ?? [];

      final loadedProducts = productsPayload.map((item) {
        final map = (item as Map).cast<String, dynamic>();
        return Product(
          name: map["name"] as String,
          pricePerUnit: (map["pricePerUnit"] as num).toDouble(),
          unit: (map["unit"] as String?) ?? "L",
          purchasePrice: (map["purchasePrice"] as num?)?.toDouble() ?? 0.0,
          stock: (map["stock"] as num?)?.toInt() ?? 0,
        );
      }).toList();

      final loadedCustomers = customersPayload.map((item) {
        final map = (item as Map).cast<String, dynamic>();
        return Customer(
          name: map["name"] as String,
          cardNumber: map["cardNumber"] as String,
          mobile: map["mobile"] as String,
          points: (map["points"] as num).toInt(),
        );
      }).toList();

      final loadedRedeemables = redeemablesPayload.map((item) {
        final map = (item as Map).cast<String, dynamic>();
        return RedeemableProduct(
          name: map["name"] as String,
          pointsRequired: (map["pointsRequired"] as num).toInt(),
          stock: (map["stock"] as num).toInt(),
        );
      }).toList();

      final loadedSales = salesPayload.map((item) {
        final map = (item as Map).cast<String, dynamic>();
        return SaleRecord(
          product: map["product"] as String,
          units: (map["units"] as num).toInt(),
          amount: (map["amount"] as num).toDouble(),
          purchaseCost: (map["purchaseCost"] as num).toDouble(),
          customer: map["customer"] as String,
          date: DateTime.parse(map["date"] as String),
          pointsEarned: (map["pointsEarned"] as num).toInt(),
          profit: (map["profit"] as num?)?.toDouble(),
        );
      }).toList();

      if (mounted) {
        setState(() {
          if (loadedProducts.isNotEmpty) {
            products = loadedProducts;
            _rebuildProductControllers();
            if (!products.any((p) => p.name == _selectedProduct) && products.isNotEmpty) {
              _selectedProduct = products.first.name;
            }
            final selected = products.firstWhere((p) => p.name == _selectedProduct, orElse: () => products.first);
            _pricePerUnit = selected.pricePerUnit;
            _purchasePrice = selected.purchasePrice;
          }

          if (loadedCustomers.isNotEmpty) {
            customers = loadedCustomers;
            _filteredCustomers = List.from(customers);
          }

          if (loadedRedeemables.isNotEmpty) {
            redeemableProducts = loadedRedeemables;
          }

          if (settingsPayload.isNotEmpty) {
            pointsSettings = {
              "petrol": (settingsPayload["petrol"] as num?)?.toInt() ?? 1,
              "diesel": (settingsPayload["diesel"] as num?)?.toInt() ?? 1,
              "oil": (settingsPayload["oil"] as num?)?.toInt() ?? 2,
              "amount": (settingsPayload["amount"] as num?)?.toInt() ?? 10,
            };
            _petrolPointsController.text = pointsSettings["petrol"].toString();
            _dieselPointsController.text = pointsSettings["diesel"].toString();
            _oilPointsController.text = pointsSettings["oil"].toString();
            _amountPointsController.text = pointsSettings["amount"].toString();
          }

          if (loadedSales.isNotEmpty) {
            salesRecords = loadedSales;
          }
        });
      }
    } catch (e) {
      if (mounted && showErrorSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load backend data: $e")),
        );
      }
    }
  }

  void _rebuildProductControllers() {
    for (var controller in _purchasePriceControllers.values) {
      controller.dispose();
    }
    for (var controller in _sellingPriceControllers.values) {
      controller.dispose();
    }
    for (var controller in _stockControllers.values) {
      controller.dispose();
    }
    _purchasePriceControllers.clear();
    _sellingPriceControllers.clear();
    _stockControllers.clear();
    for (var product in products) {
      _purchasePriceControllers[product.name] =
          TextEditingController(text: product.purchasePrice.toString());
      _sellingPriceControllers[product.name] =
          TextEditingController(text: product.pricePerUnit.toString());
      _stockControllers[product.name] =
          TextEditingController(text: product.stock.toString());
    }
  }
  
  void _filterCustomers() {
    String query = _customerSearchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = customers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
               customer.mobile.contains(query) ||
               customer.cardNumber.toLowerCase().contains(query);
      }).toList();
    });
  }
  
  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _showCustomerList = false;
      _customerSearchController.text = "${customer.name} (${customer.cardNumber})";
    });
  }
  
  void _clearCustomerSelection() {
    setState(() {
      _selectedCustomer = null;
      _customerSearchController.clear();
    });
  }
  
  void _calculateAmount() {
    if (_unitsController.text.isNotEmpty) {
      _units = int.tryParse(_unitsController.text) ?? 0;
      _totalAmount = _units * _pricePerUnit;
      _amountController.text = _totalAmount.toStringAsFixed(2);
      setState(() {});
    }
  }
  
  void _calculateUnits() {
    if (_amountController.text.isNotEmpty) {
      double amount = double.tryParse(_amountController.text) ?? 0;
      _units = (amount / _pricePerUnit).ceil();
      _unitsController.text = _units.toString();
      _totalAmount = amount;
      setState(() {});
    }
  }
  
  void _onProductSelected(String product) {
    Product selected = products.firstWhere((p) => p.name == product);
    setState(() {
      _selectedProduct = product;
      _pricePerUnit = selected.pricePerUnit;
      _purchasePrice = selected.purchasePrice;
      _calculateAmount();
    });
  }
  
  Future<void> _scanBarcode() async {
    final controller = MobileScannerController();
    String? scannedValue;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Scan Barcode"),
          content: SizedBox(
            width: 280,
            height: 280,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (scannedValue != null) return;
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final value = barcodes.first.rawValue;
                if (value == null || value.isEmpty) return;
                scannedValue = value;
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (scannedValue != null && mounted) {
      setState(() {
        _barcodeController.text = scannedValue!;
        _cardNumberController.text = scannedValue!;
      });
      await _lookupCustomerByCardNumber(scannedValue!, showNotFoundSnackbar: true);
    }
  }
  
  Future<void> _addCustomer() async {
    if (_customerNameController.text.isNotEmpty && _cardNumberController.text.isNotEmpty) {
      try {
        final uri = Uri.parse("$_backendBaseUrl/api/customers");
        final payload = {
          "name": _customerNameController.text,
          "cardNumber": _cardNumberController.text,
          "mobile": _mobileController.text,
        };
        final resp = await http
            .post(
              uri,
              headers: const {"Content-Type": "application/json"},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 5));

        if (resp.statusCode == 409) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Card number already exists")),
            );
          }
          return;
        }
        if (resp.statusCode != 200) {
          throw Exception("HTTP ${resp.statusCode}");
        }

        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final customerMap = (decoded["customer"] as Map).cast<String, dynamic>();
        final newCustomer = Customer(
          name: customerMap["name"] as String,
          cardNumber: customerMap["cardNumber"] as String,
          mobile: customerMap["mobile"] as String,
          points: (customerMap["points"] as num).toInt(),
        );

        setState(() {
          customers.add(newCustomer);
          _filteredCustomers.add(newCustomer);
          _customerNameController.clear();
          _cardNumberController.clear();
          _mobileController.clear();
          _barcodeController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Customer added ✅")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add customer: $e")),
          );
        }
      }
    }
  }

  Future<void> _lookupCustomerByCardNumber(String cardNumber, {bool showNotFoundSnackbar = true}) async {
    final trimmed = cardNumber.trim();
    if (trimmed.isEmpty) return;

    try {
      final uri = Uri.parse("$_backendBaseUrl/api/customers")
          .replace(queryParameters: {"cardNumber": trimmed});
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 404) {
        if (mounted && showNotFoundSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No customer found for this card")),
          );
        }
        return;
      }
      if (resp.statusCode != 200) {
        throw Exception("HTTP ${resp.statusCode}");
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final customerMap = (decoded["customer"] as Map).cast<String, dynamic>();
      final foundCustomer = Customer(
        name: customerMap["name"] as String,
        cardNumber: customerMap["cardNumber"] as String,
        mobile: customerMap["mobile"] as String,
        points: (customerMap["points"] as num).toInt(),
      );

      setState(() {
        _barcodeController.text = foundCustomer.cardNumber;
        _cardNumberController.text = foundCustomer.cardNumber;
        _customerNameController.text = foundCustomer.name;
        _mobileController.text = foundCustomer.mobile;

        final index = customers.indexWhere((c) => c.cardNumber == foundCustomer.cardNumber);
        if (index == -1) {
          customers.add(foundCustomer);
        } else {
          customers[index] = foundCustomer;
        }
        _filteredCustomers = List.from(customers);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer loaded ✅")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lookup failed: $e")),
        );
      }
    }
  }
  
  Future<void> _processSale() async {
    if (_units > 0) {
      Product product = products.firstWhere((p) => p.name == _selectedProduct);
      
      // Check stock availability
      if (_units > product.stock) {
        _showStockAlert();
        return;
      }

      try {
        final uri = Uri.parse("$_backendBaseUrl/api/sales");
        final payload = {
          "product": _selectedProduct,
          "units": _units,
          "amount": _totalAmount,
          if (_selectedCustomer != null) "customerCardNumber": _selectedCustomer!.cardNumber,
        };
        final resp = await http
            .post(
              uri,
              headers: const {"Content-Type": "application/json"},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 5));

        if (resp.statusCode != 200) {
          throw Exception("HTTP ${resp.statusCode}");
        }

        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final saleMap = (decoded["sale"] as Map).cast<String, dynamic>();
        final sale = SaleRecord(
          product: saleMap["product"] as String,
          units: (saleMap["units"] as num).toInt(),
          amount: (saleMap["amount"] as num).toDouble(),
          purchaseCost: (saleMap["purchaseCost"] as num).toDouble(),
          customer: saleMap["customer"] as String,
          date: DateTime.parse(saleMap["date"] as String),
          pointsEarned: (saleMap["pointsEarned"] as num).toInt(),
          profit: (saleMap["profit"] as num?)?.toDouble(),
        );

        final productMap = (decoded["product"] as Map).cast<String, dynamic>();
        final updatedProduct = Product(
          name: productMap["name"] as String,
          pricePerUnit: (productMap["pricePerUnit"] as num).toDouble(),
          unit: (productMap["unit"] as String?) ?? "L",
          purchasePrice: (productMap["purchasePrice"] as num?)?.toDouble() ?? 0.0,
          stock: (productMap["stock"] as num).toInt(),
        );

        final customerMap = decoded["customer"] as Map<String, dynamic>?;

        setState(() {
          final index = products.indexWhere((p) => p.name == updatedProduct.name);
          if (index != -1) {
            products[index] = updatedProduct;
            _stockControllers[updatedProduct.name]?.text = updatedProduct.stock.toString();
          }

          if (customerMap != null) {
            final updatedCustomer = Customer(
              name: customerMap["name"] as String,
              cardNumber: customerMap["cardNumber"] as String,
              mobile: customerMap["mobile"] as String,
              points: (customerMap["points"] as num).toInt(),
            );
            final customerIndex = customers.indexWhere((c) => c.cardNumber == updatedCustomer.cardNumber);
            if (customerIndex != -1) {
              customers[customerIndex] = updatedCustomer;
            }
          }

          salesRecords.insert(0, sale);

          _unitsController.text = "0";
          _amountController.text = "0.00";
          _units = 0;
          _totalAmount = 0.0;
          _clearCustomerSelection();
        });
      } catch (e) {
        // Fallback to local-only processing if backend fails
        int pointsEarned = 0;
        if (_selectedProduct == "Petrol") {
          pointsEarned = _units * pointsSettings['petrol']!;
        } else if (_selectedProduct == "Diesel") {
          pointsEarned = _units * pointsSettings['diesel']!;
        } else {
          pointsEarned = _units * pointsSettings['oil']!;
        }
        pointsEarned += (_totalAmount ~/ pointsSettings['amount']!);

        product.stock -= _units;
        _stockControllers[_selectedProduct]?.text = product.stock.toString();
        double profit = _totalAmount - (_units * _purchasePrice);

        setState(() {
          salesRecords.insert(0, SaleRecord(
            product: _selectedProduct,
            units: _units,
            amount: _totalAmount,
            purchaseCost: _units * _purchasePrice,
            customer: _selectedCustomer?.name ?? "Walk-in Customer",
            date: DateTime.now(),
            pointsEarned: pointsEarned,
            profit: profit,
          ));

          if (_selectedCustomer != null) {
            int index = customers.indexWhere((c) => c.cardNumber == _selectedCustomer!.cardNumber);
            if (index != -1) {
              customers[index].points += pointsEarned;
            }
          }

          _unitsController.text = "0";
          _amountController.text = "0.00";
          _units = 0;
          _totalAmount = 0.0;
          _clearCustomerSelection();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Backend save failed, used local data: $e")),
          );
        }
      }
    }
  }
  
  void _showStockAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Insufficient Stock"),
        content: Text("Only ${products.firstWhere((p) => p.name == _selectedProduct).stock} units available for $_selectedProduct"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  
  Future<void> _savePointsSettings() async {
    setState(() {
      pointsSettings['petrol'] = int.tryParse(_petrolPointsController.text) ?? 1;
      pointsSettings['diesel'] = int.tryParse(_dieselPointsController.text) ?? 1;
      pointsSettings['oil'] = int.tryParse(_oilPointsController.text) ?? 2;
      pointsSettings['amount'] = int.tryParse(_amountPointsController.text) ?? 10;
    });

    try {
      final uri = Uri.parse("$_backendBaseUrl/api/settings/points");
      final resp = await http
          .put(
            uri,
            headers: const {"Content-Type": "application/json"},
            body: jsonEncode({
              "petrol": pointsSettings['petrol'],
              "diesel": pointsSettings['diesel'],
              "oil": pointsSettings['oil'],
              "amount": pointsSettings['amount'],
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode != 200) {
        throw Exception("HTTP ${resp.statusCode}");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Points settings saved ✅")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save points settings: $e")),
        );
      }
    }
  }
  
  Future<void> _saveProductPrices() async {
    // 1) Apply locally (so UI updates instantly)
    setState(() {
      for (var product in products) {
        final newPurchasePrice =
            double.tryParse(_purchasePriceControllers[product.name]?.text ?? "") ??
                product.purchasePrice;
        final newSellingPrice =
            double.tryParse(_sellingPriceControllers[product.name]?.text ?? "") ??
                product.pricePerUnit;
        
        product.purchasePrice = newPurchasePrice;
        product.pricePerUnit = newSellingPrice;
        
        if (product.name == _selectedProduct) {
          _pricePerUnit = newSellingPrice;
          _purchasePrice = newPurchasePrice;
          _calculateAmount();
        }
      }
    });

    await _persistProductsToBackend(successMessage: "Prices saved to backend ✅");
  }
  
  Future<void> _saveStockLevels() async {
    setState(() {
      for (var product in products) {
        int newStock = int.tryParse(_stockControllers[product.name]?.text ?? "") ?? product.stock;
        product.stock = newStock;
      }
    });

    await _persistProductsToBackend(successMessage: "Stock levels saved ✅");
  }

  Future<void> _persistProductsToBackend({required String successMessage}) async {
    try {
      final uri = Uri.parse("$_backendBaseUrl/api/products");
      final payload = {
        "products": products
            .map((p) => {
                  "name": p.name,
                  "pricePerUnit": p.pricePerUnit,
                  "unit": p.unit,
                  "purchasePrice": p.purchasePrice,
                  "stock": p.stock,
                })
            .toList(),
      };

      final resp = await http
          .put(
            uri,
            headers: const {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode != 200) {
        throw Exception("HTTP ${resp.statusCode}");
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final productsPayload = (decoded["products"] as List?)?.cast<dynamic>() ?? [];
      final loadedProducts = productsPayload.map((item) {
        final map = (item as Map).cast<String, dynamic>();
        return Product(
          name: map["name"] as String,
          pricePerUnit: (map["pricePerUnit"] as num).toDouble(),
          unit: (map["unit"] as String?) ?? "L",
          purchasePrice: (map["purchasePrice"] as num?)?.toDouble() ?? 0.0,
          stock: (map["stock"] as num?)?.toInt() ?? 0,
        );
      }).toList();

      if (loadedProducts.isNotEmpty && mounted) {
        setState(() {
          products = loadedProducts;
          _rebuildProductControllers();
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save products: $e")),
        );
      }
    }
  }
  
  Widget _buildProductCard(String productName, double price, String unit) {
    bool isSelected = _selectedProduct == productName;
    Product product = products.firstWhere((p) => p.name == productName);
    
    return GestureDetector(
      onTap: () => _onProductSelected(productName),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A2E35).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A2E35) : const Color(0xFFEEEEEE),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getProductIcon(productName),
              color: isSelected ? const Color(0xFF1A2E35) : const Color(0xFF666666),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              productName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF1A2E35) : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "₹$price/$unit",
              style: TextStyle(
                color: isSelected ? const Color(0xFF1A2E35) : const Color(0xFF666666),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Stock: ${product.stock}",
              style: TextStyle(
                color: product.stock < 100 ? Colors.red : const Color(0xFF666666),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getProductIcon(String product) {
    switch (product) {
      case "Petrol": return Icons.local_gas_station;
      case "Diesel": return Icons.local_gas_station;
      default: return Icons.invert_colors;
    }
  }
  
  // Calculate total profit from sales records
  double get _totalProfit {
    return salesRecords.fold(0.0, (sum, record) => sum + (record.profit ?? 0));
  }
  
  // Calculate today's profit
  double get _todayProfit {
    DateTime today = DateTime.now();
    return salesRecords.where((record) => 
      record.date.year == today.year &&
      record.date.month == today.month &&
      record.date.day == today.day
    ).fold(0.0, (sum, record) => sum + (record.profit ?? 0));
  }
  
  // Redemption methods
  void _addToRedemptionCart(RedeemableProduct product) {
    if (product.stock <= 0) {
      _showAlert("Out of Stock", "${product.name} is out of stock");
      return;
    }
    
    setState(() {
      int existingIndex = _redemptionCart.indexWhere((item) => item.product.name == product.name);
      if (existingIndex >= 0) {
        _redemptionCart[existingIndex].quantity++;
      } else {
        _redemptionCart.add(RedemptionItem(product: product, quantity: 1));
      }
    });
  }
  
  void _removeFromRedemptionCart(int index) {
    setState(() {
      if (_redemptionCart[index].quantity > 1) {
        _redemptionCart[index].quantity--;
      } else {
        _redemptionCart.removeAt(index);
      }
    });
  }
  
  int _getCartTotalPoints() {
    return _redemptionCart.fold(0, (sum, item) => sum + (item.product.pointsRequired * item.quantity));
  }
  
  Future<void> _redeemCart() async {
    if (_redemptionCart.isEmpty) {
      _showAlert("Empty Cart", "Please add items to redeem");
      return;
    }
    
    if (_selectedCustomer == null) {
      _showAlert("Select Customer", "Please select a customer to redeem points");
      return;
    }
    
    int totalPointsNeeded = _getCartTotalPoints();
    if (_selectedCustomer!.points < totalPointsNeeded) {
      _showAlert("Insufficient Points", "Customer has ${_selectedCustomer!.points} points but needs $totalPointsNeeded");
      return;
    }

    try {
      final uri = Uri.parse("$_backendBaseUrl/api/redemptions");
      final payload = {
        "customerCardNumber": _selectedCustomer!.cardNumber,
        "items": _redemptionCart
            .map((item) => {
                  "product": item.product.name,
                  "quantity": item.quantity,
                })
            .toList(),
      };
      final resp = await http
          .post(
            uri,
            headers: const {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode != 200) {
        throw Exception("HTTP ${resp.statusCode}");
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final customerMap = (decoded["customer"] as Map).cast<String, dynamic>();
      final updatedCustomer = Customer(
        name: customerMap["name"] as String,
        cardNumber: customerMap["cardNumber"] as String,
        mobile: customerMap["mobile"] as String,
        points: (customerMap["points"] as num).toInt(),
      );
      final productsPayload = (decoded["products"] as List?)?.cast<dynamic>() ?? [];
      final updatedRedeemables = productsPayload.map((item) {
        final map = (item as Map).cast<String, dynamic>();
        return RedeemableProduct(
          name: map["name"] as String,
          pointsRequired: (map["pointsRequired"] as num).toInt(),
          stock: (map["stock"] as num).toInt(),
        );
      }).toList();

      setState(() {
        final customerIndex = customers.indexWhere((c) => c.cardNumber == updatedCustomer.cardNumber);
        if (customerIndex != -1) {
          customers[customerIndex] = updatedCustomer;
          if (_selectedCustomer != null && _selectedCustomer!.cardNumber == updatedCustomer.cardNumber) {
            _selectedCustomer = updatedCustomer;
          }
        }

        for (var updated in updatedRedeemables) {
          final idx = redeemableProducts.indexWhere((r) => r.name == updated.name);
          if (idx != -1) {
            redeemableProducts[idx] = updated;
          }
        }

        _redemptionCart.clear();
      });

      _showAlert("Success", "Points redeemed successfully!");
    } catch (e) {
      // Fallback to local-only processing if backend fails
      setState(() {
        int customerIndex = customers.indexWhere((c) => c.cardNumber == _selectedCustomer!.cardNumber);
        if (customerIndex != -1) {
          customers[customerIndex].points -= totalPointsNeeded;
          _selectedCustomer!.points -= totalPointsNeeded;
        }

        for (var item in _redemptionCart) {
          item.product.stock -= item.quantity;
        }

        _redemptionCart.clear();
      });

      _showAlert("Success", "Points redeemed locally (backend error: $e)");
    }
  }
  
  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  
  // Push notification methods
  void _createPushNotification(TextEditingController titleController, TextEditingController messageController) {
    if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
      setState(() {
        pushNotifications.add(
          PushNotificationMessage(
            title: titleController.text,
            message: messageController.text,
          ),
        );
      });
      titleController.clear();
      messageController.clear();
      Navigator.pop(context);
      _showAlert("Success", "Push notification created!");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.yellow,
                  const Color(0xFF1A2E35).withOpacity(0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "BPCL POS SYSTEM",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(Icons.notifications_none, color: Colors.white),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Main Tabs
                  Container(
                    color: Colors.transparent,
                    child: TabBar(
                      controller: _mainTabController,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(icon: Icon(Icons.local_gas_station), text: 'SALE'),
                        Tab(icon: Icon(Icons.card_giftcard), text: 'LOYALTY'),
                        Tab(icon: Icon(Icons.bar_chart), text: 'REPORTS'),
                        Tab(icon: Icon(Icons.settings), text: 'SETTINGS'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                // SALE TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Search Section
                      Container(
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
                                if (_selectedCustomer != null) ...[
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _clearCustomerSelection,
                                    icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _customerSearchController,
                              decoration: InputDecoration(
                                hintText: "Search by name, mobile or card number",
                                prefixIcon: const Icon(Icons.person_search),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.qr_code_scanner),
                                  onPressed: _scanBarcode,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _showCustomerList = true;
                                });
                              },
                            ),
                            
                            // Customer List
                            if (_showCustomerList && _customerSearchController.text.isNotEmpty)
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
                                  itemCount: _filteredCustomers.length,
                                  itemBuilder: (context, index) {
                                    Customer customer = _filteredCustomers[index];
                                    return ListTile(
                                      leading: const Icon(Icons.person, color: Color(0xFF1A2E35)),
                                      title: Text(customer.name),
                                      subtitle: Text("${customer.cardNumber} • ${customer.mobile}"),
                                      trailing: Text("${customer.points} pts", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      onTap: () => _selectCustomer(customer),
                                    );
                                  },
                                ),
                              ),
                            
                            // Selected Customer Display
                            if (_selectedCustomer != null && !_showCustomerList)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2E35).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF1A2E35).withOpacity(0.2)),
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
                                            _selectedCustomer!.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "Card: ${_selectedCustomer!.cardNumber} • Points: ${_selectedCustomer!.points}",
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Product Selection
                      const Text(
                        "Select Product",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E35),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(
                            products[index].name,
                            products[index].pricePerUnit,
                            products[index].unit,
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Quantity/Amount Input
                      Container(
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
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Units",
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _unitsController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.format_list_numbered, color: Color(0xFF1A2E35)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Amount (₹)",
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _amountController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF1A2E35)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Summary
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Product:", style: TextStyle(color: Color(0xFF666666))),
                                      Text(_selectedProduct, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Price per unit:", style: TextStyle(color: Color(0xFF666666))),
                                      Text("₹$_pricePerUnit", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Purchase cost:", style: TextStyle(color: Color(0xFF666666))),
                                      Text("₹$_purchasePrice", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Total Units:", style: TextStyle(color: Color(0xFF666666))),
                                      Text("$_units", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Estimated Profit:", style: TextStyle(color: Color(0xFF666666))),
                                      Text(
                                        "₹${(_units * (_pricePerUnit - _purchasePrice)).toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("TOTAL AMOUNT:", style: TextStyle(
                                        color: Color(0xFF1A2E35),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )),
                                      Text(
                                        "₹${_totalAmount.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Color(0xFF1A2E35),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Process Sale Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _processSale,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A2E35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "PROCESS SALE",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // REDEEM POINTS SECTION
                      Container(
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
                            Row(
                              children: [
                                const Icon(Icons.card_giftcard, color: Color(0xFF1A2E35), size: 28),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Redeem Points",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A2E35),
                                    ),
                                  ),
                                ),
                                if (_selectedCustomer != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${_selectedCustomer!.points} pts",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            if (_selectedCustomer == null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: const Text(
                                  "Please select a customer to redeem points",
                                  style: TextStyle(color: Colors.orange),
                                ),
                              )
                            else ...[
                              // Available Products Grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: redeemableProducts.length,
                                itemBuilder: (context, index) {
                                  RedeemableProduct product = redeemableProducts[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: product.stock > 0 ? Colors.white : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: product.stock > 0 ? const Color(0xFFEEEEEE) : Colors.grey,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.1),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.card_giftcard,
                                                    color: Colors.primaries[index % Colors.primaries.length],
                                                    size: 32,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${product.pointsRequired} pts",
                                                    style: TextStyle(
                                                      color: Colors.green.shade700,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Stock: ${product.stock}",
                                                    style: TextStyle(
                                                      color: product.stock > 0 ? Colors.grey : Colors.red,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (product.stock > 0)
                                          Positioned(
                                            right: 4,
                                            bottom: 4,
                                            child: GestureDetector(
                                              onTap: () => _addToRedemptionCart(product),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.add, color: Colors.white, size: 16),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Redemption Cart
                              if (_redemptionCart.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.shopping_cart, color: Colors.blue, size: 20),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              "Redemption Cart",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "${_getCartTotalPoints()} pts",
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 12),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _redemptionCart.length,
                                        itemBuilder: (context, index) {
                                          RedemptionItem item = _redemptionCart[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.product.name,
                                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                                      ),
                                                      Text(
                                                        "${item.product.pointsRequired} × ${item.quantity} = ${item.product.pointsRequired * item.quantity} pts",
                                                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () => _removeFromRedemptionCart(index),
                                                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(width: 4),
                                                    IconButton(
                                                      onPressed: () => _addToRedemptionCart(item.product),
                                                      icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _redeemCart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "REDEEM NOW",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // LOYALTY TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Register New Card
                      Container(
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
                            
                            // Barcode Scanner
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _barcodeController,
                                    decoration: InputDecoration(
                                      labelText: "Barcode",
                                      prefixIcon: const Icon(Icons.qr_code_scanner),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: _scanBarcode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A2E35),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  child: const Text("SCAN"),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _cardNumberController,
                                    onSubmitted: (value) =>
                                        _lookupCustomerByCardNumber(value, showNotFoundSnackbar: true),
                                    decoration: InputDecoration(
                                      labelText: "Card Number",
                                      prefixIcon: const Icon(Icons.credit_card),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _lookupCustomerByCardNumber(
                                    _cardNumberController.text,
                                    showNotFoundSnackbar: true,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A2E35),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Text("LOOKUP"),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextField(
                              controller: _customerNameController,
                              decoration: InputDecoration(
                                labelText: "Customer Name",
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "Mobile Number",
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _addCustomer,
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
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Registered Customers
                      Container(
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
                            
                            ...customers.map((customer) => _buildCustomerCard(customer)).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // REPORTS TAB
                Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
                      child: TabBar(
                        controller: _reportsTabController,
                        indicatorColor: const Color(0xFF1A2E35),
                        labelColor: const Color(0xFF1A2E35),
                        unselectedLabelColor: const Color(0xFF666666),
                        tabs: const [
                          Tab(text: 'SALES'),
                          Tab(text: 'PROFIT'),
                          Tab(text: 'STOCK'),
                          Tab(text: 'LOYALTY'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _reportsTabController,
                        children: [
                          // Sales Report
                          ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: salesRecords.length,
                            itemBuilder: (context, index) {
                              return _buildSaleRecordCard(salesRecords[index]);
                            },
                          ),
                          
                          // Profit Report
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Profit Summary Cards
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  children: [
                                    _buildProfitCard(
                                      "Today's Profit",
                                      _todayProfit,
                                      Colors.green,
                                      Icons.today,
                                    ),
                                    _buildProfitCard(
                                      "Total Profit",
                                      _totalProfit,
                                      Colors.blue,
                                      Icons.attach_money,
                                    ),
                                    _buildProfitCard(
                                      "Total Sales",
                                      salesRecords.fold(0.0, (sum, record) => sum + record.amount),
                                      Colors.orange,
                                      Icons.shopping_cart,
                                    ),
                                    _buildProfitCard(
                                      "Total Units Sold",
                                      salesRecords.fold(0, (sum, record) => sum + record.units).toDouble(),
                                      Colors.purple,
                                      Icons.format_list_numbered,
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Profit by Product
                                Container(
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
                                        "Profit by Product",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A2E35),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      ...products.map((product) {
                                        double productProfit = salesRecords
                                          .where((record) => record.product == product.name)
                                          .fold(0.0, (sum, record) => sum + (record.profit ?? 0));
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product.name,
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              Text(
                                                "₹${productProfit.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  color: productProfit >= 0 ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Recent Profitable Sales
                                Container(
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
                                        "Recent Profitable Sales",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A2E35),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      ...salesRecords.take(5).map((record) => _buildProfitRecordCard(record)).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Stock Report
                          ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildStockCard(products[index]);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // SETTINGS TAB
               // SETTINGS TAB - Tabbed Version
Column(
  children: [
    Container(
      color: const Color(0xFFF8F9FA),
      child: TabBar(
        controller: _settingsTabController,
        indicatorColor: const Color(0xFF1A2E35),
        labelColor: const Color(0xFF1A2E35),
        unselectedLabelColor: const Color(0xFF666666),
        tabs: const [
          Tab(text: 'LOYALTY'),
          Tab(text: 'PRICES'),
          Tab(text: 'STOCK'),
          Tab(text: 'NOTIFICATIONS'),
        ],
      ),
    ),
    Expanded(
      child: TabBarView(
        controller: _settingsTabController,
        children: [
          // LOYALTY SETTINGS TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2E35).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.card_giftcard,
                              color: Color(0xFF1A2E35),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Loyalty Points Settings",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2E35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      const Text(
                        "Points per Liter/Unit:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Petrol Points
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_gas_station,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Petrol",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _petrolPointsController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "Points",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Diesel Points
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_gas_station,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Diesel",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _dieselPointsController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "Points",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Oil Points
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.invert_colors,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Oil Products",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _oilPointsController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "Points",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Additional Points
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2E35).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1A2E35).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  color: Color(0xFF1A2E35),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Additional Points per ₹ Amount",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A2E35),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _amountPointsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Points for every ₹ amount",
                                prefixIcon: const Icon(Icons.add_circle_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Example: Setting '10' means 1 point for every ₹10 spent",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _savePointsSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A2E35),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "SAVE LOYALTY SETTINGS",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Current Settings Display
                Container(
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
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF1A2E35),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Current Loyalty Settings",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2E35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSettingItem("Petrol points per liter:", "${pointsSettings['petrol']}"),
                      _buildSettingItem("Diesel points per liter:", "${pointsSettings['diesel']}"),
                      _buildSettingItem("Oil points per liter:", "${pointsSettings['oil']}"),
                      _buildSettingItem("Additional points for every ₹:", "${pointsSettings['amount']}"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // PRICE SETTINGS TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Product Price Settings",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2E35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Price Settings Table
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "Product",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2E35),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Purchase (₹)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2E35),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Selling (₹)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2E35),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Margin %",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2E35),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Product Rows
                            ...products.map((product) {
                              double margin = ((product.pricePerUnit - product.purchasePrice) / product.purchasePrice * 100);
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: const Color(0xFFEEEEEE),
                                      width: product == products.first ? 0 : 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: _getProductColor(product.name).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getProductIcon(product.name),
                                              color: _getProductColor(product.name),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  "Stock: ${product.stock}",
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
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: TextField(
                                          controller: _purchasePriceControllers[product.name],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: TextField(
                                          controller: _sellingPriceControllers[product.name],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "${margin.toStringAsFixed(1)}%",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: margin >= 0 ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Quick Actions
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildQuickActionButton(
                            "Apply 5% Increase",
                            Icons.trending_up,
                            Colors.green,
                            () {
                              for (var product in products) {
                                double current = product.pricePerUnit;
                                double newPrice = current * 1.05;
                                _sellingPriceControllers[product.name]?.text = newPrice.toStringAsFixed(2);
                              }
                              setState(() {});
                            },
                          ),
                          _buildQuickActionButton(
                            "Apply 3% Decrease",
                            Icons.trending_down,
                            Colors.orange,
                            () {
                              for (var product in products) {
                                double current = product.pricePerUnit;
                                double newPrice = current * 0.97;
                                _sellingPriceControllers[product.name]?.text = newPrice.toStringAsFixed(2);
                              }
                              setState(() {});
                            },
                          ),
                          _buildQuickActionButton(
                            "Copy Purchase to Selling",
                            Icons.copy,
                            Colors.blue,
                            () {
                              for (var product in products) {
                                double purchase = product.purchasePrice;
                                _sellingPriceControllers[product.name]?.text = (purchase * 1.1).toStringAsFixed(2);
                              }
                              setState(() {});
                            },
                          ),
                          _buildQuickActionButton(
                            "Reset to Default",
                            Icons.restart_alt,
                            Colors.red,
                            () {
                              for (var product in products) {
                                _sellingPriceControllers[product.name]?.text = product.pricePerUnit.toStringAsFixed(2);
                                _purchasePriceControllers[product.name]?.text = product.purchasePrice.toStringAsFixed(2);
                              }
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _saveProductPrices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "SAVE PRICE SETTINGS",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // STOCK SETTINGS TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Stock Management",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2E35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Stock Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Total Stock Value",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2E35),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "₹${products.fold(0.0, (sum, product) => sum + (product.stock * product.purchasePrice)).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2E35),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Color(0xFF666666)),
                                const SizedBox(width: 4),
                                Text(
                                  "Based on purchase prices",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Stock Management Table
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "Product",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2E35),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Current Stock",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2E35),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Update To",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2E35),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Status",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2E35),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Product Rows
                            ...products.map((product) {
                              Color statusColor = Colors.green;
                              String status = "Good";
                              if (product.stock < 100) {
                                statusColor = Colors.red;
                                status = "Low";
                              } else if (product.stock < 500) {
                                statusColor = Colors.orange;
                                status = "Medium";
                              }
                              
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: const Color(0xFFEEEEEE),
                                      width: product == products.first ? 0 : 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: _getProductColor(product.name).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getProductIcon(product.name),
                                              color: _getProductColor(product.name),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  "Purchase: ₹${product.purchasePrice}",
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
                                    Expanded(
                                      child: Text(
                                        "${product.stock}",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: TextField(
                                          controller: _stockControllers[product.name],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: statusColor.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          status,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Quick Stock Actions
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildQuickActionButton(
                            "Add 100 to All",
                            Icons.add,
                            Colors.green,
                            () {
                              for (var product in products) {
                                int current = product.stock;
                                _stockControllers[product.name]?.text = (current + 100).toString();
                              }
                              setState(() {});
                            },
                          ),
                          _buildQuickActionButton(
                            "Set Minimum 500",
                            Icons.security,
                            Colors.blue,
                            () {
                              for (var product in products) {
                                _stockControllers[product.name]?.text = "500";
                              }
                              setState(() {});
                            },
                          ),
                          _buildQuickActionButton(
                            "Restock All",
                            Icons.refresh,
                            Colors.orange,
                            () {
                              for (var product in products) {
                                int defaultStock = 1000;
                                if (product.name.contains("Oil")) defaultStock = 200;
                                _stockControllers[product.name]?.text = defaultStock.toString();
                              }
                              setState(() {});
                            },
                          ),
                          _buildQuickActionButton(
                            "Reset Current",
                            Icons.restart_alt,
                            Colors.red,
                            () {
                              for (var product in products) {
                                _stockControllers[product.name]?.text = product.stock.toString();
                              }
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _saveStockLevels,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "UPDATE STOCK LEVELS",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Stock Alerts
                Container(
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
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Low Stock Alerts",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2E35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      ...products.where((p) => p.stock < 100).map((product) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "${product.name} is running low (${product.stock} units)",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      
                      if (products.where((p) => p.stock < 100).isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "No low stock alerts. All products have sufficient stock.",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // NOTIFICATIONS TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Create New Message
                Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Create Push Notification",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2E35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      ElevatedButton.icon(
                        onPressed: () {
                          TextEditingController titleController = TextEditingController();
                          TextEditingController messageController = TextEditingController();
                          
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Create Push Notification"),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: titleController,
                                      decoration: InputDecoration(
                                        labelText: "Title",
                                        hintText: "Enter notification title",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: messageController,
                                      decoration: InputDecoration(
                                        labelText: "Message",
                                        hintText: "Enter notification message",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () => _createPushNotification(titleController, messageController),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: const Text("Create"),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Create New Message"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Messages List
                Container(
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Notification Messages",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2E35),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${pushNotifications.length}",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (pushNotifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "No notification messages created yet.",
                            style: TextStyle(color: Color(0xFF999999)),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pushNotifications.length,
                          itemBuilder: (context, index) {
                            PushNotificationMessage msg = pushNotifications[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.notifications, color: Colors.blue, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          msg.message,
                                          style: const TextStyle(
                                            color: Color(0xFF666666),
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        pushNotifications.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
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
            
// Helper Widgets


],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSettingItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E35),
          ),
        ),
      ],
    ),
  );
}

Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: color.withOpacity(0.1),
      foregroundColor: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}
  Widget _buildCustomerCard(Customer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E35).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF1A2E35)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Card: ${customer.cardNumber}",
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
                Text(
                  "Mobile: ${customer.mobile}",
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${customer.points}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1A2E35),
                ),
              ),
              const Text(
                "Points",
                style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSaleRecordCard(SaleRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt, color: Color(0xFF34C759)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.product,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${record.units} units • ₹${record.amount.toStringAsFixed(2)}",
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "+${record.pointsEarned}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E35),
                    ),
                  ),
                  const Text(
                    "Points",
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Customer: ${record.customer}",
            style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${record.date.day}/${record.date.month}/${record.date.year} ${record.date.hour}:${record.date.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
              ),
              if (record.profit != null)
                Text(
                  "Profit: ₹${record.profit!.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: record.profit! >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfitCard(String title, double value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "₹${value.toStringAsFixed(2)}",
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfitRecordCard(SaleRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.product,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${record.units} units • ${record.customer}",
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
                Text(
                  "${record.date.day}/${record.date.month}/${record.date.year}",
                  style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${record.amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Profit: ₹${record.profit?.toStringAsFixed(2) ?? "0.00"}",
                style: TextStyle(
                  color: (record.profit ?? 0) >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStockCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getProductColor(product.name).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductIcon(product.name),
              color: _getProductColor(product.name),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Selling: ₹${product.pricePerUnit}/L • Purchase: ₹${product.purchasePrice}/L",
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: product.stock / 1000,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    product.stock < 100 ? Colors.red : product.stock < 500 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${product.stock}",
                style: TextStyle(
                  color: product.stock < 100 ? Colors.red : const Color(0xFF1A2E35),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const Text(
                "Units",
                style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
              Text(
                "Stock Value: ₹${(product.stock * product.purchasePrice).toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceSettingRow(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getProductColor(product.name).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductIcon(product.name),
              color: _getProductColor(product.name),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _purchasePriceControllers[product.name],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Purchase",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _sellingPriceControllers[product.name],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Selling",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStockSettingRow(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getProductColor(product.name).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductIcon(product.name),
              color: _getProductColor(product.name),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Current: ${product.stock} units",
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: TextField(
              controller: _stockControllers[product.name],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Update Stock Level",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getProductColor(String product) {
    switch (product) {
      case "Petrol": return Colors.orange;
      case "Diesel": return Colors.blue;
      default: return Colors.green;
    }
  }
}

// Data Models
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
  String mobile;
  int points;
  
  Customer({
    required this.name,
    required this.cardNumber,
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
  String title;
  String message;
  
  PushNotificationMessage({
    required this.title,
    required this.message,
  });
}
