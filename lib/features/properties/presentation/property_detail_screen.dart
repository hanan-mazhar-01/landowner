import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/states.dart';
import 'detail/detail_cards.dart';
import 'detail/detail_extras.dart';
import 'detail/detail_header.dart';
import 'detail/property_detail_vm.dart';
import 'detail/tenancy_cards.dart';
import '../../tenants/presentation/tenant_providers.dart';

class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.id, this.initialTab = 0});
  final String id;
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(propertyDetailProvider(id));
    void back() => context.canPop() ? context.pop() : context.go(Routes.properties);
    if (vm == null) {
      return ColoredBox(
        color: AppColors.background,
        child: Center(
          child: EmptyStateCard(
            title: 'Property not found',
            message: 'It may have been removed from your portfolio.',
            actionLabel: 'Back to portfolio',
            onAction: back,
          ),
        ),
      );
    }
    final today = ref.read(clockProvider).today();
    final m = vm.m;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.background,
        // Header and sheet share one Column so the sheet paints over the
        // photo (slivers paint later siblings underneath).
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DetailHeader(
                    m: m,
                    onBack: back,
                    onEdit: () => context.push(Routes.add('property', editId: id)),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 26, 16, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ValueRow(m: m),
                          const SizedBox(height: 22),
                          MetricGrid(m: m),
                          const SizedBox(height: 14),
                          PerformanceCard(m: m, initialTab: initialTab),
                          const SizedBox(height: 14),
                          TenancyCard(
                            vm: vm,
                            today: today,
                            onMarkRented: () => context.push(Routes.add('lease', propertyId: id)),
                            onOpen: () {
                              final lease = ref.read(primaryLeaseForProvider(id));
                              if (lease != null) context.push(Routes.tenant(lease));
                            },
                          ),
                          if (vm.timeline.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            TimelineCard(
                              title: 'Rental timeline',
                              action: vm.focusCharge == null
                                  ? LinkText('Payments →', onTap: () => context.push(Routes.forProperty(Routes.payments, id)))
                                  : SolidButton(
                                      label: 'Resolve overdue',
                                      height: 30,
                                      radius: 10,
                                      fontSize: 12,
                                      padding: 12,
                                      color: AppColors.overdueTint,
                                      foreground: AppColors.overdueText,
                                      onTap: () => context.push(Routes.overdue(vm.focusCharge!.id)),
                                    ),
                              children: [
                                for (var i = 0; i < vm.timeline.length; i++)
                                  TimelineRow(
                                    title: vm.timeline[i].title,
                                    meta: vm.timeline[i].meta,
                                    color: vm.timeline[i].color,
                                    dots: vm.timeline[i].dots,
                                    last: i == vm.timeline.length - 1,
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          TimelineCard(
                            title: 'Maintenance',
                            action: LinkText(
                              'View all',
                              onTap: () => context.push(Routes.forProperty(Routes.maintenance, id)),
                            ),
                            children: [
                              for (var i = 0; i < vm.maintenance.length; i++)
                                TimelineRow(
                                  title: vm.maintenance[i].title,
                                  meta: vm.maintenance[i].meta,
                                  color: vm.maintenance[i].color,
                                  trailing: vm.maintenance[i].cost,
                                  hollow: true,
                                  last: i == vm.maintenance.length - 1,
                                ),
                              if (vm.maintenance.isEmpty)
                                const Text(
                                  'No maintenance logged yet.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DocumentsStrip(
                            docs: vm.documents,
                            onAdd: () => context.push(Routes.add('document', propertyId: id)),
                            onViewAll: () => context.push(Routes.forProperty(Routes.documents, id)),
                            onOpen: (docId) => context.push(Routes.document(docId)),
                          ),
                          const SizedBox(height: 20),
                          IntelligenceCard(text: vm.insight, onTap: () => context.push(Routes.ai)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
