import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/constants.dart' as constants;
import '../../domain/entities/character.dart';
import '../bloc/character_bloc.dart';
import '../widgets/character_card.dart';
import '../widgets/error_widget.dart';

class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    context.read<CharacterBloc>().add(const LoadCharacters());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCharacters();
    }
  }

  void _loadMoreCharacters() {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      final currentState = context.read<CharacterBloc>().state;
      if (currentState is CharactersLoaded && !currentState.hasReachedMax) {
        context.read<CharacterBloc>().add(
              LoadCharacters(page: currentState.currentPage + 1),
            );
      }
    }
  }

  void _onFavoriteToggle(int characterId) {
    context.read<CharacterBloc>().add(ToggleFavorite(characterId));
  }

  Future<void> _onRefresh() async {
    context.read<CharacterBloc>().add(const LoadCharacters());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<CharacterBloc, CharacterState>(
        listenWhen: (previous, current) =>
            current is CharactersLoaded || current is CharacterError,
        listener: (context, state) {
          if (_isLoadingMore) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        },
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: BlocBuilder<CharacterBloc, CharacterState>(
            builder: (context, state) {
              // Если есть текущие данные, показываем их
              if (state is CharactersLoaded) {
                return _buildCharactersList(
                  characters: state.characters,
                  favoriteIds: state.favoriteIds,
                  isLoadingMore: _isLoadingMore,
                );
              }

              // Если есть ошибка, но есть текущие данные
              if (state is CharacterError &&
                  state.currentCharacters != null &&
                  state.currentCharacters!.isNotEmpty) {
                return Column(
                  children: [
                    Expanded(
                      child: _buildCharactersList(
                        characters: state.currentCharacters!,
                        favoriteIds: state.currentFavoriteIds ?? const [],
                        isLoadingMore: false,
                      ),
                    ),
                    AppErrorWidget(
                      error: state.error,
                      customMessage: 'Ошибка при загрузке новых данных',
                    ),
                  ],
                );
              }

              // Если загрузка
              if (state is CharacterLoading) {
                if (state.isLoadingMore && state.currentCharacters.isNotEmpty) {
                  return _buildCharactersList(
                    characters: state.currentCharacters,
                    favoriteIds: const [],
                    isLoadingMore: true,
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }

              // Если ошибка без данных
              if (state is CharacterError) {
                return AppErrorWidget(
                  error: state.error,
                  customMessage: 'Не удалось загрузить персонажей',
                );
              }

              // Fallback для всех остальных случаев
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCharactersList({
    required List<Character> characters,
    required List<int> favoriteIds,
    required bool isLoadingMore,
  }) {
    if (characters.isEmpty) {
      return const Center(
        child: Text(
          'Нет персонажей для отображения',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(constants.AppConstants.defaultPadding),
      itemCount: characters.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == characters.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final character = characters[index];
        final isFavorite = favoriteIds.contains(character.id);

        return CharacterCard(
          character: character,
          isFavorite: isFavorite,
          onFavoriteToggle: () => _onFavoriteToggle(character.id),
        );
      },
    );
  }
}
