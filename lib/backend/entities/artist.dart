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
}
