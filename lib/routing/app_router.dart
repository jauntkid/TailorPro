import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../screens/main_screen.dart';
import '../screens/orders/create_order_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/edit_order_screen.dart';
import '../screens/customers/add_customer_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../screens/customers/edit_customer_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case '/search':
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case '/create-order':
        final customer = settings.arguments as Customer?;
        return MaterialPageRoute(
          builder: (_) => CreateOrderScreen(preselectedCustomer: customer),
        );
      case '/order-detail':
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: orderId),
        );
      case '/edit-order':
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => EditOrderScreen(orderId: orderId),
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      case '/privacy-policy':
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
        );
      case '/add-customer':
        return MaterialPageRoute(
          builder: (_) => const AddCustomerScreen(),
        );
      case '/customer-detail':
        final customerId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(customerId: customerId),
        );
      case '/edit-customer':
        final customerId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => EditCustomerScreen(customerId: customerId),
        );
      default:
        return MaterialPageRoute(builder: (_) => const MainScreen());
    }
  }
}
