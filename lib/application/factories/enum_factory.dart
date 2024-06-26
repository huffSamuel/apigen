part of 'factories.dart';

void enums(
  String name,
  OpenApiSchema obj,
  GenerateConfig config,
  Generate generate
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

  safeAdd(generate, name, t);
}
