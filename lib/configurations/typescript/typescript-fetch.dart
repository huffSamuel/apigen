import '../../application/utils/casing.dart';
import '../../application/utils/name.dart';
import '../../domain/schemas/schema.dart';
import '../language_specific_configuration.dart';

class TypescriptOptions {
  bool installDependencies = false;
  bool formatCode = false;
}

class TypescriptFetch extends GenerateConfig {
  @override
  String get name => 'typescript-fetch';

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

  @override
  String arrayType(String name) {
    return '$name[]';
  }

  @override
  String typename({String? name, Schema? schema}) {
    if (name != null) {
      return typeName(name);
    }

    if (schema == null) {
      return anyType();
    }

    switch (schema) {
      case final OpenApiReferenceSchema ref:
        return typeName(referenceName(ref));
      case final OpenApiArraySchema ray:
        return arrayType(typename(schema: ray.items!.a!));
      case final CompositeSchema composite:
        String separator = (composite is AllOfSchema) ? '&' : '|';
        return composite.schemas
            .map((x) => typename(schema: x))
            .join(separator);
      default:
        return anyType();
    }
  }
}
