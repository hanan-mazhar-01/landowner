import 'dart:async';

import 'package:flutter/material.dart' show TextField, InputDecoration, InputBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_decor.dart';
import '../icons/homely_icon.dart';

/// The Portfolio search field (50px, radius 18) with a 250ms debounce.
class HomelySearchField extends StatefulWidget {
  const HomelySearchField({
    super.key,
    required this.onChanged,
    this.placeholder = 'Search',
    this.margin = const EdgeInsets.fromLTRB(16, 20, 16, 0),
  });

  final ValueChanged<String> onChanged;
  final String placeholder;
  final EdgeInsets margin;

  @override
  State<HomelySearchField> createState() => _HomelySearchFieldState();
}

class _HomelySearchFieldState extends State<HomelySearchField> {
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: widget.margin,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.search),
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          const HomelyIcon(HomelyIcons.search, size: 18, color: AppColors.textFaint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (q) {
                _t?.cancel();
                _t = Timer(const Duration(milliseconds: 250), () => widget.onChanged(q.trim().toLowerCase()));
              },
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: const TextStyle(fontSize: 15, color: AppColors.textFaint),
              ),
            ),
          ),
        ]),
      );
}
