import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/ui/core/theme/theme_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 启动屏幕
class SplashScreen extends StatefulWidget {
  final Color? backgroundColor;
  final Color? progressColor;
  
  const SplashScreen({
    Key? key,
    this.backgroundColor,
    this.progressColor,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _rotationAnimation;
  
  String _appVersion = '';
  bool _isError = false;
  
  @override
  void initState() {
    super.initState();
    
    // 设置动画控制器
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // 淡入动画
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    
    // 旋转动画
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    // 启动动画
    _controller.forward();
    
    // 获取版本信息
    _loadVersionInfo();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  /// 加载版本信息
  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${packageInfo.version}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 尝试使用ThemeManager中的主题色，如果未初始化则使用默认色
    Color backgroundColor = widget.backgroundColor ?? Colors.white;
    Color progressColor = widget.progressColor ?? Colors.blue;
    
    try {
      final themeManager = GetIt.instance<ThemeManager>();
      backgroundColor = themeManager.isDarkMode(context) 
          ? themeManager.currentDarkTheme.scaffoldBackgroundColor
          : themeManager.currentLightTheme.scaffoldBackgroundColor;
      
      progressColor = themeManager.isDarkMode(context)
          ? themeManager.currentDarkTheme.colorScheme.primary
          : themeManager.currentLightTheme.colorScheme.primary;
    } catch (e) {
      // 忽略错误，使用默认颜色
    }
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeInAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 旋转的APP图标
                    Transform.rotate(
                      angle: _rotationAnimation.value * 3.14,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: progressColor.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.brush,
                          size: 64,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // 应用名称
                    Text(
                      'NAI CasRand',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 版本号
                    if (_appVersion.isNotEmpty)
                      Text(
                        _appVersion,
                        style: TextStyle(
                          fontSize: 14,
                          color: progressColor.withOpacity(0.7),
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // 加载进度条
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _isError ? null : _controller.value,
                        backgroundColor: progressColor.withOpacity(0.2),
                        color: progressColor,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 加载状态文字
                    Text(
                      _isError ? tr('loading_error') : tr('loading'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _isError 
                            ? Colors.red 
                            : progressColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
