import 'schema.dart';

class SchemaUtils {
  static bool isEnum(OpenApiSchema schema) =>
      schema.enumValues?.isNotEmpty == true &&
      schema.type != 'object' &&
      !isReference(schema);
  static bool isConstrainedNumber(OpenApiSchema schema) =>
      schema is OpenApiNumericSchema &&
      (schema.multipleOf != null ||
          schema.exclusiveMaximum != null ||
          schema.exclusiveMinimum != null ||
          schema.maximum != null ||
          schema.minimum != null);
  static bool isPrimitive(OpenApiSchema schema) =>
      !isArray(schema) && !isObject(schema) && !isEnum(schema);
  static bool isArray(OpenApiSchema schema) => schema.type == 'array';
  static bool isObject(OpenApiSchema schema) => schema.type == 'object';
  static bool isReference(OpenApiSchema schema) =>
      schema is OpenApiReferenceSchema;
  static String referenceName(OpenApiReferenceSchema schema) =>
      schema.ref.substring(schema.ref.lastIndexOf('/') + 1);
}
