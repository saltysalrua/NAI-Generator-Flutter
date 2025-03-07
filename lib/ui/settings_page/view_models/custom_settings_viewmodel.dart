import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/data/models/settings.dart';
import 'package:nai_casrand/data/services/config_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户自定义设置的视图模型，扩展原有的设置页面
class CustomSettingsViewModel extends ChangeNotifier {
  static const String _themeBox = 'themeBox';
  static const String _layoutBox = 'layoutBox';
  static const String _accessibilityBox = 'accessibilityBox';
  
  late Box _themeSettings;
  late Box _layoutSettings;
  late Box _accessibilitySettings;
  late SharedPreferences _preferences;
  
  PayloadConfig payloadConfig;
  
  // 主题设置
  Color _primaryColor = Colors.blue;
  Color _accentColor = Colors.pink;
  bool _useDarkMode = false;
  bool _useSystemTheme = true;
  
  // 布局设置
  bool _compactLayout = false;
  int _cardsPerRow = 2;
  bool _showLabels = true;
  
  // 可访问性设置
  double _textScaleFactor = 1.0;
  bool _highContrast = false;
  int _animationSpeed = 1; // 0: 无动画, 1: 正常, 2: 慢速
  
  // 网络设置
  int _connectionTimeout = 30;
  int _maxRetries = 3;
  bool _autoRetry = true;
  
  // 性能设置
  bool _lowMemoryMode = false;
  int _maxHistoryEntries = 200;
  int _maxCacheSize = 500; // MB
  
  CustomSettingsViewModel({required this.payloadConfig});
  
  // Getters
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  bool get useDarkMode => _useDarkMode;
  bool get useSystemTheme => _useSystemTheme;
  
  bool get compactLayout => _compactLayout;
  int get cardsPerRow => _cardsPerRow;
  bool get showLabels => _showLabels;
  
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast;
  int get animationSpeed => _animationSpeed;
  
  int get connectionTimeout => _connectionTimeout;
  int get maxRetries => _maxRetries;
  bool get autoRetry => _autoRetry;
  
  bool get lowMemoryMode => _lowMemoryMode;
  int get maxHistoryEntries => _maxHistoryEntries;
  int get maxCacheSize => _maxCacheSize;
  
  /// 初始化设置
  Future<void> init() async {
    // 初始化Hive
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    
    _themeSettings = await Hive.openBox(_themeBox);
    _layoutSettings = await Hive.openBox(_layoutBox);
    _accessibilitySettings = await Hive.openBox(_accessibilityBox);
    
    _preferences = await SharedPreferences.getInstance();
    
    // 加载设置
    _loadThemeSettings();
    _loadLayoutSettings();
    _loadAccessibilitySettings();
    _loadNetworkSettings();
    _loadPerformanceSettings();
  }
  
  /// 加载主题设置
  void _loadThemeSettings() {
    final primaryColorValue = _themeSettings.get('primary_color');
    if (primaryColorValue != null) {
      _primaryColor = Color(primaryColorValue);
    }
    
    final accentColorValue = _themeSettings.get('accent_color');
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }
    
    _useDarkMode = _themeSettings.get('use_dark_mode', defaultValue: false);
    _useSystemTheme = _themeSettings.get('use_system_theme', defaultValue: true);
  }
  
  /// 加载布局设置
  void _loadLayoutSettings() {
    _compactLayout = _layoutSettings.get('compact_layout', defaultValue: false);
    _cardsPerRow = _layoutSettings.get('cards_per_row', defaultValue: 2);
    _showLabels = _layoutSettings.get('show_labels', defaultValue: true);
  }
  
  /// 加载可访问性设置
  void _loadAccessibilitySettings() {
    final textScaleValue = _accessibilitySettings.get('text_scale_factor');
    if (textScaleValue != null) {
      _textScaleFactor = textScaleValue;
    }
    
    _highContrast = _accessibilitySettings.get('high_contrast', defaultValue: false);
    _animationSpeed = _accessibilitySettings.get('animation_speed', defaultValue: 1);
  }
  
  /// 加载网络设置
  void _loadNetworkSettings() {
    _connectionTimeout = _preferences.getInt('connection_timeout') ?? 30;
    _maxRetries = _preferences.getInt('max_retries') ?? 3;
    _autoRetry = _preferences.getBool('auto_retry') ?? true;
  }
  
  /// 加载性能设置
  void _loadPerformanceSettings() {
    _lowMemoryMode = _preferences.getBool('low_memory_mode') ?? false;
    _maxHistoryEntries = _preferences.getInt('max_history_entries') ?? 200;
    _maxCacheSize = _preferences.getInt('max_cache_size') ?? 500;
  }
  
  /// 设置主色调
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    await _themeSettings.put('primary_color', color.value);
    notifyListeners();
  }
  
  /// 设置强调色
  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _themeSettings.put('accent_color', color.value);
    notifyListeners();
  }
  
  /// 设置是否使用深色模式
  Future<void> setUseDarkMode(bool value) async {
    _useDarkMode = value;
    await _themeSettings.put('use_dark_mode', value);
    notifyListeners();
  }
  
  /// 设置是否使用系统主题
  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;
    await _themeSettings.put('use_system_theme', value);
    notifyListeners();
  }
  
  /// 设置是否使用紧凑布局
  Future<void> setCompactLayout(bool value) async {
    _compactLayout = value;
    await _layoutSettings.put('compact_layout', value);
    notifyListeners();
  }
  
  /// 设置每行卡片数量
  Future<void> setCardsPerRow(int value) async {
    _cardsPerRow = value;
    await _layoutSettings.put('cards_per_row', value);
    notifyListeners();
  }
  
  /// 设置是否显示标签
  Future<void> setShowLabels(bool value) async {
    _showLabels = value;
    await _layoutSettings.put('show_labels', value);
    notifyListeners();
  }
  
  /// 设置文本缩放比例
  Future<void> setTextScaleFactor(double value) async {
    _textScaleFactor = value;
    await _accessibilitySettings.put('text_scale_factor', value);
    notifyListeners();
  }
  
  /// 设置是否使用高对比度
  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    await _accessibilitySettings.put('high_contrast', value);
    notifyListeners();
  }
  
  /// 设置动画速度
  Future<void> setAnimationSpeed(int value) async {
    _animationSpeed = value;
    await _accessibilitySettings.put('animation_speed', value);
    notifyListeners();
  }
  
  /// 设置连接超时时间
  Future<void> setConnectionTimeout(int value) async {
    _connectionTimeout = value;
    await _preferences.setInt('connection_timeout', value);
    notifyListeners();
  }
  
  /// 设置最大重试次数
  Future<void> setMaxRetries(int value) async {
    _maxRetries = value;
    await _preferences.setInt('max_retries', value);
    notifyListeners();
  }
  
  /// 设置是否自动重试
  Future<void> setAutoRetry(bool value) async {
    _autoRetry = value;
    await _preferences.setBool('auto_retry', value);
    notifyListeners();
  }
  
  /// 设置是否使用低内存模式
  Future<void> setLowMemoryMode(bool value) async {
    _lowMemoryMode = value;
    await _preferences.setBool('low_memory_mode', value);
    notifyListeners();
  }
  
  /// 设置最大历史记录条目数
  Future<void> setMaxHistoryEntries(int value) async {
    _maxHistoryEntries = value;
    await _preferences.setInt('max_history_entries', value);
    notifyListeners();
  }
  
  /// 设置最大缓存大小
  Future<void> setMaxCacheSize(int value) async {
    _maxCacheSize = value;
    await _preferences.setInt('max_cache_size', value);
    notifyListeners();
  }
  
  /// 重置所有设置
  Future<void> resetAllSettings() async {
    // 重置主题设置
    await _themeSettings.clear();
    // 重置布局设置
    await _layoutSettings.clear();
    // 重置可访问性设置
    await _accessibilitySettings.clear();
    // 重置网络设置
    await _preferences.remove('connection_timeout');
    await _preferences.remove('max_retries');
    await _preferences.remove('auto_retry');
    // 重置性能设置
    await _preferences.remove('low_memory_mode');
    await _preferences.remove('max_history_entries');
    await _preferences.remove('max_cache_size');
    
    // 重新加载默认值
    _loadThemeSettings();
    _loadLayoutSettings();
    _loadAccessibilitySettings();
    _loadNetworkSettings();
    _loadPerformanceSettings();
    
    notifyListeners();
  }
  
  /// 获取当前主题数据
  ThemeData getThemeData(BuildContext context) {
    final brightness = _useSystemTheme
        ? MediaQuery.of(context).platformBrightness
        : (_useDarkMode ? Brightness.dark : Brightness.light);
    
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        secondary: _accentColor,
        brightness: brightness,
      ),
      useMaterial3: true,
      // 高对比度主题
      brightness: brightness,
      visualDensity: _compactLayout
          ? VisualDensity.compact
          : VisualDensity.standard,
    );
  }
  
  /// 导出设置为JSON
  String exportSettingsToJson() {
    final Map<String, dynamic> settings = {
      'theme': {
        'primary_color': _primaryColor.value,
        'accent_color': _accentColor.value,
        'use_dark_mode': _useDarkMode,
        'use_system_theme': _useSystemTheme,
      },
      'layout': {
        'compact_layout': _compactLayout,
        'cards_per_row': _cardsPerRow,
        'show_labels': _showLabels,
      },
      'accessibility': {
        'text_scale_factor': _textScaleFactor,
        'high_contrast': _highContrast,
        'animation_speed': _animationSpeed,
      },
      'network': {
        'connection_timeout': _connectionTimeout,
        'max_retries': _maxRetries,
        'auto_retry': _autoRetry,
      },
      'performance': {
        'low_memory_mode': _lowMemoryMode,
        'max_history_entries': _maxHistoryEntries,
        'max_cache_size': _maxCacheSize,
      },
    };
    
    return json.encode(settings);
  }
  
  /// 从JSON导入设置
  Future<void> importSettingsFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> settings = json.decode(jsonString);
      
      // 导入主题设置
      if (settings.containsKey('theme')) {
        final theme = settings['theme'];
        if (theme.containsKey('primary_color')) {
          _primaryColor = Color(theme['primary_color']);
          await _themeSettings.put('primary_color', theme['primary_color']);
        }
        if (theme.containsKey('accent_color')) {
          _accentColor = Color(theme['accent_color']);
          await _themeSettings.put('accent_color', theme['accent_color']);
        }
        if (theme.containsKey('use_dark_mode')) {
          _useDarkMode = theme['use_dark_mode'];
          await _themeSettings.put('use_dark_mode', theme['use_dark_mode']);
        }
        if (theme.containsKey('use_system_theme')) {
          _useSystemTheme = theme['use_system_theme'];
          await _themeSettings.put('use_system_theme', theme['use_system_theme']);
        }
      }
      
      // 导入布局设置
      if (settings.containsKey('layout')) {
        final layout = settings['layout'];
        if (layout.containsKey('compact_layout')) {
          _compactLayout = layout['compact_layout'];
          await _layoutSettings.put('compact_layout', layout['compact_layout']);
        }
        if (layout.containsKey('cards_per_row')) {
          _cardsPerRow = layout['cards_per_row'];
          await _layoutSettings.put('cards_per_row', layout['cards_per_row']);
        }
        if (layout.containsKey('show_labels')) {
          _showLabels = layout['show_labels'];
          await _layoutSettings.put('show_labels', layout['show_labels']);
        }
      }
      
      // 导入可访问性设置
      if (settings.containsKey('accessibility')) {
        final accessibility = settings['accessibility'];
        if (accessibility.containsKey('text_scale_factor')) {
          _textScaleFactor = accessibility['text_scale_factor'];
          await _accessibilitySettings.put('text_scale_factor', accessibility['text_scale_factor']);
        }
        if (accessibility.containsKey('high_contrast')) {
          _highContrast = accessibility['high_contrast'];
          await _accessibilitySettings.put('high_contrast', accessibility['high_contrast']);
        }
        if (accessibility.containsKey('animation_speed')) {
          _animationSpeed = accessibility['animation_speed'];
          await _accessibilitySettings.put('animation_speed', accessibility['animation_speed']);
        }
      }
      
      // 导入网络设置
      if (settings.containsKey('network')) {
        final network = settings['network'];
        if (network.containsKey('connection_timeout')) {
          _connectionTimeout = network['connection_timeout'];
          await _preferences.setInt('connection_timeout', network['connection_timeout']);
        }
        if (network.containsKey('max_retries')) {
          _maxRetries = network['max_retries'];
          await _preferences.setInt('max_retries', network['max_retries']);
        }
        if (network.containsKey('auto_retry')) {
          _autoRetry = network['auto_retry'];
          await _preferences.setBool('auto_retry', network['auto_retry']);
        }
      }
      
      // 导入性能设置
      if (settings.containsKey('performance')) {
        final performance = settings['performance'];
        if (performance.containsKey('low_memory_mode')) {
          _lowMemoryMode = performance['low_memory_mode'];
          await _preferences.setBool('low_memory_mode', performance['low_memory_mode']);
        }
        if (performance.containsKey('max_history_entries')) {
          _maxHistoryEntries = performance['max_history_entries'];
          await _preferences.setInt('max_history_entries', performance['max_history_entries']);
        }
        if (performance.containsKey('max_cache_size')) {
          _maxCacheSize = performance['max_cache_size'];
          await _preferences.setInt('max_cache_size', performance['max_cache_size']);
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('导入设置失败: $e');
      throw Exception('导入设置失败: $e');
    }
  }
}
