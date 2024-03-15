import 'dart:io';

import '../syntax/node.dart';

const helper = '''export const value = <T>(
  json: any,
  key: string,
  fromJson?: (j) => T
): DeserializedValue<T> => {
  let v = json[key];

  if (v && fromJson) {
    v = fromJson(v);
  }

  return new DeserializedValue<T>(v);
};

export const array = <T>(
  json: any,
  key: string,
  fromJson?: (j) => T
): DeserializedValue<T[]> => {
  let v = json[key];

  if (v && fromJson) {
    v = v.map(x => fromJson(x));
  } else if (v) {
    v = v.map(x => x as T);
  }

  return new DeserializedValue<T[]>(v);
};

class DeserializedValue<T> {
  public readonly value: T | null | undefined;

  constructor(value: T | null | undefined) {
    this.value = value;
  }

  required(): T {
    if (this.value == null || this.value === undefined) {
      throw 'Deserialization error, required property missing';
    }

    return this.value!;
  }

  optional(): T | null | undefined {
    return this.value;
  }

  toDate() {
    if (this.value == null || this.value == undefined) {
      return new DeserializedValue<Date>(null);
    }

    if (
      typeof this.value !== 'string' &&
      typeof this.value !== 'number' &&
      this.value! instanceof Date
    ) {
      return new DeserializedValue<Date>(null);
    }

    return new DeserializedValue(new Date(this.value as any));
  }
}
''';

// TODO: for classes create a better deserializer
// TODO: See if we can inspect a generic's prototype. If so, the new Value()
// call needs to try to call `fromJson()` on that generic type

class TypescriptCodeGenerator {
  Map<String, String> additionalFiles = {'util/helper.ts': helper};

  generate(List<Node> syntax) {
    final out = Directory('./out/dto');

    if (out.existsSync()) {
      out.deleteSync(recursive: true);
    }

    out.createSync();

    for (final additionalFile in additionalFiles.entries) {
      final file = File('./out/${additionalFile.key}');
      final dir = file.parent;

      if (!dir.existsSync()) {
        dir.createSync();
      }

      file.writeAsStringSync(additionalFile.value);
    }

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

    Object.assign(o, {
      ${n.properties.map(deserialize).join(',\r\n      ')}
    })


    return o;
  }
''';
  }

  String deserialize(PropertyNode p) {
    final sb = StringBuffer('${p.name}: ');

    if (p.isArray) {
      sb.write('array');
    } else {
      sb.write('value');
    }
    if (p.isEnumType || p.isTypedef || !p.apiType) {
      sb.write('<${p.type}>(json, \'${p.id}\')');
    } else {
      sb.write('(json, \'${p.id}\', ${p.type}.fromJson)');
    }

    if (p.required) {
      sb.write('.required()');
    } else {
      sb.write('.optional()');
    }

    return sb.toString();
  }

  String requiredDeserialize(PropertyNode p) {
    return '''
if(!json['${p.id}']) {
  throw 'Missing required property: ${p.id}';
}
${deserialize(p)}
''';
  }

  String imports(String fileName, List<String> types) {
    return 'import { ${types.join(', ')} } from "./${fileName}";';
  }

  kenum(TypeDeclNode n) {
    return '''
${description(n.description)}
export enum ${n.typeName} {
  ${n.enumValues.map((x) => "${x.name} = '${x.value}',").join('\r\n  ')}
}''';
  }

  klass(TypeDeclNode n) {
    final i = n.references.entries.map((x) => imports(x.key, x.value));

    final source = '''${i.join('\r\n')}
import { value, array } from '../util/helper';

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
