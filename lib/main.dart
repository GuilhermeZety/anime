// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:anime/cubit/home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home(), debugShowCheckedModeBanner: false);
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final HomeCubit _cubit = HomeCubit();
  bool inFullScreen = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    ServicesBinding.instance.keyboard.addHandler(_onkey);
    _cubit.init();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log('state = $state');
  }

  Future setFullscreen() async {
    var isFullScreen = await WindowManager.instance.isFullScreen();
    if (isFullScreen) {
      inFullScreen = false;
      await windowManager.setFullScreen(false);
      if (mounted) setState(() {});
      return;
    } else {
      inFullScreen = true;
      await windowManager.setFullScreen(true);
      if (mounted) setState(() {});
      return;
    }
  }

  bool _onkey(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.f11 && event is KeyDownEvent) {
      setFullscreen();
    }
    return false;
  }

  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer(
        bloc: _cubit,
        listener: (context, state) {
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HomeInitial) {
            return Center(
              child: Card(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  width: 400,
                  child: TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Digite o nome do anime',
                    ),
                    onFieldSubmitted: (value) async {
                      await _cubit.search(value);
                    },
                  ),
                ),
              ),
            );
          }
          if (state is HomeSearch) {
            return Column(
              children: [
                AppBar(
                    title: const Text('Resultados'),
                    leading: IconButton(
                      onPressed: () => _cubit.toInitial(),
                      icon: const Icon(Icons.arrow_back),
                    )),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      children: [
                        ...state.images
                            .map(
                              (e) => AnimeItem(
                                anime: e,
                                onTap: () => _cubit.select(e),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          if (state is HomeResult) {
            var list = _cubit.prefs.getStringList(state.info.name) ?? [];
            return Column(
              children: [
                AppBar(
                  title: Text(state.info.name),
                  leading: IconButton(
                    onPressed: () async => _cubit.toSearch(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      children: [
                        ...state.info.eps
                            .map(
                              (e) => GestureDetector(
                                onTap: () => _cubit.watch(e),
                                child: Card(
                                  color: list.contains(e.id.toString()) ? Colors.grey.shade400 : Colors.white,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.network(e.img),
                                      Text(e.name),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: Row(children: [
                    ...state.info.paginas
                        .map(
                          (e) => TextButton(
                            onPressed: () => _cubit.selectPage(e),
                            child: Text(e.toString()),
                          ),
                        )
                        .toList(),
                  ]),
                )
              ],
            );
          }
          if (state is HomeWatch) {
            log('state is HomeWatch');
            log(state.url);
            return Stack(
              children: [
                Webview(
                  _cubit.controllerWV,
                ),
                Column(
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        onPressed: () async => _cubit.toInfo(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      backgroundColor: Colors.grey.shade200,
    );
  }
}

class AnimeItem extends StatelessWidget {
  const AnimeItem({super.key, required this.anime, required this.onTap});

  final Anime anime;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.all(10),
        width: (MediaQuery.sizeOf(context).width / 4) - 20,
        height: 300,
        child: Column(
          children: [
            Image.network(
              anime.img,
              fit: BoxFit.cover,
              height: 250,
            ),
            Text(anime.name),
          ],
        ),
      ),
    );
  }
}

//

class Anime {
  String name;
  String img;
  String url;

  Anime({required this.name, required this.img, required this.url});

  Anime copyWith({
    String? name,
    String? img,
    String? url,
  }) {
    return Anime(
      name: name ?? this.name,
      img: img ?? this.img,
      url: url ?? this.url,
    );
  }
}

class InfoAnime {
  final String name;
  final String img;
  final String url;
  final List<int> paginas;
  final List<InfoEP> eps;

  InfoAnime({
    required this.name,
    required this.img,
    required this.url,
    required this.paginas,
    required this.eps,
  });
}

class InfoEP {
  final int id;
  final String name;
  final String url;
  final String img;

  InfoEP({required this.id, required this.name, required this.url, required this.img});
}
