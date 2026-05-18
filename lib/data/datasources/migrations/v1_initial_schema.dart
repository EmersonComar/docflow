import '../drivers/database_driver.dart';
import '../drivers/migration.dart';

class MigrationV1 implements Migration {
  @override
  int get version => 1;

  @override
  Future<void> up(DatabaseDriver driver) async {
    // Migrations são agora executadas no SQLiteDriftDriver na inicialização
  }

  @override
  Future<void> down(DatabaseDriver driver) async {}
}
