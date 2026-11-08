import 'dart:convert';

class SnippetModel {
  final String id;
  final String title;
  final String command;
  final String category;

  const SnippetModel({
    required this.id,
    required this.title,
    required this.command,
    this.category = 'General',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'command': command,
      'category': category,
    };
  }

  factory SnippetModel.fromMap(Map<String, dynamic> map) {
    return SnippetModel(
      id: map['id'] as String,
      title: map['title'] as String,
      command: map['command'] as String,
      category: map['category'] as String? ?? 'General',
    );
  }

  String toJson() => json.encode(toMap());

  factory SnippetModel.fromJson(String source) =>
      SnippetModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
