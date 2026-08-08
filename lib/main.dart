import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:docflow/generated/app_localizations.dart';

import 'core/services/app_config_service.dart';
import 'presentation/providers/database_provider.dart';
import 'presentation/providers/theme_notifier.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/welcome_screen.dart';

void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('Usage: docflow [options]');
    stdout.writeln('Options:');
    stdout.writeln('  -v, --version    Shows the application version');
    stdout.writeln('  -h, --help       Display this help message');
    exit(0);
  }

  if (args.contains('--version') || args.contains('-v')) {
    try {
      stdout.writeln('DocFlow version 3.0.0');
    } catch (e) {
      stdout.writeln('DocFlow version unknown');
    }
    exit(0);
  }

  await runGui();
}

Future<void> runGui() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final configService = AppConfigService();
  final databaseProvider = DatabaseProvider(configService);

  await databaseProvider.tryAutoOpen();

  final lifecycleObserver = AppLifecycleObserver(databaseProvider);
  WidgetsBinding.instance.addObserver(lifecycleObserver);

  runApp(
    ChangeNotifierProvider.value(
      value: databaseProvider,
      child: const MyApp(),
    ),
  );
}

class AppLifecycleObserver extends WidgetsBindingObserver {
  final DatabaseProvider _databaseProvider;

  AppLifecycleObserver(this._databaseProvider);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _databaseProvider.themeNotifier; 
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.watch<DatabaseProvider>();

    if (dbProvider.status == DatabaseStatus.ready) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: dbProvider.themeNotifier!),
          ChangeNotifierProvider.value(value: dbProvider.localeProvider!),
          ChangeNotifierProvider.value(value: dbProvider.templateProvider!),
          ChangeNotifierProvider.value(value: dbProvider.changelogProvider!),
        ],
        child: Consumer2<ThemeNotifier, LocaleProvider>(
          builder: (context, themeNotifier, localeProvider, child) {
            return MaterialApp(
              title: 'DocFlow',
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: localeProvider.locale,
              localeResolutionCallback: (locale, supportedLocales) {
                if (locale == null) return const Locale('pt');
                for (var supported in supportedLocales) {
                  if (supported.languageCode == locale.languageCode) {
                    return supported;
                  }
                }
                return const Locale('pt');
              },
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorSchemeSeed: const Color(0xFF33691E),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorSchemeSeed: const Color(0xFF33691E),
              ),
              themeMode: themeNotifier.themeMode,
              home: const HomeScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      );
    }

    return MaterialApp(
      title: 'DocFlow',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF33691E),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF33691E),
      ),
      home: dbProvider.status == DatabaseStatus.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}