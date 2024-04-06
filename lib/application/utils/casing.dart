/// camelCase
String camelCase(List<String> parts) {
  return parts.skip(1).fold(parts[0].toLowerCase(), (a, b) => a + _pascal(b));
}

/// snake_case
String snakeCase(List<String> parts) {
  return parts.map((x) => x.toLowerCase()).join('_');
}

/// PascalCase
String pascalCase(List<String> parts) {
  return parts.map(_pascal).join('');
}

String _pascal(String p) {
  return p[0].toUpperCase() + p.substring(1).toLowerCase();
}

/// Similar to PascalCase but preserves the casing of the string except for the first character.
String firstUpper(String str) {
  return str[0].toUpperCase() + str.substring(1);
}

String firstLower(String str) {
  return str[0].toLowerCase() + str.substring(1);
}
