import 'dart:convert';
import 'dart:io';

import 'package:mustache_template/mustache.dart';

final partialRegex = RegExp("{{>(.*)}}");

class TemplateLoader {
  final _templateCache = <String, Template?>{};

  Future<(Template?, Map<String, Template?>)> _loadTemplate(String path) async {
    if (_templateCache[path] != null) {
      print('[INFO] Using cached template');
      return (_templateCache[path], <String, Template>{});
    }

    var template = StringBuffer();
    final resolver = <String, Template?>{};

    await File(path)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .asyncMap((line) async {
      if (partialRegex.hasMatch(line)) {
        for (final match in partialRegex.allMatches(line)) {
          if (match.groupCount < 1) {
            continue;
          }
          final partialName = match.group(1)!;

          final current = Uri.parse(path);
          final loadFile = [
            ...current.pathSegments.take(current.pathSegments.length - 1),
            '${partialName.replaceAll('.', Platform.pathSeparator)}.mustache'
          ].join(Platform.pathSeparator);

          if (loadFile == path) {
            continue;
          }
          final partial = await _loadTemplate(loadFile);
          resolver[partialName] = partial.$1;
          resolver.addAll(partial.$2);
        }
      }

      return line;
    }).forEach((line) {
      template.writeln(line);
    });

    final t = Template(
      template.toString(),
      lenient: false,
      partialResolver: (n) => resolver[n],
    );

    _templateCache[path] = t;

    return (t, resolver);
  }

  // Load a template.
  //
  // Recursively loads all partial child templates required by this template.
  Future<Template?> load(String path) async {
    return (await _loadTemplate(path)).$1;
  }
}
