import 'package:json_annotation/json_annotation.dart';

import 'helpers.dart';
import 'schema.dart';

part 'spec_file.g.dart';

OpenApiPaths? pathsFromJson(Map<String, dynamic> j) {
  return null;
}

@JsonSerializable()
class OpenApi {
  /// The version number of the OpenAPI specification that the OpenAPI document uses.
  final String openapi;

  /// Metadata about the API.
  final OpenApiInfo info;

  /// The default value for the `$schema` keyword within [Schema] objects.
  final String? jsonSchemaDialect;

  /// An array of server objects, which provide connectivity information to a target server.
  final List<OpenApiServer>? servers;

  /// Available paths and operations for the API.
  @JsonKey(fromJson: pathsFromJson)
  final OpenApiPaths? paths;

  /// The incoming webhooks that MAY be received as part of this API and that the API
  /// consumer MAY choose to implement.
  final Map<String, dynamic>?
      webhooks; // todo; PathItemObject | ReferenceObject

  /// An element to hold various schemas for the document.
  final OpenApiComponents? components;

  /// A declaration of which security mechanisms can be used across the API.
  final List<OpenApiSecurityRequirement>? security;

  /// A list of tags used by the document with additional metadata.
  final List<OpenApiTag>? tags;

  /// Additional external documentation.
  final OpenApiExternalDocumentation? externalDocumentation;

  OpenApi({
    required this.openapi,
    required this.info,
    this.jsonSchemaDialect,
    this.servers,
    this.paths,
    this.webhooks,
    this.components,
    this.security,
    this.tags,
    this.externalDocumentation,
  });

  factory OpenApi.fromJson(Map<String, dynamic> json) =>
      _$OpenApiFromJson(json);
}

@JsonSerializable()
class OpenApiInfo {
  final String title;
  final String? summary;
  final String? description;
  final String? termsOfService;
  final OpenApiContact? contact;
  final OpenApiLicense? license;
  final String version;

  OpenApiInfo({
    required this.title,
    this.summary,
    this.description,
    this.termsOfService,
    this.contact,
    this.license,
    required this.version,
  });

  factory OpenApiInfo.fromJson(Map<String, dynamic> json) =>
      _$OpenApiInfoFromJson(json);
}

@JsonSerializable()
class OpenApiContact {
  final String? name;
  final String? url;
  final String? email;

  OpenApiContact({this.name, this.url, this.email});

  factory OpenApiContact.fromJson(Map<String, dynamic> json) =>
      _$OpenApiContactFromJson(json);
}

@JsonSerializable()
class OpenApiLicense {
  final String name;
  final String? identifier;
  final String? url;

  OpenApiLicense({required this.name, this.identifier, this.url});

  factory OpenApiLicense.fromJson(Map<String, dynamic> json) =>
      _$OpenApiLicenseFromJson(json);
}

@JsonSerializable()
class OpenApiServer {
  final String url;
  final String? description;
  final Map<String, OpenApiServerVariable>? variables;

  OpenApiServer({
    required this.url,
    this.description,
    this.variables,
  });

  factory OpenApiServer.fromJson(Map<String, dynamic> json) =>
      _$OpenApiServerFromJson(json);
}

@JsonSerializable()
class OpenApiServerVariable {
  @JsonKey(name: 'enum')
  final List<String> enums;
  @JsonKey(name: 'default')
  final String defaultValue;
  final String? description;

  OpenApiServerVariable({
    required this.enums,
    required this.defaultValue,
    this.description,
  });

  factory OpenApiServerVariable.fromJson(Map<String, dynamic> json) =>
      _$OpenApiServerVariableFromJson(json);
}

@JsonSerializable()
class OpenApiExternalDocumentation {
  final String? description;
  final String url;

  OpenApiExternalDocumentation({
    this.description,
    required this.url,
  });

  factory OpenApiExternalDocumentation.fromJson(Map<String, dynamic> json) =>
      _$OpenApiExternalDocumentationFromJson(json);
}

@JsonSerializable()
class OpenApiTag {
  final String name;
  final String? description;
  final OpenApiExternalDocumentation? externalDocs;

  OpenApiTag({
    required this.name,
    this.description,
    this.externalDocs,
  });

  factory OpenApiTag.fromJson(Map<String, dynamic> json) =>
      _$OpenApiTagFromJson(json);
}

@JsonSerializable()
class OpenApiSecurityRequirement {
  // TODO: Figure out how to pattern these. I think a Map may be best.

  OpenApiSecurityRequirement();

  factory OpenApiSecurityRequirement.fromJson(Map<String, dynamic> json) =>
      _$OpenApiSecurityRequirementFromJson(json);
}

class OpenApiPaths {
  final Map<String, OpenApiPath>? paths;

  OpenApiPaths({
    this.paths,
  });

  factory OpenApiPaths.fromJson(Map<String, dynamic> json) {
    final paths = <String, OpenApiPath>{};

    for (var entry in json.entries) {
      paths[entry.key] =
          OpenApiPath.fromJson(entry.value as Map<String, dynamic>);
    }

    return OpenApiPaths(
      paths: paths,
    );
  }
}

@JsonSerializable()
class OpenApiPath {
  @JsonKey(name: '\$ref')
  final String? ref;
  final String? summary;
  final String? description;
  final OpenApiOperation? get;
  final OpenApiOperation? put;
  final OpenApiOperation? post;
  final OpenApiOperation? delete;
  final OpenApiOperation? options;
  final OpenApiOperation? head;
  final OpenApiOperation? patch;
  final OpenApiOperation? trace;
  final List<OpenApiServer>? servers;
  final List<dynamic>? parameters;

  OpenApiPath({
    this.ref,
    this.summary,
    this.description,
    this.get,
    this.put,
    this.post,
    this.delete,
    this.options,
    this.head,
    this.patch,
    this.trace,
    this.servers,
    this.parameters,
  });

  factory OpenApiPath.fromJson(Map<String, dynamic> json) =>
      _$OpenApiPathFromJson(json);
}

@JsonSerializable()
class OpenApiOperation {
  final List<String>? tags;
  final String? summary;
  final String? description;
  final OpenApiExternalDocumentation? externalDocs;
  final String? operationId;
  final dynamic parameters;
  final dynamic requestBody;
  final dynamic responses;
  final Map<String, dynamic>? callbacks;
  final bool? deprecated;
  final List<OpenApiSecurityRequirement>? security;
  final OpenApiServer? server;

  OpenApiOperation({
    this.tags,
    this.summary,
    this.description,
    this.externalDocs,
    this.operationId,
    this.parameters,
    this.requestBody,
    this.responses,
    this.callbacks,
    this.deprecated,
    this.security,
    this.server,
  });

  factory OpenApiOperation.fromJson(Map<String, dynamic> json) =>
      _$OpenApiOperationFromJson(json);
}

@JsonSerializable()
class OpenApiComponents {
  /// An object to hold reusable schema objects.
  @JsonKey(defaultValue: {})
  final Map<String, OpenApiSchema> schemas;

  @JsonKey(fromJson: _responsesFromJson)
  final Map<String, Tuple<OpenApiResponse, OpenApiReference>>? responses;

  @JsonKey(fromJson: _parametersFromJson)
  final Map<String, Tuple<OpenApiParameter, OpenApiReference>>? parameters;

  @JsonKey(fromJson: _examplesFromJson)
  final Map<String, Tuple<OpenApiExample, OpenApiReference>>? examples;

  @JsonKey(fromJson: _requestsFromJson)
  final Map<String, Tuple<OpenApiRequestBody, OpenApiReference>>? requestBodies;

  @JsonKey(fromJson: _headersFromJson)
  final Map<String, Tuple<OpenApiHeader, OpenApiReference>>? headers;

  @JsonKey(fromJson: _securitySchemesFromJson)
  final Map<String, Tuple<OpenApiSecurityScheme, OpenApiReference>>?
      securitySchemes;

  @JsonKey(fromJson: _linksFromJson)
  final Map<String, Tuple<OpenApiLink, OpenApiReference>>? links;
  final Map<String, dynamic>? callbacks;
  final Map<String, dynamic>? pathItems;

  OpenApiComponents({
    required this.schemas,
    this.responses,
    this.parameters,
    this.examples,
    this.requestBodies,
    this.headers,
    this.securitySchemes,
    this.links,
    this.callbacks,
    this.pathItems,
  });

  static Map<String, Tuple<OpenApiLink, OpenApiReference>>? _linksFromJson(
    Map<String, dynamic>? json,
  ) {
    final m = <String, Tuple<OpenApiLink, OpenApiReference>>{};

    if (json == null) {
      return null;
    }

    for (var entry in json.entries) {
      m[entry.key] = Tuple.fromJson(
        OpenApiLink.fromJson,
        OpenApiReference.fromJson,
        entry.value as Map<String, dynamic>,
      );
    }

    return m;
  }

  static Map<String, Tuple<OpenApiSecurityScheme, OpenApiReference>>?
      _securitySchemesFromJson(
    Map<String, dynamic>? json,
  ) {
    final m = <String, Tuple<OpenApiSecurityScheme, OpenApiReference>>{};

    if (json == null) {
      return null;
    }

    for (var entry in json.entries) {
      m[entry.key] = Tuple.fromJson(
        OpenApiSecurityScheme.fromJson,
        OpenApiReference.fromJson,
        entry.value as Map<String, dynamic>,
      );
    }

    return m;
  }

  static Map<String, Tuple<OpenApiHeader, OpenApiReference>> _headersFromJson(
    Map<String, dynamic>? json,
  ) {
    final m = <String, Tuple<OpenApiHeader, OpenApiReference>>{};

    if (json == null) {
      return m;
    }

    for (var entry in json.entries) {
      m[entry.key] = Tuple.fromJson(
        OpenApiHeader.fromJson,
        OpenApiReference.fromJson,
        entry.value as Map<String, dynamic>,
      );
    }

    return m;
  }

  static Map<String, Tuple<OpenApiResponse, OpenApiReference>>
      _responsesFromJson(
    Map<String, dynamic>? json,
  ) {
    final m = <String, Tuple<OpenApiResponse, OpenApiReference>>{};

    if (json == null) {
      return m;
    }

    for (var entry in json.entries) {
      m[entry.key] = Tuple.fromJson(
        OpenApiResponse.fromJson,
        OpenApiReference.fromJson,
        entry.value as Map<String, dynamic>,
      );
    }

    return m;
  }

  static Map<String, Tuple<OpenApiParameter, OpenApiReference>>
      _parametersFromJson(
    Map<String, dynamic>? json,
  ) {
    final m = <String, Tuple<OpenApiParameter, OpenApiReference>>{};

    if (json == null) {
      return m;
    }

    for (var entry in json.entries) {
      m[entry.key] = Tuple.fromJson(
        OpenApiParameter.fromJson,
        OpenApiReference.fromJson,
        json,
      );
    }

    return m;
  }

  static Map<String, Tuple<OpenApiExample, OpenApiReference>> _examplesFromJson(
    Map<String, dynamic>? json,
  ) {
    final m = <String, Tuple<OpenApiExample, OpenApiReference>>{};

    if (json == null) {
      return m;
    }

    for (var entry in json.entries) {
      m[entry.key] = Tuple.fromJson(
        OpenApiExample.fromJson,
        OpenApiReference.fromJson,
        json,
      );
    }

    return m;
  }

  static Map<String, Tuple<OpenApiRequestBody, OpenApiReference>>
      _requestsFromJson(Map<String, dynamic>? json) {
    final m = <String, Tuple<OpenApiRequestBody, OpenApiReference>>{};

    if (json == null) {
      return m;
    }

    for (var entry in json.entries) {
      m[entry.key] = Tuple.fromJson(
        OpenApiRequestBody.fromJson,
        OpenApiReference.fromJson,
        json,
      );
    }

    return m;
  }

  factory OpenApiComponents.fromJson(Map<String, dynamic> json) =>
      _$OpenApiComponentsFromJson(json);
}

@JsonSerializable()
class OpenApiLink {
  final String? operationRef;
  final String? operationId;
  final Map<String, dynamic>? parameters;
  final dynamic requestBody;
  final String? description;
  final OpenApiServer? server;

  OpenApiLink({
    this.operationRef,
    this.operationId,
    this.parameters,
    this.requestBody,
    this.description,
    this.server,
  });

  factory OpenApiLink.fromJson(Map<String, dynamic> json) =>
      _$OpenApiLinkFromJson(json);
}

@JsonSerializable()
class OpenApiSecurityScheme {
  final String type;
  final String? description;
  final String name;
  final String i;
  final String scheme;
  final String? bearerFormat;
  final dynamic flows;
  final String openIdConnectUrl;

  OpenApiSecurityScheme({
    required this.type,
    this.description,
    required this.name,
    required this.i,
    required this.scheme,
    this.bearerFormat,
    this.flows,
    required this.openIdConnectUrl,
  });

  factory OpenApiSecurityScheme.fromJson(Map<String, dynamic> json) =>
      _$OpenApiSecuritySchemeFromJson(json);
}

@JsonSerializable()
class OpenApiHeader {
  final String description;
  final bool? required;
  final bool? deprecated;
  final bool? allowEmptyValue;

  OpenApiHeader({
    required this.description,
    this.required,
    this.deprecated,
    this.allowEmptyValue,
  });

  factory OpenApiHeader.fromJson(Map<String, dynamic> json) =>
      _$OpenApiHeaderFromJson(json);
}

@JsonSerializable()
class OpenApiRequestBody {
  final String? description;
  final Map<String, OpenApiMediaType>? content;
  final bool? required;

  OpenApiRequestBody({
    this.description,
    this.content,
    this.required,
  });

  factory OpenApiRequestBody.fromJson(Map<String, dynamic> json) =>
      _$OpenApiRequestBodyFromJson(json);
}

@JsonSerializable()
class OpenApiParameter {
  final String name;
  @JsonKey(name: 'in')
  final String input;
  final String? description;
  final bool? required;
  final bool deprecated;
  final bool allowEmptyValue;

  OpenApiParameter({
    required this.name,
    required this.input,
    this.description,
    this.required,
    required this.deprecated,
    required this.allowEmptyValue,
  });

  factory OpenApiParameter.fromJson(Map<String, dynamic> json) =>
      _$OpenApiParameterFromJson(json);
}

@JsonSerializable()
class OpenApiExample {
  final String? summary;
  final String? description;
  final dynamic value;
  final String? externalValue;

  OpenApiExample({
    this.summary,
    this.description,
    this.value,
    this.externalValue,
  });

  factory OpenApiExample.fromJson(Map<String, dynamic> json) =>
      _$OpenApiExampleFromJson(json);
}

@JsonSerializable()
class OpenApiResponse {
  final String description;
  final Map<String, dynamic>? headers;
  final Map<String, OpenApiMediaType>? content;
  final Map<String, dynamic>? links;

  OpenApiResponse({
    required this.description,
    this.headers,
    this.content,
    this.links,
  });

  factory OpenApiResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenApiResponseFromJson(json);
}

@JsonSerializable()
class OpenApiMediaType {
  final OpenApiSchema? schema;
  final dynamic example;
  final Map<String, dynamic>? examples;
  final Map<String, OpenApiEncoding>? encoding;

  OpenApiMediaType({
    this.schema,
    this.example,
    this.examples,
    this.encoding,
  });

  factory OpenApiMediaType.fromJson(Map<String, dynamic> json) =>
      _$OpenApiMediaTypeFromJson(json);
}

@JsonSerializable()
class OpenApiEncoding {
  final String? contentType;
  final Map<String, dynamic>? headers;
  final String? style;
  final bool? explode;
  final bool? allowReserved;

  OpenApiEncoding({
    this.contentType,
    this.headers,
    this.style,
    this.explode,
    this.allowReserved,
  });

  factory OpenApiEncoding.fromJson(Map<String, dynamic> json) =>
      _$OpenApiEncodingFromJson(json);
}

@JsonSerializable()
class OpenApiReference {
  @JsonKey(name: '\$ref')
  final String ref;
  final String? summary;
  final String? description;

  OpenApiReference({
    required this.ref,
    this.summary,
    this.description,
  });

  factory OpenApiReference.fromJson(Map<String, dynamic> json) =>
      _$OpenApiReferenceFromJson(json);
}
