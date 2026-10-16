import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitto_app/app/app.dart';
import 'package:vitto_app/app/routes.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: VittoApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('home renders in English on phone width', (tester) async {
    await pumpApp(tester, const Size(320, 700));
    expect(find.text('Buy and sell in Nigeria and Benin'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching to French translates the UI', (tester) async {
    await pumpApp(tester, const Size(1280, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Achetez et vendez au Nigeria et au Bénin'),
      findsOneWidget,
    );
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('protected routes redirect to sign-in when signed out', (
    tester,
  ) async {
    await pumpApp(tester, const Size(1280, 800));
    await tester.tap(find.text('Sell'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Create Listing'), findsNothing);
  });

  test('public route classification', () {
    expect(Routes.isPublic('/'), isTrue);
    expect(Routes.isPublic('/l/abc'), isTrue);
    expect(Routes.isPublic('/u/abc'), isTrue);
    expect(Routes.isPublic('/l/abc/edit'), isFalse);
    expect(Routes.isPublic('/sell'), isFalse);
    expect(Routes.isPublic('/deals/1'), isFalse);
    expect(Routes.isPublic('/admin'), isFalse);
  });
}
