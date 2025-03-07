import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 日志级别
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  off,
}

/// 应用日志工具
class AppLogger {
  static LogLevel _currentLevel = LogLevel.info;
  static File? _logFile;
  static final List<String> _memoryLogs = [];
  static const int _maxMemoryLogs = 1000;
  static bool _initialized = false;
  
  /// 初始化日志系统
  static Future<void> init({LogLevel level = LogLevel.info}) async {
    _currentLevel = level;
    
    if (!kIsWeb) {
      try {
        // 创建日志文件
        final appDir = await getApplicationDocumentsDirectory();
        final logsDir = Directory('${appDir.path}/logs');
        if (!await logsDir.exists()) {
          await logsDir.create(recursive: true);
        }
        
        // 清理旧日志
        await _cleanupOldLogs(logsDir);
        
        // 创建新日志文件
        final today = DateTime.now().toIso8601String().split('T')[0];
        _logFile = File('${logsDir.path}/app_log_$today.txt');
        
        // 写入日志头
        if (!await _logFile!.exists()) {
          await _logFile!.writeAsString(
            '=== 应用日志 - $today ===\n',
            mode: FileMode.append,
          );
        }
        
        _initialized = true;
        log('日志系统初始化完成', level: LogLevel.debug);
      } catch (e) {
        // 无法创建日志文件，只使用内存日志
        debugPrint('无法创建日志文件: $e');
      }
    }
    
    _initialized = true;
  }
  
  /// 清理旧日志文件(保留最近7天)
  static Future<void> _cleanupOldLogs(Directory logsDir) async {
    try {
      final files = await logsDir.list().toList();
      final now = DateTime.now();
      
      for (var fileEntity in files) {
        if (fileEntity is File && fileEntity.path.endsWith('.txt')) {
          final filename = fileEntity.path.split('/').last;
          
          // 提取日期
          final dateMatch = RegExp(r'app_log_(\d{4}-\d{2}-\d{2})\.txt').firstMatch(filename);
          if (dateMatch != null) {
            final dateStr = dateMatch.group(1);
            final fileDate = DateTime.parse(dateStr!);
            
            // 删除7天前的日志
            if (now.difference(fileDate).inDays > 7) {
              await fileEntity.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('清理旧日志失败: $e');
    }
  }
  
  /// 记录日志
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_initialized) {
      // 尚未初始化，使用系统日志
      debugPrint(message);
      if (error != null) debugPrint(error.toString());
      if (stackTrace != null) debugPrint(stackTrace.toString());
      return;
    }
    
    // 检查日志级别
    if (level.index < _currentLevel.index) {
      return;
    }
    
    // 格式化日志
    final now = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    String logMessage = '[$now][$levelStr] $message';
    
    if (error != null) {
      logMessage += '\nERROR: $error';
    }
    
    if (stackTrace != null) {
      logMessage += '\nSTACK: $stackTrace';
    }
    
    // 打印到控制台
    if (kDebugMode) {
      debugPrint(logMessage);
    }
    
    // 添加到内存日志
    _memoryLogs.add(logMessage);
    if (_memoryLogs.length > _maxMemoryLogs) {
      _memoryLogs.removeAt(0);
    }
    
    // 写入文件
    if (_logFile != null && !kIsWeb) {
      try {
        _logFile!.writeAsString(
          '$logMessage\n',
          mode: FileMode.append,
        );
      } catch (e) {
        debugPrint('写入日志文件失败: $e');
      }
    }
  }
  
  /// 记录调试日志
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.debug, error: error, stackTrace: stackTrace);
  }
  
  /// 记录信息日志
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.info, error: error, stackTrace: stackTrace);
  }
  
  /// 记录警告日志
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.warning, error: error, stackTrace: stackTrace);
  }
  
  /// 记录错误日志
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
  }
  
  /// 获取内存中的日志
  static List<String> getMemoryLogs() {
    return List.from(_memoryLogs);
  }
  
  /// 导出日志文件
  static Future<File?> exportLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      // 复制文件至下载目录
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final exportFile = File('${downloadsDir.path}/app_log_export_$today.txt');
        
        try {
          return await _logFile!.copy(exportFile.path);
        } catch (e) {
          error('导出日志失败', e);
          return null;
        }
      }
    }
    
    return null;
  }
  
  /// 导出日志为文本
  static Future<String> exportLogsAsText() async {
    if (_logFile != null && await _logFile!.exists()) {
      try {
        return await _logFile!.readAsString();
      } catch (e) {
        error('读取日志文件失败', e);
      }
    }
    
    // 如果无法读取文件，返回内存日志
    return _memoryLogs.join('\n');
  }
  
  /// 清空日志
  static Future<void> clearLogs() async {
    _memoryLogs.clear();
    
    if (_logFile != null && await _logFile!.exists()) {
      try {
        await _logFile!.delete();
        final today = DateTime.now().toIso8601String().split('T')[0];
        await _logFile!.create();
        await _logFile!.writeAsString(
          '=== 应用日志 - $today (已清空) ===\n',
          mode: FileMode.append,
        );
      } catch (e) {
        error('清空日志文件失败', e);
      }
    }
  }
  
  /// 设置日志级别
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
    log('日志级别已设置为 $level', level: LogLevel.debug);
  }
}
