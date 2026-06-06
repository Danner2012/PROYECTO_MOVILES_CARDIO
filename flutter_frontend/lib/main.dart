import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Tus Providers ---
import 'features/auth/logic/auth_provider.dart';
import 'features/dashboard/logic/menu_app_controller.dart';
import 'features/ia_prediction/logic/prediction_provider.dart';
import 'features/dashboard/logic/doctor_provider.dart';
import 'features/ollama/logic/ollama_provider.dart';
import 'features/pacientes/logic/pacientes_provider.dart'; // ¡Añadido!


// --- Tus Pantallas ---
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/main/main_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

// --- Otros ---
import 'core/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuAppController()),
        ChangeNotifierProvider(create: (_) => IaPredictionProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => OllamaProvider()),
        ChangeNotifierProvider(create: (_) => PacientesProvider()), // ¡Provider integrado!
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cardio Project',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => MainScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthProvider>();
    await auth.loadUser();
    if (mounted) {
      if (auth.user != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
