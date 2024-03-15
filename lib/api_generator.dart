import 'dart:convert';
import 'dart:io';

import 'code_generator/typescript_code_generator.dart';
import 'configurations/language_specific_configuration.dart';
import 'configurations/typescript/typescript.dart';
import 'schemas/schema.dart';
import 'schemas/spec_file.dart';
import 'syntax/node.dart';

class ApiGenerator {
  final cg = TypescriptCodeGenerator();
  final s = SyntaxBuilder(TypescriptConfiguration());

  Future<void> generate(String schemaPath) async {
    var schemaText = jsonDecode(await File(schemaPath).readAsString());
    var schema = OpenApi.fromJson(schemaText);
    var syntax = s.build(schema);
    cg.generate(syntax);
  }
}

// CLI Params
// --output, -o <path>
// --schema, -s <path>
// --format, -f [format...]

extension PutOrAdd<T extends String, K extends dynamic> on Map<T, List<K>> {
  void putOrAdd(T key, K value) {
    if (!containsKey(key)) {
      this[key] = [];
    }

    this[key]!.add(value);
  }
}

class SyntaxBuilder {
  final LanguageSpecificConfiguration config;

  SyntaxBuilder(this.config);

  property(String name, OpenApiSchema schema, TypeDeclNode t) {
    final pr = PropertyNode(name, schema);
    pr.name = config.propertyName(name);

    switch (schema) {
      // TODO: We need to add the value deserializaiton helper for the specified language
      case final OpenApiArraySchema ray:
      // TODO: We need to add the array deserialization helpers for the specific language
        switch (ray.items!.a) {
          case final OpenApiReferenceSchema ref:
            pr.apiType = true;
            pr.type = config
                .className(ref.ref.substring(ref.ref.lastIndexOf('/') + 1));

            t.references.putOrAdd(config.fileName(pr.type), pr.type);
            break;
          case final OpenApiObjectSchema obj:
            pr.type = config.className(obj.type!);
            t.references.putOrAdd(config.fileName(pr.type), pr.type);
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
      default:
        pr.type = config.typeName(schema.type ?? 'unknown');
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

  TypeDeclNode? enums(
    String name,
    OpenApiSchema obj,
  ) {
    final t = TypeDeclNode(name, obj);

    if (obj.enumValues?.isNotEmpty != true) {
      return null;
    }

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

  List<Node> build(
    OpenApi schema,
  ) {
    List<TypeDeclNode> syntax = [];

    if (schema.components != null) {
      for (final e in schema.components!.schemas.entries) {
        switch (e.value) {
          case final OpenApiObjectSchema obj:
            syntax.add(type(e.key, obj));
            break;
          default:
            if (e.value.enumValues?.isNotEmpty == true) {
              syntax.add(enums(e.key, e.value)!);
            } else {
              final t = TypeDeclNode(e.key, e.value);
              t.typeName = config.typeName(e.key);
              t.fileName = config.fileName(e.key);
              t.isTypedef = true;
              t.typedef = e.value.type!;

              syntax.add(t);
            }

            break;
        }
      }
    }

    for (final t in syntax) {
      for (final p in t.properties) {
        if (p.typeReference == null) {
          continue;
        }

        // Find the matching type decl
        // TODO: Make syntax a map<String, TypeDeclNode> for faster lookup
        final type =
            syntax.singleWhere((element) => element.id == p.typeReference);

        p.isEnumType = type.isEnum;
        p.isTypedef = type.isTypedef;
      }
    }

    // Any "object" schemas nested within another type get promoted to a full type here
    // CONSIDER: Is this the best option? Or should they be kept within the source code
    // files for the type they are nested underneath?
    // TODO: Avoid name collisions
    final typesWithDecls = syntax.where((x) => x.typeDecls.isNotEmpty).toList();

    for (final typeWithDecls in typesWithDecls) {
      for (final c in typeWithDecls.typeDecls) {
        final p = typeWithDecls.properties.singleWhere((x) => x.id == c.id);

        if (syntax.any((x) => x.id == c.id)) {
          c.typeName = config.className(typeWithDecls.typeName + c.typeName);
        }

        p.type = c.typeName;
        syntax.add(c);
      }
    }

    return syntax;
  }
}

void log(String message, [List<dynamic> params = const []]) {
  final buf = StringBuffer(message);

  for (final param in params) {
    buf.write(', ${param}');
  }

  print(buf.toString());
}
