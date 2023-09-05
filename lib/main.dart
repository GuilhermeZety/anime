import 'package:anime/cubit/home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final HomeCubit _cubit = HomeCubit();

  @override
  void initState() {
    super.initState();
  }

  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer(
        bloc: _cubit,
        listener: (context, state) {},
        builder: (context, state) {
          if (state is HomeInitial) {
            return Center(
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Digite o link do vídeo',
                ),
                onFieldSubmitted: (value) {
                  _cubit.search(value);
                },
              ),
            );
          }
          if (state is HomeSearch) {
            return SingleChildScrollView(
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
            );
          }
          if (state is HomeResult) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      children: [
                        ...state.info.eps
                            .map(
                              (e) => GestureDetector(
                                onTap: () => _cubit.watch(e),
                                child: Card(
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
                            // onPressed: () => _cubit.selectPage(e),
                            onPressed: () {},
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
            return Center(child: SelectableText(state.url));
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
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
      child: Card(
        child: Column(
          children: [
            Image.network(anime.img),
            Text(anime.name),
          ],
        ),
      ),
    );
  }
}

//

class Anime {
  final String name;
  final String img;
  final String url;

  Anime({required this.name, required this.img, required this.url});
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
