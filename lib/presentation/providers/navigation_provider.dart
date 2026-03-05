import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int _previousIndex = 0;

  int get currentIndex => _currentIndex;
  int get previousIndex => _previousIndex;

  void setIndex(int index) {
    if (_currentIndex == index) return;

    _previousIndex = _currentIndex;
    _currentIndex = index;

    notifyListeners();
  }
}
