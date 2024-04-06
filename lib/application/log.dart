class Log {
  static info(String message, [List<dynamic> params = const []]) {
    _write(message, (v) => '[INFO] $v', params);
  }

  static warn(String message, [List<dynamic> params = const []]) {
    _write(message, (v) => '\x1B[33m[WARN] $v\x1B[0m', params);
  }

  static error(String message, [List<dynamic> params = const []]) {
    _write(message, (v) => '\x1B[31m[ERROR] $v\x1B[0m', params);
  }

  static _write(
    String message,
    String Function(String v) interp, [
    List<dynamic> params = const [],
  ]) {
    final buf = StringBuffer(message);

    for (final param in params) {
      buf.write(', $param');
    }
    print(interp(buf.toString()));
  }
}
