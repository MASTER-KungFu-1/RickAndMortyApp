import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/character.dart';
import '../bloc/character_bloc.dart';
import '../widgets/error_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/image_service.dart';
import '../../core/services/image_cache_manager.dart';

class FavoritesScreenIOS extends StatefulWidget {
  const FavoritesScreenIOS({super.key});

  @override
  State<FavoritesScreenIOS> createState() => _FavoritesScreenIOSState();
}

class _FavoritesScreenIOSState extends State<FavoritesScreenIOS> {
  String _sortBy = 'name'; // По умолчанию сортируем по имени

  @override
  void initState() {
    super.initState();
    context.read<CharacterBloc>().add(const LoadFavorites());
  }

  List<Character> _sortFavorites(List<Character> favorites) {
    switch (_sortBy) {
      case 'name':
        favorites.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'status':
        favorites.sort((a, b) => a.status.compareTo(b.status));
        break;
      case 'species':
        favorites.sort((a, b) => a.species.compareTo(b.species));
        break;
    }
    return favorites;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharacterBloc, CharacterState>(
      builder: (context, state) {
        if (state is FavoritesLoaded) {
          final sortedFavorites = _sortFavorites(List.from(state.favorites));

          if (sortedFavorites.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildSortControls(),
              Expanded(
                child: _buildFavoritesList(sortedFavorites),
              ),
            ],
          );
        } else if (state is CharacterLoading) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is CharacterError) {
          return AppErrorWidget(
            error: state.error,
            customMessage: 'Не удалось загрузить избранное',
          );
        } else {
          return const Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }

  Widget _buildSortControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Сортировка:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _sortBy,
              children: const {
                'name': Text('По имени'),
                'status': Text('По статусу'),
                'species': Text('По виду'),
              },
              onValueChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(List<Character> favorites) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final character = favorites[index];
        return _FavoriteCardIOS(character: character);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.heart,
            size: 80,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет избранных персонажей',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Свайпните вправо на персонаже,\nчтобы добавить в избранное',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCardIOS extends StatefulWidget {
  const _FavoriteCardIOS({required this.character});
  final Character character;

  @override
  State<_FavoriteCardIOS> createState() => _FavoriteCardIOSState();
}

class _FavoriteCardIOSState extends State<_FavoriteCardIOS> {
  String? _resolvedImageUrl;
  bool _isLoading = false;
  bool _hasTriedResolve = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  Future<void> _resolveImage() async {
    if (_isLoading || _hasTriedResolve) return;

    setState(() => _isLoading = true);

    try {
      final url = await ImageService.getImageUrl(
        widget.character.id.toString(),
        widget.character.name,
      );

      if (mounted) {
        setState(() {
          _resolvedImageUrl = url;
          _isLoading = false;
          _hasTriedResolve = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedImageUrl = null;
          _isLoading = false;
          _hasTriedResolve = true;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return CupertinoColors.systemGreen;
      case 'dead':
        return CupertinoColors.systemRed;
      case 'unknown':
        return CupertinoColors.systemOrange;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolvedImageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey
                .resolveFrom(context)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: SizedBox(
              width: 100,
              height: 100,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(CupertinoIcons.photo, size: 30),
                      ),
                      cacheManager: ImageCacheManager.instance,
                    )
                  : _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : const Center(
                          child: Icon(CupertinoIcons.photo, size: 30),
                        ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.character.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.character.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.character.status,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.character.species,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () {
              context.read<CharacterBloc>().add(
                    RemoveFromFavorites(widget.character.id),
                  );
            },
            child: Icon(
              CupertinoIcons.heart_fill,
              color: CupertinoColors.systemRed,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
