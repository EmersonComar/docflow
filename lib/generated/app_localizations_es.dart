// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'DocFlow';

  @override
  String get newsTitle => 'Novedades';

  @override
  String get filters => 'Filtros';

  @override
  String get search => 'Buscar';

  @override
  String get tags => 'Etiquetas';

  @override
  String get noTagsFound => 'No se encontraron etiquetas.';

  @override
  String get copyCodeSnack => '¡Código copiado!';

  @override
  String get copyCodeTooltip => 'Copiar código';

  @override
  String get editTemplate => 'Editar Plantilla';

  @override
  String get newTemplate => 'Nueva Plantilla';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get titleLabel => 'Título';

  @override
  String get contentLabel => 'Contenido';

  @override
  String get pleaseInsertTitle => 'Por favor, introduce un título';

  @override
  String get pleaseInsertContent => 'Por favor, introduce el contenido';

  @override
  String get tagsLabel => 'Etiquetas (separadas por coma)';

  @override
  String get importMarkdown => 'Importar markdown';

  @override
  String get importMarkdownError =>
      'No se pudo leer el archivo markdown. Asegúrese de que sea un archivo UTF-8 válido.';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get noTemplatesFound => 'No se encontraron plantillas.';

  @override
  String get confirmDeleteTitle => 'Confirmar Eliminación';

  @override
  String confirmDeleteContent(String title) {
    return '¿Estás seguro que quieres eliminar la plantilla \"$title\"?';
  }

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get contentCopied => '¡Contenido copiado!';

  @override
  String get copy => 'Copiar';

  @override
  String get changeTheme => 'Cambiar Tema';

  @override
  String get newTemplateFab => 'Nueva Plantilla';

  @override
  String unexpectedError(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String loadMoreFailed(String error) {
    return 'Error al cargar más plantillas: $error';
  }

  @override
  String databaseInitializationFailed(String error) {
    return 'Error al inicializar la base de datos: $error';
  }

  @override
  String createTemplateFailed(String error) {
    return 'Error al crear la plantilla: $error';
  }

  @override
  String get templateIdCannotBeNull =>
      'El ID de la plantilla no puede ser nulo';

  @override
  String updateTemplateFailed(String error) {
    return 'Error al actualizar la plantilla: $error';
  }

  @override
  String deleteTemplateFailed(String error) {
    return 'Error al eliminar la plantilla: $error';
  }

  @override
  String loadTemplatesFailed(String error) {
    return 'Error al cargar las plantillas: $error';
  }

  @override
  String loadTagsFailed(String error) {
    return 'Error al cargar las etiquetas: $error';
  }

  @override
  String get unknownError => 'Ocurrió un error desconocido';

  @override
  String get fillVariablesTitle => 'Completar Variables';

  @override
  String get confirmCopy => 'Copiar';

  @override
  String get changeLanguage => 'Idioma';

  @override
  String get enableMarkdown => 'Habilitar Markdown';

  @override
  String get enableSnippets => 'Habilitar Snippets';

  @override
  String get templateSettings => 'Configuraciones';

  @override
  String get markdownPreview => 'Vista previa';

  @override
  String get plainTextPreview => 'Texto plano';

  @override
  String get welcomeTitle => '¡Bienvenido a DocFlow!';

  @override
  String get welcomeSubtitle =>
      'Todas tus plantillas en un solo lugar.\nElige dónde guardar tu archivo de datos.';

  @override
  String get createNewDatabase => 'Crear nuevo archivo';

  @override
  String get openExistingDatabase => 'Abrir archivo existente';

  @override
  String get openAnotherFile => 'Abrir otro archivo';

  @override
  String currentFile(String name) {
    return 'Archivo: $name';
  }

  @override
  String get databaseNotFound => 'Archivo no encontrado. Elige otro.';

  @override
  String get selectSaveLocation => 'Elegir ubicación para guardar';

  @override
  String get selectDatabaseFile => 'Seleccionar archivo de base de datos';

  @override
  String get invalidDatabaseFile =>
      'El archivo seleccionado no es una base de datos válida.';

  @override
  String get postgresConnectionTitle => 'Conexión PostgreSQL';

  @override
  String get postgresConnectionSubtitle =>
      'Conéctese a una base de datos PostgreSQL externa';

  @override
  String get serverIpLabel => 'IP del Servidor / Hostname';

  @override
  String get portLabel => 'Puerto';

  @override
  String get databaseLabel => 'Base de Datos';

  @override
  String get usernameLabel => 'Usuario';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get connectButton => 'Conectar';

  @override
  String get connecting => 'Conectando...';

  @override
  String get allFieldsRequired => 'Todos los campos son obligatorios';

  @override
  String get invalidPort => 'Puerto inválido (1-65535)';

  @override
  String connectionError(String error) {
    return 'Error de conexión: $error';
  }

  @override
  String get aboutTitle => 'Acerca de DocFlow';

  @override
  String appVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get supportLabel => 'Sugerencias o Errores (GitHub)';

  @override
  String get settingsMenu => 'Configuración';
}
