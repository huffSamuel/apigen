import 'dart:convert';
import 'dart:io';

import 'code_generator/typescript_code_generator.dart';
import 'configurations/language_specific_configuration.dart';
import 'configurations/typescript/typescript.dart';
import 'extension/map.dart';
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

class SyntaxBuilder {
  final LanguageSpecificConfiguration config;

  SyntaxBuilder(this.config);

  property(String name, OpenApiSchema schema, TypeDeclNode t) {
    final pr = PropertyNode(name, schema);
    pr.name = config.propertyName(name);

    switch (schema) {
      // TODO: We need to add a reference to the value deserialization helper for the specific language
      // e.g. t.references['util/helper'] = ['value']
      case final OpenApiArraySchema ray:
        // TODO: We need to add a reference to the array deserialization helper for the specific language
        // e.g. t.references['util/helper'] = ['array']
        switch (ray.items!.a) {
          case final OpenApiReferenceSchema ref:
            pr.apiType = true;
            pr.type = config
                .className(ref.ref.substring(ref.ref.lastIndexOf('/') + 1));

            t.references.putOrAdd(config.fileName(pr.type), pr.type);
            break;
          case final OpenApiObjectSchema obj:
            pr.type = config.className(name);
            t.references.putOrAdd(config.fileName(name), name);
            t.typeDecls.add(type(name, obj));
            break;
          default:
            pr.type = config.typeName(ray.items!.a!.type ?? 'unknown');
        }
        break;
      case final OpenApiReferenceSchema ref:
        pr.apiType = true;
        pr.typeReference = ref.ref.substring(ref.ref.lastIndexOf('/') + 1);
        pr.type =
            config.className(ref.ref.substring(ref.ref.lastIndexOf('/') + 1));
        t.references.putOrAdd(config.fileName(pr.type), pr.type);
        break;
      case final OpenApiObjectSchema obj:
        pr.apiType = true;
        pr.type = config.className(name);
        t.references.putOrAdd(config.fileName(name), name);
        t.typeDecls.add(type(name, obj));
        break;
      default:
        pr.type = config.typeName(schema.type ?? 'unknown');

        if (schema.enumValues?.isNotEmpty == true) {
          pr.apiType = true;
          pr.isEnumType = true;
          t.typeDecls.add(enums(name, schema));
        }
        break;
    }

    return pr;
  }

  TypeDeclNode type(
    String name,
    OpenApiObjectSchema obj,
  ) {
    final t = TypeDeclNode(name, obj);
    t.typeName = config.typeName(name);
    t.fileName = config.fileName(name);

    for (final p in obj.properties.entries) {
      final prop = property(config.className(p.key), p.value, t);
      prop.required = obj.required.contains(p.key);
      t.properties.add(prop);
    }

    return t;
  }

  TypeDeclNode enums(
    String name,
    OpenApiSchema obj,
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

  Syntax build(
    OpenApi schema,
    Syntax syntax,
  ) {
    if (schema.components != null) {
      for (final e in schema.components!.schemas.entries) {
        switch (e.value) {
          case final OpenApiObjectSchema obj:
            syntax.types[e.key] = type(e.key, obj);
            break;
          default:
            if (e.value.enumValues?.isNotEmpty == true) {
              syntax.types[e.key] = enums(e.key, e.value);
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
            final p = ParamDecl('${path.key}.$index');

            if (param.a != null) {
              // TODO: Pull a reference out of the pre-processed parameters
              print(
                  '[INFO]: Get this reference from schema.components.parameters');
              p.type = 'dynamic';
            } else if (param.b != null) {
              p.schema = param.b!;

              if (param.b?.schema?.a?.type != null) {
                p.type = config.typeName(param.b!.schema!.a!.type!);
              } else {
                // TODO: Handle composite schemas, likely by generating a new typedef
                print(
                    '[INFO]: This is a composite schema which we cannot process yet');
                p.type = 'dynamic';
              }
            } else {
              print('[ERROR] Unprocessable parameter');
              continue;
            }

            commonParams.add(p);
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
              final p = ParamDecl('${operation.value.operationId}.$index');

              if (param.a != null) {
                // TODO: Pull a reference out of the pre-processed parameters
                print(
                  '[INFO]: Get this reference from schema.components.parameters',
                );
                p.type = config.anyType();
              } else if (param.b != null) {
                p.schema = param.b!;

                if (param.b?.schema?.a != null) {
                  switch (param.b!.schema!.a!) {
                    case OpenApiReferenceSchema ref:
                      final t = syntax.types[
                          ref.ref.substring(ref.ref.lastIndexOf('/') + 1)]!;
                      // TODO: Add a reference to the source file
                      p.type = t.typeName;
                      break;
                    default:
                      final r = param.b!.schema!.a!;

                      if (r.type != null) {
                        p.type = config.typeName(r.type!);
                      } else {
                        print(
                          '[ERROR]: Unprocessable parameter - ${operation.value.operationId} parameter $index',
                        );
                        p.type = config.anyType();
                      }
                      break;
                  }
                } else {
                  // Hand this off to the language config. It either needs to modify the generated syntax with a new composite type
                  // and assign the referenced type OR it needs to assign the any type, if supported. If the language can't support
                  // composites or anys, /shrug?
                  print(
                    '[INFO]: This is a composite schema which we cannot process yet',
                  );
                  p.type = config.anyType();
                }
              } else {
                print(
                    '[ERROR] Unprocessable parameter - ${operation.value.operationId} parameter $index');
                continue;
              }

              node.parameters.add(p);
            }
          }

          // TODO: Add requestbodies to the known typedecls
          // TODO: Add the request bodies to the method node so it knows how to generate a request

          // TODO: Add responses to the known typedecls
          // TODO: Add response type to the methodnode

          // TODO: Handle security

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

void log(String message, [List<dynamic> params = const []]) {
  final buf = StringBuffer(message);

  for (final param in params) {
    buf.write(', ${param}');
  }

  print(buf.toString());
}
