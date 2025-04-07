import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';

// Model for Category
class CategoryModel {
  final String title;
  final List<Color> gradientColors;
  final IconData icon;
  final List<String> measurements;
  final String id;

  CategoryModel({
    required this.title,
    required this.gradientColors,
    required this.icon,
    required this.measurements,
    this.id = '',
  });
}

// Model for Product
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final List<MeasurementRange> measurements;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.measurements = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<MeasurementRange> measurementsList = [];

    if (json['measurements'] != null && json['measurements'] is List) {
      measurementsList = (json['measurements'] as List)
          .map((m) => MeasurementRange.fromJson(m))
          .toList();
    }

    return ProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is num) ? json['price'].toDouble() : 0.0,
      categoryId: json['category'] is String
          ? json['category']
          : json['category'] is Map
              ? json['category']['_id'] ?? ''
              : '',
      measurements: measurementsList,
    );
  }
}

// Model for measurement ranges
class MeasurementRange {
  final String name;
  final String unit;
  final double minValue;
  final double maxValue;

  MeasurementRange({
    required this.name,
    this.unit = 'in',
    this.minValue = 0,
    this.maxValue = 100,
  });

  factory MeasurementRange.fromJson(Map<String, dynamic> json) {
    return MeasurementRange(
      name: json['name'] ?? '',
      unit: json['unit'] ?? 'in',
      minValue: (json['minValue'] is num) ? json['minValue'].toDouble() : 0.0,
      maxValue: (json['maxValue'] is num) ? json['maxValue'].toDouble() : 100.0,
    );
  }
}

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({Key? key}) : super(key: key);

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  // Controllers
  late ScrollController _scrollController;
  late TextEditingController _customerSearchController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  late Map<String, TextEditingController> _measurementControllers;

  // State variables
  bool _isLoading = false;
  bool _showCustomerSearch = false;
  bool _isEditing = false;
  String _orderId = '';

  // Store measurements for order items
  Map<String, dynamic> _orderMeasurements = {};

  // Customer selection
  Map<String, dynamic>? _selectedCustomer;

  final TextEditingController _searchController = TextEditingController();

  DateTime? _selectedDate;
  String _priority = 'High';
  CategoryModel? _selectedCategory;
  ProductModel? _selectedProduct;
  List<ProductModel> _products = [];
  bool _isLoadingProducts = false;

  // Measurement controllers
  // final Map<String, TextEditingController> _measurementControllers = {};

  // Photo handling
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];

  final ApiService _apiService = ApiService();

  // List to track multiple order items
  final List<Map<String, dynamic>> _orderItems = [];

  // Category list
  List<CategoryModel> _categories = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCartExpanded = false;

  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _customerSearchController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController();
    _notesController = TextEditingController();

    // Initialize measurement controllers
    _measurementControllers = {};

    // Set default due date to 7 days from now
    _selectedDate = DateTime.now().add(const Duration(days: 7));

    // Load sample data for demonstration
    _loadSampleData();

    // Add a post-frame callback to check for editing mode after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForEditingMode();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _measurementControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _initializeMeasurementControllers(List<MeasurementRange> measurements) {
    // Clear old controllers
    _measurementControllers.forEach((_, controller) => controller.dispose());
    _measurementControllers.clear();

    // Create new controllers for selected product's measurements
    for (var measurement in measurements) {
      _measurementControllers[measurement.name] = TextEditingController();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.cardBackground,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Search customer via API based on input (by name or phone)
  Future<void> _searchCustomer() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a search term'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    final result =
        await _apiService.getCustomers(search: query, page: 1, limit: 10);
    print('API Response: $result');

    if (result['success']) {
      // Check if result['data'] is a Map or List and extract the customers accordingly.
      List<dynamic> customers;
      if (result['data'] is List) {
        customers = result['data'];
      } else if (result['data'] is Map && result['data'].containsKey('data')) {
        customers = result['data']['data'];
      } else {
        customers = [];
      }

      if (customers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No customers found'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      } else {
        // Show customers in a bottom sheet to select one.
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  title: Text(customer['name'] ?? ''),
                  subtitle: Text(customer['phone'] ?? ''),
                  onTap: () {
                    setState(() {
                      _selectedCustomer = customer;
                      _searchController.text = customer['name'] ?? '';
                    });
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Search failed'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  // Fetch products for selected category
  Future<void> _fetchProductsByCategory(String categoryTitle) async {
    setState(() {
      _isLoadingProducts = true;
      _products = [];
      _selectedProduct = null;
    });

    // Hardcoded product data for each category as fallback
    Map<String, List<ProductModel>> fallbackProducts = {
      'Suits & Blazers': [
        ProductModel(
          id: 'suit1',
          name: 'Business Suit',
          description: 'Professional business suit',
          price: 5000.0,
          categoryId: 'suit_category',
          measurements: [
            MeasurementRange(
                name: 'Chest', unit: 'in', minValue: 34, maxValue: 50),
            MeasurementRange(
                name: 'Waist', unit: 'in', minValue: 28, maxValue: 46),
            MeasurementRange(
                name: 'Shoulder', unit: 'in', minValue: 15, maxValue: 22),
            MeasurementRange(
                name: 'Sleeve Length', unit: 'in', minValue: 22, maxValue: 28),
            MeasurementRange(
                name: 'Jacket Length', unit: 'in', minValue: 26, maxValue: 36),
          ],
        ),
        ProductModel(
          id: 'suit2',
          name: 'Wedding Suit',
          description: 'Elegant wedding suit',
          price: 8000.0,
          categoryId: 'suit_category',
          measurements: [
            MeasurementRange(
                name: 'Chest', unit: 'in', minValue: 34, maxValue: 50),
            MeasurementRange(
                name: 'Waist', unit: 'in', minValue: 28, maxValue: 46),
            MeasurementRange(
                name: 'Shoulder', unit: 'in', minValue: 15, maxValue: 22),
            MeasurementRange(
                name: 'Sleeve Length', unit: 'in', minValue: 22, maxValue: 28),
            MeasurementRange(
                name: 'Neck', unit: 'in', minValue: 13, maxValue: 20),
          ],
        ),
      ],
      'Shirts & Pants': [
        ProductModel(
          id: 'shirt1',
          name: 'Formal Shirt',
          description: 'Tailored formal shirt',
          price: 1200.0,
          categoryId: 'shirt_category',
          measurements: [
            MeasurementRange(
                name: 'Neck', unit: 'in', minValue: 13, maxValue: 20),
            MeasurementRange(
                name: 'Chest', unit: 'in', minValue: 34, maxValue: 50),
            MeasurementRange(
                name: 'Waist', unit: 'in', minValue: 28, maxValue: 46),
            MeasurementRange(
                name: 'Sleeve Length', unit: 'in', minValue: 22, maxValue: 28),
          ],
        ),
        ProductModel(
          id: 'shirt2',
          name: 'Casual Shirt',
          description: 'Comfortable casual shirt',
          price: 800.0,
          categoryId: 'shirt_category',
          measurements: [
            MeasurementRange(
                name: 'Neck', unit: 'in', minValue: 13, maxValue: 20),
            MeasurementRange(
                name: 'Chest', unit: 'in', minValue: 34, maxValue: 50),
            MeasurementRange(
                name: 'Shoulder', unit: 'in', minValue: 15, maxValue: 22),
          ],
        ),
        ProductModel(
          id: 'pant1',
          name: 'Formal Trousers',
          description: 'Tailored formal trousers',
          price: 1500.0,
          categoryId: 'pant_category',
          measurements: [
            MeasurementRange(
                name: 'Waist', unit: 'in', minValue: 28, maxValue: 46),
            MeasurementRange(
                name: 'Hip', unit: 'in', minValue: 34, maxValue: 52),
            MeasurementRange(
                name: 'Inseam', unit: 'in', minValue: 26, maxValue: 36),
          ],
        ),
      ],
      'Traditional Wear': [
        ProductModel(
          id: 'trad1',
          name: 'Traditional Outfit',
          description: 'Elegant traditional wear',
          price: 3500.0,
          categoryId: 'traditional_category',
          measurements: [
            MeasurementRange(
                name: 'Chest', unit: 'in', minValue: 34, maxValue: 50),
            MeasurementRange(
                name: 'Waist', unit: 'in', minValue: 28, maxValue: 46),
            MeasurementRange(
                name: 'Shoulder', unit: 'in', minValue: 15, maxValue: 22),
            MeasurementRange(
                name: 'Length', unit: 'in', minValue: 26, maxValue: 36),
            MeasurementRange(
                name: 'Sleeve', unit: 'in', minValue: 22, maxValue: 28),
            MeasurementRange(
                name: 'Collar', unit: 'in', minValue: 13, maxValue: 20),
          ],
        ),
      ],
    };

    try {
      // Try to fetch from API first
      final result = await _apiService.getCategories();
      print('Categories API response: $result');

      if (result['success']) {
        // Handle different data formats
        List<dynamic> categories = [];

        if (result['data'] is List) {
          categories = result['data'];
        } else if (result['data'] is Map &&
            result['data'].containsKey('data')) {
          // If data is in a nested 'data' field
          categories = result['data']['data'] as List;
        } else if (result['data'] is Map) {
          // If data is a map of categories
          categories = result['data'].values.toList();
        }

        if (categories.isNotEmpty) {
          // Find exact match first
          Map<String, dynamic>? matchingCategory = categories.firstWhere(
            (c) => c['title'] == categoryTitle,
            orElse: () => null,
          );

          // If no exact match, try mapping to API category names
          if (matchingCategory == null) {
            // Map from UI category names to API category names
            String apiCategoryName = '';
            if (categoryTitle == 'Suits & Blazers') {
              apiCategoryName = 'Suits';
            } else if (categoryTitle == 'Shirts & Pants') {
              apiCategoryName = 'Shirts';
            } else if (categoryTitle == 'Traditional Wear') {
              apiCategoryName = 'Pants'; // Fallback
            }

            // Try to find with mapped name
            matchingCategory = categories.firstWhere(
              (c) => c['title'] == apiCategoryName,
              orElse: () => null,
            );
          }

          if (matchingCategory != null) {
            final categoryId = matchingCategory['_id'];
            final productsResult =
                await _apiService.getProducts(category: categoryId);

            if (productsResult['success']) {
              List<dynamic> productsData = [];

              if (productsResult['data'] is List) {
                productsData = productsResult['data'];
              } else if (productsResult['data'] is Map &&
                  productsResult['data'].containsKey('data')) {
                productsData = productsResult['data']['data'];
              }

              if (productsData.isNotEmpty) {
                setState(() {
                  _products = productsData
                      .map((product) => ProductModel.fromJson(product))
                      .toList();
                });
                return; // Success, exit function
              }
            }
          }
        }
      }

      // If API failed or returned no products, use fallback data
      print('Using fallback products for: $categoryTitle');
      setState(() {
        _products = fallbackProducts[categoryTitle] ?? [];
      });
    } catch (e) {
      print('Error in _fetchProductsByCategory: $e');
      // If exception occurs, use fallback data
      setState(() {
        _products = fallbackProducts[categoryTitle] ?? [];
      });
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  // Pick images
  Future<void> _pickImages(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Select Image Source',
            style: AppTheme.bodyLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppTheme.textPrimary),
                title: const Text('Camera', style: AppTheme.bodyRegular),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppTheme.textPrimary),
                title: const Text('Gallery', style: AppTheme.bodyRegular),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Check if editing an existing order
  void _checkForEditingMode() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null &&
        args is Map<String, dynamic> &&
        args['isEditing'] == true) {
      setState(() {
        _isEditing = true;
        _orderId = args['orderId'] ?? '';
      });

      // Pre-populate order fields
      if (args.containsKey('customerName') && args['customerName'] != null) {
        setState(() {
          _selectedCustomer = {
            'name': args['customerName'],
            'phone': args['customerPhone'] ?? '',
            'id': args['customerId'] ?? '',
          };
          _searchController.text = args['customerName'];
        });
      }

      // Pre-populate notes, priority, due date
      final orderData = args['orderData'];
      if (orderData is Map<String, dynamic>) {
        setState(() {
          _notesController.text = orderData['notes'] ?? '';
          _priority = orderData['priority'] ?? 'Medium';

          // Parse due date if available
          if (orderData.containsKey('dueDate') &&
              orderData['dueDate'] != null) {
            try {
              // Check if the dueDate is in a formatted string (like "Jan 15") or ISO format
              final dueDateStr = orderData['dueDate'];
              if (dueDateStr.contains(' ')) {
                // Try to parse a formatted date like "Jan 15"
                final parts = dueDateStr.split(' ');
                if (parts.length == 2) {
                  final String month = parts[0];
                  final int day = int.tryParse(parts[1]) ?? 1;
                  final Map<String, int> monthMap = {
                    'Jan': 1,
                    'Feb': 2,
                    'Mar': 3,
                    'Apr': 4,
                    'May': 5,
                    'Jun': 6,
                    'Jul': 7,
                    'Aug': 8,
                    'Sep': 9,
                    'Oct': 10,
                    'Nov': 11,
                    'Dec': 12
                  };
                  final int monthNum = monthMap[month] ?? 1;
                  // Use current year
                  _selectedDate = DateTime(DateTime.now().year, monthNum, day);
                }
              } else {
                // Try to parse as ISO date
                _selectedDate = DateTime.parse(dueDateStr);
              }
            } catch (e) {
              print('Error parsing due date: $e');
              // Set default due date to 7 days from now
              _selectedDate = DateTime.now().add(const Duration(days: 7));
            }
          }
        });

        // Pre-populate measurements if available
        if (args.containsKey('measurements') && args['measurements'] != null) {
          final measurements = args['measurements'];
          if (measurements is Map<String, dynamic>) {
            // These will be applied to each item when it's loaded
            _orderMeasurements = Map<String, dynamic>.from(measurements);
          }
        }

        // Pre-populate order items
        if (orderData.containsKey('items') && orderData['items'] is List) {
          final items = orderData['items'] as List;

          // Clear any existing items
          _orderItems.clear();

          // Add each item from the order data
          for (var item in items) {
            if (item is Map<String, dynamic>) {
              final Map<String, dynamic> newItem = {
                'product': item['id'] ?? '',
                'productId': item['id'] ?? '',
                'productName': item['name'] ?? 'Unknown Product',
                'productDescription': item['description'] ?? '',
                'quantity': item['quantity'] ?? 1,
                'price': item['price'] ?? 0.0,
              };

              // Add measurements data if available
              if (item.containsKey('measurementsData')) {
                newItem['measurementsData'] = item['measurementsData'];
              }

              _orderItems.add(newItem);
            }
          }

          // Pre-select the first item's category and product if the order has items
          if (_orderItems.isNotEmpty) {
            _preSelectCategoryAndProduct(_orderItems.first);
          }
        }
      }
    }
  }

  // Helper method to pre-select category and product
  void _preSelectCategoryAndProduct(Map<String, dynamic> item) {
    // First, find product by ID (most reliable)
    if (item.containsKey('product') && item['product'] is String) {
      String productId = item['product'];
      _apiService.getProduct(productId).then((result) {
        if (result['success'] && result['data'] != null) {
          final productData = result['data'];
          String categoryId = '';

          // Get category ID from product
          if (productData['category'] is String) {
            categoryId = productData['category'];
          } else if (productData['category'] is Map &&
              productData['category'].containsKey('_id')) {
            categoryId = productData['category']['_id'];
          }

          if (categoryId.isNotEmpty) {
            // Fetch the category first
            _apiService.getCategory(categoryId).then((categoryResult) {
              if (categoryResult['success'] && categoryResult['data'] != null) {
                final categoryData = categoryResult['data'];

                // Create category model
                final category = _categories
                    .firstWhere((c) => c.id == categoryId, orElse: () {
                  // If not found in local categories, create a new one
                  final title = categoryData['title'] ?? 'Unknown Category';
                  final newCategory = CategoryModel(
                    id: categoryId,
                    title: title,
                    gradientColors: [
                      Colors.blue.shade200,
                      Colors.blue.shade400
                    ],
                    icon: Icons.category,
                    measurements: [], // Will be populated when we get product
                  );

                  // Add to local list
                  if (mounted) {
                    setState(() {
                      _categories.add(newCategory);
                    });
                  }
                  return newCategory;
                });

                // Now select the category and fetch products
                if (mounted) {
                  setState(() {
                    _selectedCategory = category;
                  });

                  // Fetch products for this category
                  _fetchProductsByCategory(category.title).then((_) {
                    // After products are loaded, select the product
                    if (_products.isNotEmpty && mounted) {
                      // Find matching product
                      final product = _products.firstWhere(
                          (p) => p.id == productId,
                          orElse: () => _products.first);

                      setState(() {
                        _selectedProduct = product;
                        _priceController.text = item['price'].toString();
                        _quantityController.text = item['quantity'].toString();

                        // Initialize measurement controllers
                        _initializeMeasurementControllers(product.measurements);

                        // Apply measurements if available
                        if (item.containsKey('measurementsData')) {
                          final measurementsData = item['measurementsData'];
                          if (measurementsData is Map<String, dynamic>) {
                            measurementsData.forEach((key, value) {
                              if (_measurementControllers.containsKey(key)) {
                                _measurementControllers[key]?.text =
                                    value.toString();
                              }
                            });
                          }
                        }
                      });
                    }
                  });
                }
              }
            });
          }
        } else {
          // Fallback to name-based matching
          _findCategoryAndProductByName(item['productName'] ?? 'Unknown');
        }
      }).catchError((e) {
        print('Error pre-selecting product: $e');
        // Fallback to name-based matching
        _findCategoryAndProductByName(item['productName'] ?? 'Unknown');
      });
    } else {
      // If no product ID, try to match by name
      _findCategoryAndProductByName(item['productName'] ?? 'Unknown');
    }
  }

  // Find category and product by name for better pre-population
  void _findCategoryAndProductByName(String productName) {
    final lowercaseName = productName.toLowerCase();

    // Try to find the appropriate category based on product name
    CategoryModel? category;

    if (lowercaseName.contains('suit') || lowercaseName.contains('blazer')) {
      category = _categories.firstWhere(
        (c) => c.title.contains('Suit') || c.title.contains('Blazer'),
        orElse: () => _categories.isNotEmpty
            ? _categories.first
            : _createDefaultCategory(),
      );
    } else if (lowercaseName.contains('shirt') ||
        lowercaseName.contains('pant')) {
      category = _categories.firstWhere(
        (c) => c.title.contains('Shirt') || c.title.contains('Pant'),
        orElse: () => _categories.isNotEmpty
            ? _categories.first
            : _createDefaultCategory(),
      );
    } else if (lowercaseName.contains('kurta') ||
        lowercaseName.contains('traditional') ||
        lowercaseName.contains('ethnic')) {
      category = _categories.firstWhere(
        (c) => c.title.contains('Traditional') || c.title.contains('Ethnic'),
        orElse: () => _categories.isNotEmpty
            ? _categories.first
            : _createDefaultCategory(),
      );
    } else if (_categories.isNotEmpty) {
      // Default to first category if no match
      category = _categories.first;
    } else {
      // No categories available
      return;
    }

    // If found a category, select it and fetch products
    if (mounted) {
      setState(() {
        _selectedCategory = category;
      });

      _fetchProductsByCategory(category.title).then((_) {
        // After products are loaded, try to find a matching product
        if (_products.isNotEmpty && mounted) {
          // Find a product that matches the name
          final product = _products.firstWhere(
              (p) => p.name.toLowerCase().contains(lowercaseName),
              orElse: () => _products.first);

          setState(() {
            _selectedProduct = product;
          });
        }
      });
    }
  }

  // Helper method to create a default category when none is found
  CategoryModel _createDefaultCategory() {
    return CategoryModel(
      id: 'default',
      title: 'Default Category',
      gradientColors: [Colors.grey.shade300, Colors.grey.shade500],
      icon: Icons.category,
      measurements: [],
    );
  }

  void _addCurrentItemToOrder() {
    // Validate product selection
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    // Validate and parse quantity
    int quantity = 1;
    if (_quantityController.text.isNotEmpty) {
      quantity = int.tryParse(_quantityController.text) ?? 1;
    }

    // Validate and parse price
    double price = _selectedProduct!.price;
    if (_priceController.text.isNotEmpty) {
      price = double.tryParse(_priceController.text) ?? _selectedProduct!.price;
    }

    // Collect measurements data
    Map<String, dynamic> measurementsData = {};
    _measurementControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        // Try to parse as number if possible, otherwise store as string
        final value = double.tryParse(controller.text) ?? controller.text;
        measurementsData[key] = value;
      }
    });

    // Create the item with complete product information
    Map<String, dynamic> orderItem = {
      'product': _selectedProduct!.id, // Store the product ID string
      'productId': _selectedProduct!.id, // Also store as productId for clarity
      'productName': _selectedProduct!.name,
      'productDescription': _selectedProduct!.description,
      'quantity': quantity,
      'price': price,
      'notes': _notesController.text.trim(),
    };

    // Add measurements data if any
    if (measurementsData.isNotEmpty) {
      orderItem['measurementsData'] = measurementsData;
    }

    print('Adding item to order: $orderItem');
    print('Product ID: ${_selectedProduct!.id}');

    // Add to order items or update if we're editing
    setState(() {
      if (_editingItemIndex != null) {
        // Insert at the same index we removed from
        _orderItems.insert(_editingItemIndex!, orderItem);
        _editingItemIndex = null; // Reset editing index
      } else {
        _orderItems.add(orderItem);
      }

      // Reset selection and controllers
      _selectedProduct = null;
      _quantityController.text = '1';
      _priceController.text = '';
      _notesController.text = '';

      // Clear measurement controllers
      _measurementControllers.forEach((key, controller) {
        controller.text = '';
      });
    });

    // Close the cart if it's expanded
    if (_isCartExpanded) {
      _toggleCart();
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${orderItem['productName']} added to order'),
        backgroundColor: AppTheme.statusInProgress,
      ),
    );
  }

  Future<void> _createOrder() async {
    // Validation checks
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the order'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    try {
      // Set loading state
      setState(() {
        _isLoading = true;
      });

      // Format the order items data for API with all necessary information
      List<Map<String, dynamic>> formattedItems = [];
      for (var item in _orderItems) {
        // Ensure product ID is correctly formatted
        String productId = '';
        if (item.containsKey('product') && item['product'] != null) {
          productId = item['product'].toString();
        } else if (item.containsKey('productId') && item['productId'] != null) {
          productId = item['productId'].toString();
        }

        if (productId.isEmpty) {
          print('Warning: Item has no product ID: ${item['productName']}');
          // Skip items without product IDs to prevent API errors
          continue;
        }

        Map<String, dynamic> formattedItem = {
          'product': productId, // Always use the string ID
          'quantity': item['quantity'] ?? 1,
          'price': item['price'] ?? 0.0,
          'notes': item['notes'] ?? '',
        };

        // Include product name and description in API request for better debugging
        if (item.containsKey('productName')) {
          formattedItem['productName'] = item['productName'];
        }

        if (item.containsKey('productDescription')) {
          formattedItem['productDescription'] = item['productDescription'];
        }

        // Include measurements if available
        if (item.containsKey('measurementsData') &&
            item['measurementsData'] is Map) {
          formattedItem['measurements'] = item['measurementsData'];
        }

        formattedItems.add(formattedItem);
        print('Formatted item for API: $formattedItem');
      }

      // Calculate the accurate total amount
      final double calculatedTotal = _calculateTotal();

      // Create order data for API
      final orderData = {
        'customer': _selectedCustomer!['_id'] ?? _selectedCustomer!['id'],
        'items': formattedItems.map((item) {
          // Ensure product ID is correctly formatted
          if (item['product'] is Map) {
            // If product is an object, extract its ID
            item['product'] = item['product']['_id'] ?? item['product']['id'];
          }
          return item;
        }).toList(),
        'status': _isEditing ? null : 'New', // Don't update status if editing
        'totalAmount': calculatedTotal, // Use calculated total
        'dueDate': _selectedDate!.toIso8601String(),
        'priority': _priority,
        'notes': _notesController.text.trim(),
      };

      print('Order data for API: $orderData');

      Map<String, dynamic> result;

      if (_isEditing && _orderId.isNotEmpty) {
        // Update existing order
        print('Updating order with ID: $_orderId with total: $calculatedTotal');
        result = await _apiService.updateOrder(_orderId, orderData);

        // Print debug info to verify API response
        print('Update order API response: $result');
      } else {
        // Create new order
        print('Creating new order with total: $calculatedTotal');
        result = await _apiService.createOrder(orderData);

        // Print debug info to verify API response
        print('Create order API response: $result');
      }

      if (result['success']) {
        // Success! Get the order ID from the response.
        final String orderId = result['data']['_id'] ?? '';
        print('Order saved successfully with ID: $orderId');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Order updated successfully'
                : 'Order created successfully'),
            backgroundColor: AppTheme.statusInProgress,
          ),
        );

        // Navigate based on whether we're editing or creating
        if (orderId.isNotEmpty) {
          if (_isEditing) {
            // For updates, go back to order detail page with refresh flag
            print('Navigating to order detail after update with refresh flag');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/order_detail',
              (route) => route.settings.name == '/', // Keep only the home route
              arguments: {
                'id': orderId,
                'shouldRefresh':
                    true, // Flag to indicate data should be refreshed
              },
            );
          } else {
            // For new orders, go to bill page
            print('Navigating to bill page after creation');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/bill',
              (route) => route.settings.name == '/', // Keep only the home route
              arguments: {
                'orderId': orderId,
                'shouldRefresh':
                    true, // Flag to indicate data should be refreshed
              },
            );
          }
        } else {
          // If no order ID, just go back to home
          Navigator.popUntil(context, ModalRoute.withName('/'));
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to create order');
      }
    } catch (e) {
      print('Error creating/updating order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _exit() {
    Navigator.pop(context);
  }

  void _selectCategory(CategoryModel category) {
    setState(() {
      _selectedCategory = category;
      _selectedProduct = null; // Clear previously selected product
      _measurementControllers.clear(); // Clear measurement controllers
      _fetchProductsByCategory(category.title);
    });
  }

  void _selectProduct(ProductModel product) {
    setState(() {
      _selectedProduct = product;
      _priceController.text = product.price.toString();

      // Initialize measurement controllers based on the selected product's measurements
      _initializeMeasurementControllers(product.measurements);
    });
  }

  // Add a method to toggle cart
  void _toggleCart() {
    setState(() {
      _isCartExpanded = !_isCartExpanded;
    });
  }

  // Create a draggable cart widget
  Widget _buildDraggableCart() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // Darker shadow
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      margin: EdgeInsets.only(
        // Add margin to ensure the cart doesn't overlap with the bottom nav bar
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 0,
      ),
      child: SafeArea(
        top: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height:
              _isCartExpanded ? MediaQuery.of(context).size.height * 0.6 : 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar for dragging
              GestureDetector(
                onTap: _toggleCart,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cart (${_orderItems.length} items)',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cart preview (always visible)
              if (!_isCartExpanded)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_orderItems.length} items · ₹${_calculateTotal().toStringAsFixed(2)}',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _addCurrentItemToOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              child: const Text(
                                'Add Item',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _createOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              child: Text(
                                _isEditing ? 'Update' : 'Create',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Full cart (visible when expanded)
              if (_isCartExpanded)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _orderItems.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No items in cart',
                                    style: AppTheme.bodyRegular,
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _orderItems.length,
                                  itemBuilder: (context, index) =>
                                      _buildOrderItemCard(index),
                                ),
                        ),

                        // Order summary and action buttons
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppTheme.dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: AppTheme.headingMedium,
                                  ),
                                  Text(
                                    '₹${_calculateTotal().toStringAsFixed(2)}',
                                    style: AppTheme.headingLarge.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _addCurrentItemToOrder,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      child: const Text(
                                        'Add Item',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _createOrder,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.secondary,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _isEditing
                                                  ? 'Update Order'
                                                  : 'Create Order',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Add a method to calculate the total
  double _calculateTotal() {
    return _orderItems.fold(0.0, (sum, item) {
      return sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Order' : 'New Order',
          style: AppTheme.headingMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Use a Stack instead of Column to properly position the cart
      body: Stack(
        children: [
          // Main content - scrollable - takes full screen height
          Container(
            height: MediaQuery.of(context).size.height,
            padding: EdgeInsets.only(
              // Add padding at the bottom to prevent content from being hidden behind the cart
              bottom: _isCartExpanded
                  ? MediaQuery.of(context).size.height * 0.6 + 60
                  : // More padding when expanded
                  160, // Fixed padding when collapsed
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerSection(),
                  const SizedBox(height: 24),
                  _buildProductSection(),
                  const SizedBox(height: 24),
                  _buildMeasurementsSection(),
                  const SizedBox(height: 24),
                  _buildOrderDetailsSection(),
                ],
              ),
            ),
          ),

          // Fixed cart at the bottom - positioned absolutely
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildDraggableCart(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
    );
  }

  // Customer section implementation
  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer',
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: 16),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: TextField(
            controller: _searchController,
            style: AppTheme.bodyRegular,
            decoration: InputDecoration(
              hintText: 'Search customer (by name or phone)',
              hintStyle: const TextStyle(color: Color(0xFFADAEBC)),
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.textSecondary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primary),
                onPressed: _searchCustomer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Display selected customer info (if any)
        if (_selectedCustomer != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer!['name'] ?? 'Unknown Customer',
                        style: AppTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCustomer!['phone'] ?? 'No phone',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle,
                    color: AppTheme.statusInProgress),
              ],
            ),
          ),
      ],
    );
  }

  // Product section implementation
  Widget _buildProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product',
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: 16),
        // Categories
        const Text(
          'Select Category',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        // Category cards
        ..._categories.map((category) => _buildCategoryCard(category)),

        // Products (show only if category is selected)
        if (_selectedCategory != null) ...[
          const SizedBox(height: 24),
          const Text(
            'Select Product',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : _buildProductsGrid(),
        ],
      ],
    );
  }

  // Measurements section implementation
  Widget _buildMeasurementsSection() {
    if (_selectedProduct == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Details',
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuantityField(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPriceField(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Measurements',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _buildMeasurementsGrid(),
        const SizedBox(height: 24),
        const Text(
          'Photos',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _buildPhotoUpload(),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSelectedImagesGrid(),
        ],
      ],
    );
  }

  // Order details section implementation
  Widget _buildOrderDetailsSection() {
    if (_selectedProduct == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Details',
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: 16),
        // Deadline selector
        const Text(
          'Deadline',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _buildDatePicker(),
        const SizedBox(height: 24),
        // Priority selector
        const Text(
          'Priority',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _buildPrioritySelector(),
        const SizedBox(height: 24),
        // Notes
        const Text(
          'Notes',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _buildNotesField(),
      ],
    );
  }

  // Widget to build each order item card with edit and delete options
  Widget _buildOrderItemCard(int index) {
    final item = _orderItems[index];
    final productName = item['productName'] ?? 'Unknown Product';
    final productDesc = item['productDescription'] ?? '';
    final quantity = item['quantity'] ?? 1;
    final price = item['price'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product icon/image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconForProductName(productName),
                      size: 30,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: AppTheme.bodyLarge,
                      ),
                      if (productDesc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          productDesc,
                          style: AppTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Qty: $quantity',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Column(
                  children: [
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editOrderItem(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                    const SizedBox(height: 10),
                    // Delete button
                    IconButton(
                      icon:
                          const Icon(Icons.delete, color: AppTheme.accentColor),
                      onPressed: () => _deleteOrderItem(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method to edit an existing order item
  void _editOrderItem(int index) {
    final item = _orderItems[index];

    // Set selected product and category based on item
    _selectedProduct = null;
    _selectedCategory = null;

    // Find the product by name in the available products
    final productName = item['productName'] ?? '';

    if (item.containsKey('productId') && item['productId'] != null) {
      // If we have a product ID, find product by ID
      _findProductById(item['productId']);
    } else {
      // Otherwise find by name
      _findCategoryAndProductByName(productName);
    }

    // Pre-populate form fields
    _quantityController.text = (item['quantity'] ?? 1).toString();
    _priceController.text = (item['price'] ?? 0.0).toString();

    // Pre-populate measurements if available
    if (item.containsKey('measurementsData') &&
        item['measurementsData'] != null &&
        item['measurementsData'] is Map) {
      Map<String, dynamic> measurementsData = item['measurementsData'];

      // Wait for measurement controllers to be initialized after product selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        measurementsData.forEach((key, value) {
          if (_measurementControllers.containsKey(key)) {
            _measurementControllers[key]?.text = value.toString();
          }
        });
      });
    }

    // Remove the item from the list as we'll add it back when user saves
    setState(() {
      _orderItems.removeAt(index);
      _editingItemIndex = index; // Track that we're editing this item
    });

    // Scroll back to the product selection section
    _scrollToSection(0);
  }

  // Method to delete an order item
  void _deleteOrderItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Delete Item', style: AppTheme.headingMedium),
          content: const Text(
            'Are you sure you want to remove this item from the order?',
            style: AppTheme.bodyRegular,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _orderItems.removeAt(index);
                });
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Add this field to track which item is being edited
  int? _editingItemIndex;

  // Define the icons for products based on name
  IconData _getIconForProductName(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('shirt') || name.contains('blouse')) {
      return Icons.dry_cleaning;
    } else if (name.contains('suit') || name.contains('blazer')) {
      return Icons.business;
    } else if (name.contains('pant') || name.contains('trouser')) {
      return Icons.accessibility_new;
    } else if (name.contains('dress') || name.contains('lehenga')) {
      return Icons.checkroom;
    } else {
      return Icons.design_services;
    }
  }

  // Add this method to scroll to a specific section
  void _scrollToSection(int index) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        index *
            (AppTheme.paddingMedium +
                56), // Adjust the calculation based on your layout
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _findProductById(String productId) {
    if (productId.isEmpty) return;

    print('Finding product with ID: $productId');

    // Find the product in the API products list
    if (_products.isNotEmpty) {
      for (var product in _products) {
        if (product.id == productId) {
          print('Found product by ID: ${product.name}');

          // Select the product
          setState(() {
            _selectedProduct = product;
            _priceController.text = product.price.toString();
            _quantityController.text = '1';
          });

          // Find and select the appropriate category
          for (var category in _categories) {
            if (product.categoryId.isNotEmpty &&
                (category.title
                        .toLowerCase()
                        .contains(product.categoryId.toLowerCase()) ||
                    _matchCategoryByProductName(
                        product.name, category.title))) {
              print('Selecting category: ${category.title}');
              _selectCategory(category);
              break;
            }
          }

          return;
        }
      }
    }

    print('Product with ID $productId not found');
  }

  bool _matchCategoryByProductName(String productName, String categoryTitle) {
    final name = productName.toLowerCase();
    return name.contains(categoryTitle.toLowerCase());
  }

  // Add the missing _loadSampleData method
  void _loadSampleData() {
    // This method should load sample data for when the app is in demo mode
    // For now, just initialize with dummy data

    // Load sample categories
    _categories = [
      CategoryModel(
        id: 'cat1',
        title: 'Suits & Blazers',
        icon: Icons.business,
        gradientColors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        measurements: [
          'Chest',
          'Waist',
          'Shoulder',
          'Length',
          'Arm Length',
          'Neck'
        ],
      ),
      CategoryModel(
        id: 'cat2',
        title: 'Shirts & Pants',
        icon: Icons.dry_cleaning,
        gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
        measurements: [
          'Chest',
          'Waist',
          'Hip',
          'Inseam',
          'Shoulder',
          'Sleeve Length'
        ],
      ),
      CategoryModel(
        id: 'cat3',
        title: 'Traditional Wear',
        icon: Icons.checkroom,
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        measurements: [
          'Chest',
          'Waist',
          'Shoulder',
          'Length',
          'Sleeve',
          'Collar'
        ],
      ),
    ];

    // Initialize product items for demo
    // These will be replaced with real API data when a category is selected
    _products = [];
  }

  // Add the missing UI builder methods
  Widget _buildCategoryCard(CategoryModel category) {
    final bool isSelected = _selectedCategory?.title == category.title;
    return GestureDetector(
      onTap: () => _selectCategory(category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isSelected
                ? [category.gradientColors[0], category.gradientColors[1]]
                : [
                    category.gradientColors[0].withOpacity(0.7),
                    category.gradientColors[1].withOpacity(0.7)
                  ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.gradientColors[1].withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(category.icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(category.title,
                style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
            const Spacer(),
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text('No products found for this category',
              style: AppTheme.bodyRegular),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final isSelected = _selectedProduct?.id == product.id;

        return GestureDetector(
          onTap: () => _selectProduct(product),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withOpacity(0.2)
                  : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: AppTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: AppTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs. ${product.price.toStringAsFixed(2)}',
                  style: AppTheme.bodyRegular,
                ),
                const SizedBox(width: 16),
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantity', style: AppTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: TextField(
            controller: _quantityController,
            style: AppTheme.bodyRegular,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price (Rs)', style: AppTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: TextField(
            controller: _priceController,
            style: AppTheme.bodyRegular,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementsGrid() {
    if (_selectedProduct == null || _selectedProduct!.measurements.isEmpty) {
      return const Center(
        child: Text(
          'No measurements available for this product',
          style: AppTheme.bodySmall,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 173 / 48,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _selectedProduct!.measurements.length,
      itemBuilder: (context, index) {
        final measurement = _selectedProduct!.measurements[index];
        final controller = _measurementControllers[measurement.name]!;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: TextField(
            controller: controller,
            style: AppTheme.bodyRegular,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: measurement.name,
              hintStyle: const TextStyle(color: Color(0xFFADAEBC)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(left: 12),
              suffixText: measurement.unit,
              suffixStyle: const TextStyle(color: AppTheme.textSecondary),
              helperText: '${measurement.minValue} - ${measurement.maxValue}',
              helperStyle:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          border: Border.all(width: 2, color: const Color(0xFF374151)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined,
                  color: AppTheme.textSecondary, size: 24),
              SizedBox(height: 8),
              Text('Add photos', style: AppTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_selectedImages[index]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImages.removeAt(index);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              _selectedDate == null
                  ? 'mm/dd/yyyy'
                  : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
              style: _selectedDate == null
                  ? AppTheme.bodyRegular
                      .copyWith(color: const Color(0xFFADAEBC))
                  : AppTheme.bodyRegular,
            ),
            const Spacer(),
            const Icon(Icons.calendar_today_outlined,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: [
        _buildPriorityButton('High', const Color(0xFFDC2626)),
        const SizedBox(width: 16),
        _buildPriorityButton('Medium', AppTheme.cardBackground),
        const SizedBox(width: 16),
        _buildPriorityButton('Low', AppTheme.cardBackground),
      ],
    );
  }

  Widget _buildPriorityButton(String priority, Color backgroundColor) {
    final bool isSelected = _priority == priority;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _priority = priority;
          });
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? (priority == 'High'
                    ? const Color(0xFFDC2626)
                    : (priority == 'Medium'
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF059669)))
                : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          alignment: Alignment.center,
          child: Text(
            priority,
            style: AppTheme.bodyRegular.copyWith(
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        style: AppTheme.bodyRegular,
        decoration: const InputDecoration(
          hintText: 'Add special instructions...',
          hintStyle: TextStyle(color: Color(0xFFADAEBC)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    print('Navigation tapped in new_order.dart: $index');

    // Don't navigate if already on the selected page
    if (index == _currentNavIndex) {
      print('Already on this page, not navigating');
      return;
    }

    setState(() {
      _currentNavIndex = index;
    });

    // Get the route from the AppBottomNav
    final String route = AppBottomNav.getRouteForIndex(index);
    print('Navigating to route: $route');

    // Navigate to the selected route and clear the navigation stack
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }
}
