import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/app_error.dart';
import 'image_cache_manager.dart';

/// Сервис для разрешения URL изображений персонажей
/// Стратегия:
/// 1) Пытаемся найти URL в манифесте (кэшируем его на час)
/// 2) Если не найдено — генерируем URL по ID `images/{id}.webp`
/// 3) Не блокируем UI проверками доступности (HEAD), кэшируем выданный URL
/// 4) Все изображения загружаются исключительно с GitHub, без fallback на API
class ImageService {
  static const String _baseUrl = 'https://master-kungfu-1.github.io';
  static const String _manifestPath = '/manifest.json';

  // Для тестов: инъекция http клиента
  static http.Client? _testClient;
  static http.Client _client() => _testClient ?? http.Client();

  // Кэш для манифеста
  static List<Map<String, dynamic>>? _manifestCache;
  static DateTime? _lastManifestUpdate;
  static const Duration _manifestCacheDuration = Duration(hours: 1);

  /// Получает URL изображения для персонажа
  /// Использует id как ключ кэша
  static Future<String?> getImageUrl(
      String characterId, String characterName) async {
    try {
      // Проверяем глобальный кэш URL
      final cachedUrl = ImageCacheManager.getCachedImageUrl(characterId);
      if (cachedUrl != null) {
        return cachedUrl;
      }

      // Проверяем кэш манифеста
      if (_shouldRefreshManifest()) {
        await _loadManifest();
      }

      // Ищем изображение в кэшированном манифесте
      if (_manifestCache != null) {
        final imageUrl = _findImageInManifest(characterName);
        if (imageUrl != null) {
          // Сохраняем в глобальный кэш
          ImageCacheManager.cacheImageUrl(characterId, imageUrl);
          return imageUrl;
        }
      }

      // Если не нашли в манифесте, генерируем URL по ID
      // Это основной источник изображений для всех персонажей
      final generatedUrl = '$_baseUrl/images/$characterId.webp';

      // Кэшируем сгенерированный URL
      ImageCacheManager.cacheImageUrl(characterId, generatedUrl);
      return generatedUrl;
    } catch (e) {
      return null;
    }
  }

  /// Проверяет, нужно ли обновить кэш манифеста
  static bool _shouldRefreshManifest() {
    if (_manifestCache == null || _lastManifestUpdate == null) {
      return true;
    }

    final timeSinceUpdate = DateTime.now().difference(_lastManifestUpdate!);
    return timeSinceUpdate > _manifestCacheDuration;
  }

  /// Загружает манифест и кэширует его
  static Future<void> _loadManifest() async {
    try {
      final response = await _client().get(
        Uri.parse('$_baseUrl$_manifestPath'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        _manifestCache = jsonData.cast<Map<String, dynamic>>();
        _lastManifestUpdate = DateTime.now();
      } else {
        throw NetworkError(
          message: 'Failed to load manifest',
          statusCode: response.statusCode,
          url: '$_baseUrl$_manifestPath',
        );
      }
    } catch (e) {
      // Если не удалось загрузить манифест, сбрасываем кэш
      _manifestCache = [];
      _lastManifestUpdate = DateTime.now();
    }
  }

  /// Ищет изображение в манифесте по имени персонажа
  static String? _findImageInManifest(String characterName) {
    if (_manifestCache == null || _manifestCache!.isEmpty) {
      return null;
    }

    // Сначала ищем точное совпадение
    for (final character in _manifestCache!) {
      if (character['name'] == characterName) {
        return character['url'] as String?;
      }
    }

    // Если точное совпадение не найдено, ищем частичное
    final normalizedName = characterName.toLowerCase().trim();
    for (final character in _manifestCache!) {
      final manifestName = (character['name'] as String?)?.toLowerCase().trim();
      if (manifestName != null && manifestName.contains(normalizedName)) {
        return character['url'] as String?;
      }
    }

    return null;
  }

  /// Очищает кэш манифеста
  static void clearCache() {
    _manifestCache = null;
    _lastManifestUpdate = null;
  }

  /// Только для тестов: установить клиент HTTP
  static void setHttpClientForTesting(http.Client? client) {
    _testClient = client;
  }

  /// Получает статус сервиса
  static Map<String, dynamic> getServiceStatus() {
    return {
      'manifestCached': _manifestCache != null,
      'lastUpdate': _lastManifestUpdate?.toIso8601String(),
      'cacheSize': _manifestCache?.length ?? 0,
      'baseUrl': _baseUrl,
    };
  }
}
