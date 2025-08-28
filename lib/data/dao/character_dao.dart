import 'package:hive/hive.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/constants.dart';
import '../dto/character_dto.dart';

class CharacterDao {
  static const String _boxName = AppConstants.charactersBox;

  Future<Box<CharacterDto>> _getBox() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        return await Hive.openBox<CharacterDto>(_boxName);
      }
      return Hive.box<CharacterDto>(_boxName);
    } catch (e) {
      throw CacheError.readError('Не удалось открыть box $_boxName: $e');
    }
  }

  Future<void> saveCharacters(List<CharacterDto> characters) async {
    try {
      final box = await _getBox();
      await box.clear();

      for (final character in characters) {
        await box.put(character.id.toString(), character);
      }
    } catch (e) {
      throw CacheError.writeError('Не удалось сохранить персонажей: $e');
    }
  }

  Future<void> addCharacters(List<CharacterDto> characters) async {
    try {
      final box = await _getBox();

      for (final character in characters) {
        await box.put(character.id.toString(), character);
      }
    } catch (e) {
      throw CacheError.writeError('Не удалось добавить персонажей: $e');
    }
  }

  Future<List<CharacterDto>> getCharacters() async {
    try {
      final box = await _getBox();
      return box.values.toList();
    } catch (e) {
      throw CacheError.readError('Не удалось получить персонажей: $e');
    }
  }

  Future<CharacterDto?> getCharacter(int id) async {
    try {
      final box = await _getBox();
      return box.get(id.toString());
    } catch (e) {
      throw CacheError.readError('Не удалось получить персонажа с ID $id: $e');
    }
  }

  Future<void> saveFavorite(int characterId) async {
    try {
      final favoritesBox = await Hive.openBox<int>('favorites_box');
      if (!favoritesBox.values.contains(characterId)) {
        await favoritesBox.add(characterId);
      }
    } catch (e) {
      throw CacheError.writeError('Не удалось сохранить избранное: $e');
    }
  }

  Future<void> removeFavorite(int characterId) async {
    try {
      final favoritesBox = await Hive.openBox<int>('favorites_box');
      final index = favoritesBox.values.toList().indexOf(characterId);
      if (index != -1) {
        await favoritesBox.deleteAt(index);
      }
    } catch (e) {
      throw CacheError.deleteError('Не удалось удалить из избранного: $e');
    }
  }

  Future<List<int>> getFavorites() async {
    try {
      final favoritesBox = await Hive.openBox<int>('favorites_box');
      return favoritesBox.values.toList();
    } catch (e) {
      throw CacheError.readError('Не удалось получить избранное: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      throw CacheError.deleteError('Не удалось очистить кэш: $e');
    }
  }
}
