import '../../schemas/schema.dart';
import '../../utils/log.dart';

void processSchema(
  OpenApiSchema? schema, {
  Function(OpenApiObjectSchema onObject)? onObject,
  Function(OpenApiReferenceSchema onReference)? onReference,
  Function()? onArrayNull,
  Function()? onNull,
}) {
  switch (schema) {
    case final OpenApiArraySchema ray:
      processSchema(
        ray.items!.a,
        onObject: onObject,
        onReference: onReference,
        onNull: onArrayNull,
      );
      break;
    case final OpenApiObjectSchema obj:
      onObject?.call(obj);
      break;
    case final OpenApiReferenceSchema ref:
      onReference?.call(ref);
      break;
    case null:
      onNull?.call();
    default:
      Log.error("Cannot process this type");
  }
}
