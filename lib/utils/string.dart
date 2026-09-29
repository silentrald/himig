import "dart:convert";
import "dart:math";

import "package:crypto/crypto.dart";

// https://stackoverflow.com/a/61929967
const _characters =
    "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890";
final _random = Random();

String getRandomString(int length) {
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _characters.codeUnitAt(_random.nextInt(_characters.length)),
    ),
  );
}

String hashMd5(String plaintext) {
  return md5.convert(utf8.encode(plaintext)).toString();
}

bool isValidHostname(String hostname) {
  try {
    final uri = Uri.parse(hostname);
    return uri.host.isNotEmpty;
  } catch (e) {
    return false;
  }
}
