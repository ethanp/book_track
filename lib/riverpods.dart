import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'riverpods.g.dart';

/// Annotating a class by `@riverpod` defines shared state
/// accessible via `<className>Provider`.
///
/// This class is both responsible for initializing the state
/// (through the [build] method) and exposing ways to modify it (cf [update]).
@riverpod
class SelectedBottomBarIdx extends _$SelectedBottomBarIdx {
  /// Classes annotated by `@riverpod` **must** define a [build] function,
  /// which returns the initial state.
  ///
  /// It is acceptable to return a [Future] or [Stream] if you need to instead.
  ///
  /// You can also freely define parameters on this method.
  @override
  int build() => 0;

  void update(int idx) => state = idx;
}
