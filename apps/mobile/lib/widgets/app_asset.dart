import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Maps a backend category `slug` to a built-in Material icon.
///
/// Category art is delivered as PNGs progressively; until those land this gives
/// every category tile a clean, always-visible branded glyph instead of an
/// empty circle.
IconData categoryIconData(String slug) {
  switch (slug) {
    case 'canned-goods':
      return Icons.inventory_2_outlined;
    case 'sweets':
      return Icons.cake_outlined;
    case 'chips':
      return Icons.fastfood_outlined;
    case 'chocolate':
      return Icons.cookie_outlined;
    case 'home-producers':
      return Icons.shopping_basket_outlined;
    case 'spices-herbs':
      return Icons.spa_outlined;
    case 'tea':
      return Icons.emoji_food_beverage_outlined;
    case 'soft-drinks':
      return Icons.local_drink_outlined;
    case 'dates':
      return Icons.park_outlined;
    case 'dairy-eggs':
      return Icons.egg_outlined;
    case 'noodles':
      return Icons.ramen_dining_outlined;
    case 'organic':
      return Icons.eco_outlined;
    case 'bakery':
      return Icons.bakery_dining_outlined;
    case 'frozen':
      return Icons.ac_unit_outlined;
    case 'ice-cream':
      return Icons.icecream_outlined;
    case 'plastics-cleaning':
      return Icons.cleaning_services_outlined;
    case 'rice-grains':
      return Icons.rice_bowl_outlined;
    case 'chilled-chicken':
      return Icons.set_meal_outlined;
    default:
      return Icons.category_outlined;
  }
}

/// Resilient asset loaders.
///
/// Assets are delivered progressively. Until a file exists these widgets render
/// the supplied [fallback] (empty by default) — never a substitute icon or
/// emoji. Once the real file is dropped in with the registered name it appears
/// automatically, with zero code changes.

/// Loads a raster (PNG/JPG) asset. Missing files degrade to [fallback].
class AppAssetImage extends StatelessWidget {
  const AppAssetImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stack) =>
          fallback ?? SizedBox(width: width, height: height),
    );
  }
}

/// Loads an SVG asset (e.g. the golden outline icon set / logo). Missing files
/// degrade to [fallback] without throwing.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.path, {
    super.key,
    this.size = 24,
    this.color,
    this.fallback,
  });

  final String path;
  final double size;
  final Color? color;
  final Widget? fallback;

  /// Caches asset presence so we only probe the bundle once per path.
  static final Map<String, Future<bool>> _presence = {};

  static Future<bool> _exists(BuildContext context, String path) {
    return _presence.putIfAbsent(path, () async {
      try {
        await DefaultAssetBundle.of(context).loadString(path);
        return true;
      } on FlutterError {
        return false;
      } catch (_) {
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _exists(context, path),
      builder: (context, snap) {
        if (snap.data == true) {
          return SvgPicture.asset(
            path,
            width: size,
            height: size,
            colorFilter:
                color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
          );
        }
        return fallback ?? SizedBox(width: size, height: size);
      },
    );
  }
}
