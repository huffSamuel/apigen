// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenApiReferenceSchema _$OpenApiReferenceSchemaFromJson(
        Map<String, dynamic> json) =>
    OpenApiReferenceSchema(
      ref: json[r'$ref'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      deprecated: json['deprecated'] as bool?,
      readOnly: json['readOnly'] as bool?,
      writeOnly: json['writeOnly'] as bool?,
      comment: json[r'$comment'] as String?,
      enumValues: json['enum'] as List<dynamic>? ?? [],
      constValue: json['const'],
    );

OpenApiStringSchema _$OpenApiStringSchemaFromJson(Map<String, dynamic> json) =>
    OpenApiStringSchema(
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      format: json['format'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      deprecated: json['deprecated'] as bool?,
      readOnly: json['readOnly'] as bool?,
      writeOnly: json['writeOnly'] as bool?,
      comment: json[r'$comment'] as String?,
      enumValues: json['enum'] as List<dynamic>? ?? [],
      constValue: json['const'],
    );

OpenApiIntegerSchema _$OpenApiIntegerSchemaFromJson(
        Map<String, dynamic> json) =>
    OpenApiIntegerSchema(
      multipleOf: json['multipleOf'] as int?,
      minimum: json['minimum'] as int?,
      exclusiveMinimum: json['exclusiveMinimum'] as int?,
      maximum: json['maximum'] as int?,
      exclusiveMaximum: json['exclusiveMaximum'] as int?,
      title: json['title'] as String?,
      type: json['type'] as String?,
      deprecated: json['deprecated'] as bool?,
      readOnly: json['readOnly'] as bool?,
      writeOnly: json['writeOnly'] as bool?,
      comment: json[r'$comment'] as String?,
      enumValues: json['enum'] as List<dynamic>? ?? [],
      constValue: json['const'],
      description: json['description'] as String?,
    );

OpenApiNumberSchema _$OpenApiNumberSchemaFromJson(Map<String, dynamic> json) =>
    OpenApiNumberSchema(
      multipleOf: json['multipleOf'] as int?,
      minimum: json['minimum'] as int?,
      exclusiveMinimum: json['exclusiveMinimum'] as int?,
      maximum: json['maximum'] as int?,
      exclusiveMaximum: json['exclusiveMaximum'] as int?,
      title: json['title'] as String?,
      type: json['type'] as String?,
      deprecated: json['deprecated'] as bool?,
      readOnly: json['readOnly'] as bool?,
      writeOnly: json['writeOnly'] as bool?,
      comment: json[r'$comment'] as String?,
      enumValues: json['enum'] as List<dynamic>? ?? [],
      constValue: json['const'],
      description: json['description'] as String?,
    );

OpenApiObjectSchema _$OpenApiObjectSchemaFromJson(Map<String, dynamic> json) =>
    OpenApiObjectSchema(
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, OpenApiSchema.fromJson(e as Map<String, dynamic>)),
          ) ??
          {},
      required: (json['required'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      patternProperties: (json['patternProperties'] as Map<String, dynamic>?)
              ?.map(
            (k, e) =>
                MapEntry(k, OpenApiSchema.fromJson(e as Map<String, dynamic>)),
          ) ??
          {},
      additionalProperties: json['additionalProperties'] as bool?,
      title: json['title'] as String?,
      type: json['type'] as String?,
      deprecated: json['deprecated'] as bool?,
      readOnly: json['readOnly'] as bool?,
      writeOnly: json['writeOnly'] as bool?,
      comment: json[r'$comment'] as String?,
      enumValues: json['enum'] as List<dynamic>? ?? [],
      constValue: json['const'],
      description: json['description'] as String?,
    );

OpenApiArraySchema _$OpenApiArraySchemaFromJson(Map<String, dynamic> json) =>
    OpenApiArraySchema(
      items: OpenApiArraySchema._itemsFromJson(
          json['items'] as Map<String, dynamic>?),
      prefixItems: (json['prefixItems'] as List<dynamic>?)
          ?.map((e) => OpenApiSchema.fromJson(e as Map<String, dynamic>))
          .toList(),
      contains: json['contains'] == null
          ? null
          : OpenApiSchema.fromJson(json['contains'] as Map<String, dynamic>),
      minContains: json['minContains'] as int?,
      maxContains: json['maxContains'] as int?,
      minItems: json['minItems'] as int?,
      maxItems: json['maxItems'] as int?,
      uniqueItems: json['uniqueItems'] as bool?,
      title: json['title'] as String?,
      type: json['type'] as String?,
      deprecated: json['deprecated'] as bool?,
      readOnly: json['readOnly'] as bool?,
      writeOnly: json['writeOnly'] as bool?,
      comment: json[r'$comment'] as String?,
      enumValues: json['enum'] as List<dynamic>? ?? [],
      constValue: json['const'],
      description: json['description'] as String?,
    );

OpenApiBooleanSchema _$OpenApiBooleanSchemaFromJson(
        Map<String, dynamic> json) =>
    OpenApiBooleanSchema(
      title: json['title'] as String?,
      type: json['type'] as String?,
      deprecated: json['deprecated'] as bool?,
      readOnly: json['readOnly'] as bool?,
      writeOnly: json['writeOnly'] as bool?,
      comment: json[r'$comment'] as String?,
      enumValues: json['enum'] as List<dynamic>? ?? [],
      constValue: json['const'],
      description: json['description'] as String?,
    );

OpenApiNullSchema _$OpenApiNullSchemaFromJson(Map<String, dynamic> json) =>
    OpenApiNullSchema(
      title: json['title'] as String?,
      type: json['type'] as String?,
      deprecated: json['deprecated'] as bool?,
      readOnly: json['readOnly'] as bool?,
      writeOnly: json['writeOnly'] as bool?,
      comment: json[r'$comment'] as String?,
      enumValues: json['enum'] as List<dynamic>? ?? [],
      constValue: json['const'],
      description: json['description'] as String?,
    );
