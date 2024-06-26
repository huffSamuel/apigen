import '../domain/schemas/schema.dart';

abstract class GenerateConfig {
  Map<String, String> get typeMap;
  /// Name of this language configuration.
  /// 
  /// This name determines the assets to use when generating source code. For instance:  
  /// `"typescript-fetch"` will use assets in `/assets/typescript/fetch`. 
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
