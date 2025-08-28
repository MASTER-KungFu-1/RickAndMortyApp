import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheManager {
  ImageCacheManager._();

  static final CacheManager instance = CacheManager(
    Config(
      'rick_and_morty_image_cache',
      stalePeriod: const Duration(days: 365),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'rick_and_morty_image_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// Кэш для URL изображений (ключ — id персонажа)
  static final Map<String, String> _imageUrlCache = {};
  static final Map<String, DateTime> _urlCacheTimestamps = {};
  static const Duration _urlCacheDuration = Duration(hours: 24);

  /// Получает URL изображения из кэша или null
  static String? getCachedImageUrl(String characterId) {
    final timestamp = _urlCacheTimestamps[characterId];
    if (timestamp != null) {
      final timeSinceCache = DateTime.now().difference(timestamp);
      if (timeSinceCache < _urlCacheDuration) {
        return _imageUrlCache[characterId];
      } else {
        // Удаляем устаревший кэш
        _imageUrlCache.remove(characterId);
        _urlCacheTimestamps.remove(characterId);
      }
    }
    return null;
  }

  /// Сохраняет URL изображения в кэш
  static void cacheImageUrl(String characterId, String imageUrl) {
    _imageUrlCache[characterId] = imageUrl;
    _urlCacheTimestamps[characterId] = DateTime.now();
  }

  /// Очищает весь кэш изображений
  static Future<void> clearCache() async {
    await instance.emptyCache();
    _imageUrlCache.clear();
    _urlCacheTimestamps.clear();
  }

  /// Очищает только кэш URL
  static void clearUrlCache() {
    _imageUrlCache.clear();
    _urlCacheTimestamps.clear();
  }

  /// Получает статистику кэша
  static Map<String, dynamic> getCacheStats() {
    return {
      'urlCacheSize': _imageUrlCache.length,
      'urlCacheKeys': _imageUrlCache.keys.toList(),
    };
  }
}
