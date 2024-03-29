import '../schemas/spec_file.dart';
import 'node.dart';

class ParamDecl extends Node {
  late String type;
  OpenApiParameter? schema;
  String get name => schema?.name ?? 'unknown';
  String get location => schema?.location ?? 'unknown';

  ParamDecl(super.id);
}
