import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/utils/app_theme.dart';
import 'data/api/rick_and_morty_api.dart';
import 'data/dao/character_dao.dart';
import 'data/dto/character_dto.dart';
import 'data/repositories/character_repository_impl.dart';
import 'domain/repositories/character_repository.dart';
import 'presentation/bloc/character_bloc.dart';
import 'presentation/bloc/theme_bloc.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/main_screen_ios.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Hive
  await Hive.initFlutter();

  // Регистрируем адаптеры
  Hive.registerAdapter(CharacterDtoAdapter());

  // Открываем Hive boxes
  await Hive.openBox<CharacterDto>('characters');
  await Hive.openBox<int>('favorites');

  runApp(const MyAdaptiveApp());
}

class MyAdaptiveApp extends StatelessWidget {
  const MyAdaptiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CharacterRepository>(
          create: (context) => CharacterRepositoryImpl(
            RickAndMortyApi(),
            CharacterDao(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CharacterBloc>(
            create: (context) => CharacterBloc(
              repository: context.read<CharacterRepository>(),
            ),
          ),
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc()..add(LoadTheme()),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            if (defaultTargetPlatform == TargetPlatform.iOS) {
              return CupertinoApp(
                title: 'Rick and Morty Characters',
                debugShowCheckedModeBanner: false,
                theme: CupertinoThemeData(
                  brightness: themeState is ThemeLoaded && themeState.isDarkMode
                      ? Brightness.dark
                      : Brightness.light,
                ),
                home: const MainScreenIOS(),
              );
            } else {
              return MaterialApp(
                title: 'Rick and Morty Characters',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeState is ThemeLoaded && themeState.isDarkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,
                home: const MainScreen(),
              );
            }
          },
        ),
      ),
    );
  }
}
