// 📄 lib/utils/debug_log.dart

const bool kEnableDebugLog = true;

void debugLog(Object? message, {String level = 'DEBUG'}) {
  assert(() {
    if (kEnableDebugLog) {
      // ignore: avoid_print
      print('[$level] $message');
    }
    return true;
  }());
}
