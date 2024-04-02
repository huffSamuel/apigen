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

    var syntax = Syntax();
    syntax = s.build(schema, syntax);
    syntax = a.build(schema, syntax);

    cg.generate(syntax.types.values);
    cg.generate(syntax.apis.values);
  }
}

// CLI Params
// --output, -o <path>
// --schema, -s <path>
// --format, -f [format...]

class Syntax {
  final Map<String, TypeDeclNode> types = {};
  final Map<String, ApiDeclNode> apis = {};
}

String referenceName(OpenApiReferenceSchema ref) {
  return ref.ref.substring(ref.ref.lastIndexOf('/') + 1);
}

TypeDeclNode responseType(
  String name,
  OpenApiObjectSchema obj,
  LanguageSpecificConfiguration config,
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
    );
    prop.name = p.key;
    prop.required = obj.required.contains(p.key);
    t.properties.add(prop);
  }

  return t;
}

TypeDeclNode type(
  String name,
  OpenApiObjectSchema obj,
  LanguageSpecificConfiguration config,
) {
  final t = TypeDeclNode(name, obj);
  t.typeName = config.typeName(name);
  t.fileName = config.fileName(name);

  for (final p in obj.properties.entries) {
    final prop = property(config.className(p.key), p.value, t, config);
    prop.required = obj.required.contains(p.key);
    t.properties.add(prop);
  }

  return t;
}

// TODO: This needs direct access to syntax so it can continue to process sub-object/array nodes
// Without an additional pass through the entire tree.
PropertyNode property(
  String name,
  OpenApiSchema schema,
  TypeDeclNode t,
  LanguageSpecificConfiguration config,
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
          t.typeDecls.add(type(name, obj, config));
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
      t.typeDecls.add(type(name, obj, config));
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

  Syntax build(
    OpenApi schema,
    Syntax syntax,
  ) {
    if (schema.components != null) {
      for (final e in schema.components!.schemas.entries) {
        switch (e.value) {
          case final OpenApiObjectSchema obj:
            syntax.types[e.key] = type(e.key, obj, config);
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

    for (final t in syntax.types.values) {
      for (final p in t.properties) {
        if (p.typeReference == null) {
          continue;
        }

        // Find the matching type decl
        final type = syntax.types.values
            .singleWhere((element) => element.id == p.typeReference);

        // And complete the referenced information.
        // Alternatively, we could push ever schema into a list and
        // process it if it doesn't reference any other type. If it does, push it
        // back into the end of the list for further processing. OR be cool kids
        // and run through once to build a dependency graph and process types in that order...
        // I think this is probably fine though.
        p.isEnumType = type.isEnum;
        p.isTypedef = type.isTypedef;
      }
    }

    // Any object or enum schemas nested within another type get promoted to a full type here
    // CONSIDER: Is this the best option? Or should they be kept within the source code
    // files for the type they are nested underneath?
    final typesWithDecls =
        syntax.types.values.where((x) => x.typeDecls.isNotEmpty).toList();

    for (final typeWithDecls in typesWithDecls) {
      for (final c in typeWithDecls.typeDecls) {
        // Find the property associated with the decl
        final p = typeWithDecls.properties.singleWhere((x) => x.id == c.id);

        if (syntax.types.containsKey(c.id)) {
          c.typeName = config.className(typeWithDecls.typeName + c.typeName);
          c.fileName = config.fileName(c.typeName);
        }

        p.type = c.typeName;
        syntax.types[c.typeName] = c;
        typeWithDecls.references[c.fileName] = Set.from([c.typeName]);
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

  Syntax build(OpenApi schema, Syntax syntax) {
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
              if (entry.value.b?.content?['application/json'] != null) {
                final schema =
                    entry.value.b!.content!['application/json']!.schema!;

                if (schema is! OpenApiObjectSchema) {
                  continue;
                }

                Log.info("Creating response type", [className]);
                // This really needs to process the name of child properties as a type from the parent,
                // e.g. NavigateShip200Response -> NavigateShip200ResponseData
                final t = responseType(
                  className,
                  schema,
                  config,
                );
                syntax.types[className] = t;

                if (t.typeDecls.isNotEmpty) {
                  for (final c in t.typeDecls) {
                    final p = t.properties.singleWhere((x) => x.id == c.id);

                    if (syntax.types.containsKey(c.id)) {
                      c.typeName = config.className(t.typeName + c.typeName);
                      c.fileName = config.fileName(c.typeName);
                    }

                    p.type = c.typeName;
                    syntax.types[c.typeName] = c;
                    t.references[c.fileName] = Set.from([c.typeName]);
                  }
                }
              }
            }
          }

          if (operation.value.requestBody != null) {
            // TODO: Add requestbodies to the known typedecls
            // TODO: Add the request bodies to the method node so it knows how to generate a request

            Log.info('adding request body');
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
    Syntax syntax,
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
