import '../../configurations/language_specific_configuration.dart';
import '../../domain/schemas/schema.dart';
import 'casing.dart';

String referenceName(OpenApiReferenceSchema ref) {
  return ref.ref.substring(ref.ref.lastIndexOf('/') + 1);
}

String operationName(String id, LanguageSpecificConfiguration c) {
  // TODO: This really needs to split on invalidLanguageNameChars
  final parts = camelCase(id.split('-'));

  return c.methodName(parts);
}
