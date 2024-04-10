part of 'factories.dart';

void typedef(
  String name,
  OpenApiSchema schema,
  GenerateConfig config,
  Generate generate,
) {
  final t = TypeDeclNode(name, schema);
  t.typeName = config.typeName(name);
  t.isTypedef = true;
  t.typedef = schema.type!;

  safeAdd(generate, name, t);
}
