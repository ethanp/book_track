import 'package:book_track/ui/common/centered_moving_average.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CenteredMovingAverage', () {
    test('a flat series stays flat', () {
      const smoother = CenteredMovingAverage(halfWindow: 2, passCount: 3);

      expect(smoother.smoothValues([4, 4, 4, 4, 4]), [4, 4, 4, 4, 4]);
    });

    test('one pass spreads a spike onto neighboring days', () {
      final smoothed = const CenteredMovingAverage(
        halfWindow: 1,
        passCount: 1,
      ).smoothValues([0, 0, 9, 0, 0]);

      expect(smoothed[1], greaterThan(0));
      expect(smoothed[2], lessThan(9));
      expect(smoothed[3], greaterThan(0));
    });

    test('two passes equal applying one pass twice', () {
      const values = [0.0, 0.0, 9.0, 0.0, 0.0];
      const onePass = CenteredMovingAverage(halfWindow: 1, passCount: 1);
      final twoPasses = const CenteredMovingAverage(
        halfWindow: 1,
        passCount: 2,
      ).smoothValues(values);

      expect(twoPasses, onePass.smoothValues(onePass.smoothValues(values)));
    });
  });
}
