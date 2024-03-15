abstract class LanguageSpecificConfiguration {
  Map<String, String> get typeMap;
  String get configurationName;
  List<String> get reservedWords;

  String className(String name);
  String typeName(String name);
  String propertyName(String name);
  String enumValueName(String name);
  String fileName(String name);
  String methodName(String name);
}