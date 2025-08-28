import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/constants.dart' as constants;
import '../../domain/entities/character.dart';
import '../bloc/character_bloc.dart';
import '../widgets/character_card.dart';
import '../widgets/error_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    context.read<CharacterBloc>().add(const LoadFavorites());
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        _sortBy = value;
      });
    }
  }

  void _onRemoveFromFavorites(int characterId) {
    context.read<CharacterBloc>().add(RemoveFromFavorites(characterId));
  }

  Future<void> _onRefresh() async {
    context.read<CharacterBloc>().add(const LoadFavorites());
  }

  List<Character> _sortFavorites(List<Character> favorites) {
    final sortedList = List<Character>.from(favorites);
    switch (_sortBy) {
      case 'name':
        sortedList.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'status':
        sortedList.sort((a, b) => a.status.compareTo(b.status));
        break;
      case 'species':
        sortedList.sort((a, b) => a.species.compareTo(b.species));
        break;
    }
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Text('По имени'),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Text('По статусу'),
              ),
              const PopupMenuItem(
                value: 'species',
                child: Text('По виду'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.sort),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: BlocBuilder<CharacterBloc, CharacterState>(
          builder: (context, state) {
            if (state is CharacterInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CharacterLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is FavoritesLoaded) {
              final sortedFavorites = _sortFavorites(state.favorites);

              if (sortedFavorites.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Нет избранных персонажей',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Добавьте персонажей в избранное на главной странице',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.all(constants.AppConstants.defaultPadding),
                itemCount: sortedFavorites.length,
                itemBuilder: (context, index) {
                  final character = sortedFavorites[index];
                  return Dismissible(
                    key: ValueKey('favorite_${character.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
                      _onRemoveFromFavorites(character.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${character.name} удален из избранного'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: CharacterCard(
                      character: character,
                      isFavorite: true,
                      showRemoveButton: false,
                    ),
                  );
                },
              );
            }

            if (state is CharacterError) {
              return AppErrorWidget(
                error: state.error,
                customMessage: 'Не удалось загрузить избранное',
              );
            }

            return const Center(child: Text('Неизвестное состояние'));
          },
        ),
      ),
    );
  }
}
