import 'dart:developer';

import 'package:anime/constants/app_constants.dart';
import 'package:anime/main.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_windows/webview_windows.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  String searched = '';
  final controllerWV = WebviewController();
  List<Anime> animes = [];
  Anime? anime;
  InfoAnime? info;
  late SharedPreferences prefs;

  Dio dio = Dio();

  void init() async {
    controllerWV.initialize();
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> search(String value) async {
    try {
      emit(HomeLoading());
      searched = value;
      var result = await dio.get('https://www.anitube.vip/busca.php?s=$value&submit=Buscar');


      
      var document = parse(result.data);

      List<Anime> animes = [];

      var allAn = document.getElementsByClassName('ani_loop_item');

      for (var anime in allAn) {
        var div = anime.getElementsByClassName('ani_loop_item_img').first;

        var a = div.getElementsByTagName('a').first;
        var img = div.getElementsByTagName('img').first;

        animes.add(Anime(
          name: img.attributes['title'] ?? '',
          img: img.attributes['src'] ?? '',
          url: a.attributes['href'] ?? '',
        ));
      }
      this.animes = animes;
      emit(HomeSearch(animes));
    } catch (e) {
      emit(HomeError('Houve um erro ao buscar os animes, tenta novamente mais tarde.'));
      emit(HomeInitial());
    }
  }

  void toInitial() {
    emit(HomeInitial());
  }

  void toSearch() {
    emit(HomeSearch(animes));
  }

  void toInfo() {
    controllerWV.stop();
    emit(HomeResult(info!));
  }

  void selectPage(int page) {
    if (anime != null) {
      if (anime!.url.contains('/page/')) {
        anime!.url = anime!.url.split('/page/').first;
      }
      anime!.url = '${anime!.url}/page/$page';
      select(anime!);
    }
  }

  Future select(Anime anime) async {
    emit(HomeLoading());
    this.anime = anime;

    var result = await Dio().get(anime.url);

    var document = parse(result.data);

    var pag = document.getElementsByClassName('pagination').first;
    Set<int> pags = pag.children.map((e) => int.tryParse(e.text) ?? 1).toSet();

    var eps = document.getElementsByClassName('animepag_episodios_item');
    List<InfoEP> epsInfo = [];
    for (var ep in eps) {
      var a = ep.getElementsByTagName('a').first;
      var id = a.attributes['href']?.split('/').last ?? '';
      var img = a.getElementsByTagName('img').first;
      var name = a.getElementsByClassName('animepag_episodios_item_nome').first;

      epsInfo.add(InfoEP(
        id: int.tryParse(id) ?? 0,
        name: name.text,
        url: '${AppConstants.baseUrl}/video/$id',
        img: img.attributes['src'] ?? '',
      ));
    }

    var inf = InfoAnime(
      name: anime.name,
      img: anime.img,
      url: anime.url,
      paginas: pags.toList(),
      eps: epsInfo,
    );
    info = inf;
    emit(HomeResult(inf));
  }

  Future watch(InfoEP ep) async {
    var list = prefs.getStringList(anime!.name) ?? [];

    list.removeWhere((element) => element == ep.id.toString());
    list.add(ep.id.toString());
    await prefs.setStringList(anime!.name, list);

    String qualidade = 'apphd';

    String qualidadeSD = 'appsd';
    String qualidadeSD2 = 'appsd2';

    String qualidadeHD = 'apphd';
    String qualidadeHD2 = 'apphd2';
    String qualidadeFullHD = 'appfullhd';
    String qualidadeFullHD2 = 'appfullhd2';
    emit(HomeLoading());
    var result = await Dio().get(ep.url);

    var document = parse(result.data);

    var url = document.querySelectorAll('[itemprop="contentURL"]').first.attributes['content'] ?? '';
    var tmb = document.querySelectorAll('[itemprop="thumbnailUrl"]').first.attributes['content'] ?? '';

    if (url.contains('appsd2')) {
      url = url.replaceAll('appsd2', 'apphd2');
    } else if (url.contains('appsd')) {
      url = url.replaceAll('appsd', 'apphd');
    }

    await controllerWV.setBackgroundColor(Colors.transparent);
    await controllerWV.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    await controllerWV.loadUrl('${AppConstants.baseUrl}/playerricas.php?name=$qualidade/.mp4&img=$tmb&url=$url');

    log('${AppConstants.baseUrl}/playerricas.php?name=$qualidade/.mp4&img=$tmb&url=$url');
    emit(HomeWatch('${AppConstants.baseUrl}/playerricas.php?name=$qualidade/.mp4&img=$tmb&url=$url'));
  }
}
