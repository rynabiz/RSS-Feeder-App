import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/ad_service.dart';
import 'services/rss_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await AdService.init();
  }

  // Set preferred orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RssService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const RequestApp(),
    ),
  );
}

class RequestApp extends StatelessWidget {
  const RequestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Consume ThemeService
    final themeService = Provider.of<ThemeService>(context);
    final theme = themeService.currentTheme;

    return MaterialApp(
      title: 'RSS Feed Reader',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('hi', 'IN'), // Hindi
        Locale('bn', 'IN'), // Bengali
        Locale('ta', 'IN'), // Tamil
        Locale('te', 'IN'), // Telugu
        Locale('mr', 'IN'), // Marathi
        Locale('gu', 'IN'), // Gujarati
        Locale('kn', 'IN'), // Kannada
        Locale('ml', 'IN'), // Malayalam
        Locale('pa', 'IN'), // Punjabi
        Locale('or', 'IN'), // Odia
        Locale('as', 'IN'), // Assamese
        Locale('ur', 'IN'), // Urdu
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        primaryColor: theme.accentColor,
        scaffoldBackgroundColor: theme.baseColor,
        cardColor: theme.surfaceColor, // Use surface color for cards
        // Define IconTheme to match text color
        iconTheme: IconThemeData(color: theme.textColor),
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.accentColor, // Use accent as seed
          background: theme.baseColor,
          surface: theme.surfaceColor,
          secondary: theme.secondaryAccentColor, // Use secondary accent
          brightness: theme.isDark ? Brightness.dark : Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.textColor,
          elevation: 0,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: theme.textColor),
          bodyMedium: TextStyle(color: theme.textColor),
          titleLarge: TextStyle(color: theme.textColor),
          titleMedium: TextStyle(color: theme.textColor),
          titleSmall: TextStyle(color: theme.textColor),
          displayLarge: TextStyle(color: theme.textColor),
          displayMedium: TextStyle(color: theme.textColor),
          displaySmall: TextStyle(color: theme.textColor),
          labelLarge: TextStyle(color: theme.textColor),
          labelMedium: TextStyle(color: theme.textColor),
          labelSmall: TextStyle(color: theme.textColor),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
