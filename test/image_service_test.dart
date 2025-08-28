import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rick_and_morty/core/services/image_service.dart';
import 'package:rick_and_morty/core/services/image_cache_manager.dart';

void main() {
  setUp(() async {
    ImageService.clearCache();
    ImageCacheManager.clearUrlCache();
  });
  tearDown(() {
    ImageService.setHttpClientForTesting(null);
  });

  test('getImageUrl returns URL from manifest and caches it, timing check',
      () async {
    final client = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.toString().endsWith('/manifest.json')) {
        final body = jsonEncode([
          {'name': 'Rick Sanchez', 'url': 'https://cdn.example.com/rick.webp'},
        ]);
        return http.Response(body, 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('Not found', 404);
    });
    ImageService.setHttpClientForTesting(client);

    final start = DateTime.now();
    final url = await ImageService.getImageUrl('1', 'Rick Sanchez');
    final elapsedMs = DateTime.now().difference(start).inMilliseconds;
    expect(url, 'https://cdn.example.com/rick.webp');
    expect(elapsedMs, lessThan(1000));

    final start2 = DateTime.now();
    final url2 = await ImageService.getImageUrl('1', 'Rick Sanchez');
    final elapsed2Ms = DateTime.now().difference(start2).inMilliseconds;
    expect(url2, 'https://cdn.example.com/rick.webp');
    expect(elapsed2Ms, lessThan(50));
  });

  test(
      'getImageUrl falls back to generated URL if manifest not found, timing check',
      () async {
    final client = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.toString().endsWith('/manifest.json')) {
        return http.Response('Not Found', 404);
      }
      if (request.method == 'HEAD' &&
          request.url.toString().contains('/images/2.webp')) {
        return http.Response('', 200);
      }
      return http.Response('Not found', 404);
    });
    ImageService.setHttpClientForTesting(client);

    final start = DateTime.now();
    final url = await ImageService.getImageUrl('2', 'Morty Smith');
    final elapsedMs = DateTime.now().difference(start).inMilliseconds;

    expect(url, 'https://master-kungfu-1.github.io/images/2.webp');
    expect(elapsedMs, lessThan(1500));
  });
}
