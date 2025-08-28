import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  // Integration test: checks that every image URL listed in the GitHub manifest exists
  test('All GitHub images from manifest are available (HTTP 200)', () async {
    const baseUrl = 'https://master-kungfu-1.github.io';
    const manifestPath = '/manifest.json';
    final client = http.Client();

    try {
      final manifestResp = await client
          .get(Uri.parse('$baseUrl$manifestPath'))
          .timeout(const Duration(seconds: 20));
      expect(manifestResp.statusCode, 200,
          reason: 'Failed to fetch manifest: HTTP ${manifestResp.statusCode}');

      final List<dynamic> jsonList = json.decode(manifestResp.body);
      expect(jsonList.isNotEmpty, true, reason: 'Manifest is empty');

      // Iterate sequentially to avoid rate limits
      final total = jsonList.length;
      var index = 0;
      for (final item in jsonList) {
        index += 1;
        final String? url = (item is Map && item['url'] is String)
            ? item['url'] as String
            : null;
        if (url == null || url.isEmpty) {
          fail('Invalid url entry in manifest: $item');
        }

        final uri = Uri.parse(url);

        // Prefer HEAD; if not 200, try GET as fallback
        final headSw = Stopwatch()..start();
        final headResp =
            await client.head(uri).timeout(const Duration(seconds: 10));
        headSw.stop();
        // Feedback for HEAD
        // ignore: avoid_print
        print(
            '[${index.toString().padLeft(3)}/$total] HEAD ${headResp.statusCode} ${headSw.elapsedMilliseconds}ms: $url');

        if (headResp.statusCode != 200) {
          final getSw = Stopwatch()..start();
          final getResp =
              await client.get(uri).timeout(const Duration(seconds: 15));
          getSw.stop();
          // Feedback for GET fallback
          // ignore: avoid_print
          print(
              '[${index.toString().padLeft(3)}/$total]  GET ${getResp.statusCode} ${getSw.elapsedMilliseconds}ms (fallback): $url');
          expect(getResp.statusCode, 200,
              reason:
                  'Image not available: $url (HEAD ${headResp.statusCode}, GET ${getResp.statusCode})');
        } else {
          // HEAD success summary
          // ignore: avoid_print
          print('[${index.toString().padLeft(3)}/$total]  OK  via HEAD');
        }
      }
    } finally {
      client.close();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
