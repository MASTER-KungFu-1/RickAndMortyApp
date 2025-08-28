import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/character.dart';
import '../bloc/character_bloc.dart';
import '../widgets/error_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/image_service.dart';
import '../../core/services/image_cache_manager.dart';

class CharactersScreenIOS extends StatefulWidget {
  const CharactersScreenIOS({super.key});

  @override
  State<CharactersScreenIOS> createState() => _CharactersScreenIOSState();
}

class _CharactersScreenIOSState extends State<CharactersScreenIOS>
    with TickerProviderStateMixin {
  int _index = 0;
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
    return BlocBuilder<CharacterBloc, CharacterState>(
      builder: (context, state) {
        if (state is CharactersLoaded) {
          return _buildCharacterStack(state.characters);
        } else if (state is CharacterLoading) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is CharacterError) {
          return AppErrorWidget(
            error: state.error,
            customMessage: 'Не удалось загрузить персонажей',
          );
        } else {
          return const Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }

  Widget _buildCharacterStack(List<Character> characters) {
    if (characters.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
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
                    child: _CharacterCardFullIOS(character: character),
                  ),
                ),
                _DecisionOverlayIOS(
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
            child: CupertinoButton(
              padding: const EdgeInsets.all(12),
              onPressed: () {
                setState(() {
                  _index--;
                  _position = Offset.zero;
                  _angle = 0;
                });
              },
              color: CupertinoColors.systemBackground
                  .resolveFrom(context)
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25),
              child: const Icon(CupertinoIcons.arrow_counterclockwise,
                  color: CupertinoColors.label),
            ),
          ),
        Positioned(
          top: 50,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6
                  .resolveFrom(context)
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_index + 1}/${characters.length}',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CharacterCardFullIOS extends StatefulWidget {
  const _CharacterCardFullIOS({required this.character});
  final Character character;

  @override
  State<_CharacterCardFullIOS> createState() => _CharacterCardFullIOSState();
}

class _CharacterCardFullIOSState extends State<_CharacterCardFullIOS> {
  String? _resolvedImageUrl;
  bool _isLoading = false;
  bool _hasTriedResolve = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(_CharacterCardFullIOS oldWidget) {
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CupertinoActivityIndicator(),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(CupertinoIcons.photo, size: 40),
              ),
              cacheManager: ImageCacheManager.instance,
            )
          else if (_isLoading)
            const Center(
              child: CupertinoActivityIndicator(),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.photo,
                      size: 60, color: CupertinoColors.systemGrey),
                  SizedBox(height: 16),
                  Text(
                    'Изображение недоступно',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
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
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    CupertinoColors.systemBackground
                        .resolveFrom(context)
                        .withValues(alpha: 0.9),
                    CupertinoColors.systemBackground
                        .resolveFrom(context)
                        .withValues(alpha: 0.7),
                    CupertinoColors.systemBackground
                        .resolveFrom(context)
                        .withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.character.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.character.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.character.status,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.character.species,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.character.type.isNotEmpty)
                    Text(
                      'Type: ${widget.character.type}',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (widget.character.gender.isNotEmpty)
                    Text(
                      'Gender: ${widget.character.gender}',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
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

class _DecisionOverlayIOS extends StatelessWidget {
  const _DecisionOverlayIOS({
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
              child:
                  _StampIOS(text: 'LIKE', color: CupertinoColors.systemGreen),
            ),
          ),
          Positioned(
            top: 50,
            right: 30,
            child: Opacity(
              opacity: nopeOpacity,
              child: _StampIOS(text: 'NOPE', color: CupertinoColors.systemRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _StampIOS extends StatelessWidget {
  const _StampIOS({required this.text, required this.color});
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
