import 'package:flutter/foundation.dart';
import '../../data/datasources/local_database.dart';
import '../utils/changelog_data.dart';

class ChangelogProvider extends ChangeNotifier {
  final LocalDatabase _database;
  String? _lastViewedVersion;
  bool _isLoading = true;

  ChangelogProvider(this._database);

  bool get isLoading => _isLoading;
  String? get lastViewedVersion => _lastViewedVersion;

  bool get hasNewVersion {
    if (changelogData.isEmpty) return false;
    if (_lastViewedVersion == null) return true;
    return changelogData.first.version != _lastViewedVersion;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _lastViewedVersion = await _database.getPreference('last_viewed_version');
    } catch (e) {
      debugPrint('Error loading last viewed version: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsViewed() async {
    if (changelogData.isEmpty) return;
    
    final latestVersion = changelogData.first.version;
    if (_lastViewedVersion == latestVersion) return;

    try {
      await _database.savePreference('last_viewed_version', latestVersion);
      _lastViewedVersion = latestVersion;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving last viewed version: $e');
    }
  }
}
