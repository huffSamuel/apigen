class Log {
  static info(String message, [List<dynamic> params = const []]) {
    final buf = StringBuffer(message);

    for (final param in params) {
      buf.write(', $param');
    }

    print('[INFO] ${buf.toString()}');
  }

  static warn(String message, [List<dynamic> params = const []]) {
    final buf = StringBuffer(message);

    for (final param in params) {
      buf.write(', $param');
    }

    print('\x1B[33m[WARN] ${buf.toString()}\x1B[0m');
  }

  static error(String message, [List<dynamic> params = const []]) {
    final buf = StringBuffer(message);

    for (final param in params) {
      buf.write(', $param');
    }

    print('\x1B[31m[ERROR] ${buf.toString()}\x1B[0m');
  }
}
