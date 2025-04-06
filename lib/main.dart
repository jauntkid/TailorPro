import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siri/config/theme.dart';
import 'package:siri/providers/auth_provider.dart';
import 'package:siri/screen/bill.dart';
import 'package:siri/screen/home.dart';
import 'package:siri/screen/login_screen.dart';
import 'package:siri/screen/new_customer.dart';
import 'package:siri/screen/new_order.dart';
import 'package:siri/screen/order_detail.dart';
import 'package:siri/screen/setting.dart';
import 'package:siri/screen/splash_screen.dart';
import 'package:siri/screen/track.dart';
import 'package:siri/screen/user_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Tailor Management App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppTheme.primary,
          scaffoldBackgroundColor: AppTheme.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppTheme.cardBackground,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
          ),
          textTheme: const TextTheme(
            headlineLarge: AppTheme.headingLarge,
            headlineMedium: AppTheme.headingMedium,
            bodyLarge: AppTheme.bodyLarge,
            bodyMedium: AppTheme.bodyRegular,
            bodySmall: AppTheme.bodySmall,
          ),
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            secondary: AppTheme.secondary,
            surface: AppTheme.cardBackground,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/new_customer': (context) => const NewCustomerScreen(),
          '/new_order': (context) => const NewOrderScreen(),
          '/bill': (context) => const BillScreen(),
          '/track': (context) => const TrackScreen(),
          '/order_detail': (context) => const OrderDetailScreen(),
          '/preset': (context) => const PresetScreen(),
          '/user_page': (context) => const UserPage(),
          '/customers': (context) => const NewCustomerScreen(),
          '/settings': (context) => const PresetScreen(),
        },
      ),
    );
  }
}
