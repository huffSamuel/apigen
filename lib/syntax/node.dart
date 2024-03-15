import '../schemas/schema.dart';

abstract class Node {
  String id;

  Node(this.id);
}

class PropertyNode extends Node {
  final OpenApiSchema schema;

  String? get description => schema.description?.trim();

  late String name;
  late String type;

  bool required = false;
  bool get readonly => schema.readOnly ?? false;
  bool get isArray => schema is OpenApiArraySchema;

  /// If set, this property referenced a type that had not yet been identified and
  /// needs to be finished at a later time.
  ///
  /// This assists in identifying enums.
  String? typeReference;

  // If set, this property's [type] is a typedef.
  bool isTypedef = false;

  /// If set, this type is defined by the API.
  bool apiType = false;

  /// If set, this type is an enum
  bool isEnumType = false;

  PropertyNode(super.id, this.schema);
}

class EnumValueDecl extends Node {
  String? description;

  late String typeName;
  late dynamic value;
  late String name;

  EnumValueDecl(super.id);
}

class TypeDeclNode extends Node {
  late String typeName;
  late String fileName;

  bool isTypedef = false;
  String typedef = '';

  String? get description => schema.description?.trim();

  final OpenApiSchema schema;
  final List<PropertyNode> properties = [];
  final List<TypeDeclNode> typeDecls = [];
  final Map<String, Set<String>> references = {};

  bool isEnum = false;
  List<EnumValueDecl> enumValues = [];

  TypeDeclNode(super.name, this.schema);

  @override
  String toString() {
    return id;
  }
}
