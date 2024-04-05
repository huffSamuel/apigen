import 'dart:convert';
import 'dart:io';

import 'application/factories/factories.dart';
import 'application/generate.dart';
import 'application/utils/is_enum.dart';
import 'code_generator/typescript_code_generator.dart';
import 'configurations/language_specific_configuration.dart';
import 'configurations/typescript/typescript.dart';
import 'schemas/helpers.dart';
import 'schemas/schema.dart';
import 'schemas/spec_file.dart';
import 'syntax/method_node.dart';
import 'syntax/node.dart';
import 'syntax/param_node.dart';
import 'utils/log.dart';

class ApiGenerator {
  final cg = TypescriptCodeGenerator();
  final s = SyntaxBuilder(TypescriptConfiguration());
  final a = ApiBuilder(TypescriptConfiguration());

  Future<void> generate(String schemaPath) async {
    var schemaText = jsonDecode(await File(schemaPath).readAsString());
    var schema = OpenApi.fromJson(schemaText);

    final create = ['./out', './out/dto', './out/api'];

    for (final c in create) {
      final out = Directory(c);

      if (out.existsSync()) {
        out.deleteSync(recursive: true);
      }

      out.createSync();
    }

    var generate = Generate();
    generate = s.build(schema, generate);
    generate = a.build(schema, generate);

    cg.generate(generate.types.values);
    cg.generate(generate.apis.values);
  }
}

// CLI Params
// --output, -o <path>
// --schema, -s <path>
// --format, -f [format...]

class SyntaxBuilder {
  final LanguageSpecificConfiguration config;

  SyntaxBuilder(this.config);

  Generate build(
    OpenApi schema,
    Generate syntax,
  ) {
    if (schema.components != null) {
      for (final e in schema.components!.schemas.entries) {
        switch (e.value) {
          case final OpenApiObjectSchema obj:
            objectType(e.key, obj, config, syntax);
            break;
          default:
            if (isEnum(e.value)) {
              enums(e.key, e.value, config, syntax);
            } else {
              typedef(e.key, e.value, config, syntax);
            }

            break;
        }
      }
    }

    return syntax;
  }
}

class ApiBuilder {
  final LanguageSpecificConfiguration config;

  ApiBuilder(this.config);

  methodName(String operationId) {
    final parts = camelCase(operationId.split('-'));

    return config.methodName(parts);
  }

  Generate build(OpenApi schema, Generate syntax) {
    syntax.apis.addAll({
      'Default': ApiDeclNode('DefaultApi')
        ..typeName = config.typeName('DefaultApi')
        ..fileName = config.fileName('DefaultApi'),
    });

    if (schema.paths?.paths != null) {
      for (final path in schema.paths!.paths!.entries) {
        List<ParamDecl> commonParams = [];

        if (path.value.parameters?.isNotEmpty == true) {
          for (final (index, param) in path.value.parameters!.indexed) {
            commonParams.add(parameter(
              param,
              syntax,
              path.key,
              index,
            ));
          }
        }

        for (final op in operations(path.value).entries) {
          final node = MethodNode(op.key, op.value);
          node.name = methodName(op.value.operationId!);
          node.path = path.key;
          node.method = op.key;
          node.parameters.addAll(commonParams);

          if (op.value.parameters?.isNotEmpty == true) {
            for (final (index, param) in op.value.parameters!.indexed) {
              node.parameters.add(parameter(
                param,
                syntax,
                op.value.operationId!,
                index,
              ));
            }
          }

          if (op.value.responses?.isNotEmpty == true) {
            for (final entry in op.value.responses!.entries) {
              final className =
                  config.className('${node.name}${entry.key}Response');
              // TODO: Handle non-JSON response objects
              // This will require support from the actual language generators/templating engine.
              if (hasContentType(entry.value.b, ContentType.json)) {
                final schema =
                    getContent(entry.value.b!, ContentType.json).schema;

                if (schema is! OpenApiObjectSchema) {
                  continue;
                }

                Log.info("Creating response type", [className]);
                bodyType(
                  className,
                  schema,
                  config,
                  syntax,
                );
              }
            }
          }

          if (op.value.requestBody != null) {
            if (op.value.requestBody?.a != null) {
              Log.info("Cannot process references request body");
            }

            if (op.value.requestBody?.b != null) {
              final className = config.className('${node.name}Request');

              if (hasContentType(op.value.requestBody!.b, ContentType.json)) {
                final schema =
                    getContent(op.value.requestBody!.b!, ContentType.json)
                        .schema;

                switch (schema) {
                  case final OpenApiObjectSchema o:
                    bodyType(className, o, config, syntax);
                    final param = ParamDecl('${node.name}Request');
                    param.type = className;
                    param.name = 'body';
                    node.parameters.add(param);
                    break;
                  case final OpenApiReferenceSchema ref:
                    final param = ParamDecl('${node.name}Request');
                    param.type = referenceClassName(ref);
                    param.name = 'body';
                    node.parameters.add(param);
                    break;
                  default:
                    Log.info("Cannot process this type");
                }
              }
            }
          }

          if (op.value.security?.isNotEmpty == true) {
            // TODO: Handle
            Log.info('Handle security');
          }

          if (op.value.tags?.isEmpty == true) {
            syntax.apis['Default']!.methods.add(node);
          } else {
            for (final at in op.value.tags!) {
              syntax.apis.putIfAbsent(
                  at,
                  () => ApiDeclNode('${at}Api')
                    ..typeName = config.typeName('${at}Api')
                    ..fileName = config.fileName('${at}Api'));
              syntax.apis[at]!.methods.add(node);
            }
          }
        }
      }
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
      // TODO: Pull a reference out of the pre-processed parameters
      Log.info(
        'Get this reference from schema.components.parameters',
      );
      p.type = config.anyType();
    } else if (param.b != null) {
      p.schema = param.b!;

      if (param.b?.schema?.a != null) {
        switch (param.b!.schema!.a!) {
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
        // Hand this off to the language config. It either needs to modify the generated syntax with a new composite type
        // and assign the referenced type OR it needs to assign the any type, if supported. If the language can't support
        // composites or anys, /shrug?
        Log.warn('This is a composite schema which we cannot process yet');
        p.type = config.anyType();
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
