part of 'home_cubit.dart';

sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}

final class HomeLoading extends HomeState {}

final class HomeSearch extends HomeState {
  final List<Anime> images;

  HomeSearch(this.images);
}

final class HomeResult extends HomeState {
  final InfoAnime info;

  HomeResult(this.info);
}

// final class HomeWatch extends HomeState {
//   final String url;

//   HomeWatch(this.url);
// }
