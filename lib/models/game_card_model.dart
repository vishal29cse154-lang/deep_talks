enum GameCategory { warmUp, deepSecrets, intimate }

enum CardType { truth, dare }

class GameCardModel {
  final String id;
  final GameCategory category;
  final CardType type;
  final String text;

  const GameCardModel({
    required this.id,
    required this.category,
    required this.type,
    required this.text,
  });

  factory GameCardModel.fromMap(Map<String, dynamic> map) {
    return GameCardModel(
      id: map['id'] ?? '',
      category: GameCategory.values.firstWhere(
        (e) => e.name == (map['category'] ?? 'warmUp'),
        orElse: () => GameCategory.warmUp,
      ),
      type: CardType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'truth'),
        orElse: () => CardType.truth,
      ),
      text: map['text'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'type': type.name,
      'text': text,
    };
  }
}
