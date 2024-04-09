import 'schemas/spec_file.dart';

bool hasContentType(HasContent? obj, ContentType contentType) {
  return obj != null &&
      obj.content != null &&
      obj.content![contentType.type] != null;
}

OpenApiMediaType getContent(HasContent obj, ContentType contentType) {
  return obj.content![contentType.type]!;
}

enum ContentType {
  json("application/json");

  const ContentType(this.type);

  final String type;
}
