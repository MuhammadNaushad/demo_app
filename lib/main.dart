import 'package:flutter/material.dart';
import 'app_widgets.dart';
import 'places_screen.dart';

void main() {
  runApp(const PlacesApp());
}

class PlacesApp extends StatelessWidget {
  const PlacesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Places',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
        ),
      ),
      home: const PlacesScreen(),
    );
  }
}
