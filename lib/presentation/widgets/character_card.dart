import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/character.dart';
import '../../core/services/image_service.dart';
import '../../core/services/image_cache_manager.dart';
import '../../core/utils/constants.dart' as constants;

class CharacterCard extends StatefulWidget {
  final Character character;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;
  final bool showRemoveButton;

  const CharacterCard({
    super.key,
    required this.character,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap,
    this.showRemoveButton = false,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String? _resolvedImageUrl;
  bool _isLoading = false;
  bool _hasTriedResolve = false; // Флаг для предотвращения повторных попыток

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _resolveImage();
  }

  @override
  void didUpdateWidget(CharacterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      _resolvedImageUrl = null;
      _isLoading = false;
      _hasTriedResolve = false;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _resolveImage() async {
    // Если уже пытались загрузить или загружаем, не делаем ничего
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
          _hasTriedResolve = true; // Отмечаем, что попытка была
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedImageUrl = widget.character.image; // fallback
          _isLoading = false;
          _hasTriedResolve = true; // Отмечаем, что попытка была
        });
      }
    }
  }

  void _onFavoriteToggle() {
    if (widget.onFavoriteToggle != null) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      widget.onFavoriteToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('character_${widget.character.id}'),
      margin: const EdgeInsets.only(
        bottom: constants.AppConstants.defaultPadding,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          constants.AppConstants.defaultRadius,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(
          constants.AppConstants.defaultRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(constants.AppConstants.defaultPadding),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  constants.AppConstants.defaultRadius,
                ),
                child: _buildImage(),
              ),
              const SizedBox(width: constants.AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.character.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildStatusChip(),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.character.species} • ${widget.character.gender}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (widget.character.type.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.character.type,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onFavoriteToggle != null)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: IconButton(
                        onPressed: _onFavoriteToggle,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            widget.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey(widget.isFavorite),
                            color: widget.isFavorite ? Colors.red : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (widget.showRemoveButton && widget.onTap != null)
                IconButton(
                  onPressed: widget.onTap,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_isLoading) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Используем разрешенный URL или fallback к оригинальному
    final imageUrl = _resolvedImageUrl ?? widget.character.image;

    return CachedNetworkImage(
      key: ValueKey('image_${widget.character.id}_$imageUrl'),
      imageUrl: imageUrl,
      cacheManager: ImageCacheManager.instance,
      width: 80,
      height: 80,
      fit: BoxFit.cover, // Масштабируем изображение по размеру контейнера
      placeholder: (context, url) => Container(
        width: 80,
        height: 80,
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        width: 80,
        height: 80,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    IconData iconData;

    switch (widget.character.status.toLowerCase()) {
      case 'alive':
        chipColor = Colors.green;
        iconData = Icons.favorite;
        break;
      case 'dead':
        chipColor = Colors.red;
        iconData = Icons.close;
        break;
      default:
        chipColor = Colors.grey;
        iconData = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            widget.character.status,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
