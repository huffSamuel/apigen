import 'dart:io';

import '../generate.dart';
import '../../domain/syntax/method_node.dart';
import '../../domain/syntax/node.dart';
import '../../domain/syntax/param_node.dart';

const package = '''{
  "dependencies": {
    "isomorphic-unfetch": "^4.0.2"
  }
}''';

const imports = '''import fetch from 'isomorphic-unfetch';''';

const api = '''export class BaseApi {
  baseUrl = '';

  send(
    method: string,
    req: {
      path: string;
      query?: Record<
        string,
        string | number | boolean | string[] | number[] | boolean[]
      >;
    }
  ) {
    let url = this.baseUrl + req.path;

    if (req.query) {
      const p = new URLSearchParams();

      for (const q in req.query) {
        const v = req.query[q];

        if (Array.isArray(v)) {
          for (const f of v) {
            p.append(q, f.toString());
          }
        } else {
          p.append(q, v.toString());
        }
      }

      url += '?';

      url += p.toString();
    }

    fetch(url, {
      method,
    });
  }
}''';

const helper = '''export const value = <T>(
  json: any,
  key: string,
  fromJson?: (j: Record<string, any>) => T
): DeserializedValue<T> => {
  let v = json[key];

  if (v && fromJson) {
    v = fromJson(v);
  }

  return new DeserializedValue<T>(v, key);
};

export const array = <T>(
  json: any,
  key: string,
  fromJson?: (j: Record<string, any>) => T
): DeserializedValue<T[]> => {
  let v = json[key];

  if (v && fromJson) {
    v = v.map((x: Record<string, any>) => fromJson(x as Record<string, any>));
  } else if (v) {
    v = v.map((x: T) => x);
  }

  return new DeserializedValue<T[]>(v, key);
};

class DeserializedValue<T> {
  public readonly value: T | null | undefined;

  constructor(value: T | null | undefined, private readonly name: string) {
    this.value = value;
  }

  required(): T {
    if (this.value == null || this.value === undefined) {
      throw `Deserialization error, required property \${this.name} missing`;
    }

    return this.value!;
  }

  optional(): T | null | undefined {
    return this.value;
  }

  toDate() {
    if (this.value == null || this.value == undefined) {
      return new DeserializedValue<Date>(null, this.name);
    }

    if (
      typeof this.value !== 'string' &&
      typeof this.value !== 'number' && 
      !(this.value instanceof Date)
    ) {
      return new DeserializedValue<Date>(null, this.name);
    }

    return new DeserializedValue(new Date(this.value as any), this.name);
  }
}''';

// TODO: for classes create a better deserializer
// TODO: See if we can inspect a generic's prototype. If so, the new Value()
// call needs to try to call `fromJson()` on that generic type

class TypescriptCodeGenerator {
  List<String> additional = [api];

  Map<String, String> additionalFiles = {
    'package.json': package,
  };

  generate(Generate generate) {
    final sb = StringBuffer();

    for (final additionalFile in additionalFiles.entries) {
      final file = File('./out/${additionalFile.key}');

      if (!file.parent.existsSync()) {
        file.parent.createSync();
      }

      file.writeAsString(additionalFile.value);
    }

    for (final add in additional) {
      sb.writeln(add);
    }

    for (final c in generate.apis.values.whereType<ApiDeclNode>()) {
      String src = klass(c);
      sb.writeln(src);
    }

    for (final c in generate.types.values.whereType<TypeDeclNode>()) {
      String src;

      if (c.isEnum) {
        src = kenum(c);
      } else if (c.isTypedef) {
        src = ktypedef(c);
      } else {
        src = kinterface(c);
      }

      sb.writeln(src);
    }

    final file = File('out/api.ts');
    file.writeAsStringSync(sb.toString());
  }

  ktypedef(TypeDeclNode n) {
    return '''${description(n.description)}
export type ${n.typeName} = ${n.typedef};''';
  }

  String description(String? d) {
    if (d == null) {
      return '';
    }

    return '''/**
 * $d
 */''';
  }

  kenum(TypeDeclNode n) {
    return '''${description(n.description)}
export enum ${n.typeName} {
  ${n.enumValues.map((x) => "${x.name} = '${x.value}',").join('\r\n  ')}
}''';
  }

  klass(ApiDeclNode n) {
    final source = '''export class ${n.typeName} {
  constructor(private readonly api: BaseApi) {}

  ${n.methods.map((m) => kmethod(m)).join('\r\n  ')}
}''';

    return source;
  }

  String kmethod(MethodNode m) {
    return '''${description(m.description)}
${m.name}(${m.parameters.map(parameter).join(', ')}) {
  ${path(m.path, m.parameters)}
  this.api.send('${m.method}', {path, query: {${m.parameters.where((x) => x.location == 'query').map((x) => x.name).join(',')}}});
}''';
  }

  String parameter(ParamDecl param) {
    final sb = StringBuffer('${param.name}: ${param.type}');
    if (param.isArray) {
      sb.write('[]');
    }
    return sb.toString();
  }

  String path(String path, List<ParamDecl> params) {
    var sb = StringBuffer('let path = \'$path\'');

    final pathParams = params.where((x) => x.location == 'path');

    if (pathParams.isEmpty) {
      return sb.toString();
    }

    sb.write('\nconst pathParams={');
    sb.write(pathParams.map((x) => x.name).join(','));
    sb.writeln('};');

    sb.write(
      'for (const p in pathParams) { path = path.replace(`{\${p}}`, pathParams[p]);}',
    );

    return sb.toString();
  }

  kinterface(TypeDeclNode n) {
    final source = '''${description(n.description)}
export interface ${n.typeName} {
  ${n.properties.map(property).join('\r\n  ')}
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
