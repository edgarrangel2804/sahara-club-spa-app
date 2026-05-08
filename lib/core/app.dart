import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sahara_club_spa_app/core/locale_cubit.dart';
import 'package:sahara_club_spa_app/core/router.dart';
import 'package:sahara_club_spa_app/core/theme.dart';

final saharaNavigatorKey = GlobalKey<NavigatorState>();

class SaharaApp extends StatelessWidget {
  const SaharaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp(
          title: 'Sahara Club',
          debugShowCheckedModeBanner: false,
          navigatorKey: saharaNavigatorKey,
          theme: SaharaTheme.theme,
          locale: locale,
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          onGenerateRoute: onGenerateRoute,
          initialRoute: AppRoutes.splash,
        );
      },
    );
  }
}
