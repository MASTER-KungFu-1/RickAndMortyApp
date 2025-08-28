import '../../core/errors/app_error.dart';
import '../../core/utils/duplicate_filter.dart';
import '../../domain/entities/character.dart';
import '../../domain/repositories/character_repository.dart';
import '../api/rick_and_morty_api.dart';
import '../dao/character_dao.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final RickAndMortyApi _api;
  final CharacterDao _dao;

  CharacterRepositoryImpl(this._api, this._dao);

  @override
  Future<Result<List<Character>>> getCharacters({int page = 1}) async {
    try {
      // Сначала пытаемся получить из кэша
      final cachedCharacters = await _dao.getCharacters();

      if (page == 1 && cachedCharacters.isNotEmpty) {
        // Для первой страницы возвращаем кэшированные данные
        final entities = cachedCharacters.map((dto) => dto.toEntity()).toList();
        final filteredCharacters = DuplicateFilter.removeDuplicates(entities);
        return Result.success(filteredCharacters);
      }

      // Получаем новые данные с API
      try {
        final newCharacters = await _api.getCharacters(page: page);

        // Сохраняем в кэш
        if (page == 1) {
          await _dao.saveCharacters(newCharacters);
        } else {
          // Для последующих страниц добавляем к существующим
          await _dao.addCharacters(newCharacters);
        }

        // Получаем все кэшированные данные и фильтруем дубликаты
        final allCachedCharacters = await _dao.getCharacters();
        final entities =
            allCachedCharacters.map((dto) => dto.toEntity()).toList();
        final filteredCharacters = DuplicateFilter.removeDuplicates(entities);

        return Result.success(filteredCharacters);
      } on AppError catch (e) {
        // Если API недоступен, возвращаем кэшированные данные
        if (cachedCharacters.isNotEmpty) {
          final entities =
              cachedCharacters.map((dto) => dto.toEntity()).toList();
          final filteredCharacters = DuplicateFilter.removeDuplicates(entities);
          return Result.success(filteredCharacters);
        }
        return Result.failure(e);
      }
    } catch (e, stackTrace) {
      return Result.failure(UnknownError.fromException(e, stackTrace));
    }
  }

  @override
  Future<Result<Character>> getCharacter(int id) async {
    try {
      // Сначала пытаемся получить из кэша
      final cachedCharacter = await _dao.getCharacter(id);
      if (cachedCharacter != null) {
        return Result.success(cachedCharacter.toEntity());
      }

      // Если нет в кэше, получаем с API
      try {
        final character = await _api.getCharacter(id);
        // Сохраняем в кэш для будущего использования
        await _dao.saveCharacters([character]);
        return Result.success(character.toEntity());
      } on AppError catch (e) {
        return Result.failure(e);
      }
    } catch (e, stackTrace) {
      return Result.failure(UnknownError.fromException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<Character>>> searchCharacters(String query) async {
    try {
      // Сначала пытаемся найти в кэше
      final cachedCharacters = await _dao.getCharacters();
      final cachedEntities =
          cachedCharacters.map((dto) => dto.toEntity()).toList();
      final cachedResults = cachedEntities
          .where((character) =>
              character.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

      // Получаем результаты с API
      try {
        final apiCharacters = await _api.searchCharacters(query);
        final apiEntities = apiCharacters.map((dto) => dto.toEntity()).toList();

        // Объединяем результаты и убираем дубликаты
        final allResults = [...cachedResults, ...apiEntities];
        final filteredResults = DuplicateFilter.removeDuplicates(allResults);

        // Сохраняем новые результаты в кэш
        if (apiCharacters.isNotEmpty) {
          await _dao.saveCharacters(apiCharacters);
        }

        return Result.success(filteredResults);
      } on AppError catch (e) {
        // Если API недоступен, возвращаем кэшированные результаты
        if (cachedResults.isNotEmpty) {
          return Result.success(cachedResults);
        }
        return Result.failure(e);
      }
    } catch (e, stackTrace) {
      return Result.failure(UnknownError.fromException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<Character>>> getFavorites() async {
    try {
      final favoriteIds = await _dao.getFavorites();
      final characters = <Character>[];

      for (final id in favoriteIds) {
        final character = await getCharacter(id);
        if (character.isSuccess) {
          characters.add(character.data!);
        }
      }

      // Убираем дубликаты из избранного
      final filteredFavorites = DuplicateFilter.removeDuplicates(characters);
      return Result.success(filteredFavorites);
    } catch (e, stackTrace) {
      return Result.failure(UnknownError.fromException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<int>>> getFavoriteIds() async {
    try {
      final favoriteIds = await _dao.getFavorites();
      return Result.success(favoriteIds);
    } catch (e, stackTrace) {
      return Result.failure(UnknownError.fromException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> toggleFavorite(int characterId) async {
    try {
      final favoriteIds = await _dao.getFavorites();

      if (favoriteIds.contains(characterId)) {
        await _dao.removeFavorite(characterId);
      } else {
        await _dao.saveFavorite(characterId);
      }

      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(UnknownError.fromException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> removeFromFavorites(int characterId) async {
    try {
      await _dao.removeFavorite(characterId);
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(UnknownError.fromException(e, stackTrace));
    }
  }
}
