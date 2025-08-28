import 'package:equatable/equatable.dart';
import '../../core/errors/app_error.dart';
import '../entities/character.dart';

abstract class CharacterRepository {
  Future<Result<List<Character>>> getCharacters({int page = 1});
  Future<Result<Character>> getCharacter(int id);
  Future<Result<List<Character>>> searchCharacters(String query);
  Future<Result<List<Character>>> getFavorites();
  Future<Result<List<int>>> getFavoriteIds();
  Future<Result<void>> toggleFavorite(int characterId);
  Future<Result<void>> removeFromFavorites(int characterId);
}

class Result<T> extends Equatable {
  final T? data;
  final AppError? error;

  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  @override
  List<Object?> get props => [data, error];
}
