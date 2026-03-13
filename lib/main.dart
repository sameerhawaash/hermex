import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/config/env.dart';
import 'core/widgets/customer_service_fab.dart';
import 'core/providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase.
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'), // Default language
        child: const TayaRakApp(),
      ),
    ),
  );
}

class TayaRakApp extends ConsumerWidget {
  const TayaRakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentLocale = ref.watch(localeProvider);

    // Sync EasyLocalization with Riverpod provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.locale.languageCode != currentLocale.languageCode) {
        context.setLocale(currentLocale);
      }
    });

    return MaterialApp.router(
      title: 'Forrira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: currentLocale,
      builder: (context, child) {
        // Enforce RTL/LTR dynamically based on the current locale
        return Directionality(
          textDirection: currentLocale.languageCode == 'ar'
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: Stack(
            children: [
              child!,
              // Customer Service Fab — always visible on bottom corner based on direction
              Positioned(
                bottom: 24,
                left: currentLocale.languageCode == 'ar' ? 16 : null,
                right: currentLocale.languageCode == 'ar' ? null : 16,
                child: const CustomerServiceFab(),
              ),
            ],
          ),
        );
      },
    );
  }
}
