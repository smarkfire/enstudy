class File {
  final String path;
  File(this.path);

  Future<List<int>> readAsBytes() async => [];
  Future<String> readAsString() async => '';
  Future<void> writeAsBytes(List<int> bytes) async {}
  Future<void> writeAsString(String content) async {}
  Future<bool> exists() async => false;
}

class Directory {
  final String path;
  Directory(this.path);

  Future<bool> exists() async => false;
}
