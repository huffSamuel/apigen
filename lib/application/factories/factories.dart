import '../../configurations/language_specific_configuration.dart';
import '../../configurations/typescript/typescript.dart';
import '../../extension/map.dart';
import '../../schemas/schema.dart';
import '../../syntax/node.dart';
import '../../utils/log.dart';
import '../generate.dart';
import '../utils/reference_name.dart';

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
