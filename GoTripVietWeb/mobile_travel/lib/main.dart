import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 1. IMPORT THIS

// Import ViewModels
import 'features/home/view_models/home_view_model.dart';
import 'features/auth/view_models/auth_view_model.dart';
import 'features/product/view_models/product_view_model.dart'; // 2. IMPORT THIS
import 'features/profile/view_models/profile_view_model.dart';
// Import Screens
import 'features/auth/views/screens/login_screen.dart';
import 'features/home/views/screens/home_screen.dart'; // 3. IMPORT THIS

import 'features/booking/view_models/booking_view_model.dart';
import 'features/payment/view_models/payment_view_model.dart';  

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()..checkLoginStatus()),
        ChangeNotifierProvider(create: (_) => ProductViewModel()),
        ChangeNotifierProvider(create: (_) => BookingViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GoTripViet',
        theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
        
        // 5. ADD LOCALIZATION DELEGATES (Fixes DateFormat error)
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi', 'VN')],

        // 6. RESTORE AUTH LOGIC (Home vs Login)
        home: Consumer<AuthViewModel>(
          builder: (context, auth, _) {
            // While checking for token...
            if (auth.isLoading) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            
            // If logged in -> Home, else -> Login
            return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}