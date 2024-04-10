import 'dart:convert';
import 'dart:io';

import '../configurations/language_specific_configuration.dart';
import '../configurations/typescript/typescript.dart';
import '../domain/content_type.dart';
import '../domain/schemas/helpers.dart';
import '../domain/schemas/schema.dart';
import '../domain/schemas/spec_file.dart';
import '../domain/syntax/method_node.dart';
import '../domain/syntax/node.dart';
import '../domain/syntax/param_node.dart';
import 'code_generator/typescript_code_generator.dart';
import 'factories/factories.dart';
import 'generate.dart';
import 'log.dart';
import 'utils/is.dart';
import 'utils/name.dart';

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

    cg.generate(generate, TypescriptConfiguration());
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
    return config.methodName(operationId);
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
              param = ParamDecl(referenceName(operation.requestBody!.a!))
                ..name = 'body'
                ..type = referenceName(operation.requestBody!.a!);
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
                          ..type = referenceName(ref)
                          ..isArray = true;
                        break;
                      case null:
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
                    param.type = referenceName(ref);
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
                  () => ApiDeclNode('${config.className(at)}Api')
                    ..typeName = config.typeName('${config.className(at)}Api'));
              syntax.apis[at]!.methods.add(node);
            }
          }
        });
      });
    }

    if (syntax.apis['Default']!.methods.isEmpty) {
      syntax.apis.remove('Default');
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
      p.type = referenceName(param.a!);
      // TODO: This needs to get the location from the pre-built type
    } else if (param.b != null) {
      p.schema = param.b!;

      if (param.b?.schema?.a != null) {
        switch (param.b!.schema!.a!) {
          case OpenApiArraySchema ray:
            switch (ray.items!.a) {
              case OpenApiReferenceSchema ref:
                final t = syntax.types[referenceName(ref)]!;
                p.type = t.typeName;
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
            p.type = config.arrayType(p.type);
            break;
          case OpenApiReferenceSchema ref:
            final t = syntax.types[referenceName(ref)]!;
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
        p.type = config.typename(schema: param.b!.schema!.b!);
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
