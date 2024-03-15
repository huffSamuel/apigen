import '../language_specific_configuration.dart';

String camelCase(List<String> parts) {
  return parts
      .skip(1)
      .fold(parts[0], (a, b) => a + b[0].toUpperCase() + b.substring(1));
}

class TypescriptConfiguration extends LanguageSpecificConfiguration {
  @override
  String get configurationName => 'Typescript';

  @override
  Map<String, String> get typeMap => {
        'string': 'string',
        'integer': 'number',
      };

  @override
  String className(String name) {
    return typeName(name[0].toUpperCase() + name.substring(1));
  }

  @override
  String propertyName(String name) {
    return name[0].toLowerCase() + name.substring(1);
  }

  @override
  String fileName(String name) {
    return propertyName(name);
  }

  @override
  String enumValueName(String name) {
    final parts = name.toLowerCase().split('_');

    if (parts.length == 1) {
      return parts[0];
    }

    return camelCase(parts);
  }

  @override
  String typeName(String name) {
    if (reservedWords.contains(name)) {
      return '_$name';
    }

    if (typeMap.containsKey(name)) {
      return typeMap[name]!;
    }

    return name;
  }

  @override
  List<String> get reservedWords => ['yield'];
}