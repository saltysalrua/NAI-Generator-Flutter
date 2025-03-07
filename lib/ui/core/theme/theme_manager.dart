import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nai_casrand/ui/core/theme/app_themes.dart';

/// 主题模式
enum ThemeMode {
  light,    // 亮色模式
  dark,     // 暗色模式
  system,   // 跟随系统
  custom,   // 自定义主题
}

/// 主题管理器
class ThemeManager extends ChangeNotifier {
  static const String _themeBox = 'themeBox';
  static const String _themeProfilesBox = 'themeProfilesBox';
  
  // 主题相关设置的Hive盒子
  late Box _themeSettings;
  late Box _themeProfiles;
  
  // 当前主题设置
  ThemeMode _currentThemeMode = ThemeMode.system;
  ThemeData _currentLightTheme = AppThemes.lightTheme;
  ThemeData _currentDarkTheme = AppThemes.darkTheme;
  String _currentThemeProfileName = 'default';
  
  // 主题定制选项
  Color _primaryColor = Colors.blue;
  Color _accentColor = Colors.pink;
  double _borderRadius = 8.0;
  double _elevationLevel = 2.0;
  bool _useMaterial3 = true;
  double _fontSizeScale = 1.0;
  bool _highContrast = false;
  bool _reducedMotion = false;
  
  // Getters
  ThemeMode get currentThemeMode => _currentThemeMode;
  ThemeData get currentLightTheme => _currentLightTheme;
  ThemeData get currentDarkTheme => _currentDarkTheme;
  String get currentThemeProfileName => _currentThemeProfileName;
  
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  double get borderRadius => _borderRadius;
  double get elevationLevel => _elevationLevel;
  bool get useMaterial3 => _useMaterial3;
  double get fontSizeScale => _fontSizeScale;
  bool get highContrast => _highContrast;
  bool get reducedMotion => _reducedMotion;
  
  /// 判断当前是否是暗色模式
  bool isDarkMode(BuildContext context) {
    if (_currentThemeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _currentThemeMode == ThemeMode.dark;
  }
  
  /// 初始化主题管理器
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    
    _themeSettings = await Hive.openBox(_themeBox);
    _themeProfiles = await Hive.openBox(_themeProfilesBox);
    
    _loadThemeSettings();
    
    // 确保有默认主题配置
    if (!_themeProfiles.containsKey('default')) {
      await _saveThemeProfile('default');
    }
  }
  
  /// 加载主题设置
  void _loadThemeSettings() {
    final themeModeStr = _themeSettings.get('theme_mode');
    if (themeModeStr != null) {
      _currentThemeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeStr,
        orElse: () => ThemeMode.system,
      );
    }
    
    final profileName = _themeSettings.get('current_profile');
    if (profileName != null) {
      _loadThemeProfile(profileName);
    } else {
      // 如果没有已保存的配置，使用默认配置
      _loadThemeProfile('default');
    }
    
    _updateThemes();
  }
  
  /// 加载主题配置
  void _loadThemeProfile(String profileName) {
    final profileData = _themeProfiles.get(profileName);
    if (profileData == null) return;
    
    try {
      final Map<String, dynamic> profile = json.decode(profileData);
      
      _currentThemeProfileName = profileName;
      
      // 加载颜色
      if (profile.containsKey('primary_color')) {
        _primaryColor = Color(profile['primary_color']);
      }
      
      if (profile.containsKey('accent_color')) {
        _accentColor = Color(profile['accent_color']);
      }
      
      // 加载其他设置
      _borderRadius = profile['border_radius'] ?? 8.0;
      _elevationLevel = profile['elevation_level'] ?? 2.0;
      _useMaterial3 = profile['use_material3'] ?? true;
      _fontSizeScale = profile['font_size_scale'] ?? 1.0;
      _highContrast = profile['high_contrast'] ?? false;
      _reducedMotion = profile['reduced_motion'] ?? false;
      
      // 保存当前配置名称
      _themeSettings.put('current_profile', profileName);
      
      notifyListeners();
    } catch (e) {
      print('加载主题配置失败: $e');
    }
  }
  
  /// 保存当前主题配置
  Future<void> _saveThemeProfile(String profileName) async {
    final Map<String, dynamic> profile = {
      'primary_color': _primaryColor.value,
      'accent_color': _accentColor.value,
      'border_radius': _borderRadius,
      'elevation_level': _elevationLevel,
      'use_material3': _useMaterial3,
      'font_size_scale': _fontSizeScale,
      'high_contrast': _highContrast,
      'reduced_motion': _reducedMotion,
    };
    
    await _themeProfiles.put(profileName, json.encode(profile));
    _currentThemeProfileName = profileName;
    await _themeSettings.put('current_profile', profileName);
  }
  
  /// 更新主题
  void _updateThemes() {
    _currentLightTheme = _createTheme(Brightness.light);
    _currentDarkTheme = _createTheme(Brightness.dark);
    notifyListeners();
  }
  
  /// 创建主题
  ThemeData _createTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    
    // 创建基础色彩方案
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _accentColor,
      brightness: brightness,
      // 高对比度设置
      contrast: _highContrast ? 1.3 : 1.0,
    );
    
    // 创建按钮主题
    final buttonTheme = ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
    );
    
    // 创建输入装饰主题
    final inputDecorationTheme = InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
    
    // 创建卡片主题
    final cardTheme = CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      elevation: _elevationLevel,
    );
    
    // 创建文本主题
    final textTheme = (isLight ? AppThemes.lightTheme : AppThemes.darkTheme)
        .textTheme
        .apply(
          fontSizeFactor: _fontSizeScale,
        );
    
    // 创建页面过渡主题
    final pageTransitionsTheme = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _reducedMotion
            ? const NoAnimationPageTransitionsBuilder()
            : const ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: _reducedMotion
            ? const NoAnimationPageTransitionsBuilder()
            : const CupertinoPageTransitionsBuilder(),
      },
    );
    
    // 创建主题
    return ThemeData(
      colorScheme: colorScheme,
      primaryColor: _primaryColor,
      brightness: brightness,
      buttonTheme: buttonTheme,
      inputDecorationTheme: inputDecorationTheme,
      cardTheme: cardTheme,
      textTheme: textTheme,
      pageTransitionsTheme: pageTransitionsTheme,
      useMaterial3: _useMaterial3,
      visualDensity: VisualDensity.standard,
    );
  }
  
  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _currentThemeMode = themeMode;
    await _themeSettings.put('theme_mode', themeMode.toString());
    notifyListeners();
  }
  
  /// 设置主色调
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _updateThemes();
  }
  
  /// 设置强调色
  void setAccentColor(Color color) {
    _accentColor = color;
    _updateThemes();
  }
  
  /// 设置边框圆角
  void setBorderRadius(double radius) {
    _borderRadius = radius;
    _updateThemes();
  }
  
  /// 设置阴影高度
  void setElevationLevel(double elevation) {
    _elevationLevel = elevation;
    _updateThemes();
  }
  
  /// 设置是否使用Material 3
  void setUseMaterial3(bool useMaterial3) {
    _useMaterial3 = useMaterial3;
    _updateThemes();
  }
  
  /// 设置字体大小比例
  void setFontSizeScale(double scale) {
    _fontSizeScale = scale;
    _updateThemes();
  }
  
  /// 设置是否使用高对比度
  void setHighContrast(bool highContrast) {
    _highContrast = highContrast;
    _updateThemes();
  }
  
  /// 设置是否减少动画
  void setReducedMotion(bool reducedMotion) {
    _reducedMotion = reducedMotion;
    _updateThemes();
  }
  
  /// 切换亮暗模式
  void toggleThemeMode() {
    if (_currentThemeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
  
  /// 获取所有主题配置名称
  List<String> getThemeProfileNames() {
    return _themeProfiles.keys.cast<String>().toList();
  }
  
  /// 加载指定名称的主题配置
  void loadThemeProfile(String profileName) {
    _loadThemeProfile(profileName);
    _updateThemes();
  }
  
  /// 保存当前主题配置
  Future<void> saveCurrentThemeProfile(String profileName) async {
    await _saveThemeProfile(profileName);
    notifyListeners();
  }
  
  /// 删除主题配置
  Future<void> deleteThemeProfile(String profileName) async {
    if (profileName == 'default') {
      // 默认配置不能删除
      return;
    }
    
    await _themeProfiles.delete(profileName);
    
    // 如果删除的是当前使用的配置，切换到默认配置
    if (_currentThemeProfileName == profileName) {
      _loadThemeProfile('default');
      _updateThemes();
    }
    
    notifyListeners();
  }
  
  /// 重置为默认主题
  void resetToDefaultTheme() {
    _loadThemeProfile('default');
    _updateThemes();
  }
}

/// 无动画页面过渡构建器（减少动画）
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
