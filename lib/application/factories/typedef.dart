part of 'factories.dart';

void typedef(
  String name,
  OpenApiSchema schema,
  LanguageSpecificConfiguration config,
  Generate generate,
) {
  final t = TypeDeclNode(name, schema);
  t.typeName = config.typeName(name);
  t.fileName = config.fileName(name);
  t.isTypedef = true;
  t.typedef = schema.type!;

  safeAdd(generate, name, t);
}
