class QueryBuilder {
  final StringBuffer _buffer = StringBuffer();
  final List<dynamic> _params = [];

  void raw(String sql) {
    _buffer.write(sql);
  }

  void addParam(dynamic value) {
    _params.add(value);
  }

  List<dynamic> get params => _params;
  String get query => _buffer.toString();

  void clear() {
    _buffer.clear();
    _params.clear();
  }

  String buildPlaceholder() => '?';

  static String buildInPlaceholders(int count) {
    return List.filled(count, '?').join(',');
  }
}
