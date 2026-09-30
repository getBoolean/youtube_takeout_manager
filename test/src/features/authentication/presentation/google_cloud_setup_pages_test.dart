import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/oauth_client_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/oauth_client.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_cloud_client_form.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_cloud_setup_pages.dart';

const _id = '123-abc.apps.googleusercontent.com';
const _secret = 'GOCSPX-abc';
const _firstPage = ValueKey('first-page');

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  /// A modal whose first page opens setup, from the start or [change]ing
  /// the client, followed by the setup pages.
  Future<void> open(
    WidgetTester tester, {
    bool web = false,
    bool change = false,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => WoltModalSheet.show<void>(
                  context: context,
                  pageListBuilder: (_) => [
                    WoltModalSheetPage(
                      child: Builder(
                        builder: (context) => TextButton(
                          key: _firstPage,
                          onPressed: () =>
                              showGoogleCloudSetup(context, change: change),
                          child: const Text('Set up'),
                        ),
                      ),
                    ),
                    ...GoogleCloudSetupPages.build(
                      web: web,
                      origin: web ? 'http://localhost:9000' : null,
                    ),
                  ],
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_firstPage));
    await tester.pumpAndSettle();
  }

  Finder field(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byType(TextField));

  bool hasError(WidgetTester tester, Key key) =>
      tester.widget<TextField>(field(key)).decoration?.errorText != null;

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(GoogleCloudSetupPages.nextKey));
    await tester.pumpAndSettle();
  }

  Future<void> goToPasteStep(WidgetTester tester) async {
    while (find.byKey(GoogleCloudSetupPages.nextKey).evaluate().isNotEmpty) {
      await next(tester);
    }
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(GoogleCloudClientForm.saveKey));
    await tester.pumpAndSettle();
  }

  Future<OAuthClient?> savedClient() =>
      container.read(oauthClientRepositoryProvider).load();

  testWidgets('each step shows further progress, to done on the last', (
    tester,
  ) async {
    await open(tester);

    double progress() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;
    final seen = [progress()];
    while (find.byKey(GoogleCloudSetupPages.nextKey).evaluate().isNotEmpty) {
      await next(tester);
      seen.add(progress());
    }

    expect(seen, hasLength(greaterThan(1)));
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], greaterThan(seen[i - 1]));
    }
    expect(seen.last, 1);
  });

  testWidgets('a pasted client is saved, and it goes back to where setup '
      'was opened', (tester) async {
    await open(tester);
    await goToPasteStep(tester);

    await tester.enterText(field(GoogleCloudClientForm.idFieldKey), ' $_id ');
    await tester.enterText(
      field(GoogleCloudClientForm.secretFieldKey),
      '$_secret\n',
    );
    await save(tester);

    expect(find.byKey(_firstPage), findsOneWidget);
    expect(await savedClient(), const OAuthClient(id: _id, secret: _secret));
  });

  testWidgets(
    "something that isn't a client ID is refused where it was pasted",
    (tester) async {
      await open(tester);
      await goToPasteStep(tester);

      await tester.enterText(field(GoogleCloudClientForm.idFieldKey), _secret);
      await tester.enterText(
        field(GoogleCloudClientForm.secretFieldKey),
        _secret,
      );
      await save(tester);

      expect(hasError(tester, GoogleCloudClientForm.idFieldKey), isTrue);
      expect(hasError(tester, GoogleCloudClientForm.secretFieldKey), isFalse);
      expect(
        tester
            .widget<TextField>(field(GoogleCloudClientForm.idFieldKey))
            .focusNode
            ?.hasFocus,
        isTrue,
      );
      expect(find.byKey(_firstPage), findsNothing);
      expect(await savedClient(), isNull);
    },
  );

  testWidgets('a desktop client needs its secret', (tester) async {
    await open(tester);
    await goToPasteStep(tester);

    await tester.enterText(field(GoogleCloudClientForm.idFieldKey), _id);
    await save(tester);

    expect(hasError(tester, GoogleCloudClientForm.secretFieldKey), isTrue);
    expect(await savedClient(), isNull);
  });

  testWidgets('the secret can be shown and hidden', (tester) async {
    await open(tester);
    await goToPasteStep(tester);
    bool obscured() => tester
        .widget<TextField>(field(GoogleCloudClientForm.secretFieldKey))
        .obscureText;

    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('Show secret'));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.byTooltip('Hide secret'));
    await tester.pump();
    expect(obscured(), isTrue);
  });

  testWidgets("on web there's no secret, and the origin to add can be "
      'copied', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await open(tester, web: true);

    while (find.byKey(GoogleCloudSetupPages.copyOriginKey).evaluate().isEmpty) {
      await next(tester);
    }
    expect(find.text('http://localhost:9000'), findsOneWidget);
    await tester.tap(find.byKey(GoogleCloudSetupPages.copyOriginKey));
    await tester.pump();
    expect(copied, 'http://localhost:9000');

    await goToPasteStep(tester);
    expect(find.byKey(GoogleCloudClientForm.secretFieldKey), findsNothing);
    await tester.enterText(field(GoogleCloudClientForm.idFieldKey), _id);
    await save(tester);

    expect(find.byKey(_firstPage), findsOneWidget);
    expect(await savedClient(), const OAuthClient(id: _id));
  });

  testWidgets('changing a client opens on it, ready to edit', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.oauth_client': const OAuthClient(
        id: _id,
        secret: _secret,
      ).toJson(),
    });
    await open(tester, change: true);

    expect(
      tester
          .widget<TextField>(field(GoogleCloudClientForm.idFieldKey))
          .controller
          ?.text,
      _id,
    );
  });

  testWidgets('Back from the first step, or Cancel, returns without saving', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(_firstPage), findsOneWidget);

    await tester.tap(find.byKey(_firstPage));
    await tester.pumpAndSettle();
    await goToPasteStep(tester);
    await tester.enterText(field(GoogleCloudClientForm.idFieldKey), _id);
    await tester.tap(find.byKey(GoogleCloudSetupPages.cancelKey));
    await tester.pumpAndSettle();

    expect(find.byKey(_firstPage), findsOneWidget);
    expect(await savedClient(), isNull);
  });
}
