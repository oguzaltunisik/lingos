import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lingos/pages/gate_page.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/term_service.dart';
import 'package:lingos/services/user_prefs_service.dart';
import 'package:lingos/services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.initializeAppLanguage();
  await TermService.loadTerms();
  await UserPrefsService.init();
  await TtsService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen to language changes
    LanguageService.appLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageService.appLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {
      // Rebuild when language changes
    });
  }

  Locale get _locale {
    return Locale(LanguageService.appLanguageNotifier.value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lingos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          clipBehavior: Clip.hardEdge,
          elevation: 3,
        ),
        appBarTheme: const AppBarTheme(
          actionsPadding: EdgeInsets.only(right: 16),
          centerTitle: false,
        ),
      ),
      locale: _locale,
      supportedLocales: const [
        Locale('tr', ''),
        Locale('en', ''),
        Locale('fi', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const GatePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
