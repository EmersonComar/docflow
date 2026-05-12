import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:docflow/core/utils/result.dart';
import 'package:docflow/domain/entities/template.dart';
import 'package:docflow/presentation/providers/template_provider.dart';
import 'package:docflow/presentation/widgets/add_template_dialog.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:docflow/generated/app_localizations.dart';

import '../template_provider_test.mocks.dart';

/// Constrói um app mínimo com o dialog já exibido via showDialog.
Future<void> pumpDialog(
  WidgetTester tester,
  TemplateProvider provider, {
  Template? template,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<TemplateProvider>.value(
        value: provider,
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ChangeNotifierProvider<TemplateProvider>.value(
                  value: provider,
                  child: AddTemplateDialog(template: template),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  late MockTemplateRepository mockRepository;
  late TemplateProvider provider;

  void stubSuccess() {
    when(mockRepository.ensureInitialized())
        .thenAnswer((_) async => Result.success(null));
    when(mockRepository.getAllTags())
        .thenAnswer((_) async => Result.success([]));
    when(mockRepository.getTemplates(
      limit: anyNamed('limit'),
      offset: anyNamed('offset'),
      tags: anyNamed('tags'),
      searchQuery: anyNamed('searchQuery'),
    )).thenAnswer((_) async => Result.success([]));
    when(mockRepository.create(any))
        .thenAnswer((_) async => Result.success(const Template(
              id: 1,
              titulo: 'Novo Template',
              conteudo: 'Conteúdo',
              tags: [],
            )));
    when(mockRepository.update(any))
        .thenAnswer((_) async => Result.success(const Template(
              id: 1,
              titulo: 'Atualizado',
              conteudo: 'Conteúdo',
              tags: [],
            )));
  }

  setUp(() {
    mockRepository = MockTemplateRepository();
    provider = TemplateProvider(mockRepository);
    stubSuccess();
  });

  group('AddTemplateDialog', () {
    testWidgets('abre o dialog de novo template corretamente', (tester) async {
      await pumpDialog(tester, provider);

      // O título do dialog deve conter a chave de localização de "novo template"
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('exibe campos de título, conteúdo e tags', (tester) async {
      await pumpDialog(tester, provider);

      // Deve haver pelo menos 3 TextFormFields (titulo, conteudo, tags)
      expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
    });

    testWidgets('botão Cancelar fecha o dialog', (tester) async {
      await pumpDialog(tester, provider);

      expect(find.byType(AlertDialog), findsOneWidget);

      // Toca o botão de cancelar pelo ícone
      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('salvar sem título não dispara create (validação de formulário)', (tester) async {
      await pumpDialog(tester, provider);

      // Não preenche o título, mas preenche conteúdo
      await tester.enterText(
        find.byType(TextFormField).at(1), // campo conteúdo
        'Algum conteúdo',
      );
      await tester.pumpAndSettle();

      // Toca o botão Salvar
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // create não deve ter sido chamado
      verifyNever(mockRepository.create(any));
      // Dialog ainda deve estar aberto (formulário inválido)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('preencher título e conteúdo e salvar chama create', (tester) async {
      await pumpDialog(tester, provider);

      await tester.enterText(
        find.byType(TextFormField).first, // campo título
        'Meu Novo Template',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1), // campo conteúdo
        'Conteúdo do template',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      verify(mockRepository.create(any)).called(1);
    });

    testWidgets('pré-preenche campos ao editar um template existente', (tester) async {
      const existing = Template(
        id: 5,
        titulo: 'Template Existente',
        conteudo: 'Conteúdo existente',
        tags: ['dart'],
        markdownEnabled: true,
        snippetsEnabled: false,
      );

      await pumpDialog(tester, provider, template: existing);

      expect(find.widgetWithText(TextFormField, 'Template Existente'), findsOneWidget);
    });

    testWidgets('ao editar, salvar chama update em vez de create', (tester) async {
      const existing = Template(
        id: 5,
        titulo: 'Template Existente',
        conteudo: 'Conteúdo existente',
        tags: [],
      );

      await pumpDialog(tester, provider, template: existing);

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      verify(mockRepository.update(any)).called(1);
      verifyNever(mockRepository.create(any));
    });
  });
}
