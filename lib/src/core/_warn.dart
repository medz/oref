import 'dart:developer' as developer show log;
import 'package:flutter/foundation.dart' show kDebugMode;

void warn(String message) {
  if (kDebugMode) {
    developer.log(message, name: '[Oref warn]', level: 900);
  }
}
