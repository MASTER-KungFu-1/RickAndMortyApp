import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/character.dart';
import '../bloc/character_bloc.dart';

import '../widgets/error_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/image_service.dart';
import '../../core/services/image_cache_manager.dart';

class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen>
    with TickerProviderStateMixin {
  // Индекс текущей карточки
  int _index = 0;
  // Текущее смещение и угол карточки (для жестов)
  Offset _position = Offset.zero;
  double _angle = 0;
  late AnimationController _resetCtrl;
  late AnimationController _flyCtrl;
  Animation<Offset>? _positionAnim;
  Animation<double>? _angleAnim;

  static const double _angleFactor = 0.0035;
  static const double _swipeThreshold = 100;

  @override
  void initState() {
    super.initState();
    context.read<CharacterBloc>().add(const LoadCharacters());

    _resetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {
          _position = _positionAnim?.value ?? Offset.zero;
          _angle = _angleAnim?.value ?? 0;
        });
      });

    _flyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )
      ..addListener(() {
        setState(() {
          _position = _positionAnim?.value ?? _position;
          _angle = _angleAnim?.value ?? _angle;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _advanceCard();
        }
      });
  }

  @override
  void dispose() {
    _resetCtrl.dispose();
    _flyCtrl.dispose();
    super.dispose();
  }

  void _advanceCard() {
    setState(() {
      _index++;
      _position = Offset.zero;
      _angle = 0;
    });

    // Если подходим к концу списка, загружаем новые данные
    final currentState = context.read<CharacterBloc>().state;
    if (currentState is CharacterLoading && currentState.isLoadingMore) {
      return;
    }

    if (currentState is CharactersLoaded) {
      final total = currentState.characters.length;
      if (_index >= total - 2 && !currentState.hasReachedMax) {
        context
            .read<CharacterBloc>()
            .add(LoadCharacters(page: currentState.currentPage + 1));
      }
    }
  }

  void _onPanStart(DragStartDetails d) {
    _resetCtrl.stop();
    _flyCtrl.stop();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _position += d.delta;
      _angle = _position.dx * _angleFactor;
    });
  }

  void _onPanEnd(DragEndDetails d, Character character) {
    if (_position.dx > _swipeThreshold) {
      context.read<CharacterBloc>().add(ToggleFavorite(character.id));
      _animateFlyOut(true);
    } else if (_position.dx < -_swipeThreshold) {
      _animateFlyOut(false);
    } else {
      _animateReset();
    }
  }

  void _animateReset() {
    _positionAnim = Tween<Offset>(begin: _position, end: Offset.zero).animate(
      CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutBack),
    );
    _angleAnim = Tween<double>(begin: _angle, end: 0).animate(
      CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutBack),
    );
    _resetCtrl
      ..reset()
      ..forward();
  }

  void _animateFlyOut(bool toRight) {
    final size = context.size!;
    final target =
        _position + Offset(toRight ? size.width * 1.2 : -size.width * 1.2, 0);
    final targetAngle = toRight ? math.pi / 12 : -math.pi / 12;

    _positionAnim = Tween<Offset>(begin: _position, end: target).animate(
      CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn),
    );
    _angleAnim = Tween<double>(begin: _angle, end: targetAngle).animate(
      CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn),
    );
    _flyCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CharacterBloc, CharacterState>(
        builder: (context, state) {
          if (state is CharactersLoaded) {
            return _buildCharacterStack(state.characters,
                showCornerLoader: false);
          } else if (state is CharacterLoading && state.isLoadingMore) {
            return _buildCharacterStack(state.currentCharacters,
                showCornerLoader: true);
          } else if (state is CharacterLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CharacterError) {
            return AppErrorWidget(
              error: state.error,
              customMessage: 'Не удалось загрузить персонажей',
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  /// Строит общий UI карточки персонажа для набора персонажей
  Widget _buildCharacterStack(List<Character> characters,
      {required bool showCornerLoader}) {
    if (characters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_index >= characters.length) {
      return const Center(child: Text('Больше персонажей нет'));
    }
    final character = characters[_index];

    return Stack(
      children: [
        Center(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: (d) => _onPanEnd(d, character),
            child: Stack(
              children: [
                Transform.rotate(
                  angle: _angle,
                  child: Transform.translate(
                    offset: _position,
                    child: _CharacterCardFull(character: character),
                  ),
                ),
                _DecisionOverlay(
                  dx: _position.dx,
                  likeThreshold: _swipeThreshold,
                  nopeThreshold: -_swipeThreshold,
                )
              ],
            ),
          ),
        ),
        if (_index > 0)
          Positioned(
            top: 50,
            left: 20,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _index--;
                  _position = Offset.zero;
                  _angle = 0;
                });
              },
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: const Icon(Icons.undo, color: Colors.black87),
            ),
          ),
        Positioned(
          top: 50,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_index + 1}/${characters.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (showCornerLoader)
          const Positioned(
            bottom: 20,
            right: 20,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _CharacterCardFull extends StatefulWidget {
  const _CharacterCardFull({required this.character});
  final Character character;

  @override
  State<_CharacterCardFull> createState() => _CharacterCardFullState();
}

class _CharacterCardFullState extends State<_CharacterCardFull> {
  String? _resolvedImageUrl;
  bool _isLoading = false;
  bool _hasTriedResolve = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(_CharacterCardFull oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      _resolvedImageUrl = null;
      _isLoading = false;
      _hasTriedResolve = false;
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    if (_isLoading || _hasTriedResolve) return;

    setState(() => _isLoading = true);

    try {
      // Получаем URL изображения исключительно с GitHub
      final url = await ImageService.getImageUrl(
        widget.character.id.toString(),
        widget.character.name,
      );

      if (mounted) {
        setState(() {
          // Используем только GitHub URL, без fallback на API
          _resolvedImageUrl = url;
          _isLoading = false;
          _hasTriedResolve = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          // В случае ошибки не используем API изображение, оставляем null
          // Это заставит показать error widget
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
        return Colors.green;
      case 'dead':
        return Colors.red;
      case 'unknown':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolvedImageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            // Показываем GitHub изображение если URL получен
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, size: 40),
              ),
              cacheManager: ImageCacheManager.instance,
            )
          else if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Изображение недоступно',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.black54, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Имя персонажа
                  Text(
                    widget.character.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Статус с цветным индикатором
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.character.status),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(widget.character.status)
                                  .withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.character.status,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Вид персонажа
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.character.species,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Дополнительная информация
                  if (widget.character.type.isNotEmpty)
                    Text(
                      'Type: ${widget.character.type}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (widget.character.gender.isNotEmpty)
                    Text(
                      'Gender: ${widget.character.gender}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionOverlay extends StatelessWidget {
  const _DecisionOverlay({
    required this.dx,
    required this.likeThreshold,
    required this.nopeThreshold,
  });

  final double dx;
  final double likeThreshold;
  final double nopeThreshold;

  @override
  Widget build(BuildContext context) {
    final likeOpacity = (dx / likeThreshold).clamp(0.0, 1.0);
    final nopeOpacity = (-dx / -nopeThreshold).clamp(0.0, 1.0);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 50,
            left: 30,
            child: Opacity(
              opacity: likeOpacity,
              child: _Stamp(text: 'LIKE', color: Colors.green),
            ),
          ),
          Positioned(
            top: 50,
            right: 30,
            child: Opacity(
              opacity: nopeOpacity,
              child: _Stamp(text: 'NOPE', color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
