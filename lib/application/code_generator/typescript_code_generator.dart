import 'dart:io';

import 'package:apigen_cli/application/template_loader.dart';

import '../../configurations/language_specific_configuration.dart';
import '../../domain/syntax/method_node.dart';
import '../../domain/syntax/node.dart';
import '../../domain/syntax/param_node.dart';
import '../generate.dart';

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

String joinPath(List<String> paths) {
  return paths.join(Platform.pathSeparator);
}

String fileName(File file) {
  return file.path.split('/').last;
}

class TypescriptCodeGenerator {
  final templateLoader = TemplateLoader();

  generate(
      Generate generate, GenerateConfig configuration) async {
    final assetDirectory = Directory(joinPath([
      Directory.current.path,
      'assets',
      ...configuration.name.split('-'),
    ]));

    assetDirectory.listSync().forEach((element) {
      if (element is File) {
        element.copy('./out/${fileName(element)}');
      }
    });

    final templateDirectory =
        Directory(joinPath([assetDirectory.path, 'templates']));

    final clientTemplate = await templateLoader
        .load(joinPath([templateDirectory.path, 'client.mustache']));

    final props = {
      'open_curly': '{',
      'close_curly': '}',
      'classes': generate.apis.values.map((e) => {
            'typeName': e.typeName,
            'methods': e.methods.map((m) => {
                  'description': m.description,
                  'name': m.name,
                  'path': m.path,
                  'method': m.method,
                  'hasBody': m.parameters.any((x) => x.location == 'body'),
                  'body': m.parameters
                      .where((x) => x.location == 'body')
                      .map((x) => {
                            'name': x.name,
                          }),
                  'hasRequestParameters': m.parameters.any(
                      (x) => x.location == 'query' || x.location == 'body'),
                  'hasQueryParameters': m.parameters.any(
                    (x) => x.location == 'query',
                  ),
                  'queryParameters': m.parameters
                      .where((element) => element.location == 'query')
                      .map((x) => {
                            'name': x.name,
                          }),
                  'pathParameters': m.parameters
                      .where((element) => element.location == 'path')
                      .map((x) => {
                            'name': x.name,
                          }),
                  'parameters': m.parameters.map((p) => {
                        'name': p.name,
                        'type': p.type,
                      }),
                }),
          }),
      'types': generate.types.values.map((e) => {
            'typeName': e.typeName,
            'isEnum': e.isEnum,
            'enumValues': e.enumValues.map((e) => {
                  'name': e.name,
                  'value': e.value,
                }),
            'isTypeDef': e.isTypedef,
            'typedef': e.typedef,
            'isType': !e.isEnum && !e.isTypedef,
            'properties': e.properties.map((e) => {
                  'description': e.description,
                  'name': e.name,
                  'type': e.type,
                })
          })
    };

    final client = clientTemplate!.renderString(props);

    File('./out/api.ts').writeAsStringSync(client);
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
    final sb = StringBuffer('''${description(m.description)}
${m.name}(${m.parameters.map(parameter).join(', ')}) {
  ${path(m.path, m.parameters)}
  this.api.send('${m.method}', path''');

    if (m.parameters.any((x) => x.location != 'path')) {
      sb.write(', {');
    }

    if (m.parameters.any((x) => x.location == 'query')) {
      sb.write(
          'query: {${m.parameters.where((x) => x.location == 'query').map((x) => x.name).join(',')}}');
    }

    if (m.parameters.any((x) => x.location != 'path')) {
      sb.write('}');
    }

    sb.write(');}');

    return sb.toString();
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
