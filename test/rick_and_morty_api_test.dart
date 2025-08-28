import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rick_and_morty/data/api/rick_and_morty_api.dart';

void main() {
  test('getCharacters returns parsed list and within time budget', () async {
    final client = MockClient((request) async {
      final results = [
        {
          'id': 1,
          'name': 'Rick Sanchez',
          'status': 'Alive',
          'species': 'Human',
          'type': '',
          'gender': 'Male',
          'image': 'https://example.com/1.png',
          'url': 'https://example.com/1',
          'created': '2017-11-04T18:48:46.250Z'
        }
      ];
      final body = jsonEncode({'results': results});
      return http.Response(body, 200,
          headers: {'content-type': 'application/json'});
    });

    final api = RickAndMortyApi(client: client);

    final start = DateTime.now();
    final list = await api.getCharacters(page: 1);
    final elapsedMs = DateTime.now().difference(start).inMilliseconds;

    expect(list.length, 1);
    expect(list.first.id, 1);
    expect(elapsedMs, lessThan(500));
  });

  test('getCharacter returns parsed character and within time budget',
      () async {
    final client = MockClient((request) async {
      final body = jsonEncode({
        'id': 2,
        'name': 'Morty Smith',
        'status': 'Alive',
        'species': 'Human',
        'type': '',
        'gender': 'Male',
        'image': 'https://example.com/2.png',
        'url': 'https://example.com/2',
        'created': '2017-11-04T18:50:21.651Z'
      });
      return http.Response(body, 200,
          headers: {'content-type': 'application/json'});
    });

    final api = RickAndMortyApi(client: client);

    final start = DateTime.now();
    final c = await api.getCharacter(2);
    final elapsedMs = DateTime.now().difference(start).inMilliseconds;

    expect(c.id, 2);
    expect(c.name, 'Morty Smith');
    expect(elapsedMs, lessThan(500));
  });

  test('searchCharacters returns list, empty on 404, timing check', () async {
    final client = MockClient((request) async {
      if (request.url.toString().contains('name=Summer')) {
        final body = jsonEncode({'results': []});
        return http.Response(body, 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('Not found', 404);
    });

    final api = RickAndMortyApi(client: client);

    final start = DateTime.now();
    final list = await api.searchCharacters('Summer');
    final elapsedMs = DateTime.now().difference(start).inMilliseconds;

    expect(list, isEmpty);
    expect(elapsedMs, lessThan(500));
  });
}
