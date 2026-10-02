import '../../finance/domain/ledger_entry.dart';
import '../../leases/domain/lease.dart';
import '../../leases/domain/rent_charge.dart';
import '../../maintenance/domain/maintenance_ticket.dart';
import '../../properties/domain/property_metrics.dart';

/// Read-only snapshot handed to the assistant. The Cloud Function version
/// receives the same shape (serialised) and grounds its answer in it.
class PortfolioContext {
  const PortfolioContext({
    required this.today,
    required this.metrics,
    required this.ledger,
    required this.charges,
    required this.leases,
    required this.maintenance,
  });

  final DateTime today;
  final List<PropertyMetrics> metrics;
  final List<LedgerEntry> ledger;
  final List<RentCharge> charges;
  final List<Lease> leases;
  final List<MaintenanceTicket> maintenance;
}

class AiAnswer {
  const AiAnswer(this.text, {this.grounded = true});
  final String text;

  /// True when the answer was computed from recorded data.
  final bool grounded;
}

/// Portfolio assistant contract.
///
/// `LocalAiRepository` answers deterministically on-device. A
/// `CloudAiRepository` will call an HTTPS Cloud Function that runs a Claude
/// model server-side (API keys never ship in the app).
abstract interface class AiRepository {
  List<String> get suggestions;
  Future<AiAnswer> ask(String question, PortfolioContext context);
}
