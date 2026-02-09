class Folder {
  final int id;
  final String name;
  final int userId;
  final int vocabularyCount;

  Folder({
    required this.id,
    required this.name,
    required this.userId,
    required this.vocabularyCount,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'],
      name: json['name'],
      userId: json['userId'],
      vocabularyCount: json['vocabularyCount'] ?? 0,
    );
  }
}

class FolderPage {
  final List<Folder> content;
  final int totalPages;
  final bool isLast;

  FolderPage({
    required this.content,
    required this.totalPages,
    required this.isLast,
  });

  factory FolderPage.fromJson(Map<String, dynamic> json) {
    var list = json['content'] as List;
    List<Folder> folderList = list.map((i) => Folder.fromJson(i)).toList();
    return FolderPage(
      content: folderList,
      totalPages: json['totalPages'],
      isLast: json['last'],
    );
  }
}
