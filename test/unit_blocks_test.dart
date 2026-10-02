import 'package:flutter_test/flutter_test.dart';
import 'package:landowner/features/home/presentation/widgets/month_glance_card.dart';

void main() {
  test('up to 10 units map one block per unit', () {
    expect(MonthGlanceCard.blocksFor(2, 2), (2, 2));
    expect(MonthGlanceCard.blocksFor(10, 7), (10, 7));
    expect(MonthGlanceCard.blocksFor(0, 0), (0, 0));
  });

  test('more than 10 units never show more than 10 blocks', () {
    expect(MonthGlanceCard.blocksFor(100, 63), (10, 6));
    expect(MonthGlanceCard.blocksFor(100, 100), (10, 10));
    expect(MonthGlanceCard.blocksFor(250, 0), (10, 0));
  });

  test('partial occupancy is never rounded to all-empty or all-full', () {
    expect(MonthGlanceCard.blocksFor(100, 1), (10, 1));
    expect(MonthGlanceCard.blocksFor(100, 99), (10, 9));
  });
}
