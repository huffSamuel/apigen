import '../application/feature.dart';
import '../domain/schemas/schema.dart';

abstract class LanguageSpecificConfiguration {
  Map<String, String> get typeMap;
  String get configurationName;
  List<String> get reservedWords;
  List<Feature> get supportedFeatures;

  String className(String name);
  String typeName(String name);
  String typename({String name, Schema schema});
  String propertyName(String name);
  String enumValueName(String name);
  String methodName(String name);
  String anyType();

  bool supports(Feature? feat) => supportedFeatures.contains(feat);
}
