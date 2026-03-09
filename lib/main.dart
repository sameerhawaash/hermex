import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/config/env.dart';
import 'core/widgets/customer_service_fab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase.
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  runApp(const ProviderScope(child: TayaRakApp()));
}

class TayaRakApp extends ConsumerWidget {
  const TayaRakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TayaRak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: const [
        // Add localization delegates here later
      ],
      supportedLocales: const [
        Locale('ar', 'EG'), // Default language is Arabic (Egypt)
        Locale('en', 'US'),
      ],
      builder: (context, child) {
        // Enforce RTL globally + inject the Customer Service FAB on all pages
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              child!,
              // Customer Service Fab — always visible on bottom-left corner
              Positioned(
                bottom: 24,
                left: 16,
                child: const CustomerServiceFab(),
              ),
            ],
          ),
        );
      },
    );
  }
}
