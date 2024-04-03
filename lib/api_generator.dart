import 'dart:convert';
import 'dart:io';

import 'utils/log.dart';

import 'code_generator/typescript_code_generator.dart';
import 'configurations/language_specific_configuration.dart';
import 'configurations/typescript/typescript.dart';
import 'extension/map.dart';
import 'schemas/helpers.dart';
import 'schemas/schema.dart';
import 'schemas/spec_file.dart';
import 'syntax/method_node.dart';
import 'syntax/node.dart';
import 'syntax/param_node.dart';

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

class Generate {
  final Map<String, TypeDeclNode> types = {};
  final Map<String, ApiDeclNode> apis = {};
}

String referenceName(OpenApiReferenceSchema ref) {
  return ref.ref.substring(ref.ref.lastIndexOf('/') + 1);
}

void responseType(
  String name,
  OpenApiObjectSchema obj,
  LanguageSpecificConfiguration config,
  Generate generate,
) {
  final t = TypeDeclNode(name, obj);
  t.typeName = config.typeName(name);
  t.fileName = config.fileName(name);

  for (final p in obj.properties.entries) {
    // TODO: This needs to separate propertyName and typeName
    final prop = property(
      config.className(camelCase([name, p.key])),
      p.value,
      t,
      config,
      generate,
    );
    prop.name = p.key;
    prop.required = obj.required.contains(p.key);
    t.properties.add(prop);
  }

  generate.types[t.typeName] = t;
}

void type(
  String name,
  OpenApiObjectSchema obj,
  LanguageSpecificConfiguration config,
  Generate generate,
) {
  final t = TypeDeclNode(name, obj);
  t.typeName = config.typeName(name);
  t.fileName = config.fileName(name);

  for (final p in obj.properties.entries) {
    final prop = property(
      config.className(p.key),
      p.value,
      t,
      config,
      generate,
    );
    prop.required = obj.required.contains(p.key);
    t.properties.add(prop);
  }

  generate.types[name] = t;
}

PropertyNode property(
  String name,
  OpenApiSchema schema,
  TypeDeclNode t,
  LanguageSpecificConfiguration config,
  Generate generate,
) {
  final pr = PropertyNode(name, schema);
  pr.name = config.propertyName(name);

  switch (schema) {
    case final OpenApiArraySchema ray:
      switch (ray.items!.a) {
        case final OpenApiReferenceSchema ref:
          pr.type = config.className(referenceName(ref));
          t.references.putOrAdd(config.fileName(pr.type), pr.type);
          break;
        case final OpenApiObjectSchema obj:
          pr.type = config.className(name);
          t.references.putOrAdd(config.fileName(name), name);
          type(name, obj, config, generate);
          break;
        case null:
          Log.warn(
              'This is likely a composite schema that we cannot handle at this time');
          pr.type = config.anyType();
          break;
        default:
          pr.type = config.typeName(ray.items!.a!.type ?? 'unknown');

          if (schema.enumValues?.isNotEmpty == true) {
            pr.isEnumType = true;
            t.typeDecls.add(enums(name, schema, config));
          }
      }
      break;
    case final OpenApiReferenceSchema ref:
      pr.typeReference = referenceName(ref);
      pr.type = config.className(pr.typeReference!);
      t.references.putOrAdd(config.fileName(pr.type), pr.type);
      break;
    case final OpenApiObjectSchema obj:
      pr.type = config.className(name);
      t.references.putOrAdd(config.fileName(name), name);
      type(
        name,
        obj,
        config,
        generate,
      );
      break;
    default:
      pr.type = config.typeName(schema.type ?? 'unknown');

      if (schema.enumValues?.isNotEmpty == true) {
        pr.isEnumType = true;
        t.typeDecls.add(enums(name, schema, config));
      }
      break;
  }

  return pr;
}

TypeDeclNode enums(
  String name,
  OpenApiSchema obj,
  LanguageSpecificConfiguration config,
) {
  final t = TypeDeclNode(name, obj);

  t.isEnum = true;
  t.typeName = config.typeName(name);
  t.fileName = config.fileName(name);
  t.enumValues.addAll(obj.enumValues!.map((x) {
    final d = EnumValueDecl(x);

    d.typeName = config.typeName(obj.type ?? 'unknown');
    d.value = x;
    d.name = config.enumValueName(x);

    return d;
  }));

  return t;
}

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
            type(e.key, obj, config, syntax);
            break;
          default:
            if (e.value.enumValues?.isNotEmpty == true) {
              syntax.types[e.key] = enums(e.key, e.value, config);
            } else {
              final t = TypeDeclNode(e.key, e.value);
              t.typeName = config.typeName(e.key);
              t.fileName = config.fileName(e.key);
              t.isTypedef = true;
              t.typedef = e.value.type!;

              syntax.types[e.key] = t;
            }

            break;
        }
      }
    }

// This is a pass to complete the "ref" objects in the schema.
// We don't have that information when we process the open api schema iteratively
// so we need to loop back over all types and complete the information for any type
// that was referenced after that type has been processed.
//
// There are ways to prevent this additional pass, but IMO any method is going to increase
// complexity more than it's worth to just loop through all the objects again.
    for (final t in syntax.types.values) {
      for (final p
          in t.properties.where((element) => element.typeReference != null)) {
        // Find the matching type decl
        final type = syntax.types.values
            .singleWhere((element) => element.id == p.typeReference);

        p.isEnumType = type.isEnum;
        p.isTypedef = type.isTypedef;
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

        for (final operation in operations(path.value).entries) {
          final node = MethodNode(operation.key, operation.value);
          node.name = methodName(operation.value.operationId!);
          node.path = path.key;
          node.method = operation.key;
          node.parameters.addAll(commonParams);

          if (operation.value.parameters?.isNotEmpty == true) {
            for (final (index, param) in operation.value.parameters!.indexed) {
              node.parameters.add(parameter(
                param,
                syntax,
                operation.value.operationId!,
                index,
              ));
            }
          }

          if (operation.value.responses?.isNotEmpty == true) {
            for (final entry in operation.value.responses!.entries) {
              final className =
                  config.className('${node.name}${entry.key}Response');
              // TODO: Handle non-JSON response objects
              // This will require application-wide enhancement to support multiple deserialization methods
              // And probably helper classes for the target types that don't natively support non-JSON deserialization.
              if (entry.value.b?.content?['application/json'] != null) {
                final schema =
                    entry.value.b!.content!['application/json']!.schema!;

                if (schema is! OpenApiObjectSchema) {
                  continue;
                }

                Log.info("Creating response type", [className]);
                responseType(
                  className,
                  schema,
                  config,
                  syntax,
                );
              }
            }
          }

          if (operation.value.requestBody != null) {
            if (operation.value.requestBody?.b != null) {
              final className = config.className('${node.name}Request');

              if (operation
                      .value.requestBody!.b!.content?['application/json'] !=
                  null) {
                final schema = operation
                    .value.requestBody!.b!.content!['application/json']!.schema;

                if (schema is! OpenApiObjectSchema) {
                  continue;
                }

                Log.info("Creating request body type", [className]);
                responseType(className, schema, config, syntax);
                // TODO: This needs to add the request body as a parameter of the method
              }
            }
          }

          if (operation.value.security?.isNotEmpty == true) {
            // TODO: Handle
            Log.info('Handle security');
          }

          if (operation.value.tags?.isEmpty == true) {
            syntax.apis['Default']!.methods.add(node);
          } else {
            for (final at in operation.value.tags!) {
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
            final t =
                syntax.types[ref.ref.substring(ref.ref.lastIndexOf('/') + 1)]!;
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
