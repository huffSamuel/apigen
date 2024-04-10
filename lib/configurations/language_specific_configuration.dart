import '../domain/schemas/schema.dart';

abstract class GenerateConfig {
  Map<String, String> get typeMap;
  String get name;
  List<String> get reservedWords;

  String arrayType(String name);
  String className(String name);
  String typeName(String name);
  String typename({String name, Schema schema});
  String propertyName(String name);
  String enumValueName(String name);
  String methodName(String name);
  String anyType();
}
