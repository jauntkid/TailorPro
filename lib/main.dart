import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/store.dart';
import 'services/auth_service.dart';
import 'services/store_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/store_setup_screen.dart';
import 'theme/app_theme.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  runApp(const GodukaanApp());
}

class GodukaanApp extends StatefulWidget {
  const GodukaanApp({super.key});

  @override
  State<GodukaanApp> createState() => _GodukaanAppState();
}

/// App states:
/// 1. loading → splash
/// 2. no user → login screen
/// 3. user but no store → store setup screen
/// 4. user + store → main app
class _GodukaanAppState extends State<GodukaanApp> {
  final _authService = AuthService();
  final _storeService = StoreService();
  DataService? _dataService;
  bool _loading = true;
  bool _needsStore = false;
  User? _currentUser;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = _authService.authStateChanges.listen(_handleAuthChange);
  }

  Future<void> _handleAuthChange(User? user) async {
    if (user != null) {
      _currentUser = user;
      // Check if user has a linked store
      final storeId = await _storeService.getUserStoreId(user.uid);
      if (storeId != null) {
        // Validate store exists and user is still allowed
        final store = await _storeService.getStore(storeId);
        if (store != null && store.isAllowed(user.email ?? '')) {
          await _initDataService(storeId);
          return;
        }
      }
      // No store or invalid store — show store setup
      if (mounted) {
        setState(() {
          _needsStore = true;
          _loading = false;
        });
      }
    } else {
      _currentUser = null;
      NotificationService.instance.detach();
      _dataService?.dispose();
      if (mounted) {
        setState(() {
          _dataService = null;
          _needsStore = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _initDataService(String storeId) async {
    _dataService?.dispose();
    final ds = DataService(storeId: storeId);
    await ds.init();
    NotificationService.instance.attach(ds);
    if (mounted) {
      setState(() {
        _dataService = ds;
        _needsStore = false;
        _loading = false;
      });
    }
  }

  void _onStoreReady(Store store) {
    _initDataService(store.id);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _dataService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _SplashView(),
      );
    }

    if (_currentUser == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: LoginScreen(authService: _authService),
        builder: (context, child) => GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
      );
    }

    if (_needsStore) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: StoreSetupScreen(
          uid: _currentUser!.uid,
          email: _currentUser!.email ?? '',
          displayName: _currentUser!.displayName ?? 'User',
          onStoreReady: _onStoreReady,
          onSignOut: () async {
            await _authService.signOut();
          },
        ),
        builder: (context, child) => GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _dataService!,
      child: Consumer<DataService>(
        builder: (_, ds, __) => MaterialApp(
          title: 'Godukaan',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ds.themeMode,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: '/',
          builder: (context, child) => GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child:
                  Image.asset('assets/images/logo.png', width: 80, height: 80),
            ),
            const SizedBox(height: 16),
            const Text(
              'GODUKAAN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
                color: Color(0xFFD4A574),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD4A574),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
