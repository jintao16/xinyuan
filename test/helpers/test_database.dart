import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mock PathProviderPlatform - 返回临时目录作为文档目录
class MockPathProviderPlatform extends PathProviderPlatform {
  final String docsPath;

  MockPathProviderPlatform(this.docsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;

  @override
  Future<String?> getTemporaryPath() async => docsPath;

  @override
  Future<String?> getLibraryPath() async => docsPath;

  @override
  Future<String?> getApplicationSupportPath() async => docsPath;

  @override
  Future<String?> getApplicationCachePath() async => docsPath;

  @override
  Future<String?> getDownloadsPath() async => docsPath;

  @override
  Future<List<String>?> getExternalCachePaths() async => [docsPath];

  @override
  Future<String?> getExternalStoragePath() async => docsPath;

  @override
  Future<List<String>?> getExternalStoragePaths({
    bool? removable,
    StorageDirectory? type,
  }) async => [docsPath];
}

/// 测试数据库环境
/// 通过 sqflite_common_ffi + path_provider mock 让真实 DatabaseHelper 在测试环境工作
class TestDatabaseEnvironment {
  static bool _initialized = false;
  static late Directory _tempDir;

  /// 初始化 ffi + path_provider mock（仅一次）
  static void ensureInitialized() {
    if (_initialized) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _tempDir = Directory.systemTemp.createTempSync('xinyuan_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(_tempDir.path);

    _initialized = true;
  }

  /// 获取临时目录
  static String get tempPath => _tempDir.path;

  /// 清理临时目录
  static void cleanup() {
    if (_tempDir.existsSync()) {
      _tempDir.deleteSync(recursive: true);
    }
  }
}
