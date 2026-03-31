import 'package:flutter/material.dart';
import 'package:my_daily_plus/repositories/data_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final DataRepository repository;

  static DataRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.repository != repository;
}
