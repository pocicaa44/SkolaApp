import 'base_view.dart';

abstract class BasePresenter<V extends BaseView> {
  V? _view;

  V? get view => _view;
  bool get isViewAttached => _view != null;

  void attachView(V view) {
    _view = view;
    onViewAttached();
  }

  void detachView() {
    _view = null;
    onViewDetached();
  }

  /// Hook dipanggil saat view berhasil terpasang
  void onViewAttached() {}

  /// Hook dipanggil saat view dilepas untuk membersihkan listener / async tasks
  void onViewDetached() {}
}
