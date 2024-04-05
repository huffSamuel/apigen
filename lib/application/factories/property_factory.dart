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
          Log.warn(
              'This is likely a composite schema that we cannot handle at this time');
          pr.type = config.anyType();
          break;
        default:
          pr.type = config.typeName(ray.items!.a!.type ?? 'unknown');

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
    default:
      pr.type = config.typeName(schema.type ?? 'unknown');

      if (schema.enumValues?.isNotEmpty == true) {
        enums(name, schema, config, generate);
      }
      break;
  }

  return pr;
}
