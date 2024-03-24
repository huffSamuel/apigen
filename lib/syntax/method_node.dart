import '../schemas/spec_file.dart';
import 'node.dart';
import 'param_node.dart';

class MethodNode extends Node {
  final OpenApiOperation schema;
  final List<ParamDecl> parameters = [];

  String? get description => schema.description;

  late String name;
  late String path;

  MethodNode(super.id, this.schema);

  @override
  String toString() {
    return name;
  }
}
