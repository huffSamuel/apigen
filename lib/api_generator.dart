import 'dart:convert';
import 'dart:io';

import 'application/code_generator/typescript_code_generator.dart';
import 'application/factories/factories.dart';
import 'application/feature.dart';
import 'application/generate.dart';
import 'application/log.dart';
import 'application/utils/casing.dart';
import 'application/utils/is.dart';
import 'configurations/language_specific_configuration.dart';
import 'configurations/typescript/typescript.dart';
import 'domain/schemas/helpers.dart';
import 'domain/schemas/schema.dart';
import 'domain/schemas/spec_file.dart';
import 'domain/syntax/method_node.dart';
import 'domain/syntax/node.dart';
import 'domain/syntax/param_node.dart';

class ApiGenerator {
  final cg = TypescriptCodeGenerator();
  final a = ApiBuilder(TypescriptConfiguration());

  Future<void> generate(String schemaPath) async {
    var schemaText = jsonDecode(await File(schemaPath).readAsString());
    var schema = OpenApi.fromJson(schemaText);

    final create = ['./out'];

    for (final c in create) {
      final out = Directory(c);

      if (out.existsSync()) {
        out.deleteSync(recursive: true);
      }

      out.createSync();
    }

    var generate = Generate();
    generate = a.build(schema, generate);

    cg.generate(generate);
  }
}

// CLI Params
// --output, -o <path>
// --schema, -s <path>
// --format, -f [format...]

class ApiBuilder {
  final LanguageSpecificConfiguration config;

  ApiBuilder(this.config);

  methodName(String operationId) {
    final parts = camelCase(operationId.split('-'));

    return config.methodName(parts);
  }

  Generate build(OpenApi schema, Generate syntax) {
    if (schema.components != null) {
      schema.components!.schemas.forEach((k, v) {
        if (v is OpenApiObjectSchema) {
          objectType(k, v, config, syntax);
        } else if (isEnum(v)) {
          enums(k, v, config, syntax);
        } else {
          typedef(k, v, config, syntax);
        }
      });
    }

    syntax.apis.addAll({
      'Default': ApiDeclNode('DefaultApi')
        ..typeName = config.typeName('DefaultApi')
    });

    if (schema.paths != null) {
      schema.paths!.paths.forEach((pathName, path) {
        List<ParamDecl> commonParams = [];

        for (final (index, param) in path.parameters.indexed) {
          commonParams.add(parameter(
            param,
            syntax,
            pathName,
            index,
          ));
        }

        operations(path).forEach((operationName, operation) {
          final node = MethodNode(operationName, operation)
            ..name = methodName(operation.operationId!)
            ..path = pathName
            ..method = operationName
            ..parameters.addAll(commonParams);

          for (final (index, param) in operation.parameters.indexed) {
            node.parameters.add(parameter(
              param,
              syntax,
              operation.operationId!,
              index,
            ));
          }

          operation.responses.forEach((status, response) {
            final className = config.className('${node.name}${status}Response');
            // TODO: Handle non-JSON response objects
            // This will require support from the actual language generators/templating engine.
            // TODO: Foreach contenttype
            if (hasContentType(response.b, ContentType.json)) {
              final schema = getContent(response.b!, ContentType.json).schema;

              if (schema is! OpenApiObjectSchema) {
                return;
              }
              bodyType(
                className,
                schema,
                config,
                syntax,
              );
            }
          });

          if (operation.requestBody != null) {
            final body = operation.requestBody!;
            ParamDecl? param;

            if (body.a != null) {
              param = ParamDecl(referenceClassName(operation.requestBody!.a!))
                ..name = 'body'
                ..type = referenceClassName(operation.requestBody!.a!);
            } else if (body.b != null) {
              final className = config.className('${node.name}Request');

              if (hasContentType(body.b, ContentType.json)) {
                final schema = getContent(body.b!, ContentType.json).schema;

                switch (schema) {
                  case final OpenApiArraySchema ray:
                    switch (ray.items!.a) {
                      case final OpenApiObjectSchema o:
                        bodyType(className, o, config, syntax);
                        param = ParamDecl('${node.name}Request')
                          ..type = className
                          ..isArray = true;
                        break;
                      case final OpenApiReferenceSchema ref:
                        param = ParamDecl('${node.name}Request')
                          ..type = referenceClassName(ref)
                          ..isArray = true;
                        break;
                      case null:
                        Log.warn("This is likely a composite");
                        param = ParamDecl("${node.name}Request")
                          ..type = config.anyType()
                          ..isArray = true;
                        break;
                      default:
                        Log.error("Cannot process this type");
                        break;
                    }
                    break;
                  case final OpenApiObjectSchema o:
                    bodyType(className, o, config, syntax);
                    param = ParamDecl('${node.name}Request');
                    param.type = className;
                    break;
                  case final OpenApiReferenceSchema ref:
                    param = ParamDecl('${node.name}Request');
                    param.type = referenceClassName(ref);
                    break;
                  default:
                    Log.error("Cannot process this type");
                }
              }
            } else {
              Log.error("Unknown parameter type");
            }

            if (param != null) {
              param.name = 'body';
              node.parameters.add(param);
            }
            return;
          }

          if (operation.security?.isNotEmpty == true) {
            // TODO: Handle
          }

          if (operation.tags?.isEmpty == true) {
            syntax.apis['Default']!.methods.add(node);
          } else {
            for (final at in operation.tags!) {
              syntax.apis.putIfAbsent(
                  at,
                  () => ApiDeclNode('${config.className(api)}Api')
                    ..typeName = config.typeName('${config.className(at)}Api'));
              syntax.apis[at]!.methods.add(node);
            }
          }
        });
      });
    }
    return syntax;
  }

  ParamDecl parameter(
    Tuple<OpenApiReferenceSchema, OpenApiParameter> param,
    Generate syntax,
    String id,
    int index,
  ) {
    final p = ParamDecl('$id.$index');

    if (param.a != null) {
      p.type = referenceClassName(param.a!);
      // TODO: This needs to get the location from the pre-built type
    } else if (param.b != null) {
      p.schema = param.b!;

      if (param.b?.schema?.a != null) {
        switch (param.b!.schema!.a!) {
          case OpenApiArraySchema ray:
            p.isArray = true;
            switch (ray.items!.a) {
              case OpenApiReferenceSchema ref:
                final t = syntax.types[referenceClassName(ref)]!;
                p.type = t.typeName;
                break;
              case null:
                Log.warn("Composite type");
                p.type = config.anyType();
                break;
              default:
                final r = (ray.items!.a! as OpenApiSchema);

                p.type = config.typeName(r.type!);

                if (isEnum(r)) {
                  // TODO: Process a nested enum.
                  Log.warn("Unprocessed enum");
                }
                break;
            }
            break;
          case OpenApiReferenceSchema ref:
            final t = syntax.types[referenceClassName(ref)]!;
            p.type = t.typeName;
            break;
          default:
            final r = param.b!.schema!.a!;

            if (r.type != null) {
              p.type = config.typeName(r.type!);
            } else {
              Log.error(
                'Unprocessable parameter - $id parameter $index',
              );
              p.type = config.anyType();
            }
            break;
        }
      } else {
        if (config.supports(compositeTypeFeature(param.b!.schema!.b))) {
          // TODO: Generate the actual composite type information here.
          // This probably needs to create a new typedef
          p.type = config.anyType();
        } else {
          Log.warn('This generator does not support composite schemas.');
          p.type = config.anyType();
        }
      }
    } else {
      Log.error(' Unprocessable parameter - $id parameter $index');
    }

    return p;
  }

  Map<String, OpenApiOperation> operations(OpenApiPath path) {
    final Map<String, OpenApiOperation> operations = {};
    final ops = {
      'get': path.get,
      'put': path.put,
      'post': path.post,
      'delete': path.delete,
      'options': path.options,
      'head': path.head,
      'patch': path.patch,
      'trace': path.trace,
    }..removeWhere((k, v) => v == null);

    for (final entry in ops.entries) {
      operations[entry.key] = entry.value!;
    }

    return operations;
  }
}

bool hasContentType(HasContent? obj, ContentType contentType) {
  return obj != null &&
      obj.content != null &&
      obj.content![contentType.type] != null;
}

OpenApiMediaType getContent(HasContent obj, ContentType contentType) {
  return obj.content![contentType.type]!;
}

enum ContentType {
  json("application/json");

  const ContentType(this.type);

  final String type;
}

String referenceClassName(OpenApiReferenceSchema ref) {
  return ref.ref.substring(ref.ref.lastIndexOf('/') + 1);
}
