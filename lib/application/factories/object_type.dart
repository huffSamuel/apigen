part of 'factories.dart';

void objectType(
  String name,
  OpenApiObjectSchema obj,
  LanguageSpecificConfiguration config,
  Generate generate,
) {
  final t = TypeDeclNode(name, obj);
  t.typeName = config.typeName(name);
  t.fileName = config.fileName(name);

  for (final p in obj.properties.entries) {
    final prop = property(
      config.className(t.typeName + config.className(p.key)),
      p.value,
      t,
      config,
      generate,
    );
    prop.required = obj.required.contains(p.key);
    t.properties.add(prop);
  }

  safeAdd(generate, name, t);
}
