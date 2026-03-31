import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// На Windows / Linux / macOS sqflite использует FFI; на Android / iOS — встроенная реализация.
Future<void> configureSqfliteForDesktop() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
