import 'package:flutter/material.dart';
import 'qr_scanner.dart';
import 'welcome_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 199, 23, 23),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
          ),
        ),
      ),
      home: const WelcomePage(),
      routes: {
        '/home': (context) => const WelcomePage(),
        '/scanner': (context) => const QrScanner(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/scanner':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const QrScanner(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          default:
            return null;
        }
      },
    );
  }
}
