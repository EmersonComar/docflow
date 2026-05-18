import 'database_driver.dart';

abstract class Migration {
  int get version;

  Future<void> up(DatabaseDriver driver);

  Future<void> down(DatabaseDriver driver);
}
