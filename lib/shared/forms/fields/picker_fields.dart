import 'package:flutter/cupertino.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';

/// Date / time field — tap opens an iOS-style wheel in a rounded sheet.
class DateTimeField extends StatelessWidget {
  const DateTimeField({super.key, required this.value, required this.onChanged, this.timeOnly = false});
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool timeOnly;

  Future<void> _pick(BuildContext context) async {
    var picked = value ?? DateTime.now();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 320,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(children: [
              LinkText('Cancel', color: AppColors.textMuted, onTap: () => Navigator.pop(ctx)),
              const Spacer(),
              LinkText('Done', onTap: () {
                onChanged(picked);
                Navigator.pop(ctx);
              }),
            ]),
          ),
          Expanded(
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: TextStyle(fontSize: 21, color: AppColors.ink)),
              ),
              child: CupertinoDatePicker(
                mode: timeOnly ? CupertinoDatePickerMode.time : CupertinoDatePickerMode.date,
                initialDateTime: picked,
                use24hFormat: true,
                minimumYear: 1950,
                maximumYear: 2100,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _pick(context),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            value == null ? (timeOnly ? '--:--' : 'Select a date') : (timeOnly ? Dates.hm(value!) : Dates.dMy(value!)),
            style: TextStyle(fontSize: 16, color: value == null ? AppColors.textFaint : AppColors.ink),
          ),
        ),
      );
}
