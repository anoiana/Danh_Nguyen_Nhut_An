import 'package:flutter/material.dart';

enum ViewState { idle, busy, error }

class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String _errorMessage = '';

  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  bool get isBusy => _state == ViewState.busy;
  bool get isError => _state == ViewState.error;

  void setBusy(bool isBusy) {
    setState(isBusy ? ViewState.busy : ViewState.idle);
  }

  void setError(String message) {
    _errorMessage = message;
    setState(ViewState.error);
  }

  void clearError() {
    _errorMessage = '';
    if (_state == ViewState.error) {
      _state = ViewState.idle;
      notifyListeners();
    }
  }

  void setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }
}
