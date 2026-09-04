import 'package:aldiafa/core/network/api_client.dart';
import 'package:aldiafa/core/storage/token_storage.dart';
import 'package:aldiafa/core/theme/app_theme.dart';
import 'package:aldiafa/data/models/cart.dart';
import 'package:aldiafa/data/models/user.dart';
import 'package:aldiafa/data/repositories/auth_repository.dart';
import 'package:aldiafa/features/account/account_screen.dart';
import 'package:aldiafa/features/cart/cart_screen.dart';
import 'package:aldiafa/providers/auth_controller.dart';
import 'package:aldiafa/providers/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards against layout faults that only surface as a blank area in a release
/// build. A themed button dropped into a `Row` once inherited an infinite
/// minimum width from `minimumSize: Size.fromHeight(...)`, which threw during
/// layout and left the cart header unpainted.
void main() {
  Widget host(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }

  /// Pumps [child] on a phone-sized surface and fails on any layout error.
  Future<void> expectClean(
    WidgetTester tester,
    Widget child, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(child, overrides: overrides));
    await tester.pump();

    expect(tester.takeException(), isNull);
  }

  testWidgets('cart renders with items', (tester) async {
    await expectClean(
      tester,
      const CartScreen(),
      overrides: [cartControllerProvider.overrideWith((ref) => _FakeCart())],
    );

    // The header must sit at the top, above the list — the shipped bug pushed
    // everything to the bottom half of the screen.
    final header = tester.getRect(find.text('السلة'));
    expect(header.top, lessThan(80));
    expect(
      tester.getRect(find.text('إضافة أصناف')).width,
      lessThan(200),
      reason: 'the header button must hug its label, not stretch the row',
    );
    expect(find.text('إتمام الطلب'), findsOneWidget);
  });

  testWidgets('cart renders when empty', (tester) async {
    await expectClean(tester, const CartScreen());
    expect(find.text('سلتك فارغة'), findsOneWidget);
  });

  testWidgets('account renders', (tester) async {
    await expectClean(
      tester,
      const AccountScreen(),
      overrides: [authControllerProvider.overrideWith((ref) => _FakeAuth())],
    );
    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('حذف الحساب'), findsOneWidget);
  });
}

class _FakeCart extends CartController {
  _FakeCart() : super(_DeadRef()) {
    state = CartState(
      cart: Cart(
        subtotal: 47.5,
        itemCount: 2,
        items: [
          CartLine(
            id: '1',
            productId: 'p1',
            nameAr: 'حلوى الفواكه بالنكهات المشكّلة',
            nameEn: 'Fruit candy',
            unitPrice: 12.5,
            quantity: 2,
            lineTotal: 25,
          ),
          CartLine(
            id: '2',
            productId: 'p2',
            nameAr: 'مصاصات ملوّنة',
            nameEn: 'Lollipops',
            unitPrice: 22.5,
            quantity: 1,
            lineTotal: 22.5,
            unit: 'CARTON',
            unitsPerCarton: 24,
          ),
        ],
      ),
    );
  }
}

class _FakeAuth extends AuthController {
  _FakeAuth()
    : super(
        repo: AuthRepository(ApiClient(tokenStorage: TokenStorage())),
        tokens: TokenStorage(),
      ) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: AppUser(
        id: '1',
        fullName: 'عميل الضيافة',
        phone: '+966512345678',
      ),
    );
  }
}

/// The fakes never touch the repositories, so the controllers only need a [Ref]
/// shaped object to satisfy their constructors.
class _DeadRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the fake cart must not hit the network');
}
