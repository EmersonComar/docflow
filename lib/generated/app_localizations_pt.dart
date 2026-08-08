// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'DocFlow';

  @override
  String get newsTitle => 'Novidades';

  @override
  String get filters => 'Filtros';

  @override
  String get search => 'Buscar';

  @override
  String get tags => 'Tags';

  @override
  String get noTagsFound => 'Nenhuma tag encontrada.';

  @override
  String get copyCodeSnack => 'Código copiado!';

  @override
  String get copyCodeTooltip => 'Copiar código';

  @override
  String get editTemplate => 'Editar Template';

  @override
  String get newTemplate => 'Novo Template';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get titleLabel => 'Título';

  @override
  String get contentLabel => 'Conteúdo';

  @override
  String get pleaseInsertTitle => 'Por favor, insira um título';

  @override
  String get pleaseInsertContent => 'Por favor, insira o conteúdo';

  @override
  String get tagsLabel => 'Tags (separadas por vírgula)';

  @override
  String get importMarkdown => 'Importar markdown';

  @override
  String get importMarkdownError =>
      'Falha ao ler o arquivo markdown. Por favor, verifique se é um arquivo UTF-8 válido.';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get noTemplatesFound => 'Nenhum template encontrado.';

  @override
  String get confirmDeleteTitle => 'Confirmar Exclusão';

  @override
  String confirmDeleteContent(String title) {
    return 'Você tem certeza que deseja deletar o template \"$title\"?';
  }

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get delete => 'Deletar';

  @override
  String get contentCopied => 'Conteúdo copiado!';

  @override
  String get copy => 'Copiar';

  @override
  String get changeTheme => 'Alterar Tema';

  @override
  String get newTemplateFab => 'Novo Template';

  @override
  String unexpectedError(String error) {
    return 'Erro inesperado: $error';
  }

  @override
  String loadMoreFailed(String error) {
    return 'Falha ao carregar mais templates: $error';
  }

  @override
  String databaseInitializationFailed(String error) {
    return 'Falha ao inicializar banco de dados: $error';
  }

  @override
  String createTemplateFailed(String error) {
    return 'Falha ao criar template: $error';
  }

  @override
  String get templateIdCannotBeNull => 'ID do template não pode ser nulo';

  @override
  String updateTemplateFailed(String error) {
    return 'Falha ao atualizar template: $error';
  }

  @override
  String deleteTemplateFailed(String error) {
    return 'Falha ao deletar template: $error';
  }

  @override
  String loadTemplatesFailed(String error) {
    return 'Falha ao carregar templates: $error';
  }

  @override
  String loadTagsFailed(String error) {
    return 'Falha ao carregar tags: $error';
  }

  @override
  String get unknownError => 'Ocorreu um erro desconhecido';

  @override
  String get fillVariablesTitle => 'Preencher Variáveis';

  @override
  String get confirmCopy => 'Copiar';

  @override
  String get changeLanguage => 'Idioma';

  @override
  String get enableMarkdown => 'Habilitar Markdown';

  @override
  String get enableSnippets => 'Habilitar Snippets';

  @override
  String get templateSettings => 'Configurações';

  @override
  String get markdownPreview => 'Pré-visualização';

  @override
  String get plainTextPreview => 'Texto simples';

  @override
  String get welcomeTitle => 'Bem-vindo ao DocFlow!';

  @override
  String get welcomeSubtitle =>
      'Seus templates em um único lugar.\nEscolha onde guardar seu arquivo de dados.';

  @override
  String get createNewDatabase => 'Criar novo arquivo';

  @override
  String get openExistingDatabase => 'Abrir arquivo existente';

  @override
  String get openAnotherFile => 'Abrir outro arquivo';

  @override
  String currentFile(String name) {
    return 'Arquivo: $name';
  }

  @override
  String get databaseNotFound => 'Arquivo não encontrado. Escolha outro.';

  @override
  String get selectSaveLocation => 'Escolher local para salvar';

  @override
  String get selectDatabaseFile => 'Selecionar arquivo de banco de dados';

  @override
  String get invalidDatabaseFile =>
      'O arquivo selecionado não é um banco de dados válido.';

  @override
  String get postgresConnectionTitle => 'Conexão PostgreSQL';

  @override
  String get postgresConnectionSubtitle =>
      'Conecte-se a um banco de dados PostgreSQL externo';

  @override
  String get serverIpLabel => 'IP do Servidor / Hostname';

  @override
  String get portLabel => 'Porta';

  @override
  String get databaseLabel => 'Banco de Dados';

  @override
  String get usernameLabel => 'Usuário';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get connectButton => 'Conectar';

  @override
  String get connecting => 'Conectando...';

  @override
  String get allFieldsRequired => 'Todos os campos são obrigatórios';

  @override
  String get invalidPort => 'Porta inválida (1-65535)';

  @override
  String connectionError(String error) {
    return 'Erro ao conectar: $error';
  }

  @override
  String get aboutTitle => 'Sobre o DocFlow';

  @override
  String appVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get supportLabel => 'Sugestões ou Bugs (GitHub)';

  @override
  String get settingsMenu => 'Configurações';

  @override
  String get sslEnabled => 'Habilitar SSL';

  @override
  String get selfSignedCertToggle => 'Certificado autoassinado';

  @override
  String get selfSignedCertHint =>
      'Necessário quando o servidor usa um certificado que não foi emitido por uma autoridade certificadora pública';

  @override
  String get selectCertificateButton => 'Selecionar certificado (.pem/.crt)';

  @override
  String certificateSelectedLabel(String fileName) {
    return 'Certificado selecionado: $fileName';
  }

  @override
  String get removeCertificateTooltip => 'Remover certificado';

  @override
  String get certificateRequiredError =>
      'Selecione o arquivo de certificado do servidor';

  @override
  String get certificateReadError =>
      'Não foi possível ler o certificado selecionado.';

  @override
  String get certificateInvalidFormat =>
      'O arquivo selecionado não parece ser um certificado PEM válido.';
}
