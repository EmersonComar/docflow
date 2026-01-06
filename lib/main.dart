import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:docflow/generated/app_localizations.dart';

import 'data/datasources/local_database.dart';
import 'data/repositories/template_repository_impl.dart';
import 'presentation/providers/template_provider.dart';
import 'presentation/providers/theme_notifier.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/changelog_provider.dart';
import 'presentation/screens/home_screen.dart';

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
      stdout.writeln('DocFlow version 1.3.5');
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

  final database = LocalDatabase();
  final templateRepository = TemplateRepositoryImpl(database);

  // Adiciona o observador do ciclo de vida.
  final lifecycleObserver = AppLifecycleObserver(database);
  WidgetsBinding.instance.addObserver(lifecycleObserver);

  final themeNotifier = ThemeNotifier(database);
  await themeNotifier.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider(create: (_) => LocaleProvider(database)),
        ChangeNotifierProvider(
          create: (_) => TemplateProvider(templateRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ChangelogProvider(database)..load(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
class AppLifecycleObserver extends WidgetsBindingObserver {
  final LocalDatabase _database;

  AppLifecycleObserver(this._database);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _database.close();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeNotifier, LocaleProvider>(
      builder: (context, themeNotifier, localeProvider, child) {
        return MaterialApp(
          title: 'DocFlow',
          // Localization setup
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: localeProvider.locale,
          localeResolutionCallback: (locale, supportedLocales) {
            // Default to Portuguese when detection fails
            if (locale == null) return const Locale('pt');
            for (var supported in supportedLocales) {
              if (supported.languageCode == locale.languageCode) return supported;
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
    );
  }
}