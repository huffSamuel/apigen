// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spec_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenApi _$OpenApiFromJson(Map<String, dynamic> json) => OpenApi(
      openapi: json['openapi'] as String,
      info: OpenApiInfo.fromJson(json['info'] as Map<String, dynamic>),
      jsonSchemaDialect: json['jsonSchemaDialect'] as String?,
      servers: (json['servers'] as List<dynamic>?)
          ?.map((e) => OpenApiServer.fromJson(e as Map<String, dynamic>))
          .toList(),
      paths: json['paths'] == null
          ? null
          : OpenApiPaths.fromJson(json['paths'] as Map<String, dynamic>),
      webhooks: json['webhooks'] as Map<String, dynamic>?,
      components: json['components'] == null
          ? null
          : OpenApiComponents.fromJson(
              json['components'] as Map<String, dynamic>),
      security: (json['security'] as List<dynamic>?)
          ?.map((e) =>
              OpenApiSecurityRequirement.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => OpenApiTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      externalDocumentation: json['externalDocumentation'] == null
          ? null
          : OpenApiExternalDocumentation.fromJson(
              json['externalDocumentation'] as Map<String, dynamic>),
    );

OpenApiInfo _$OpenApiInfoFromJson(Map<String, dynamic> json) => OpenApiInfo(
      title: json['title'] as String,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      termsOfService: json['termsOfService'] as String?,
      contact: json['contact'] == null
          ? null
          : OpenApiContact.fromJson(json['contact'] as Map<String, dynamic>),
      license: json['license'] == null
          ? null
          : OpenApiLicense.fromJson(json['license'] as Map<String, dynamic>),
      version: json['version'] as String,
    );

OpenApiContact _$OpenApiContactFromJson(Map<String, dynamic> json) =>
    OpenApiContact(
      name: json['name'] as String?,
      url: json['url'] as String?,
      email: json['email'] as String?,
    );

OpenApiLicense _$OpenApiLicenseFromJson(Map<String, dynamic> json) =>
    OpenApiLicense(
      name: json['name'] as String,
      identifier: json['identifier'] as String?,
      url: json['url'] as String?,
    );

OpenApiServer _$OpenApiServerFromJson(Map<String, dynamic> json) =>
    OpenApiServer(
      url: json['url'] as String,
      description: json['description'] as String?,
      variables: (json['variables'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k, OpenApiServerVariable.fromJson(e as Map<String, dynamic>)),
      ),
    );

OpenApiServerVariable _$OpenApiServerVariableFromJson(
        Map<String, dynamic> json) =>
    OpenApiServerVariable(
      enums: (json['enum'] as List<dynamic>).map((e) => e as String).toList(),
      defaultValue: json['default'] as String,
      description: json['description'] as String?,
    );

OpenApiExternalDocumentation _$OpenApiExternalDocumentationFromJson(
        Map<String, dynamic> json) =>
    OpenApiExternalDocumentation(
      description: json['description'] as String?,
      url: json['url'] as String,
    );

OpenApiTag _$OpenApiTagFromJson(Map<String, dynamic> json) => OpenApiTag(
      name: json['name'] as String,
      description: json['description'] as String?,
      externalDocs: json['externalDocs'] == null
          ? null
          : OpenApiExternalDocumentation.fromJson(
              json['externalDocs'] as Map<String, dynamic>),
    );

OpenApiSecurityRequirement _$OpenApiSecurityRequirementFromJson(
        Map<String, dynamic> json) =>
    OpenApiSecurityRequirement();

OpenApiPath _$OpenApiPathFromJson(Map<String, dynamic> json) => OpenApiPath(
      ref: json[r'$ref'] as String?,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      get: json['get'] == null
          ? null
          : OpenApiOperation.fromJson(json['get'] as Map<String, dynamic>),
      put: json['put'] == null
          ? null
          : OpenApiOperation.fromJson(json['put'] as Map<String, dynamic>),
      post: json['post'] == null
          ? null
          : OpenApiOperation.fromJson(json['post'] as Map<String, dynamic>),
      delete: json['delete'] == null
          ? null
          : OpenApiOperation.fromJson(json['delete'] as Map<String, dynamic>),
      options: json['options'] == null
          ? null
          : OpenApiOperation.fromJson(json['options'] as Map<String, dynamic>),
      head: json['head'] == null
          ? null
          : OpenApiOperation.fromJson(json['head'] as Map<String, dynamic>),
      patch: json['patch'] == null
          ? null
          : OpenApiOperation.fromJson(json['patch'] as Map<String, dynamic>),
      trace: json['trace'] == null
          ? null
          : OpenApiOperation.fromJson(json['trace'] as Map<String, dynamic>),
      servers: (json['servers'] as List<dynamic>?)
          ?.map((e) => OpenApiServer.fromJson(e as Map<String, dynamic>))
          .toList(),
      parameters: json['parameters'] as List<dynamic>?,
    );

OpenApiOperation _$OpenApiOperationFromJson(Map<String, dynamic> json) =>
    OpenApiOperation(
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      externalDocs: json['externalDocs'] == null
          ? null
          : OpenApiExternalDocumentation.fromJson(
              json['externalDocs'] as Map<String, dynamic>),
      operationId: json['operationId'] as String?,
      parameters: json['parameters'],
      requestBody: json['requestBody'],
      responses: json['responses'],
      callbacks: json['callbacks'] as Map<String, dynamic>?,
      deprecated: json['deprecated'] as bool?,
      security: (json['security'] as List<dynamic>?)
          ?.map((e) =>
              OpenApiSecurityRequirement.fromJson(e as Map<String, dynamic>))
          .toList(),
      server: json['server'] == null
          ? null
          : OpenApiServer.fromJson(json['server'] as Map<String, dynamic>),
    );

OpenApiComponents _$OpenApiComponentsFromJson(Map<String, dynamic> json) =>
    OpenApiComponents(
      schemas: (json['schemas'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, OpenApiSchema.fromJson(e as Map<String, dynamic>)),
          ) ??
          {},
      responses: OpenApiComponents._responsesFromJson(
          json['responses'] as Map<String, dynamic>?),
      parameters: OpenApiComponents._parametersFromJson(
          json['parameters'] as Map<String, dynamic>?),
      examples: OpenApiComponents._examplesFromJson(
          json['examples'] as Map<String, dynamic>?),
      requestBodies: OpenApiComponents._requestsFromJson(
          json['requestBodies'] as Map<String, dynamic>?),
      headers: OpenApiComponents._headersFromJson(
          json['headers'] as Map<String, dynamic>?),
      securitySchemes: OpenApiComponents._securitySchemesFromJson(
          json['securitySchemes'] as Map<String, dynamic>?),
      links: OpenApiComponents._linksFromJson(
          json['links'] as Map<String, dynamic>?),
      callbacks: json['callbacks'] as Map<String, dynamic>?,
      pathItems: json['pathItems'] as Map<String, dynamic>?,
    );

OpenApiLink _$OpenApiLinkFromJson(Map<String, dynamic> json) => OpenApiLink(
      operationRef: json['operationRef'] as String?,
      operationId: json['operationId'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      requestBody: json['requestBody'],
      description: json['description'] as String?,
      server: json['server'] == null
          ? null
          : OpenApiServer.fromJson(json['server'] as Map<String, dynamic>),
    );

OpenApiSecurityScheme _$OpenApiSecuritySchemeFromJson(
        Map<String, dynamic> json) =>
    OpenApiSecurityScheme(
      type: json['type'] as String,
      description: json['description'] as String?,
      name: json['name'] as String,
      i: json['i'] as String,
      scheme: json['scheme'] as String,
      bearerFormat: json['bearerFormat'] as String?,
      flows: json['flows'],
      openIdConnectUrl: json['openIdConnectUrl'] as String,
    );

OpenApiHeader _$OpenApiHeaderFromJson(Map<String, dynamic> json) =>
    OpenApiHeader(
      description: json['description'] as String,
      required: json['required'] as bool?,
      deprecated: json['deprecated'] as bool?,
      allowEmptyValue: json['allowEmptyValue'] as bool?,
    );

OpenApiRequestBody _$OpenApiRequestBodyFromJson(Map<String, dynamic> json) =>
    OpenApiRequestBody(
      description: json['description'] as String?,
      content: (json['content'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, OpenApiMediaType.fromJson(e as Map<String, dynamic>)),
      ),
      required: json['required'] as bool?,
    );

OpenApiParameter _$OpenApiParameterFromJson(Map<String, dynamic> json) =>
    OpenApiParameter(
      name: json['name'] as String,
      input: json['in'] as String,
      description: json['description'] as String?,
      required: json['required'] as bool?,
      deprecated: json['deprecated'] as bool,
      allowEmptyValue: json['allowEmptyValue'] as bool,
    );

OpenApiExample _$OpenApiExampleFromJson(Map<String, dynamic> json) =>
    OpenApiExample(
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      value: json['value'],
      externalValue: json['externalValue'] as String?,
    );

OpenApiResponse _$OpenApiResponseFromJson(Map<String, dynamic> json) =>
    OpenApiResponse(
      description: json['description'] as String,
      headers: json['headers'] as Map<String, dynamic>?,
      content: (json['content'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, OpenApiMediaType.fromJson(e as Map<String, dynamic>)),
      ),
      links: json['links'] as Map<String, dynamic>?,
    );

OpenApiMediaType _$OpenApiMediaTypeFromJson(Map<String, dynamic> json) =>
    OpenApiMediaType(
      schema: json['schema'] == null
          ? null
          : OpenApiSchema.fromJson(json['schema'] as Map<String, dynamic>),
      example: json['example'],
      examples: json['examples'] as Map<String, dynamic>?,
      encoding: (json['encoding'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, OpenApiEncoding.fromJson(e as Map<String, dynamic>)),
      ),
    );

OpenApiEncoding _$OpenApiEncodingFromJson(Map<String, dynamic> json) =>
    OpenApiEncoding(
      contentType: json['contentType'] as String?,
      headers: json['headers'] as Map<String, dynamic>?,
      style: json['style'] as String?,
      explode: json['explode'] as bool?,
      allowReserved: json['allowReserved'] as bool?,
    );

OpenApiReference _$OpenApiReferenceFromJson(Map<String, dynamic> json) =>
    OpenApiReference(
      ref: json[r'$ref'] as String,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
    );
