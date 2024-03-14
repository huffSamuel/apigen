import 'dart:io';

import '../syntax/node.dart';

class TypescriptCodeGenerator {
  generate(List<Node> syntax) {
    final out = Directory('./out/dto');

    if (out.existsSync()) {
      out.deleteSync(recursive: true);
    }

    out.createSync();

    for (final c in syntax.whereType<TypeDeclNode>()) {
      String src;

      if (c.isEnum) {
        src = kenum(c);
      } else if (c.isTypedef) {
        src = ktypedef(c);
      } else {
        src = klass(c);
      }

      final file = File('./out/dto/' + c.fileName + '.ts');

      file.writeAsStringSync(src);
    }
  }

  ktypedef(TypeDeclNode n) {
    return '''
${description(n.description)}
type ${n.typeName} = ${n.typedef};
''';
  }

  String description(String? d) {
    if (d == null) {
      return '';
    }

    return '''/**
 * ${d}
 */''';
  }

  deserializer(TypeDeclNode n) {
    return '''static fromJson(json: any): ${n.typeName} {
    const o = new ${n.typeName}();

    // TODO: Handle checking required properties exist

    ${n.properties.map(deserialize).join('\r\n    ')}

    return o;
  }
''';
  }

  String deserialize(PropertyNode p) {
    if (p.apiType) {
      if (p.isArray) {
        // TODO: Handle optional
        return 'o.${p.name} = json[\'${p.id}\'].map((x) => ${p.type}.fromJson(x));';
      }

      if (p.isEnumType) {
        return 'o.${p.name} = json[\'${p.id}\']';
      }

      if (p.isTypedef) {
        return 'o.${p.name} = json[\'${p.id}\'] as ${p.type};';
      }

      return 'o.${p.name} = ${p.type}.fromJson(json[\'${p.id}\'])';
    }

    // TODO: Handle special deserializers (like new Date())

    return 'o.${p.name} = json[\'${p.id}\'];';
  }

  String requiredDeserialize(PropertyNode p) {
    return '''
if(!json['${p.id}']) {
  throw 'Missing required property: ${p.id}';
}
${deserialize(p)}
''';
  }

  imports(String fileName) {
    return 'import "./${fileName}";';
  }

  kenum(TypeDeclNode n) {
    return '''
${description(n.description)}
export enum ${n.typeName} {
  ${n.enumValues.map((x) => "${x.name} = '${x.value}',").join('\r\n  ')}
}''';
  }

  klass(TypeDeclNode n) {
    final source = '''${n.referencedFiles.map((x) => imports(x)).join('\r\n')}
${description(n.description)}
export class ${n.typeName} {
  ${n.properties.map(property).join('\r\n  ')}

  ${deserializer(n)}
}''';

    return source;
  }

  constructor(Iterable<PropertyNode> params) {
    if (params.isEmpty) {
      return '';
    }

    final sb = StringBuffer('\r\n  constructor(');

    sb.write(params.map((x) => '${x.name}: ${x.type}').join(', '));
    sb.write(') {\r\n    ');
    sb.write(params.map((x) => 'this.${x.name} = ${x.name};').join('\r\n    '));

    sb.write('\r\n  }');

    return sb.toString();
  }

  property(PropertyNode n) {
    final sb = StringBuffer();

    if (n.description != null) {
      sb.writeln(description(n.description));
      sb.write('  ');
    }

    sb.write('public');

    if (n.readonly) {
      sb.write(' readonly');
    }

    sb.write(' ${n.name}');

    if (!n.required) {
      sb.write('?');
    }

    sb.write(': ');

    if (n.isArray) {
      sb.write('${n.type}[]');
    } else {
      sb.write(n.type);
    }

    sb.write(';');

    return sb.toString();
  }
}
