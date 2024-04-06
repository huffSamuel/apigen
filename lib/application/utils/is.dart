import '../../domain/schemas/schema.dart';

bool isEnum(Schema? schema) {
  return schema is OpenApiSchema && schema.enumValues?.isEmpty == false;
}

bool isArray(Schema? schema) {
  return schema is OpenApiArraySchema;
}

bool isObject(Schema? schema) {
  return schema is OpenApiObjectSchema;
}

bool isDerivedType(Schema? schema) {
  bool fn(Schema? s) => isArray(s) || isEnum(s);

  if (fn(schema)) {
    return true;
  }

  if (isArray(schema) && schema is OpenApiArraySchema && fn(schema.items!.a)) {}

  return fn(schema) ||
      (isArray(schema) && fn((schema as OpenApiArraySchema).items!.a));
}
