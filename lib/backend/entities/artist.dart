import "dart:convert";

import "package:flutter/foundation.dart";

class Artist {
  int id;
  String name;
  Uri? imageUri;

  Artist({this.id = 0, required this.name, this.imageUri});

  Artist copyWith({int? id, String? name, Uri? imageUri}) => Artist(
    id: id ?? this.id,
    name: name ?? this.name,
    imageUri: imageUri ?? this.imageUri,
  );

  Map<String, dynamic> _toJson() => {
    "id": id,
    "name": name,
    "imageUri": imageUri?.toString(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Artist && mapEquals(_toJson(), other._toJson()));

  @override
  int get hashCode => id;

  @override
  String toString() => jsonEncode(_toJson());
}
