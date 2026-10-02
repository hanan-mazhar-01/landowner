import '../../../core/utils/formatters.dart';
import '../../finance/domain/finance_analytics.dart';
import '../../leases/domain/rent_charge.dart';
import '../domain/ai_repository.dart';

/// On-device assistant: routes a question to a computed answer.
class LocalAiRepository implements AiRepository {
  @override
  List<String> get suggestions => const [
        'What are my highest expense properties?',
        'How much rent did I collect this month?',
        'Which property generated the most net income?',
        'Show my maintenance costs.',
      ];

  @override
  Future<AiAnswer> ask(String question, PortfolioContext c) async {
    final q = question.toLowerCase();
    if (q.contains('expense') || q.contains('cost') && !q.contains('maint')) return AiAnswer(_expenses(c));
    if (q.contains('rent') && (q.contains('collect') || q.contains('month'))) return AiAnswer(_collected(c));
    if (q.contains('net') || q.contains('most') || q.contains('best')) return AiAnswer(_topNet(c));
    if (q.contains('maint') || q.contains('repair')) return AiAnswer(_maintenance(c));
    if (q.contains('lease') || q.contains('expir')) return AiAnswer(_leases(c));
    if (q.contains('vacan') || q.contains('empty')) return AiAnswer(_vacancy(c));
    if (q.contains('yield') || q.contains('return')) return AiAnswer(_yield(c));
    return const AiAnswer(
      'I can answer questions about rent, expenses, leases, maintenance and property value from your recorded '
      'data. Try one of the suggestions below.',
      grounded: false,
    );
  }

  String _expenses(PortfolioContext c) {
    final m = [...c.metrics]..sort((a, b) => b.monthlyExpenses.compareTo(a.monthlyExpenses));
    if (m.isEmpty) return 'You haven’t recorded any properties yet.';
    final total = m.fold<int>(0, (s, x) => s + x.monthlyExpenses);
    final top2 = m.take(2).fold<int>(0, (s, x) => s + x.monthlyExpenses);
    final second = m.length > 1 ? ', then ${m[1].property.name} at ${Money.k(m[1].monthlyExpenses)}' : '';
    return '${m.first.property.name} has the highest monthly costs at ${Money.k(m.first.monthlyExpenses)}$second. '
        'Together they make up ${(top2 / (total == 0 ? 1 : total) * 100).round()}% of recorded property expenses.';
  }

  String _collected(PortfolioContext c) {
    final due = c.charges.where(
        (x) => x.dueDate.year == c.today.year && x.dueDate.month == c.today.month && !x.dueDate.isAfter(c.today));
    final total = due.fold(0, (s, x) => s + x.amount);
    final paid = due.where((x) => x.isPaid).fold(0, (s, x) => s + x.amount);
    if (total == 0) return 'No rent has fallen due yet this month.';
    final outstanding = c.charges.where((x) => x.statusOn(c.today) == RentStatus.overdue).toList();
    final names = {for (final m in c.metrics) m.property.id: m.property.name};
    final owed = outstanding.isEmpty
        ? ' Nothing is outstanding.'
        : ' ${Money.k(outstanding.fold(0, (s, x) => s + x.amount))} is outstanding from '
            '${outstanding.map((x) => names[x.propertyId]).toSet().join(', ')}.';
    return 'You collected ${Money.compact(paid)} of ${Money.compact(total)} due in ${Dates.month(c.today)} — a '
        '${(paid / total * 100).toStringAsFixed(1)}% collection rate.$owed';
  }

  String _topNet(PortfolioContext c) {
    final m = [...c.metrics]..sort((a, b) => b.net.compareTo(a.net));
    if (m.isEmpty) return 'You haven’t recorded any properties yet.';
    final next = m.length > 1 ? ' ${m[1].property.name} follows with ${Money.k(m[1].net)}.' : '';
    return '${m.first.property.name}, at ${Money.k(m.first.net)} net per month.$next';
  }

  String _maintenance(PortfolioContext c) {
    final shares = FinanceAnalytics.breakdown(c.ledger, c.today);
    final maint = shares.where((s) => s.category.label == 'Maintenance').firstOrNull;
    final biggest = [...c.maintenance]..sort((a, b) => b.cost.compareTo(a.cost));
    final names = {for (final m in c.metrics) m.property.id: m.property.name};
    if (maint == null) return 'No maintenance costs recorded this month.';
    final b = biggest.isEmpty ? '' : ' The ${biggest.first.title} at ${names[biggest.first.propertyId]} is the largest item at ${Money.k(biggest.first.cost)}.';
    return 'Maintenance totals ${Money.k(maint.amount)} this month — ${(maint.share * 100).round()}% of expenses.$b';
  }

  String _leases(PortfolioContext c) {
    final soon = c.leases.where((l) => l.isActiveOn(c.today) && l.end.difference(c.today).inDays <= 60).length;
    return soon == 0
        ? 'No leases expire in the next 60 days.'
        : '$soon lease${soon == 1 ? '' : 's'} expire${soon == 1 ? 's' : ''} within the next 60 days.';
  }

  String _vacancy(PortfolioContext c) {
    final v = c.metrics.where((m) => m.isVacant).toList();
    if (v.isEmpty) return 'Every property is currently let.';
    return '${v.map((m) => m.property.name).join(', ')} ${v.length == 1 ? 'is' : 'are'} vacant. '
        'At last rent that is ${Money.k(v.fold(0, (s, m) => s + m.lastRent))} a month of lost income.';
  }

  String _yield(PortfolioContext c) {
    final m = [...c.metrics]..sort((a, b) => b.yieldPct.compareTo(a.yieldPct));
    if (m.isEmpty) return 'You haven’t recorded any properties yet.';
    return '${m.first.property.name} has the highest net rental yield at ${m.first.yieldPct.toStringAsFixed(1)}%.';
  }
}
