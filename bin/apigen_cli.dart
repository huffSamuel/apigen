import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'package:apigen_cli/api_generator.dart';

const String version = '0.0.1';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'Print the tool version.',
    )
    ..addOption("schema", mandatory: true);
}

void printUsage(ArgParser argParser) {
  print('Usage: dart apigen_cli.dart <flags> [arguments]');
  print(argParser.usage);
}

class GenerateCommand extends Command {
  @override
  String get description => "Given a schema, generate an API implementation";

  @override
  String get name => "generate";


  @override
  void run() {
    final apiGenerator = ApiGenerator();
    apiGenerator.generate(argResults!.rest.single);
  }
}

void main(List<String> arguments) {
  CommandRunner("apigen", "Generates OpenAPI spec API clients")
    ..addCommand(GenerateCommand())
    ..run(arguments);
}
