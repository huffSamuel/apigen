import '../../configurations/language_specific_configuration.dart';
import '../../domain/schemas/schema.dart';
import 'is.dart';

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
