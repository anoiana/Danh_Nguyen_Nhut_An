class EventModel {
  final String id;
  final String title;
  final String imageUrl;
  final String link;

  EventModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.link,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Handle image URL logic similar to the React code
    String img = "https://placehold.co/1200x450?text=Event";
    if (json['image'] != null) {
      if (json['image'] is Map && json['image']['url'] != null) {
        img = json['image']['url'];
      } else if (json['image'] is String) {
        img = json['image'];
      }
    }

    return EventModel(
      id: json['_id'] ?? '',
      title: json['name'] ?? 'Sự kiện',
      imageUrl: img,
      link: json['slug'] ?? '',
    );
  }
}