part of 'factories.dart';

void bodyType(
  String name,
  OpenApiObjectSchema obj,
  LanguageSpecificConfiguration config,
  Generate generate,
) {
  final t = TypeDeclNode(name, obj);
  t.typeName = config.typeName(name);

  for (final p in obj.properties.entries) {
    final prop = property(
      config.className(firstUpper(name) + firstUpper(p.key)),
      p.value,
      t,
      config,
      generate,
    );
    // TODO: This is a workaround for how the c'tor generates the property
    prop.name = p.key;
    prop.required = obj.required.contains(p.key);
    t.properties.add(prop);
  }

  safeAdd(generate, name, t);
}
