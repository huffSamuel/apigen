import 'method_node.dart';
import '../schemas/schema.dart';

abstract class Node {
  String id;

  Node(this.id);
}

String? _description(OpenApiSchema? schema) {
  if (schema == null ||
      schema.description == null ||
      schema.description!.trim().isEmpty) {
    return null;
  }

  return schema.description!.trim();
}

class PropertyNode extends Node {
  final OpenApiSchema schema;

  String? get description => _description(schema);

  late String name;
  late String type;

  bool required = false;
  bool get readonly => schema.readOnly ?? false;
  bool get isArray => schema is OpenApiArraySchema;

  // If set, this property's [type] is a typedef.
  bool isTypedef = false;

  PropertyNode(super.id, this.schema);
}

class EnumValueDecl extends Node {
  late String typeName;
  late dynamic value;
  late String name;

  EnumValueDecl(super.id);
}

class TypeDeclNode extends Node {
  late String typeName;

  bool isTypedef = false;
  String typedef = '';

  String? get description => _description(schema);

  final OpenApiSchema? schema;
  final List<PropertyNode> properties = [];
  final Map<String, Set<String>> references = {};
  final List<MethodNode> methods = [];

  bool isEnum = false;
  List<EnumValueDecl> enumValues = [];

  TypeDeclNode(super.name, [this.schema]);

  @override
  String toString() {
    return id;
  }
}

class ApiDeclNode extends Node {
  late String typeName;

  bool isTypedef = false;
  String typedef = '';

  String? get description => _description(schema);

  final OpenApiSchema? schema;
  final Map<String, Set<String>> references = {};
  final List<MethodNode> methods = [];

  ApiDeclNode(super.name, [this.schema]);

  @override
  String toString() {
    return id;
  }
}
