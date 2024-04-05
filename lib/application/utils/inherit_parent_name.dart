import '../../configurations/language_specific_configuration.dart';
import '../../schemas/schema.dart';

String nestedTypeName(
  String parentName,
  String name,
  OpenApiSchema schema,
  LanguageSpecificConfiguration config,
) {
  if (isObject(schema) ||
      isEnum(schema) ||
      (schema is OpenApiArraySchema &&
          (isObject(schema.items?.a) || isEnum(schema.items?.a)))) {
    return config.className(parentName) + config.className(name);
  }

  return config.className(name);
}

bool isObject(OpenApiSchema? s) => s is OpenApiObjectSchema;
bool isEnum(OpenApiSchema? s) => s?.enumValues?.isEmpty == false;
