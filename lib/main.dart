import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_daily_plus/app_scope.dart';
import 'package:my_daily_plus/database/database_helper.dart';
import 'package:my_daily_plus/repositories/data_repository.dart';
import 'package:my_daily_plus/screens/home_shell.dart';
import 'package:my_daily_plus/services/notification_service.dart';
import 'package:my_daily_plus/sqflite_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureSqfliteForDesktop();
  await initializeDateFormatting('ru');
  final repo = DataRepository(DatabaseHelper.instance);
  await DatabaseHelper.instance.database;
  await NotificationService.instance.init();
  await NotificationService.instance.rescheduleAllFromRepository(repo);

  runApp(MyDailyPlusApp(repository: repo));
}

class MyDailyPlusApp extends StatelessWidget {
  const MyDailyPlusApp({super.key, required this.repository});

  final DataRepository repository;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      child: MaterialApp(
        title: 'Мой Ежедневник+',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF90CAF9),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}
