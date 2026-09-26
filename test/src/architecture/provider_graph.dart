import 'dart:collection';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// How a provider uses another through its `ref`.
enum EdgeKind {
  watch,
  listen,
  read,
  invalidate,
  refresh;

  /// Makes the provider depend on the other, so it's a dependent of it.
  bool get depends => this == watch || this == listen;

  /// Riverpod checks, in debug, that the other doesn't depend on the
  /// provider doing this, and throws `CircularDependencyError` if it does.
  bool get checked => this != watch;
}

class Edge {
  final String from;
  final String to;
  final EdgeKind kind;
  final String file;
  final int line;

  const Edge(this.from, this.to, this.kind, this.file, this.line);

  String get where => '$file:$line';

  @override
  String toString() => '$from ${kind.name}s $to ($where)';
}

class ProviderInfo {
  final String name;
  final String file;
  final bool keepAlive;

  const ProviderInfo(this.name, this.file, {required this.keepAlive});

  /// Repositories live under a `data` folder or in `lib/src/storage`.
  bool get isRepository =>
      file.contains('/data/') || file.contains('lib/src/storage/');
}

/// Every provider in the app and how they use each other through `ref`,
/// read from source, so every code path counts, not only the ones a test
/// happens to run.
class ProviderGraph {
  final Map<String, ProviderInfo> providers;
  final List<Edge> edges;

  /// Problems reading the source: `ref` uses that can't be followed.
  final List<String> problems;

  ProviderGraph._(this.providers, this.edges, this.problems);

  /// Builds the graph from Dart sources by path, generated `.g.dart` files
  /// included (they name the providers).
  factory ProviderGraph.fromSources(Map<String, String> sources) {
    final builder = _Builder(sources);
    builder.build();
    return ProviderGraph._(builder.providers, builder.edges, builder.problems);
  }

  late final Map<String, Set<String>> _dependencies = () {
    final map = <String, Set<String>>{};
    for (final e in edges) {
      if (e.kind.depends && e.from != e.to) {
        (map[e.from] ??= {}).add(e.to);
      }
    }
    return map;
  }();

  /// Providers that watch or listen to [name], other than [except].
  Set<String> dependentsOf(String name, {Set<String> except = const {}}) => {
    for (final e in edges)
      if (e.kind.depends &&
          e.to == name &&
          e.from != name &&
          !except.contains(e.from))
        e.from,
  };

  /// The chain of watches and listens from [from] to [to], or null if
  /// [from] doesn't depend on [to].
  List<String>? dependencyPath(String from, String to) {
    final previous = <String, String>{};
    final queue = Queue<String>()..add(from);
    final seen = {from};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final next in _dependencies[current] ?? const <String>{}) {
        if (!seen.add(next)) continue;
        previous[next] = current;
        if (next == to) {
          final path = [to];
          var step = to;
          while (step != from) {
            step = previous[step]!;
            path.add(step);
          }
          return path.reversed.toList();
        }
        queue.add(next);
      }
    }
    return null;
  }

  /// A cycle of watches and listens, or null if there's none.
  List<String>? findCycle() {
    for (final name in _dependencies.keys) {
      for (final next in _dependencies[name]!) {
        if (dependencyPath(next, name) case final path?) return [name, ...path];
      }
    }
    return null;
  }
}

class _Builder {
  final Map<String, String> sources;
  final providers = <String, ProviderInfo>{};
  final edges = <Edge>[];
  final problems = <String>[];

  /// Provider names by the library they're declared in and the name of the
  /// declaration they're generated for.
  final _generated = <String, Map<String, String>>{};

  _Builder(this.sources);

  static final _providerFor = RegExp(
    r'@ProviderFor\((\w+)\)\s*final\s+(\w+)\s*=',
  );

  void build() {
    for (final MapEntry(key: path, value: source) in sources.entries) {
      if (!path.endsWith('.g.dart')) continue;
      final library = path.replaceFirst(RegExp(r'\.g\.dart$'), '.dart');
      for (final match in _providerFor.allMatches(source)) {
        (_generated[library] ??= {})[match.group(1)!] = match.group(2)!;
      }
    }

    final units = <String, (CompilationUnit, LineInfo)>{};
    for (final MapEntry(key: path, value: source) in sources.entries) {
      if (path.endsWith('.g.dart') || path.endsWith('.mapper.dart')) continue;
      if (path.endsWith('.gr.dart')) continue;
      final result = parseString(content: source, throwIfDiagnostics: false);
      units[path] = (result.unit, result.lineInfo);
    }

    // Declarations first, so references in any file resolve.
    final bodies = <(String, String, AstNode, LineInfo, bool)>[];
    for (final MapEntry(key: path, value: (unit, lines)) in units.entries) {
      for (final declaration in unit.declarations) {
        if (_declare(path, declaration) case (final name, final body)) {
          bodies.add((
            name,
            path,
            body,
            lines,
            declaration is ClassDeclaration,
          ));
        }
      }
    }

    for (final (name, path, body, lines, isClass) in bodies) {
      body.accept(_RefVisitor(this, name, path, lines, isClass: isClass));
    }
    for (final MapEntry(key: path, value: (unit, lines)) in units.entries) {
      unit.accept(_EscapedRefVisitor(this, path, lines, bodies));
    }
  }

  /// Registers [declaration] if it declares a provider, returning its name
  /// and the code that makes up the provider.
  (String, AstNode)? _declare(String path, CompilationUnitMember declaration) {
    switch (declaration) {
      case FunctionDeclaration(:final metadata, name: final token) ||
              ClassDeclaration(:final metadata, name: final token)
          when _riverpod(metadata) != null:
        final name = _generated[path]?[token.lexeme];
        if (name == null) {
          problems.add(
            '$path: no generated provider for ${token.lexeme}; run '
            'build_runner',
          );
          return null;
        }
        providers[name] = ProviderInfo(
          name,
          path,
          keepAlive: _keepAlive(_riverpod(metadata)!),
        );
        return (name, declaration);
      case TopLevelVariableDeclaration(:final variables):
        for (final variable in variables.variables) {
          final name = variable.name.lexeme;
          final initializer = variable.initializer;
          if (!name.endsWith('Provider') || initializer == null) continue;
          final body = _handWrittenBody(path, initializer);
          if (body == null) {
            problems.add('$path: unsupported provider declaration $name');
            continue;
          }
          providers[name] = ProviderInfo(
            name,
            path,
            keepAlive: !initializer.toSource().contains('autoDispose'),
          );
          return (name, body);
        }
    }
    return null;
  }

  /// The class or function a hand-written `xProvider = SomeProvider(...)`
  /// builds from.
  AstNode? _handWrittenBody(String path, Expression initializer) {
    final arguments = switch (initializer) {
      InstanceCreationExpression(:final argumentList) => argumentList,
      MethodInvocation(:final argumentList) => argumentList,
      _ => null,
    };
    final first = arguments?.arguments.firstOrNull;
    switch (first) {
      case FunctionExpression():
        return first;
      case ConstructorReference(:final constructorName):
        return _classNamed(path, constructorName.type.name.lexeme);
      case PrefixedIdentifier(:final prefix, :final identifier)
          when identifier.name == 'new':
        return _classNamed(path, prefix.name);
    }
    return null;
  }

  ClassDeclaration? _classNamed(String path, String name) {
    final unit = parseString(
      content: sources[path]!,
      throwIfDiagnostics: false,
    ).unit;
    return unit.declarations
        .whereType<ClassDeclaration>()
        .where((c) => c.name.lexeme == name)
        .firstOrNull;
  }

  static Annotation? _riverpod(NodeList<Annotation> metadata) =>
      metadata.where((a) {
        final name = a.name.name;
        return name == 'riverpod' || name == 'Riverpod';
      }).firstOrNull;

  static bool _keepAlive(Annotation annotation) =>
      annotation.arguments?.arguments.any(
        (a) =>
            a is NamedExpression &&
            a.name.label.name == 'keepAlive' &&
            a.expression is BooleanLiteral &&
            (a.expression as BooleanLiteral).value,
      ) ??
      false;

  /// The provider [expression] is, looking through `.notifier`, `.future`,
  /// `.stream`, `.select(...)`, family arguments and import prefixes.
  String? resolve(String path, Expression expression) {
    switch (expression) {
      case ParenthesizedExpression(:final expression):
        return resolve(path, expression);
      case SimpleIdentifier(:final name):
        return _provider(path, name);
      case PrefixedIdentifier(:final prefix, :final identifier):
        if (_accessors.contains(identifier.name)) {
          return resolve(path, prefix);
        }
        return _provider(path, identifier.name);
      case PropertyAccess(:final target?, :final propertyName)
          when _accessors.contains(propertyName.name):
        return resolve(path, target);
      case MethodInvocation(:final target?, :final methodName)
          when methodName.name == 'select' || methodName.name == 'selectAsync':
        return resolve(path, target);
      case MethodInvocation(target: null, :final methodName):
        // A family, whatever it's called with.
        return _provider(path, methodName.name);
    }
    return null;
  }

  static const _accessors = {'notifier', 'future', 'stream'};

  String? _provider(String path, String name) {
    if (!name.endsWith('Provider')) return null;
    if (name.startsWith('_')) {
      // Private providers only resolve within their own library.
      final own = _generated[path]?.values.contains(name) ?? false;
      return own ? name : null;
    }
    return providers.containsKey(name) ? name : null;
  }
}

/// Collects the `ref.watch`, `listen`, `read`, `invalidate` and `refresh`
/// calls in a provider's code.
class _RefVisitor extends RecursiveAstVisitor<void> {
  final _Builder builder;
  final String provider;
  final String path;
  final LineInfo lines;
  final bool isClass;

  String? _method;

  _RefVisitor(
    this.builder,
    this.provider,
    this.path,
    this.lines, {
    required this.isClass,
  });

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final outer = _method;
    _method = node.name.lexeme;
    super.visitMethodDeclaration(node);
    _method = outer;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final kind = EdgeKind.values
        .where((k) => k.name == node.methodName.name)
        .firstOrNull;
    if (target is SimpleIdentifier && target.name == 'ref' && kind != null) {
      final line = lines.getLocation(node.offset).lineNumber;
      final argument = node.argumentList.arguments.firstOrNull;
      final to = argument == null ? null : builder.resolve(path, argument);
      if (to == null) {
        builder.problems.add(
          '$path:$line: $provider ${kind.name}s '
          '${argument?.toSource() ?? 'nothing'}, which isn\'t a provider '
          'the graph can follow; use a provider name directly',
        );
      } else {
        if (kind == EdgeKind.watch && isClass && _method != 'build') {
          builder.problems.add(
            '$path:$line: $provider watches $to outside build; use '
            'ref.read in methods',
          );
        }
        builder.edges.add(Edge(provider, to, kind, path, line));
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'ref' && !_usedAsTarget(node) && !_declares(node)) {
      final line = lines.getLocation(node.offset).lineNumber;
      builder.problems.add(
        '$path:$line: $provider hands its ref on (${node.parent?.toSource()}); '
        "the graph can't follow what's done with it there",
      );
    }
    super.visitSimpleIdentifier(node);
  }

  static bool _usedAsTarget(SimpleIdentifier node) => switch (node.parent) {
    MethodInvocation(:final target) => identical(target, node),
    PrefixedIdentifier(:final prefix) => identical(prefix, node),
    PropertyAccess(:final target) => identical(target, node),
    _ => false,
  };

  static bool _declares(SimpleIdentifier node) =>
      node.parent is FormalParameter || node.parent is NamedType;
}

/// Flags `Ref` parameters, fields and variables outside provider
/// declarations: helpers given a provider's ref would hide what it uses.
class _EscapedRefVisitor extends RecursiveAstVisitor<void> {
  final _Builder builder;
  final String path;
  final LineInfo lines;
  final Set<AstNode> _providerBodies;

  _EscapedRefVisitor(
    this.builder,
    this.path,
    this.lines,
    List<(String, String, AstNode, LineInfo, bool)> bodies,
  ) : _providerBodies = {
        for (final (_, p, body, _, _) in bodies)
          if (p == path) body,
      };

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme == 'Ref' && node.importPrefix == null) {
      final inProvider = _providerBodies.any(
        (body) => node.offset >= body.offset && node.end <= body.end,
      );
      // A provider function's own `Ref ref` parameter is fine.
      if (!inProvider) {
        final line = lines.getLocation(node.offset).lineNumber;
        builder.problems.add(
          '$path:$line: a Ref outside a provider '
          '(${node.parent?.toSource()}); read what it needs in the provider '
          'and pass the values instead',
        );
      }
    }
    super.visitNamedType(node);
  }
}
