import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:docflow/core/utils/result.dart';
import 'package:docflow/domain/entities/template.dart';
import 'package:docflow/presentation/providers/template_provider.dart';
import 'package:docflow/presentation/widgets/filter_panel.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:docflow/generated/app_localizations.dart';

import '../template_provider_test.mocks.dart';

Widget buildTestApp({
  required TemplateProvider provider,
  FocusNode? searchFocusNode,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<TemplateProvider>.value(
      value: provider,
      child: Scaffold(
        body: SizedBox(
          width: 300,
          height: 600,
          child: FilterPanel(searchFocusNode: searchFocusNode),
        ),
      ),
    ),
  );
}

void main() {
  late MockTemplateRepository mockRepository;
  late TemplateProvider provider;

  void stubWith({List<String> tags = const [], List<Template> templates = const []}) {
    when(mockRepository.ensureInitialized())
        .thenAnswer((_) async => Result.success(null));
    when(mockRepository.getAllTags())
        .thenAnswer((_) async => Result.success(tags));
    when(mockRepository.getTemplates(
      limit: anyNamed('limit'),
      offset: anyNamed('offset'),
      tags: anyNamed('tags'),
      searchQuery: anyNamed('searchQuery'),
    )).thenAnswer((_) async => Result.success(templates));
  }

  setUp(() {
    mockRepository = MockTemplateRepository();
    provider = TemplateProvider(mockRepository);
  });

  group('FilterPanel', () {
    testWidgets('renderiza campo de busca', (tester) async {
      stubWith();
      await provider.initialize();

      await tester.pumpWidget(buildTestApp(provider: provider));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('exibe mensagem de "nenhuma tag" quando lista está vazia', (tester) async {
      stubWith(tags: []);
      await provider.initialize();

      await tester.pumpWidget(buildTestApp(provider: provider));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('exibe CheckboxListTile para cada tag', (tester) async {
      stubWith(tags: ['dart', 'flutter', 'mobile']);
      await provider.initialize();

      await tester.pumpWidget(buildTestApp(provider: provider));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(find.text('dart'), findsOneWidget);
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('tap em checkbox atualiza selectedTags no provider', (tester) async {
      stubWith(tags: ['dart']);
      await provider.initialize();

      await tester.pumpWidget(buildTestApp(provider: provider));
      await tester.pumpAndSettle();

      // Tap no checkbox da tag 'dart'
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      expect(provider.selectedTags['dart'], isTrue);
    });

    testWidgets('campos de busca dispara search no provider', (tester) async {
      stubWith(tags: []);
      await provider.initialize();

      await tester.pumpWidget(buildTestApp(provider: provider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'contrato');
      await tester.pumpAndSettle();

      // Verifica que getTemplates foi chamado com a query correta
      final captured = verify(mockRepository.getTemplates(
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
        tags: anyNamed('tags'),
        searchQuery: captureAnyNamed('searchQuery'),
      )).captured;

      expect(captured, contains('contrato'));
    });
  });
}
