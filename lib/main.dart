import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app_data.dart';
import 'branding/brand_config.dart';
import 'home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/cows_screen.dart';
import 'services/firebase_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

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
    LocalGoshalaStore.instance.refreshRealtimeListeners();
    var syncAfterFirstFrame = false;
    if (FirebaseBackend.instance.isAvailable &&
        FirebaseBackend.instance.auth.currentUser != null) {
      final profile = await FirebaseBackend.instance.getCurrentUserProfile();
      if (profile != null && profile.canEditRecords) {
        syncAfterFirstFrame = true;
      }
    }
    runApp(const JayBholeGoshalaApp());
    if (syncAfterFirstFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_syncLocalDataInBackground());
      });
    }
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

Future<void> _syncLocalDataInBackground() async {
  try {
    await LocalGoshalaStore.instance.syncLocalDataToCloud();
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'JayBholeGoshala startup',
        context: ErrorDescription('Background cloud sync failed'),
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
  const JayBholeGoshalaApp({super.key, this.home});

  final Widget? home;

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
      onGenerateRoute: (settings) {
        var rawName = settings.name ?? '';
        if (kIsWeb && (rawName.isEmpty || rawName == '/')) {
          final webBase = Uri.base;
          if (webBase.path == '/cow' ||
              webBase.path == '/cows' ||
              webBase.fragment.contains('/cow')) {
            rawName = '${webBase.path}?${webBase.query}';
            if (webBase.hasFragment) {
              rawName += '#${webBase.fragment}';
            }
          }
        }
        final uri = Uri.tryParse(rawName);
        if (uri != null) {
          final isCowPath = uri.path == '/cow' ||
              uri.path == '/cows' ||
              uri.fragment.contains('/cow');
          if (isCowPath) {
            var cowId = uri.queryParameters['id'] ??
                (uri.pathSegments.length > 1 ? uri.pathSegments[1] : null);
            if (cowId == null && uri.hasFragment) {
              final fragUri = Uri.tryParse(
                uri.fragment.startsWith('/')
                    ? uri.fragment
                    : '/${uri.fragment}',
              );
              cowId = fragUri?.queryParameters['id'] ??
                  ((fragUri?.pathSegments.length ?? 0) > 1
                      ? fragUri?.pathSegments[1]
                      : null);
            }
            if (cowId != null && cowId.isNotEmpty) {
              return MaterialPageRoute(
                builder: (_) => CowDetailScreen(cowId: cowId),
                settings: settings,
              );
            }
          }
        }
        return null;
      },
      home: home ?? const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      initialData: FirebaseBackend.instance.isAvailable
          ? FirebaseBackend.instance.auth.currentUser
          : null,
      stream: FirebaseBackend.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
