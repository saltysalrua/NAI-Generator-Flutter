import 'package:flutter/material.dart';

/// 屏幕工具类，用于判断屏幕尺寸和方向
class ScreenUtils {
  /// 小屏幕的宽度阈值（手机）
  static const double smallScreenWidth = 600;
  
  /// 中屏幕的宽度阈值（小平板）
  static const double mediumScreenWidth = 900;
  
  /// 大屏幕的宽度阈值（大平板和桌面）
  static const double largeScreenWidth = 1200;
  
  /// 判断是否是小屏幕（手机）
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < smallScreenWidth;
  }
  
  /// 判断是否是中屏幕（小平板）
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallScreenWidth && width < mediumScreenWidth;
  }
  
  /// 判断是否是大屏幕（大平板和桌面）
  static bool isLargeScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mediumScreenWidth && width < largeScreenWidth;
  }
  
  /// 判断是否是超大屏幕（桌面）
  static bool isExtraLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeScreenWidth;
  }
  
  /// 判断是否是平板或桌面
  static bool isTabletOrDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= smallScreenWidth;
  }
  
  /// 判断是否是横屏模式
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// 判断是否是竖屏模式
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  /// 获取安全区域尺寸
  static EdgeInsets getSafePadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// 获取状态栏高度
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  
  /// 获取底部安全区域高度（刘海屏底部）
  static double getBottomSafeHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  /// 获取当前屏幕宽度
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// 获取当前屏幕高度
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// 获取当前屏幕尺寸
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
  
  /// 根据屏幕尺寸获取响应式缩放系数
  static double getResponsiveScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < smallScreenWidth) {
      return 1.0; // 手机屏幕标准比例
    } else if (width < mediumScreenWidth) {
      return 1.1; // 小平板稍大一些
    } else if (width < largeScreenWidth) {
      return 1.2; // 大平板
    } else {
      return 1.3; // 桌面
    }
  }
  
  /// 获取基于屏幕宽度的自适应尺寸
  static double getAdaptiveSize(BuildContext context, double baseSize) {
    return baseSize * getResponsiveScaleFactor(context);
  }
  
  /// 获取自适应字体大小
  static double getAdaptiveFontSize(BuildContext context, double fontSize) {
    return fontSize * getResponsiveScaleFactor(context);
  }
  
  /// 获取网格列数（根据屏幕宽度自动计算最佳列数）
  static int getGridColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < smallScreenWidth) {
      return 2; // 手机屏幕2列
    } else if (width < mediumScreenWidth) {
      return 3; // 小平板3列
    } else if (width < largeScreenWidth) {
      return 4; // 大平板4列
    } else {
      return 5; // 桌面5列
    }
  }
  
  /// 根据屏幕宽度动态调整水平边距
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < smallScreenWidth) {
      return 16.0; // 手机屏幕
    } else if (width < mediumScreenWidth) {
      return 24.0; // 小平板
    } else if (width < largeScreenWidth) {
      return 32.0; // 大平板
    } else {
      return 48.0; // 桌面
    }
  }
  
  /// 检查设备是否支持悬浮窗
  static bool supportsHover(BuildContext context) {
    return MediaQuery.of(context).navigationMode == NavigationMode.traditional;
  }
}
