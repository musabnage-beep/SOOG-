import 'package:flutter/widgets.dart';

/// Layout helpers that keep the app usable on every width Apple ships it to.
///
/// The app targets iPhone, but an iPhone-only app is still installable on iPad,
/// where iPadOS runs it in a resizable window. Review rejected 1.0.33 under
/// guideline 4 because the fixed two-column grids stretched each product card to
/// roughly 500pt wide there. Nothing below changes the phone layout: the extents
/// are tuned so a 390pt-wide iPhone still resolves to the original column count.

/// Product tiles keep a phone-sized footprint and simply gain columns as the
/// window widens (2 on an iPhone, 6 on a full-width iPad).
const productGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  childAspectRatio: 0.66,
);

/// Category pucks, same idea: 5 across on an iPhone, more on a wider window.
const categoryGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 80,
  childAspectRatio: 0.74,
  crossAxisSpacing: 6,
  mainAxisSpacing: 12,
);

/// Height a tab's scrollable must reserve at its bottom so the last row clears
/// the floating navigation bar.
///
/// `MainShell` sets `extendBody: true`, so every tab is drawn *behind* that bar.
/// Scaffold reports the bar's height as the body's bottom padding, which is the
/// only honest source: the screens used to hard-code 110 or 32, and the 32 on
/// the account tab left «حذف الحساب» unreachable even at the end of the scroll.
double bottomBarInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom;

/// Centres single-column content (forms, carts, order details) instead of
/// letting a text field or a list row run the full width of an iPad window.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
