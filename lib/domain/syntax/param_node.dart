import '../schemas/spec_file.dart';
import 'node.dart';

class ParamDecl extends Node {
  String? _name;

  late String type;
  OpenApiParameter? schema;
  String get name => schema?.name ?? _name ?? 'unknown';
  set name(String value) => _name = value;
  String get location => schema?.location ?? 'body';
  bool isArray = false;

  ParamDecl(super.id);
}
