class Version {
  int _major;
  int _minor;
  int _patch;

  Version({this._major = 0, this._minor = 0, this._patch = 0});

  static int _parseInt(List<String> versionNumbers, int index) =>
      (index > versionNumbers.length)
      ? 0
      : int.tryParse(versionNumbers[index]) ?? 0;

  static Version of(String version) {
    if (version.isEmpty) {
      return Version();
    }

    final versionNumbers = version.split(".");
    return Version(
      major: _parseInt(versionNumbers, 0),
      minor: _parseInt(versionNumbers, 1),
      patch: _parseInt(versionNumbers, 2),
    );
  }

  int get major => _major;
  int get minor => _minor;
  int get patch => _patch;

  void setMajor(int major) => _major = major;
  void setMinor(int minor) => _minor = minor;
  void setPatch(int patch) => _patch = patch;

  int compare(Version other) {
    int current = _major - other._major;
    if (current != 0) {
      return current;
    }

    current = _minor - other._minor;
    if (current != 0) {
      return current;
    }

    return _patch - other._patch;
  }

  @override
  String toString() => "$_major.$_minor.$_patch";
}
