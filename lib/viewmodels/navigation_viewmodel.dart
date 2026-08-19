import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationViewModel extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final navigationIndexProvider =
    NotifierProvider<NavigationViewModel, int>(NavigationViewModel.new);


