import 'package:flutter/material.dart';
import 'package:siri/config/theme.dart';
import 'package:siri/screen/bill.dart';
import 'package:siri/screen/home.dart';
import 'package:siri/screen/new_customer.dart';
import 'package:siri/screen/new_order.dart';
import 'package:siri/screen/order_detail.dart';
import 'package:siri/screen/setting.dart';
import 'package:siri/screen/track.dart';
import 'package:siri/screen/user_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailor Management App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primary,
        scaffoldBackgroundColor: AppTheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.cardBackground,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        textTheme: TextTheme(
          headlineLarge: AppTheme.headingLarge,
          headlineMedium: AppTheme.headingMedium,
          bodyLarge: AppTheme.bodyLarge,
          bodyMedium: AppTheme.bodyRegular,
          bodySmall: AppTheme.bodySmall,
        ),
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          background: AppTheme.background,
          surface: AppTheme.cardBackground,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: AppTheme.textPrimary,
          onSurface: AppTheme.textPrimary,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/new_customer': (context) => NewCustomerScreen(),
        '/new_order': (context) => NewOrderScreen(),
        '/bill': (context) => BillScreen(),
        '/track': (context) => TrackScreen(),
        '/order_detail': (context) => OrderDetailScreen(),
        '/preset': (context) => PresetScreen(),
        '/user_page': (context) => UserPage(),
      },
    );
  }
}
