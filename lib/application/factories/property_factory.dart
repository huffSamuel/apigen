part of 'factories.dart';

PropertyNode property(
  String name,
  OpenApiSchema schema,
  TypeDeclNode t,
  GenerateConfig config,
  Generate generate,
) {
  final pr = PropertyNode(name, schema);
  pr.name = config.propertyName(name);

  switch (schema) {
    case final OpenApiArraySchema ray:
      switch (ray.items!.a) {
        case final OpenApiReferenceSchema ref:
          pr.type = config.className(referenceName(ref));
          break;
        case final OpenApiObjectSchema obj:
          pr.type = config.className(name);
          objectType(name, obj, config, generate);
          break;
        case final CompositeSchema comp:
          // TODO: This needs to generate any non-reference derived subtypees.
          pr.type = config.typename(schema: comp);
          break;
        default:
          final t = (ray.items!.a as OpenApiSchema).type;
          pr.type = config.typeName(t ?? 'unknown');

          if (schema.enumValues?.isNotEmpty == true) {
            enums(name, schema, config, generate);
          }
      }
      break;
    case final OpenApiReferenceSchema ref:
      pr.type = config.className(referenceName(ref));
      break;
    case final OpenApiObjectSchema obj:
      pr.type = config.className(name);
      objectType(
        name,
        obj,
        config,
        generate,
      );
      break;
    case final CompositeSchema comp:
      // TODO: This needs to generate any non-reference derived subtypees.
      pr.type = config.typename(schema: comp);
      break;
    default:
      pr.type = config.typeName(schema.type ?? 'unknown');

      if (schema.enumValues?.isNotEmpty == true) {
        enums(name, schema, config, generate);
      }
      break;
  }

  return pr;
}
