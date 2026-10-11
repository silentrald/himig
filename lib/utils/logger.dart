// ignore_for_file: avoid_print

import "package:flutter/foundation.dart";
import "package:intl/intl.dart";

enum Level {
  fatal(1),
  error(2),
  warn(3),
  info(4),
  debug(5)
  //trace(6),
  ;

  final int value;

  const Level(this.value);
}

Level _level = Level.debug;

final _dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");
String _getCurrentDateString() => _dateFormat.format(DateTime.now());

void setLevel(Level level) => _level = level;

void fatal(String message) {
  if (kReleaseMode) {
    _fatalProd(message);
  } else {
    _fatalDev(message);
  }
}

void error(String message, {Exception? error}) {
  if (kReleaseMode) {
    _errorProd(message, error: error);
  } else {
    _errorDev(message, error: error);
  }
}

void warn(String message) {
  if (kReleaseMode) {
    _warnProd(message);
  } else {
    _warnDev(message);
  }
}

void info(String message) {
  if (kReleaseMode) {
    _infoProd(message);
  } else {
    _infoDev(message);
  }
}

void debug(String message) {
  if (kReleaseMode) {
    _debugProd(message);
  } else {
    _debugDev(message);
  }
}

/* Development/Debug Implentation */

void _fatalDev(String message) {
  print("${_getCurrentDateString()} \x1B[31mFATAL\x1B[0m: $message");
}

void _errorDev(String message, {Exception? error}) {
  if (_level.value < Level.error.value) {
    return;
  }

  print("${_getCurrentDateString()} \x1B[31mERROR\x1B[0m: $message");
  if (error != null) print(error);
}

void _warnDev(String message) {
  if (_level.value < Level.warn.value) {
    return;
  }

  print("${_getCurrentDateString()} \x1B[33mWARN\x1B[0m: $message");
}

void _infoDev(String message) {
  if (_level.value < Level.info.value) {
    return;
  }

  print("${_getCurrentDateString()} \x1B[32mINFO\x1B[0m: $message");
}

void _debugDev(String message) {
  if (_level.value < Level.info.value) {
    return;
  }

  print("${_getCurrentDateString()} \x1B[35mDEBUG\x1B[0m: $message");
}

/* Production Implementation */

void _fatalProd(String message) {
  // TODO:
}

void _errorProd(String message, {Exception? error}) {
  // TODO:
}

void _warnProd(String message) {
  // TODO:
}

void _infoProd(String message) {
  // TODO:
}

void _debugProd(String message) {
  // TODO:
}
