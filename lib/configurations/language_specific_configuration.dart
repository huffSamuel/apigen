import '../application/feature.dart';

abstract class LanguageSpecificConfiguration {
  Map<String, String> get typeMap;
  String get configurationName;
  List<String> get reservedWords;
  List<Feature> get supportedFeatures;

  String className(String name);
  String typeName(String name);
  String propertyName(String name);
  String enumValueName(String name);
  String methodName(String name);
  String anyType();

  bool supports(Feature? feat) => supportedFeatures.contains(feat);
}
