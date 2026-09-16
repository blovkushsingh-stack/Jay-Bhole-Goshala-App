import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app_data.dart';
import 'branding/brand_config.dart';
import 'services/firebase_backend.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrintStack(stackTrace: details.stack ?? StackTrace.current);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'JayBholeGoshala startup',
        context: ErrorDescription('Unhandled app startup exception'),
      ),
    );
    return true;
  };

  try {
    await LocalGoshalaStore.instance.initialize();
    await FirebaseBackend.instance.initialize();
    if (FirebaseBackend.instance.isAvailable &&
        FirebaseBackend.instance.auth.currentUser != null) {
      final profile = await FirebaseBackend.instance.getCurrentUserProfile();
      if (profile != null && !profile.isActive) {
        await FirebaseBackend.instance.signOut();
      } else if (profile != null && profile.canEditRecords) {
        await LocalGoshalaStore.instance.syncLocalDataToCloud();
      }
    }
    runApp(const JayBholeGoshalaApp());
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'JayBholeGoshala startup',
        context: ErrorDescription('Failed to initialize app startup state'),
      ),
    );
    runApp(
      MaterialApp(
        title: BrandConfig.committeeName,
        debugShowCheckedModeBanner: false,
        home: StartupErrorScreen(message: error.toString()),
      ),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandConfig.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'App initialization failed',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(message, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JayBholeGoshalaApp extends StatelessWidget {
  const JayBholeGoshalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: BrandConfig.committeeName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandConfig.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: BrandConfig.cream,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: BrandConfig.border),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
