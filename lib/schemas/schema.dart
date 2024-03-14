import 'package:json_annotation/json_annotation.dart';

import 'helpers.dart';

part 'schema.g.dart';

typedef JsonMap = Map<String, dynamic>;

class SchemaTypes {
  static const stringType = 'string';
  static const number = 'number';
  static const integer = 'integer';
  static const object = 'object';
  static const array = 'array';
  static const boolean = 'boolean';
  static const nullType = 'null';
}

abstract class OpenApiSchema {
  /// A short description of the purpose of the data described by the schema.
  final String? title;

  /// A more lengthy explanation of the purpose of the data described by the schema.
  final String? description;
  final String? type;

  /// Indicates that the instance value should not be used and may be removed in the future.
  final bool? deprecated;

  /// Indicates that a value should not be modified.
  ///
  /// It could be used to indicate that a `PUT` request that changes a value
  /// would result in a `400 Bad Request` response.
  final bool? readOnly;

  /// Indicates that a value may be set, but will remain hidden.
  ///
  /// It could be used to indicate you can set a value with a `PUT` request, but it would not be included
  /// when retrieving that record with a `GET` request.
  final bool? writeOnly;

  /// Strictly intended for adding comments to a schema.
  @JsonKey(name: '\$comment')
  final String? comment;

  /// Restrict a value to a fixed set of values.
  ///
  /// If provided, it must be an array with at least one element, where each element is unique.
  @JsonKey(name: 'enum', defaultValue: [])
  final List<dynamic>? enumValues;

  /// Restrict a value to a single value.
  @JsonKey(name: 'const')
  final dynamic constValue;

  OpenApiSchema({
    this.title,
    this.description,
    this.type,
    this.deprecated,
    this.readOnly,
    this.writeOnly,
    this.comment,
    this.enumValues,
    this.constValue,
  });

  factory OpenApiSchema.fromJson(JsonMap json) {
    switch (json['type']) {
      case SchemaTypes.stringType:
        return OpenApiStringSchema.fromJson(json);
      case SchemaTypes.number:
        return OpenApiNumberSchema.fromJson(json);
      case SchemaTypes.integer:
        return OpenApiIntegerSchema.fromJson(json);
      case SchemaTypes.object:
        return OpenApiObjectSchema.fromJson(json);
      case SchemaTypes.array:
        return OpenApiArraySchema.fromJson(json);
      case SchemaTypes.boolean:
        return OpenApiBooleanSchema.fromJson(json);
      case SchemaTypes.nullType:
        return OpenApiNullSchema.fromJson(json);

      default:
        if (json['\$ref'] != null) {
          return OpenApiReferenceSchema.fromJson(json);
        }

        print('[ERROR]: Unsupported type ${json['type']}');
        throw 'Unsupported type ${json['type']}';
    }
  }
}

@JsonSerializable()
class OpenApiReferenceSchema extends OpenApiSchema {
  @JsonKey(name: '\$ref')
  final String ref;

  OpenApiReferenceSchema({
    required this.ref,
    super.title,
    super.description,
    super.type,
    super.deprecated,
    super.readOnly,
    super.writeOnly,
    super.comment,
    super.enumValues,
    super.constValue,
  });

  factory OpenApiReferenceSchema.fromJson(Map<String, dynamic> json) =>
      _$OpenApiReferenceSchemaFromJson(json);
}

@JsonSerializable()
class OpenApiStringSchema extends OpenApiSchema {
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final String? format;

  OpenApiStringSchema({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.format,
    super.title,
    super.description,
    super.type,
    super.deprecated,
    super.readOnly,
    super.writeOnly,
    super.comment,
    super.enumValues,
    super.constValue,
  });

  factory OpenApiStringSchema.fromJson(Map<String, dynamic> json) =>
      _$OpenApiStringSchemaFromJson(json);
}

abstract class OpenApiNumericSchema<T> extends OpenApiSchema {
  final int? multipleOf;
  final T? minimum;
  final T? exclusiveMinimum;
  final T? maximum;
  final T? exclusiveMaximum;

  OpenApiNumericSchema({
    this.multipleOf,
    this.minimum,
    this.exclusiveMinimum,
    this.maximum,
    this.exclusiveMaximum,
    super.title,
    super.type,
    super.deprecated,
    super.readOnly,
    super.writeOnly,
    super.comment,
    super.enumValues,
    super.constValue,
  });
}

@JsonSerializable()
class OpenApiIntegerSchema extends OpenApiNumericSchema<int> {
  OpenApiIntegerSchema({
    super.multipleOf,
    super.minimum,
    super.exclusiveMinimum,
    super.maximum,
    super.exclusiveMaximum,
    super.title,
    super.type,
    super.deprecated,
    super.readOnly,
    super.writeOnly,
    super.comment,
    super.enumValues,
    super.constValue,
  });

  factory OpenApiIntegerSchema.fromJson(JsonMap json) =>
      _$OpenApiIntegerSchemaFromJson(json);
}

@JsonSerializable()
class OpenApiNumberSchema extends OpenApiNumericSchema<int> {
  OpenApiNumberSchema({
    super.multipleOf,
    super.minimum,
    super.exclusiveMinimum,
    super.maximum,
    super.exclusiveMaximum,
    super.title,
    super.type,
    super.deprecated,
    super.readOnly,
    super.writeOnly,
    super.comment,
    super.enumValues,
    super.constValue,
  });

  factory OpenApiNumberSchema.fromJson(JsonMap json) =>
      _$OpenApiNumberSchemaFromJson(json);
}

@JsonSerializable()
class OpenApiObjectSchema extends OpenApiSchema {
  @JsonKey(defaultValue: {})
  final Map<String, OpenApiSchema> properties;

  @JsonKey(defaultValue: {})
  final Map<String, OpenApiSchema> patternProperties;

  @JsonKey(defaultValue: [])
  final List<String> required;

  final bool? additionalProperties;

  OpenApiObjectSchema({
    required this.properties,
    required this.required,
    required this.patternProperties,
    this.additionalProperties,
    super.title,
    super.type,
    super.deprecated,
    super.readOnly,
    super.writeOnly,
    super.comment,
    super.enumValues,
    super.constValue,
    super.description,
  });

  factory OpenApiObjectSchema.fromJson(JsonMap json) =>
      _$OpenApiObjectSchemaFromJson(json);
}

@JsonSerializable()
class OpenApiArraySchema extends OpenApiSchema {
  @JsonKey(fromJson: _itemsFromJson)
  final Tuple<OpenApiSchema, bool>? items;
  final List<OpenApiSchema>? prefixItems;
  final OpenApiSchema? contains;
  final int? minContains;
  final int? maxContains;
  final int? minItems;
  final int? maxItems;
  final bool? uniqueItems;

  OpenApiArraySchema({
    this.items,
    this.prefixItems,
    this.contains,
    this.minContains,
    this.maxContains,
    this.minItems,
    this.maxItems,
    this.uniqueItems,
    super.title,
    super.type,
    super.deprecated,
    super.readOnly,
    super.writeOnly,
    super.comment,
    super.enumValues,
    super.constValue,
  });

  factory OpenApiArraySchema.fromJson(JsonMap json) =>
      _$OpenApiArraySchemaFromJson(json);

  static Tuple<OpenApiSchema, bool>? _itemsFromJson(JsonMap? json) {
    if (json == null) {
      return null;
    }

    return Tuple.fromJson(
      OpenApiSchema.fromJson,
      (j) => j as bool,
      json,
    );
  }
}

@JsonSerializable()
class OpenApiBooleanSchema extends OpenApiSchema {
  OpenApiBooleanSchema({
    super.title,
    super.type,
    super.deprecated,
    super.readOnly,
    super.writeOnly,
    super.comment,
    super.enumValues,
    super.constValue,
  });

  factory OpenApiBooleanSchema.fromJson(JsonMap json) =>
      _$OpenApiBooleanSchemaFromJson(json);
}

@JsonSerializable()
class OpenApiNullSchema extends OpenApiSchema {
  OpenApiNullSchema({
    super.title,
    super.type,
    super.deprecated,
    super.readOnly,
    super.writeOnly,
    super.comment,
    super.enumValues,
    super.constValue,
  });

  factory OpenApiNullSchema.fromJson(Map<String, dynamic> json) =>
      _$OpenApiNullSchemaFromJson(json);
}
