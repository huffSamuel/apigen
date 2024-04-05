import '../configurations/language_specific_configuration.dart';
import '../schemas/schema.dart';
import '../syntax/node.dart';

TypeDeclNode enums(
  String name,
  OpenApiSchema obj,
  LanguageSpecificConfiguration config,
) {
  final t = TypeDeclNode(name, obj);

  t.isEnum = true;
  t.typeName = config.typeName(name);
  t.enumValues.addAll(obj.enumValues!.map((x) {
    final d = EnumValueDecl(x);

    d.typeName = config.typeName(obj.type ?? 'unknown');
    d.value = x;
    d.name = config.enumValueName(x);

    return d;
  }));

  return t;
}
