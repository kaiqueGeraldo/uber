import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uber/firebase_options.dart';
import 'package:uber/src/pages/splash_screen_page.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print("Erro capturado: ${details.exception}");
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeData temaPadrao = ThemeData(
    primaryColor: AppColors.primaryColor,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.textColor,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    scaffoldBackgroundColor: AppColors.primaryColor,
    progressIndicatorTheme:
        ProgressIndicatorThemeData(color: AppColors.textColor),
    indicatorColor: AppColors.primaryColor,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.primaryColor,
      selectedItemColor: AppColors.textColor,
      unselectedItemColor: AppColors.secundarytextColor,
    ),
    textTheme: TextTheme(
      titleMedium: GoogleFonts.gothicA1(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        color: AppColors.textColor,
      ),
      titleSmall:
          GoogleFonts.inter(fontSize: 15, color: AppColors.secundaryColor),
    ),
  );

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // Método para solicitar permissões
  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      print("Permissão concedida!");
    } else if (status.isDenied) {
      print("Permissão negada.");
      _showPermissionAlert();
    } else if (status.isPermanentlyDenied) {
      print("Permissão negada permanentemente.");
      openAppSettings();
    }
  }

  // Alerta caso a permissão seja negada
  void _showPermissionAlert() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Permissão Necessária"),
          content: const Text(
              "Este app precisa de acesso à localização para funcionar corretamente."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
              child: const Text("Tentar novamente"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber',
      debugShowCheckedModeBanner: false,
      home: const SplashScreenPage(),
      theme: temaPadrao,
      initialRoute: '/',
      onGenerateRoute: Routes.generateRoutes,
    );
  }
}
