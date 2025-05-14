import 'dart:math';

extension ShuffleTogether<T> on List<List<T>> {
  void shuffleTogether([Random? random]) {
    if (isEmpty) return;

    random ??= Random();
    final length = first.length;
    final indices = List.generate(length, (i) => i)..shuffle(random);

    for (final list in this) {
      if (list.length != length) {
        throw ArgumentError('All lists must be of the same length');
      }

      final shuffled = List<T>.generate(length, (i) => list[indices[i]]);
      list.setAll(0, shuffled);
    }
  }
}
