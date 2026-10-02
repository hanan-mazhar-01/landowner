import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_motion.dart';
import '../../../domain/property_metrics.dart';
import 'deck_pose.dart';
import 'property_carousel_card.dart';

/// Swipeable stack of property cards (swipe left → next, right → previous).
///
/// A transparent [PageView] owns the gesture and physics; the visible deck is
/// painted underneath from `controller.page`, so every card's pose is a
/// continuous function of the drag. Only cards within reach are built, and
/// card subtrees are cached so a frame only rebuilds cheap transforms.
class PropertyStackCarousel extends StatefulWidget {
  const PropertyStackCarousel({super.key, required this.properties, required this.onPropertyTap, this.onPageChanged});

  final List<PropertyMetrics> properties;
  final ValueChanged<PropertyMetrics> onPropertyTap;
  final ValueChanged<int>? onPageChanged;

  @override
  State<PropertyStackCarousel> createState() => _PropertyStackCarouselState();
}

class _PropertyStackCarouselState extends State<PropertyStackCarousel> {
  PageController? _controller;
  double _viewportFraction = 0;
  int _index = 0;

  /// Cached card subtrees keyed by property id (rebuilt only when data changes).
  late List<Widget> _cards;

  @override
  void initState() {
    super.initState();
    _buildCards();
  }

  @override
  void didUpdateWidget(PropertyStackCarousel old) {
    super.didUpdateWidget(old);
    if (!identical(old.properties, widget.properties)) {
      _buildCards();
      if (_index >= widget.properties.length) _index = math.max(0, widget.properties.length - 1);
    }
  }

  void _buildCards() => _cards = [
        for (final m in widget.properties)
          RepaintBoundary(key: ValueKey(m.property.id), child: PropertyCarouselCard(m: m)),
      ];

  PageController _controllerFor(double fraction) {
    if (_controller == null || (fraction - _viewportFraction).abs() > .001) {
      final old = _controller;
      final page = old?.hasClients == true ? (old!.page ?? _index.toDouble()).round() : _index;
      // Dispose after the PageView has switched to the new controller.
      if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      _viewportFraction = fraction;
      _controller = PageController(viewportFraction: fraction, initialPage: page);
    }
    return _controller!;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.properties.length;
    if (count == 0) return const SizedBox.shrink();
    final reduce = Motion.reduced(context);

    return LayoutBuilder(builder: (context, c) {
      final size = DeckSizing.of(c.maxWidth, MediaQuery.sizeOf(context).height);
      final controller = _controllerFor(size.cardWidth / c.maxWidth);
      final layout = DeckLayout(
        viewportWidth: c.maxWidth,
        cardWidth: size.cardWidth,
        cardHeight: size.cardHeight,
        reduceMotion: reduce,
      );

      return SizedBox(
        height: size.stageHeight,
        child: Stack(clipBehavior: Clip.none, children: [
          // The visible deck — rebuilt per frame from the page position.
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => _Deck(
                    page: controller.hasClients && controller.position.haveDimensions
                        ? controller.page ?? _index.toDouble()
                        : _index.toDouble(),
                    cards: _cards,
                    layout: layout,
                    cardTop: size.cardTop,
                  ),
                ),
              ),
            ),
          ),
          // The gesture surface: one transparent page per property, the size
          // of the active card, so taps only open the card in front.
          Positioned(
            left: 0,
            right: 0,
            top: size.cardTop,
            height: size.cardHeight,
            child: PageView.builder(
              controller: controller,
              itemCount: count,
              // Platform parent: iOS bounce / Android clamp at the ends.
              physics: _DeckPhysics(parent: ScrollConfiguration.of(context).getScrollPhysics(context)),
              clipBehavior: Clip.none,
              onPageChanged: (i) {
                _index = i;
                widget.onPageChanged?.call(i);
              },
              itemBuilder: (context, i) {
                final m = widget.properties[i];
                return Semantics(
                  button: true,
                  label: PropertyCarouselCard.semanticsFor(m),
                  hint: 'Opens property details',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // Front card opens; a peeking neighbour comes forward first.
                      final current = controller.hasClients ? (controller.page ?? _index.toDouble()).round() : _index;
                      if (i == current) {
                        widget.onPropertyTap(m);
                      } else {
                        controller.animateToPage(i,
                            duration: Motion.of(context, AppMotion.screenIn), curve: AppMotion.standard);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      );
    });
  }
}

/// Paints the visible cards back-to-front for the current page position.
class _Deck extends StatelessWidget {
  const _Deck({required this.page, required this.cards, required this.layout, required this.cardTop});

  final double page;
  final List<Widget> cards;
  final DeckLayout layout;
  final double cardTop;

  @override
  Widget build(BuildContext context) {
    final entries = <(DeckPose, int)>[];
    final from = math.max(0, page.floor() - 2), to = math.min(cards.length - 1, page.ceil() + 3);
    for (var i = from; i <= to; i++) {
      final pose = layout.pose(i - page);
      if (pose.visible) entries.add((pose, i));
    }
    entries.sort((a, b) => b.$1.depth.compareTo(a.$1.depth)); // far first, front last

    return Stack(clipBehavior: Clip.none, children: [
      for (final (pose, i) in entries)
        Positioned(
          key: ValueKey('slot-$i'),
          left: (layout.viewportWidth - layout.cardWidth) / 2,
          top: cardTop,
          width: layout.cardWidth,
          height: layout.cardHeight,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(pose.dx, pose.dy, 0, 1)
              ..rotateZ(pose.rotation)
              ..scaleByDouble(pose.scale, pose.scale, 1, 1),
            child: _Elevated(depth: pose.depth, opacity: pose.opacity, child: cards[i]),
          ),
        ),
    ]);
  }
}

/// Depth treatment for a deck card: the design's "featured" shadow, fading
/// as the card moves back, and a background-coloured mist instead of
/// transparency — white cards recede without the card behind bleeding
/// through, and no offscreen layer is needed.
class _Elevated extends StatelessWidget {
  const _Elevated({required this.depth, required this.opacity, required this.child});
  final double depth, opacity;
  final Widget child;

  static final _radius = BorderRadius.circular(PropertyCarouselCard.radius);

  @override
  Widget build(BuildContext context) {
    final front = (1 - depth).clamp(0.0, 1.0);
    final mist = (1 - opacity).clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14205A).withValues(alpha: (.14 + .31 * front) * opacity),
            offset: Offset(0, 12 + 8 * front),
            blurRadius: 28 + 12 * front,
            spreadRadius: -20 - 8 * front,
          ),
        ],
      ),
      child: mist == 0
          ? child
          : Stack(fit: StackFit.expand, children: [
              child,
              DecoratedBox(decoration: BoxDecoration(color: AppColors.background.withValues(alpha: mist), borderRadius: _radius)),
            ]),
    );
  }
}

/// iOS-feeling page settle: slightly softer than the default, no bounce.
class _DeckPhysics extends PageScrollPhysics {
  const _DeckPhysics({super.parent});

  @override
  _DeckPhysics applyTo(ScrollPhysics? ancestor) => _DeckPhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(mass: 0.5, stiffness: 120, ratio: 1.0);
}

/// Responsive deck sizing — proportional to the available width, capped by
/// screen height so small phones keep the whole card plus its fan visible.
class DeckSizing {
  const DeckSizing._(this.cardWidth, this.cardHeight, this.cardTop, this.stageHeight);

  final double cardWidth, cardHeight, cardTop, stageHeight;

  static const _aspect = 1.28; // height / width
  static const _maxWidth = 380.0;

  factory DeckSizing.of(double width, double screenHeight) {
    var w = math.min(width * 0.74, _maxWidth);
    var h = w * _aspect;
    final maxH = screenHeight * 0.50;
    if (h > maxH) {
      h = maxH;
      w = h / _aspect;
    }
    final top = h * 0.075; // room for the fanned cards peeking above
    return DeckSizing._(w, h, top, top + h + 16);
  }
}

/// Subtle position indicator: dots for small portfolios, "01 / 12" beyond.
class DeckIndicator extends StatelessWidget {
  const DeckIndicator({super.key, required this.count, required this.index});
  final int count, index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    if (count > 7) {
      String two(int n) => n.toString().padLeft(2, '0');
      return Text('${two(index + 1)} / ${two(count)}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textFaint, letterSpacing: .6));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        AnimatedContainer(
          duration: Motion.of(context, AppMotion.transition),
          curve: AppMotion.standard,
          width: i == index ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i == index ? AppColors.accent : AppColors.dotInactive,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    ]);
  }
}
