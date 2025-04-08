import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siri/providers/auth_provider.dart';
import 'package:siri/screen/home.dart';
import 'package:siri/screen/login_screen.dart';
import 'package:siri/screen/order_detail.dart';
import 'package:siri/screen/bill.dart';
import 'package:siri/screen/settings_screen.dart';
import 'package:siri/screen/user_page.dart';
import 'package:siri/screen/customers.dart';
import 'package:siri/screen/customer_detail.dart';
import 'package:siri/screen/new_customer.dart';
import 'package:siri/screen/new_order.dart';
import 'package:siri/screen/track.dart';
import 'package:siri/screen/setting.dart';
import 'package:siri/screen/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AuthProvider
  final authProvider = AuthProvider();

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailor App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/order_detail': (context) => const OrderDetailScreen(),
        '/bill': (context) => const BillScreen(),
        '/user_page': (context) => const UserPage(),
        '/user_profile': (context) => const UserProfileScreen(),
        '/customers': (context) => const CustomersScreen(),
        '/customer_detail': (context) => CustomerDetailScreen(
              customerId: (ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?)?['id'] ??
                  '',
            ),
        '/new_customer': (context) => const NewCustomerScreen(),
        '/new_order': (context) => const NewOrderScreen(),
        '/track': (context) => const TrackScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
