import 'package:apigen_cli/application/log.dart';

import '../domain/schemas/schema.dart';

enum Feature {
  allOf('allOf'),
  anyOf('anyOf'),
  oneOf('oneOf');

  const Feature(this.name);

  final String name;
}

Feature? compositeTypeFeature(Schema? schema) {
  if (schema == null) {
    Log.warn("Schema is null");
    return null;
  }

  if (schema is! CompositeSchema) {
    Log.warn("Schema is not a composite schema");
    return null;
  }

  if (schema is OneOfSchema) {
    return Feature.oneOf;
  }

  if (schema is AnyOfSchema) {
    return Feature.anyOf;
  }

  if (schema is AllOfSchema) {
    return Feature.allOf;
  }

  return null;
}
