import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/errors/app_error.dart';
import '../../core/utils/constants.dart' as constants;
import '../dto/character_dto.dart';

class RickAndMortyApi {
  final http.Client _client;

  RickAndMortyApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<CharacterDto>> getCharacters({int page = 1}) async {
    try {
      final url =
          '${constants.AppConstants.baseUrl}${constants.AppConstants.charactersEndpoint}?page=$page';

      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final results = jsonData['results'] as List<dynamic>;

        return results
            .map((json) => CharacterDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw NetworkError.fromHttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          response.statusCode,
          url,
        );
      }
    } on http.ClientException {
      throw NetworkError.noConnection();
    } on SocketException {
      throw NetworkError.noConnection();
    } on TimeoutException {
      throw NetworkError.timeout();
    } on FormatException catch (e) {
      throw DataParsingError.invalidJson('Ошибка парсинга JSON: ${e.message}');
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownError.fromException(e, stackTrace);
    }
  }

  Future<CharacterDto> getCharacter(int id) async {
    try {
      final url =
          '${constants.AppConstants.baseUrl}${constants.AppConstants.charactersEndpoint}/$id';

      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return CharacterDto.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw NetworkError.fromHttpException(
          'Персонаж с ID $id не найден',
          response.statusCode,
          url,
        );
      } else {
        throw NetworkError.fromHttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          response.statusCode,
          url,
        );
      }
    } on http.ClientException {
      throw NetworkError.noConnection();
    } on SocketException {
      throw NetworkError.noConnection();
    } on TimeoutException {
      throw NetworkError.timeout();
    } on FormatException catch (e) {
      throw DataParsingError.invalidJson('Ошибка парсинга JSON: ${e.message}');
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownError.fromException(e, stackTrace);
    }
  }

  Future<List<CharacterDto>> searchCharacters(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url =
          '${constants.AppConstants.baseUrl}${constants.AppConstants.charactersEndpoint}?name=$encodedQuery';

      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final results = jsonData['results'] as List<dynamic>?;

        if (results == null) {
          return [];
        }

        return results
            .map((json) => CharacterDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw NetworkError.fromHttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          response.statusCode,
          url,
        );
      }
    } on http.ClientException {
      throw NetworkError.noConnection();
    } on SocketException {
      throw NetworkError.noConnection();
    } on TimeoutException {
      throw NetworkError.timeout();
    } on FormatException catch (e) {
      throw DataParsingError.invalidJson('Ошибка парсинга JSON: ${e.message}');
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownError.fromException(e, stackTrace);
    }
  }
}
