import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme_bloc.dart';
import 'characters_screen_ios.dart';
import 'favorites_screen_ios.dart';

class MainScreenIOS extends StatefulWidget {
  const MainScreenIOS({super.key});

  @override
  State<MainScreenIOS> createState() => _MainScreenIOSState();
}

class _MainScreenIOSState extends State<MainScreenIOS>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _themeAnimationController;
  late Animation<double> _themeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _themeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _themeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _themeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _themeAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Rick and Morty Characters'),
        trailing: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final isDarkMode =
                themeState is ThemeLoaded ? themeState.isDarkMode : false;

            return Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? CupertinoColors.systemOrange.withValues(alpha: 0.9)
                    : CupertinoColors.systemIndigo.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: (isDarkMode
                            ? CupertinoColors.systemOrange
                            : CupertinoColors.systemIndigo)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ScaleTransition(
                scale: _themeScaleAnimation,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    _themeAnimationController.forward().then((_) {
                      _themeAnimationController.reverse();
                    });
                    context.read<ThemeBloc>().add(ToggleTheme());
                  },
                  child: Icon(
                    isDarkMode ? CupertinoIcons.sun_max : CupertinoIcons.moon,
                    color: CupertinoColors.white,
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                CharactersScreenIOS(),
                FavoritesScreenIOS(),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: CupertinoTabBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person_3),
                  label: 'Персонажи',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.heart),
                  label: 'Избранное',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
