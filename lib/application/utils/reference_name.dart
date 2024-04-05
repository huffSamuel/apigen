import '../../schemas/schema.dart';

String referenceName(OpenApiReferenceSchema ref) {
  return ref.ref.substring(ref.ref.lastIndexOf('/') + 1);
}
