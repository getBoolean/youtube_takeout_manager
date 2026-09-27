import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'provider_graph.dart';

/// Starts the app's background work. It listens to each effect and nothing
/// depends on it, so it doesn't make them stores.
const _effectsHost = 'appEffectsProvider';

/// Services that read stores but are autoDispose: each belongs to one
/// widget or screen, and checks `ref.mounted` after every await.
const _autoDisposeServices = {
  'addAccountImportProvider',
  'selectionModeProvider',
  'signInNoticesProvider',
};

/// Breaks [graph]'s rules, one message per problem.
List<String> violations(ProviderGraph graph) {
  final found = <String>[...graph.problems];

  if (graph.findCycle() case final cycle?) {
    found.add('Providers depend on each other in a loop: ${cycle.join(' → ')}');
  }

  // Exactly what Riverpod checks in debug on every read, listen,
  // invalidate and refresh.
  for (final edge in graph.edges.where((e) => e.kind.checked)) {
    if (edge.from == edge.to) continue;
    if (graph.dependencyPath(edge.to, edge.from) case final path?) {
      found.add(
        '${edge.from} ${edge.kind.name}s ${edge.to} (${edge.where}), but '
        '${path.join(' → ')}: CircularDependencyError',
      );
    }
  }

  for (final provider in graph.providers.values) {
    final name = provider.name;
    final uses = graph.edges.where((e) => e.from == name);
    final dependents = graph.dependentsOf(name, except: {_effectsHost});

    if (provider.isRepository) {
      for (final edge in uses) {
        if (graph.providers[edge.to]?.isRepository ?? false) continue;
        found.add(
          '${edge.from} is a repository but ${edge.kind.name}s ${edge.to} '
          '(${edge.where}); repositories only use other repositories',
        );
      }
      continue;
    }

    if (name == _effectsHost) {
      if (graph.dependentsOf(name).isNotEmpty) {
        found.add('$_effectsHost must not be watched by other providers');
      }
      for (final edge in uses.where((e) => e.kind != EdgeKind.listen)) {
        found.add(
          '$_effectsHost ${edge.kind.name}s ${edge.to} (${edge.where}); it '
          'only listens, to start each effect',
        );
      }
      continue;
    }

    final nonRepositoryReads = [
      for (final edge in uses.where((e) => e.kind.checked))
        if (!(graph.providers[edge.to]?.isRepository ?? false)) edge,
    ];
    if (dependents.isNotEmpty) {
      // A store or derived provider: others depend on it, so anything it
      // reads that depends back on them throws.
      if (nonRepositoryReads.isEmpty) continue;
      final edge = nonRepositoryReads.first;
      found.add(
        '$name ${edge.kind.name}s ${edge.to} (${edge.where}) while '
        '${dependents.join(', ')} depend on it. Providers others depend on '
        'may only read repositories: move the read into a service, a '
        'provider nothing watches or listens to.',
      );
    } else if (nonRepositoryReads.isNotEmpty &&
        !provider.keepAlive &&
        !_autoDisposeServices.contains(name)) {
      found.add(
        '$name is a service that reads ${nonRepositoryReads.first.to} '
        '(${nonRepositoryReads.first.where}) but is autoDispose; make it '
        'keepAlive so it outlives its awaits',
      );
    }
  }
  return found;
}

Map<String, String> _libSources() => {
  for (final file in Directory('lib').listSync(recursive: true))
    if (file is File && file.path.endsWith('.dart'))
      file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
};

void main() {
  test("the app's providers can't depend on themselves", () {
    final graph = ProviderGraph.fromSources(_libSources());

    expect(graph.providers, isNotEmpty);
    expect(violations(graph), isEmpty);
  });

  group('the guard', () {
    String generated(Map<String, String> names) => [
      for (final MapEntry(key: declaration, value: provider) in names.entries)
        '@ProviderFor($declaration)\nfinal $provider = X._();',
    ].join('\n');

    ProviderGraph graph(Map<String, String> sources) =>
        ProviderGraph.fromSources(sources);

    test('catches a read of something that depends on the reader', () {
      final found = violations(
        graph({
          'lib/a/application/session.dart': '''
@Riverpod(keepAlive: true)
String? session(Ref ref) => ref.watch(picturesProvider).keys.first;
''',
          'lib/a/application/session.g.dart': generated({
            'session': 'sessionProvider',
          }),
          'lib/a/application/pictures.dart': '''
@Riverpod(keepAlive: true)
class Pictures extends _\$Pictures {
  @override
  Map<String, String> build() => {};

  void fetch() {
    final id = ref.read(sessionProvider);
  }
}
''',
          'lib/a/application/pictures.g.dart': generated({
            'Pictures': 'picturesProvider',
          }),
        }),
      );

      expect(
        found,
        contains(
          allOf(
            contains('picturesProvider reads sessionProvider'),
            contains('sessionProvider → picturesProvider'),
            contains('CircularDependencyError'),
          ),
        ),
      );
    });

    test('flags a store reading more than repositories', () {
      final found = violations(
        graph({
          'lib/a/application/store.dart': '''
@riverpod
int store(Ref ref) => ref.read(otherProvider);

@riverpod
int other(Ref ref) => 1;

@riverpod
int view(Ref ref) => ref.watch(storeProvider);
''',
          'lib/a/application/store.g.dart': generated({
            'store': 'storeProvider',
            'other': 'otherProvider',
            'view': 'viewProvider',
          }),
        }),
      );

      expect(found, contains(contains('storeProvider reads otherProvider')));
    });

    test('lets a service read anything', () {
      final found = violations(
        graph({
          'lib/a/data/repo.dart': '''
@Riverpod(keepAlive: true)
int repo(Ref ref) => 1;
''',
          'lib/a/data/repo.g.dart': generated({'repo': 'repoProvider'}),
          'lib/a/application/store.dart': '''
@Riverpod(keepAlive: true)
class Store extends _\$Store {
  @override
  int build() => ref.read(repoProvider);
}

@Riverpod(keepAlive: true)
int view(Ref ref) => ref.watch(storeProvider);

@Riverpod(keepAlive: true)
class Service extends _\$Service {
  @override
  void build() {}

  void run() {
    ref.read(viewProvider);
    ref.read(storeProvider.notifier);
  }
}
''',
          'lib/a/application/store.g.dart': generated({
            'Store': 'storeProvider',
            'view': 'viewProvider',
            'Service': 'serviceProvider',
          }),
        }),
      );

      expect(found, isEmpty);
    });

    test('follows notifier, future, select and family access', () {
      final g = graph({
        'lib/a/application/p.dart': '''
@riverpod
class Counter extends _\$Counter {
  @override
  Future<int> build() async => 0;
}

@riverpod
int item(Ref ref, int id) => id;

@riverpod
int user(Ref ref) {
  ref.watch(counterProvider.notifier);
  ref.watch(counterProvider.future);
  ref.watch(counterProvider.select((c) => c));
  ref.watch(itemProvider(1).select((i) => i));
  return ref.watch(itemProvider(2));
}
''',
        'lib/a/application/p.g.dart': generated({
          'Counter': 'counterProvider',
          'item': 'itemProvider',
          'user': 'userProvider',
        }),
      });

      expect(g.problems, isEmpty);
      expect(
        {for (final e in g.edges) e.to},
        {'counterProvider', 'itemProvider'},
      );
    });

    test("flags ref uses it can't follow", () {
      final g = graph({
        'lib/a/application/p.dart': '''
@riverpod
int user(Ref ref) {
  final p = otherProvider;
  helper(ref);
  return ref.watch(p);
}

@riverpod
int other(Ref ref) => 1;

int helper(Ref ref) => ref.read(otherProvider);
''',
        'lib/a/application/p.g.dart': generated({
          'user': 'userProvider',
          'other': 'otherProvider',
        }),
      });

      expect(g.problems, contains(contains("isn't a provider")));
      expect(g.problems, contains(contains('hands its ref on')));
      expect(g.problems, contains(contains('a Ref outside a provider')));
    });
  });
}
