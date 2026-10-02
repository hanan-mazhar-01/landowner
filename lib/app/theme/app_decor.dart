import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Corner radii used in the design.
abstract final class AppRadius {
  static const pill = 999.0;
  static const featured = 32.0;
  static const hero = 30.0;
  static const review = 28.0;
  static const card = 26.0;
  static const list = 24.0;
  static const tile = 22.0;
  static const cta = 20.0;
  static const search = 18.0;
  static const input = 16.0;
  static const iconTile = 14.0;
  static const md = 12.0;
  static const sm = 10.0;
  static const bar = 8.0;
}

/// Layout rhythm used in the design.
abstract final class AppSpacing {
  static const gutter = 24.0; // text edge
  static const cardGutter = 16.0; // card edge
  static const sectionTop = 34.0;
  static const navClearance = 140.0;
  static const topInset = 62.0 - 47.0; // design top padding minus status bar
}

/// Shadows, 1:1 from the design.
abstract final class AppShadows {
  static const _navy = Color(0xFF14205A); // rgb(20,32,90)
  static const _blue = Color(0xFF304BC7); // rgb(48,75,199)
  static const _deep = Color(0xFF23389F); // rgb(35,56,159)

  static BoxShadow _s(Color c, double o, double y, double blur, double spread) =>
      BoxShadow(color: c.withValues(alpha: o), offset: Offset(0, y), blurRadius: blur, spreadRadius: spread);

  static final card = [_s(_navy, .05, 1, 2, 0)];
  static final cardStrong = [_s(_navy, .06, 1, 2, 0)];
  static final featured = [_s(_navy, .45, 20, 40, -28)];
  static final carouselFocused = [_s(_navy, .55, 24, 40, -22)];
  static final carouselIdle = [_s(_navy, .40, 10, 20, -18)];
  static final heroCard = [_s(_deep, .80, 24, 40, -24)];
  static final cta = [_s(_blue, .70, 14, 30, -12)];
  static final ctaForm = [_s(_blue, .80, 14, 28, -14)];
  static final plus = [_s(_blue, .80, 12, 22, -8)];
  static final pin = [_s(_blue, .70, 8, 16, -6)];
  static final nav = [_s(_navy, .45, 18, 40, -18)];
  static final segment = [_s(_navy, .12, 1, 3, 0)];
  static final knob = [_s(const Color(0xFF000000), .20, 1, 3, 0)];
  static final toast = [_s(const Color(0xFF000000), .50, 12, 30, -12)];
  static final quickAction = [_s(const Color(0xFF000000), .45, 12, 26, -10)];
}

/// Gradients, 1:1 from the design. CSS angles converted to Flutter alignments.
abstract final class AppGradients {
  /// `linear-gradient(150deg,#4D6DFA,#304BC7)` — CTAs, the + button, logo tile.
  static const cta = LinearGradient(
    begin: Alignment(-0.5, -0.866),
    end: Alignment(0.5, 0.866),
    colors: [AppColors.blue400, AppColors.blue600],
  );

  /// `linear-gradient(160deg,#3F5DE8 0%,#304BC7 55%,#23389F 100%)` — hero cards.
  static const hero = LinearGradient(
    begin: Alignment(-0.342, -0.94),
    end: Alignment(0.342, 0.94),
    colors: [AppColors.blue500, AppColors.blue600, AppColors.blue700],
    stops: [0, .55, 1],
  );

  static const heroAlt = LinearGradient(
    begin: Alignment(-0.342, -0.94),
    end: Alignment(0.342, 0.94),
    colors: [AppColors.blue500, AppColors.blue600, AppColors.blue700],
    stops: [0, .60, 1],
  );

  /// Bottom scrim on property photos (carousel / review card).
  static const photoBottom = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000B1028), Color(0xD10B1028)],
    stops: [.4, 1],
  );

  /// Detail header scrim: dark top, clear middle, dark bottom.
  static const detailHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x660B1028), Color(0x000B1028), Color(0x000B1028), Color(0xBF0B1028)],
    stops: [0, .28, .5, 1],
  );

  /// Welcome hero fade into the page background.
  static const welcome = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x59111830), Color(0x00111830), Color(0x00F3F6FE), AppColors.background],
    stops: [0, .3, .6, 1],
  );
}
