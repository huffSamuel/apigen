import '../../schemas/schema.dart';

bool isEnum(OpenApiSchema schema) {
  return schema.enumValues?.isNotEmpty == true;
}
