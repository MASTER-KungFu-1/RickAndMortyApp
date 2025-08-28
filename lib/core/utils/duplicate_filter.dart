import '../../domain/entities/character.dart';

/// Утилита для фильтрации дубликатов персонажей
class DuplicateFilter {
  /// Убирает дубликаты персонажей с одинаковой информацией (кроме ID)
  /// Если все поля кроме ID одинаковые - оставляет только первого
  /// Если хоть что-то отличается - добавляет оба
  static List<Character> removeDuplicates(List<Character> characters) {
    if (characters.isEmpty) return characters;

    final List<Character> uniqueCharacters = [];
    final Map<String, Character> seenCharacters = {};

    for (final character in characters) {
      // Создаем ключ для сравнения (все поля кроме ID)
      final key = _createComparisonKey(character);

      if (seenCharacters.containsKey(key)) {
        // Проверяем, действительно ли это дубликат
        final existingCharacter = seenCharacters[key]!;
        if (_areCharactersIdentical(character, existingCharacter)) {
          // Это дубликат - пропускаем
          continue;
        } else {
          // Хоть что-то отличается - добавляем оба
          uniqueCharacters.add(character);
        }
      } else {
        // Новый персонаж - добавляем
        seenCharacters[key] = character;
        uniqueCharacters.add(character);
      }
    }

    return uniqueCharacters;
  }

  /// Создает ключ для сравнения персонажей (все поля кроме ID)
  static String _createComparisonKey(Character character) {
    return '${character.name}|${character.status}|${character.species}|${character.type}|${character.gender}|${character.image}|${character.url}|${character.created.millisecondsSinceEpoch}';
  }

  /// Проверяет, идентичны ли два персонажа (кроме ID)
  static bool _areCharactersIdentical(Character char1, Character char2) {
    return char1.name == char2.name &&
        char1.status == char2.status &&
        char1.species == char2.species &&
        char1.type == char2.type &&
        char1.gender == char2.gender &&
        char1.image == char2.image &&
        char1.url == char2.url &&
        char1.created.millisecondsSinceEpoch ==
            char2.created.millisecondsSinceEpoch;
  }

  /// Убирает дубликаты с дополнительной информацией о процессе
  static DuplicateFilterResult removeDuplicatesWithInfo(
      List<Character> characters) {
    if (characters.isEmpty) {
      return DuplicateFilterResult(
        originalCount: 0,
        filteredCount: 0,
        removedCount: 0,
        characters: [],
        removedDuplicates: [],
      );
    }

    final List<Character> uniqueCharacters = [];
    final List<Character> removedDuplicates = [];
    final Map<String, Character> seenCharacters = {};

    for (final character in characters) {
      final key = _createComparisonKey(character);

      if (seenCharacters.containsKey(key)) {
        final existingCharacter = seenCharacters[key]!;
        if (_areCharactersIdentical(character, existingCharacter)) {
          // Это дубликат - добавляем в список удаленных
          removedDuplicates.add(character);
          continue;
        } else {
          // Хоть что-то отличается - добавляем оба
          uniqueCharacters.add(character);
        }
      } else {
        // Новый персонаж
        seenCharacters[key] = character;
        uniqueCharacters.add(character);
      }
    }

    return DuplicateFilterResult(
      originalCount: characters.length,
      filteredCount: uniqueCharacters.length,
      removedCount: removedDuplicates.length,
      characters: uniqueCharacters,
      removedDuplicates: removedDuplicates,
    );
  }

  /// Проверяет, есть ли дубликаты в списке
  static bool hasDuplicates(List<Character> characters) {
    if (characters.length < 2) return false;

    final Set<String> seenKeys = {};

    for (final character in characters) {
      final key = _createComparisonKey(character);
      if (seenKeys.contains(key)) {
        return true;
      }
      seenKeys.add(key);
    }

    return false;
  }

  /// Находит все дубликаты в списке
  static List<List<Character>> findDuplicateGroups(List<Character> characters) {
    if (characters.length < 2) return [];

    final Map<String, List<Character>> groups = {};

    for (final character in characters) {
      final key = _createComparisonKey(character);
      groups.putIfAbsent(key, () => []).add(character);
    }

    return groups.values.where((group) => group.length > 1).toList();
  }
}

/// Результат фильтрации дубликатов
class DuplicateFilterResult {
  final int originalCount;
  final int filteredCount;
  final int removedCount;
  final List<Character> characters;
  final List<Character> removedDuplicates;

  const DuplicateFilterResult({
    required this.originalCount,
    required this.filteredCount,
    required this.removedCount,
    required this.characters,
    required this.removedDuplicates,
  });

  /// Процент удаленных дубликатов
  double get removalPercentage =>
      originalCount > 0 ? (removedCount / originalCount) * 100 : 0.0;

  /// Есть ли удаленные дубликаты
  bool get hasRemovedDuplicates => removedCount > 0;

  @override
  String toString() {
    return 'DuplicateFilterResult(original: $originalCount, filtered: $filteredCount, removed: $removedCount, percentage: ${removalPercentage.toStringAsFixed(1)}%)';
  }
}
