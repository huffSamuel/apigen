import '../../configurations/language_specific_configuration.dart';
import '../../domain/schemas/schema.dart';
import '../../domain/syntax/node.dart';
import '../feature.dart';
import '../generate.dart';
import '../log.dart';
import '../utils/casing.dart';
import '../utils/inherit_parent_name.dart';
import '../utils/name.dart';

part 'body_type_factory.dart';
part 'enum_factory.dart';
part 'object_type.dart';
part 'property_factory.dart';
part 'typedef.dart';

void safeAdd(Generate generate, String name, TypeDeclNode node) {
  if (generate.types.containsKey(name)) {
    throw 'Key $name already exists';
  }

  generate.types[name] = node;
}