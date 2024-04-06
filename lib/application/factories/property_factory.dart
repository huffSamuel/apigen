part of 'factories.dart';

PropertyNode property(
  String name,
  OpenApiSchema schema,
  TypeDeclNode t,
  LanguageSpecificConfiguration config,
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
        case null:
          pr.type = config.anyType();
          break;
        case final CompositeSchema comp:
          if (config.supports(compositeTypeFeature(comp))) {
            // TODO: Generate the composite type
            Log.info("Generate the composite type");

            // If it's a composite but only contains a single child spec then it isn't actually a composite.
          }
          pr.type = config.anyType();
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
      if (config.supports(compositeTypeFeature(comp))) {
        Log.info("Generate composite type");
      }
      pr.type = config.anyType();
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
