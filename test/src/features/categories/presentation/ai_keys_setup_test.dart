import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/credential_store.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_keys_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/ai_keys_setup.dart';

/// Keys that can't be saved, as when secure storage fails.
class _Broken extends AiKeysRepository {
  _Broken() : super(CredentialStore(const FlutterSecureStorage()));

  @override
  Future<void> save(AiService service, String key) async =>
      throw Exception('storage is locked');
}

void main() {
  late ProviderContainer container;

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  /// A modal whose first page has the AI keys section, then the AI keys
  /// page, with [build]'s keys built in.
  Future<void> open(
    WidgetTester tester, {
    AiKeys build = AiKeys.none,
    AiKeysRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiKeysRepositoryProvider.overrideWithValue(
            repository ??
                AiKeysRepository(
                  CredentialStore(const FlutterSecureStorage()),
                  build: build,
                ),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => WoltModalSheet.show<void>(
                  context: context,
                  pageListBuilder: (_) => [
                    WoltModalSheetPage(child: const AiKeysSection()),
                    AiKeysPages.page(),
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
  }

  Finder field(AiService service) => find.descendant(
    of: find.byKey(AiKeysForm.fieldKey(service)),
    matching: find.byType(TextField),
  );

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('a key added from the section is saved, and the page goes '
      'back to where it was opened', (tester) async {
    await open(tester);

    await tapKey(tester, AiKeysSection.setUpKey);
    await tester.enterText(field(AiService.claude), 'sk-ant-2');
    await tapKey(tester, AiKeysForm.saveKey);

    expect(container.read(aiKeysProvider).value?.anthropic, 'sk-ant-2');
    expect(find.byKey(AiKeysForm.saveKey), findsNothing);
    expect(find.byKey(AiKeysSection.changeKey), findsOneWidget);
  });

  testWidgets('both keys can be added at once', (tester) async {
    await open(tester);

    await tapKey(tester, AiKeysSection.setUpKey);
    await tester.enterText(field(AiService.jev), 'jv_live_1');
    await tester.enterText(field(AiService.claude), 'sk-ant-2');
    await tapKey(tester, AiKeysForm.saveKey);

    expect(
      container.read(aiKeysProvider).value,
      const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-2'),
    );
  });

  testWidgets('keys are hidden until shown', (tester) async {
    await open(tester);
    await tapKey(tester, AiKeysSection.setUpKey);
    await tester.enterText(field(AiService.claude), 'sk-ant-2');

    bool hidden() =>
        tester.widget<TextField>(field(AiService.claude)).obscureText;
    expect(hidden(), isTrue);

    await tester.tap(
      find.descendant(
        of: find.byKey(AiKeysForm.fieldKey(AiService.claude)),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(hidden(), isFalse);
  });

  testWidgets('cancelling goes back without saving', (tester) async {
    await open(tester);

    await tapKey(tester, AiKeysSection.setUpKey);
    await tester.enterText(field(AiService.claude), 'sk-ant-2');
    await tapKey(tester, AiKeysForm.cancelKey);

    expect(container.read(aiKeysProvider).value?.hasAny, isFalse);
    expect(find.byKey(AiKeysSection.setUpKey), findsOneWidget);
  });

  testWidgets('a saved key shows when changing, and clearing it removes it', (
    tester,
  ) async {
    await open(tester);
    await tapKey(tester, AiKeysSection.setUpKey);
    await tester.enterText(field(AiService.claude), 'sk-ant-2');
    await tapKey(tester, AiKeysForm.saveKey);

    await tapKey(tester, AiKeysSection.changeKey);
    expect(
      tester.widget<TextField>(field(AiService.claude)).controller?.text,
      'sk-ant-2',
    );
    await tester.enterText(field(AiService.claude), '');
    await tapKey(tester, AiKeysForm.saveKey);

    expect(container.read(aiKeysProvider).value?.hasClaude, isFalse);
    expect(find.byKey(AiKeysSection.setUpKey), findsOneWidget);
  });

  testWidgets("a key built into the app has no field to change it", (
    tester,
  ) async {
    await open(tester, build: const AiKeys(typesafe: 'jv_built'));

    await tapKey(tester, AiKeysSection.changeKey);

    expect(find.byKey(AiKeysForm.fieldKey(AiService.jev)), findsNothing);
    expect(find.byKey(AiKeysForm.builtInKey(AiService.jev)), findsOneWidget);
    expect(find.byKey(AiKeysForm.fieldKey(AiService.claude)), findsOneWidget);
  });

  testWidgets('with every key built in, there is nothing to set up', (
    tester,
  ) async {
    await open(
      tester,
      build: const AiKeys(typesafe: 'jv_built', anthropic: 'sk_built'),
    );

    expect(find.byKey(AiKeysSection.setUpKey), findsNothing);
    expect(find.byKey(AiKeysSection.changeKey), findsNothing);
  });

  testWidgets('a save that fails says why on the page, which stays open', (
    tester,
  ) async {
    await open(tester, repository: _Broken());

    await tapKey(tester, AiKeysSection.setUpKey);
    await tester.enterText(field(AiService.claude), 'sk-ant-2');
    await tapKey(tester, AiKeysForm.saveKey);

    expect(
      tester.widget<Text>(find.byKey(AiKeysForm.failureKey)).data,
      contains('storage is locked'),
    );
    expect(find.byKey(AiKeysForm.saveKey), findsOneWidget);
  });
}
