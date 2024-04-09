import '../../configurations/language_specific_configuration.dart';
import '../../domain/schemas/schema.dart';
import 'casing.dart';
import 'is.dart';

String referenceName(OpenApiReferenceSchema ref) {
  return ref.ref.substring(ref.ref.lastIndexOf('/') + 1);
}

String operationName(String id, LanguageSpecificConfiguration c) {
  // TODO: This really needs to split on invalidLanguageNameChars
  final parts = camelCase(id.split('-'));

  return c.methodName(parts);
}

String nestedTypeName(
  String parentName,
  String name,
  OpenApiSchema schema,
  LanguageSpecificConfiguration config,
) {
  if (isDerivedType(schema)) {
    return config.className(parentName) + config.className(name);
  }

  return config.className(name);
}
