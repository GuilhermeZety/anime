// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:anime/cubit/home_cubit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
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

class _HomeState extends State<Home> {
  final HomeCubit _cubit = HomeCubit();
  bool inFullScreen = false;

  @override
  void initState() {
    _cubit.init();
    super.initState();
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
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
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
                  ),
                ),
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
                                child: Container(
                                  width: 190,
                                  height: 190,
                                  margin: const EdgeInsets.all(5),
                                  color: list.contains(e.id.toString()) ? Colors.grey.shade400 : Colors.white,
                                  child: Column(
                                    children: [
                                      Image.network(
                                        e.img,
                                        fit: BoxFit.cover,
                                        height: 155,
                                      ),
                                      AutoSizeText(
                                        e.name,
                                        maxLines: 2,
                                      ),
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
                Wrap(children: [
                  ...state.info.paginas
                      .map(
                        (e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FilledButton(
                            onPressed: () => _cubit.selectPage(e),
                            child: Text(e.toString()),
                          ),
                        ),
                      )
                      .toList(),
                ])
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
        constraints: const BoxConstraints(
          minWidth: 170,
        ),
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
            Column(
              children: [
                AutoSizeText(
                  anime.name,
                  maxLines: 3,
                ),
              ],
            ),
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

  InfoEP({
    required this.id,
    required this.name,
    required this.url,
    required this.img,
  });
}
