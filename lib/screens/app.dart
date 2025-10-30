import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../provider/font_provider.dart';
import '../provider/theme_provider.dart';
import '../provider/contrast_provider.dart';
import 'splash/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fontScale = context.watch<FontScaleProvider>().scale;
    final themeProvider = context.watch<ThemeProvider>();
    final contrastProvider = context.watch<ContrastProvider>();

    if (!themeProvider.isInitialized || !contrastProvider.isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MauFarm',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontScale),
          ),
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_contrastMatrix(contrastProvider.contrast)),
            child: child!,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }

  List<double> _contrastMatrix(double c) {
    return [
      c, 0, 0, 0, 0,
      0, c, 0, 0, 0,
      0, 0, c, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
