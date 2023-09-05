import 'package:anime/constants/app_constants.dart';
import 'package:anime/main.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  Future search(String value) async {
    emit(HomeLoading());
    var result = await Dio().get('https://www.anitube.vip/busca.php?s=$value&submit=Buscar');

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

    emit(HomeSearch(animes));
  }

  Future select(Anime anime) async {
    emit(HomeLoading());
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
    emit(HomeResult(InfoAnime(
      name: anime.name,
      img: anime.img,
      url: anime.url,
      paginas: pags.toList(),
      eps: epsInfo,
    )));
  }

  Future watch(InfoEP ep) async {
    String qualidade = 'apphd';
    emit(HomeLoading());
    var result = await Dio().get(ep.url);

    var document = parse(result.data);

    //Select all in document when itemProp = http://schema.org/VideoObject
    var url = document.querySelectorAll('[itemprop="contentURL"]').first.attributes['content'] ?? '';
    var tmb = document.querySelectorAll('[itemprop="thumbnailUrl"]').first.attributes['content'] ?? '';

    emit(HomeWatch('${AppConstants.baseUrl}/playerricas.php?name=$qualidade/.mp4&img=$tmb&url=$url'));
  }
}
