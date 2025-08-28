import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/app_error.dart';
import '../../domain/entities/character.dart';
import '../../domain/repositories/character_repository.dart';

// Events
abstract class CharacterEvent extends Equatable {
  const CharacterEvent();

  @override
  List<Object?> get props => [];
}

class LoadCharacters extends CharacterEvent {
  final int page;

  const LoadCharacters({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class LoadCharacter extends CharacterEvent {
  final int id;

  const LoadCharacter(this.id);

  @override
  List<Object?> get props => [id];
}

class SearchCharacters extends CharacterEvent {
  final String query;

  const SearchCharacters(this.query);

  @override
  List<Object?> get props => [query];
}

class ToggleFavorite extends CharacterEvent {
  final int characterId;

  const ToggleFavorite(this.characterId);

  @override
  List<Object?> get props => [characterId];
}

class LoadFavorites extends CharacterEvent {
  const LoadFavorites();
}

class RemoveFromFavorites extends CharacterEvent {
  final int characterId;

  const RemoveFromFavorites(this.characterId);

  @override
  List<Object?> get props => [characterId];
}

// States
abstract class CharacterState extends Equatable {
  const CharacterState();

  @override
  List<Object?> get props => [];
}

class CharacterInitial extends CharacterState {}

class CharacterLoading extends CharacterState {
  final bool isLoadingMore;
  final List<Character> currentCharacters;

  const CharacterLoading({
    this.isLoadingMore = false,
    this.currentCharacters = const [],
  });

  @override
  List<Object?> get props => [isLoadingMore, currentCharacters];

  CharacterLoading copyWith({
    bool? isLoadingMore,
    List<Character>? currentCharacters,
  }) {
    return CharacterLoading(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentCharacters: currentCharacters ?? this.currentCharacters,
    );
  }
}

class CharactersLoaded extends CharacterState {
  final List<Character> characters;
  final List<int> favoriteIds;
  final bool hasReachedMax;
  final int currentPage;

  const CharactersLoaded({
    required this.characters,
    required this.favoriteIds,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props =>
      [characters, favoriteIds, hasReachedMax, currentPage];

  CharactersLoaded copyWith({
    List<Character>? characters,
    List<int>? favoriteIds,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return CharactersLoaded(
      characters: characters ?? this.characters,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class FavoritesLoaded extends CharacterState {
  final List<Character> favorites;
  final String? sortBy;

  const FavoritesLoaded({
    required this.favorites,
    this.sortBy,
  });

  @override
  List<Object?> get props => [favorites, sortBy];
}

class CharacterError extends CharacterState {
  final AppError error;
  final List<Character>? currentCharacters;
  final List<int>? currentFavoriteIds;

  const CharacterError({
    required this.error,
    this.currentCharacters,
    this.currentFavoriteIds,
  });

  @override
  List<Object?> get props => [error, currentCharacters, currentFavoriteIds];
}

/// BLoC, управляющий загрузкой персонажей, избранным и поиском
class CharacterBloc extends Bloc<CharacterEvent, CharacterState> {
  final CharacterRepository _repository;
  int _currentPage = 1;
  bool _hasReachedMax = false;

  final Set<int> _pagesInFlight = <int>{};
  bool _searchInFlight = false;

  CharacterBloc({required CharacterRepository repository})
      : _repository = repository,
        super(CharacterInitial()) {
    on<LoadCharacters>(_onLoadCharacters);
    on<LoadCharacter>(_onLoadCharacter);
    on<SearchCharacters>(_onSearchCharacters);
    on<ToggleFavorite>(_onToggleFavorite);
    on<LoadFavorites>(_onLoadFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
  }

  /// Хелпер: безопасно получить список избранных ID
  Future<List<int>> _safeFavoriteIds() async {
    final favoriteIdsResult = await _repository.getFavoriteIds();
    return favoriteIdsResult.isSuccess
        ? (favoriteIdsResult.data ?? <int>[])
        : <int>[];
  }

  Future<void> _onLoadCharacters(
      LoadCharacters event, Emitter<CharacterState> emit) async {
    if (_pagesInFlight.contains(event.page)) {
      return;
    }
    _pagesInFlight.add(event.page);

    try {
      if (event.page == 1) {
        emit(const CharacterLoading());
        _currentPage = 1;
        _hasReachedMax = false;
      } else {
        if (state is CharactersLoaded) {
          final currentState = state as CharactersLoaded;
          emit(CharacterLoading(
            isLoadingMore: true,
            currentCharacters: currentState.characters,
          ));
        }
      }

      final result = await _repository.getCharacters(page: event.page);

      if (result.isSuccess) {
        final characters = result.data!;
        if (event.page == 1) {
          _currentPage = 1;
          _hasReachedMax = characters.length < 20;
          final favoriteIds = await _safeFavoriteIds();
          emit(CharactersLoaded(
            characters: characters,
            favoriteIds: favoriteIds,
            hasReachedMax: _hasReachedMax,
            currentPage: _currentPage,
          ));
        } else {
          if (state is CharacterLoading) {
            final loadingState = state as CharacterLoading;

            final previousCount = loadingState.currentCharacters.length;
            final newCount = characters.length;
            final pageSize = (newCount - previousCount).clamp(0, 1 << 30);

            _currentPage = event.page;
            _hasReachedMax = pageSize < 20;

            final favoriteIds = await _safeFavoriteIds();

            emit(CharactersLoaded(
              characters: characters,
              favoriteIds: favoriteIds,
              hasReachedMax: _hasReachedMax,
              currentPage: _currentPage,
            ));
          }
        }
      } else {
        // Ошибка загрузки. Если это была догрузка, оставим текущий список и
        // зафиксируем конец (hasReachedMax = true), чтобы избежать вечной загрузки.
        if (event.page > 1 && state is CharacterLoading) {
          final loadingState = state as CharacterLoading;
          final previous = loadingState.currentCharacters;
          final favoriteIds = await _safeFavoriteIds();
          emit(CharactersLoaded(
            characters: previous,
            favoriteIds: favoriteIds,
            hasReachedMax: true,
            currentPage: _currentPage,
          ));
        } else {
          emit(CharacterError(
            error: result.error!,
            currentCharacters: state is CharactersLoaded
                ? (state as CharactersLoaded).characters
                : null,
            currentFavoriteIds: state is CharactersLoaded
                ? (state as CharactersLoaded).favoriteIds
                : null,
          ));
        }
      }
    } catch (e, stackTrace) {
      emit(CharacterError(
        error: UnknownError.fromException(e, stackTrace),
        currentCharacters: state is CharactersLoaded
            ? (state as CharactersLoaded).characters
            : null,
        currentFavoriteIds: state is CharactersLoaded
            ? (state as CharactersLoaded).favoriteIds
            : null,
      ));
    } finally {
      _pagesInFlight.remove(event.page);
    }
  }

  Future<void> _onLoadCharacter(
      LoadCharacter event, Emitter<CharacterState> emit) async {
    try {
      final result = await _repository.getCharacter(event.id);
      if (result.isSuccess) {
        if (state is CharactersLoaded) {
          final currentState = state as CharactersLoaded;
          final updatedCharacters =
              List<Character>.from(currentState.characters);
          final index = updatedCharacters.indexWhere((c) => c.id == event.id);
          if (index != -1) {
            updatedCharacters[index] = result.data!;
          } else {
            updatedCharacters.add(result.data!);
          }
          emit(currentState.copyWith(characters: updatedCharacters));
        }
      } else {
        emit(CharacterError(
          error: result.error!,
          currentCharacters: state is CharactersLoaded
              ? (state as CharactersLoaded).characters
              : null,
          currentFavoriteIds: state is CharactersLoaded
              ? (state as CharactersLoaded).favoriteIds
              : null,
        ));
      }
    } catch (e, stackTrace) {
      emit(CharacterError(
        error: UnknownError.fromException(e, stackTrace),
        currentCharacters: state is CharactersLoaded
            ? (state as CharactersLoaded).characters
            : null,
        currentFavoriteIds: state is CharactersLoaded
            ? (state as CharactersLoaded).favoriteIds
            : null,
      ));
    }
  }

  Future<void> _onSearchCharacters(
      SearchCharacters event, Emitter<CharacterState> emit) async {
    if (_searchInFlight) return;
    _searchInFlight = true;
    try {
      emit(const CharacterLoading());
      final result = await _repository.searchCharacters(event.query);
      if (result.isSuccess) {
        final characters = result.data!;
        final favoriteIdsResult = await _repository.getFavoriteIds();
        final favoriteIds =
            favoriteIdsResult.isSuccess ? favoriteIdsResult.data! : <int>[];
        emit(CharactersLoaded(
          characters: characters,
          favoriteIds: favoriteIds,
          hasReachedMax: true,
          currentPage: 1,
        ));
      } else {
        emit(CharacterError(error: result.error!));
      }
    } catch (e, stackTrace) {
      emit(CharacterError(error: UnknownError.fromException(e, stackTrace)));
    } finally {
      _searchInFlight = false;
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<CharacterState> emit) async {
    try {
      final result = await _repository.toggleFavorite(event.characterId);
      if (result.isSuccess) {
        final favoriteIds = await _safeFavoriteIds();
        if (favoriteIds.isNotEmpty || true) {
          if (state is CharactersLoaded) {
            final currentState = state as CharactersLoaded;
            emit(currentState.copyWith(favoriteIds: favoriteIds));
          } else if (state is FavoritesLoaded) {
            add(const LoadFavorites());
          }
        }
      } else {
        emit(CharacterError(
          error: result.error!,
          currentCharacters: state is CharactersLoaded
              ? (state as CharactersLoaded).characters
              : null,
          currentFavoriteIds: state is CharactersLoaded
              ? (state as CharactersLoaded).favoriteIds
              : null,
        ));
      }
    } catch (e, stackTrace) {
      emit(CharacterError(
        error: UnknownError.fromException(e, stackTrace),
        currentCharacters: state is CharactersLoaded
            ? (state as CharactersLoaded).characters
            : null,
        currentFavoriteIds: state is CharactersLoaded
            ? (state as CharactersLoaded).favoriteIds
            : null,
      ));
    }
  }

  Future<void> _onLoadFavorites(
      LoadFavorites event, Emitter<CharacterState> emit) async {
    try {
      emit(const CharacterLoading());
      final result = await _repository.getFavorites();
      if (result.isSuccess) {
        final favorites = result.data!;
        emit(FavoritesLoaded(favorites: favorites));
      } else {
        emit(CharacterError(error: result.error!));
      }
    } catch (e, stackTrace) {
      emit(CharacterError(error: UnknownError.fromException(e, stackTrace)));
    }
  }

  Future<void> _onRemoveFromFavorites(
      RemoveFromFavorites event, Emitter<CharacterState> emit) async {
    try {
      final result = await _repository.removeFromFavorites(event.characterId);
      if (result.isSuccess) {
        final favoriteIdsResult = await _repository.getFavoriteIds();
        if (favoriteIdsResult.isSuccess) {
          final favoriteIds = favoriteIdsResult.data!;
          if (state is CharactersLoaded) {
            final currentState = state as CharactersLoaded;
            emit(currentState.copyWith(favoriteIds: favoriteIds));
          }
        }
        add(const LoadFavorites());
      } else {
        emit(CharacterError(
          error: result.error!,
          currentCharacters: state is CharactersLoaded
              ? (state as CharactersLoaded).characters
              : null,
          currentFavoriteIds: state is CharactersLoaded
              ? (state as CharactersLoaded).favoriteIds
              : null,
        ));
      }
    } catch (e, stackTrace) {
      emit(CharacterError(
        error: UnknownError.fromException(e, stackTrace),
        currentCharacters: state is CharactersLoaded
            ? (state as CharactersLoaded).characters
            : null,
        currentFavoriteIds: state is CharactersLoaded
            ? (state as CharactersLoaded).favoriteIds
            : null,
      ));
    }
  }
}
