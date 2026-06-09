import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_wrapper.dart';
import 'services/cart_provider.dart';
import 'screens/splash_screen.dart'; // 👈 importar el splash

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
      ],
      child: const MiAppModa(),
    ),
  );
}

class MiAppModa extends StatelessWidget {
  const MiAppModa({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ✅ solo una vez
      title: 'Hub Moda Urbana',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        inputDecorationTheme: const InputDecorationTheme(
          // ...
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          // ...
        ),
      ),
      home: const SplashScreen(), // ✅ solo un home: el splash navega a MainWrapper
    );
  }
}