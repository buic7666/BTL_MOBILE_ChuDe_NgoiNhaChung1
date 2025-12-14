import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'features/house_setup/home_screen.dart';
import 'models/user_profile_house_ext.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  await UserProfileHouseExt.initializeFromStorage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BTL House',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accentBlue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home:
          const HomeScreen(), // Main welcome screen with Login/Register actions
    );
  }
}
