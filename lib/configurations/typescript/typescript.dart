import 'package:apigen_cli/domain/schemas/schema.dart';

import '../../application/feature.dart';
import '../../application/utils/casing.dart';
import '../language_specific_configuration.dart';

// TODO: CLI Options
// [] - install dependencies
// [] - format code (must install dependencies or have prettier available)

class TypescriptConfiguration extends LanguageSpecificConfiguration {
  @override
  List<Feature> supportedFeatures = [
    Feature.allOf,
    Feature.oneOf,
  ];

  @override
  String get configurationName => 'Typescript';

  // TODO: Add DateTime support
  @override
  Map<String, String> get typeMap => {
        'string': 'string',
        'integer': 'number',
      };

  @override
  String anyType() {
    return 'any';
  }

  @override
  String className(String name) {
    return typeName(firstUpper(name));
  }

  @override
  String propertyName(String name) {
    return firstLower(name);
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

    return firstUpper(name);
  }

  @override
  List<String> get reservedWords => ['yield', 'object'];

  @override
  String methodName(String name) {
    return camelCase(name.split('-'));
  }
}
