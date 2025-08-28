import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rick_and_morty/data/api/rick_and_morty_api.dart';
import 'package:rick_and_morty/data/dao/character_dao.dart';
import 'package:rick_and_morty/data/dto/character_dto.dart';
import 'package:rick_and_morty/data/repositories/character_repository_impl.dart';

class _FakeDao extends CharacterDao {
  final Map<String, CharacterDto> store = {};
  List<int> favorites = [];

  @override
  Future<void> saveCharacters(List<CharacterDto> characters) async {
    for (final c in characters) {
      store[c.id.toString()] = c;
    }
  }

  @override
  Future<void> addCharacters(List<CharacterDto> characters) async {
    for (final c in characters) {
      store[c.id.toString()] = c;
    }
  }

  @override
  Future<List<CharacterDto>> getCharacters() async => store.values.toList();

  @override
  Future<CharacterDto?> getCharacter(int id) async => store[id.toString()];

  @override
  Future<void> saveFavorite(int characterId) async {
    if (!favorites.contains(characterId)) favorites.add(characterId);
  }

  @override
  Future<void> removeFavorite(int characterId) async {
    favorites.remove(characterId);
  }

  @override
  Future<List<int>> getFavorites() async => favorites;
}

CharacterDto _dto(int id, String name) => CharacterDto(
      id: id,
      name: name,
      status: 'Alive',
      species: 'Human',
      type: '',
      gender: 'Male',
      image: 'https://example.com/$id.png',
      url: 'https://example.com/$id',
      created: '2017-11-04T18:48:46.250Z',
    );

void main() {
  test('Repository returns cache on page 1 when available quickly', () async {
    final dao = _FakeDao()..store['1'] = _dto(1, 'Rick');
    final api = RickAndMortyApi(
      client: MockClient((request) async {
        final body = jsonEncode({'results': []});
        return http.Response(body, 200);
      }),
    );
    final repo = CharacterRepositoryImpl(api, dao);

    final start = DateTime.now();
    final result = await repo.getCharacters(page: 1);
    final elapsedMs = DateTime.now().difference(start).inMilliseconds;

    expect(result.isSuccess, true);
    expect(result.data!.length, 1);
    expect(elapsedMs, lessThan(200));
  });

  test('Repository fetches from API and saves to cache, timing check',
      () async {
    final dao = _FakeDao();
    final api = RickAndMortyApi(
      client: MockClient((request) async {
        final body = jsonEncode({
          'results': [
            {
              'id': 2,
              'name': 'Morty Smith',
              'status': 'Alive',
              'species': 'Human',
              'type': '',
              'gender': 'Male',
              'image': 'https://example.com/2.png',
              'url': 'https://example.com/2',
              'created': '2017-11-04T18:50:21.651Z'
            }
          ]
        });
        return http.Response(body, 200,
            headers: {'content-type': 'application/json'});
      }),
    );
    final repo = CharacterRepositoryImpl(api, dao);

    final start = DateTime.now();
    final result = await repo.getCharacters(page: 1);
    final elapsedMs = DateTime.now().difference(start).inMilliseconds;

    expect(result.isSuccess, true);
    expect(result.data!.any((c) => c.id == 2), true);
    expect((await dao.getCharacters()).length, 1);
    expect(elapsedMs, lessThan(600));
  });

  test(
      'Repository getCharacter returns cached then API when absent, timing check',
      () async {
    final dao = _FakeDao();
    final api = RickAndMortyApi(
      client: MockClient((request) async {
        final body = jsonEncode({
          'id': 3,
          'name': 'Summer Smith',
          'status': 'Alive',
          'species': 'Human',
          'type': '',
          'gender': 'Female',
          'image': 'https://example.com/3.png',
          'url': 'https://example.com/3',
          'created': '2017-11-04T18:50:21.651Z'
        });
        return http.Response(body, 200,
            headers: {'content-type': 'application/json'});
      }),
    );
    final repo = CharacterRepositoryImpl(api, dao);

    // first fetch from API
    final start = DateTime.now();
    final result = await repo.getCharacter(3);
    final elapsedMs = DateTime.now().difference(start).inMilliseconds;
    expect(result.isSuccess, true);
    expect(result.data!.id, 3);
    expect(elapsedMs, lessThan(600));

    // second fetch from cache should be fast
    final start2 = DateTime.now();
    final result2 = await repo.getCharacter(3);
    final elapsed2Ms = DateTime.now().difference(start2).inMilliseconds;
    expect(result2.isSuccess, true);
    expect(result2.data!.id, 3);
    expect(elapsed2Ms, lessThan(150));
  });
}
