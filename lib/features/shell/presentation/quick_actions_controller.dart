import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/homely_icons.dart';

/// Open/closed state of the central + quick-action menu.
class QuickActionsController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void open() => state = true;
  void close() => state = false;
}

final quickActionsProvider = NotifierProvider<QuickActionsController, bool>(QuickActionsController.new);

/// Entry forms reachable from the + menu (keys match `/add/:form`).
enum QuickAction {
  property('Property', HomelyIcons.home),
  lease('Lease', HomelyIcons.calendar),
  income('Income', HomelyIcons.trendUp),
  expense('Expense', HomelyIcons.trendDown),
  tenant('Tenant', HomelyIcons.users),
  maintenance('Maintenance', HomelyIcons.wrench),
  document('Document', HomelyIcons.file),
  reminder('Reminder', HomelyIcons.bell);

  const QuickAction(this.label, this.icon);
  final String label;
  final HomelyIcons icon;

  static const primary = [property, lease, income, expense];
  static const secondary = [tenant, maintenance, document, reminder];
}
