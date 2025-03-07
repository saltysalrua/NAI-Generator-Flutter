import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 手势导航操作类型
enum GestureNavigationAction {
  back,        // 返回
  forward,     // 前进
  home,        // 主页
  refresh,     // 刷新
  menu,        // 菜单
  switchTab,   // 切换标签
  custom,      // 自定义
}

/// 手势导航位置
enum GestureNavigationPosition {
  left,   // 左侧
  right,  // 右侧
  bottom, // 底部
  corner, // 角落
}

/// 手势导航组件 - 为移动设备提供边缘手势导航能力
class GestureNavigation extends StatefulWidget {
  final Widget child;
  final GestureNavigationPosition position;
  final GestureNavigationAction action;
  final double threshold;
  final double width;
  final VoidCallback? onAction;
  final bool enableHapticFeedback;
  final bool showVisualFeedback;
  final Color? feedbackColor;
  final IconData? feedbackIcon;
  
  const GestureNavigation({
    Key? key,
    required this.child,
    this.position = GestureNavigationPosition.left,
    this.action = GestureNavigationAction.back,
    this.threshold = 20.0,
    this.width = 20.0,
    this.onAction,
    this.enableHapticFeedback = true,
    this.showVisualFeedback = true,
    this.feedbackColor,
    this.feedbackIcon,
  }) : super(key: key);

  @override
  State<GestureNavigation> createState() => _GestureNavigationState();
}

class _GestureNavigationState extends State<GestureNavigation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _dragDistance = 0.0;
  bool _isDragging = false;
  bool _actionTriggered = false;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    _controller.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _triggerAction() {
    if (!_actionTriggered) {
      _actionTriggered = true;
      
      if (widget.enableHapticFeedback) {
        HapticFeedback.mediumImpact();
      }
      
      if (widget.onAction != null) {
        widget.onAction!();
      } else {
        // 默认动作
        switch (widget.action) {
          case GestureNavigationAction.back:
            Navigator.of(context).maybePop();
            break;
          case GestureNavigationAction.forward:
            // 前进操作需要自定义
            break;
          case GestureNavigationAction.home:
            // 返回到根路由
            Navigator.of(context).popUntil((route) => route.isFirst);
            break;
          case GestureNavigationAction.refresh:
            // 刷新操作需要自定义
            break;
          case GestureNavigationAction.menu:
            // 菜单操作需要自定义
            break;
          case GestureNavigationAction.switchTab:
            // 切换标签操作需要自定义
            break;
          case GestureNavigationAction.custom:
            // 自定义操作需要实现
            break;
        }
      }
    }
  }
  
  void _resetState() {
    _dragDistance = 0.0;
    _isDragging = false;
    _actionTriggered = false;
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主内容
        widget.child,
        
        // 手势区域
        Positioned(
          left: widget.position == GestureNavigationPosition.left ? 0 : null,
          right: widget.position == GestureNavigationPosition.right ? 0 : null,
          bottom: widget.position == GestureNavigationPosition.bottom ? 0 : null,
          child: _buildGestureDetector(),
        ),
        
        // 视觉反馈
        if (widget.showVisualFeedback && _isDragging)
          _buildVisualFeedback(),
      ],
    );
  }
  
  Widget _buildGestureDetector() {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onVerticalDragStart: widget.position == GestureNavigationPosition.bottom ? _onDragStart : null,
      onVerticalDragUpdate: widget.position == GestureNavigationPosition.bottom ? _onDragUpdate : null,
      onVerticalDragEnd: widget.position == GestureNavigationPosition.bottom ? _onDragEnd : null,
      child: Container(
        width: widget.position == GestureNavigationPosition.bottom 
            ? MediaQuery.of(context).size.width
            : widget.width,
        height: widget.position == GestureNavigationPosition.bottom
            ? widget.width
            : MediaQuery.of(context).size.height,
        color: Colors.transparent,
      ),
    );
  }
  
  Widget _buildVisualFeedback() {
    final size = MediaQuery.of(context).size;
    
    // 确定箭头方向
    IconData icon = _getActionIcon();
    
    // 箭头位置
    double left = 0;
    double top = 0;
    
    switch (widget.position) {
      case GestureNavigationPosition.left:
        left = _dragDistance * _animation.value;
        top = size.height / 2 - 24;
        break;
      case GestureNavigationPosition.right:
        left = size.width - _dragDistance * _animation.value - 48;
        top = size.height / 2 - 24;
        break;
      case GestureNavigationPosition.bottom:
        left = size.width / 2 - 24;
        top = size.height - _dragDistance * _animation.value - 48;
        break;
      case GestureNavigationPosition.corner:
        left = 24;
        top = 24;
        break;
    }
    
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: _animation.value,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.feedbackColor ?? Colors.blue.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
  
  IconData _getActionIcon() {
    if (widget.feedbackIcon != null) {
      return widget.feedbackIcon!;
    }
    
    switch (widget.action) {
      case GestureNavigationAction.back:
        return widget.position == GestureNavigationPosition.right
            ? Icons.arrow_forward
            : Icons.arrow_back;
      case GestureNavigationAction.forward:
        return widget.position == GestureNavigationPosition.left
            ? Icons.arrow_forward
            : Icons.arrow_back;
      case GestureNavigationAction.home:
        return Icons.home;
      case GestureNavigationAction.refresh:
        return Icons.refresh;
      case GestureNavigationAction.menu:
        return Icons.menu;
      case GestureNavigationAction.switchTab:
        return Icons.tab;
      case GestureNavigationAction.custom:
        return Icons.touch_app;
    }
  }
  
  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _actionTriggered = false;
      _controller.forward();
    });
  }
  
  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      if (widget.position == GestureNavigationPosition.bottom) {
        _dragDistance += details.delta.dy.abs();
      } else {
        _dragDistance += details.delta.dx.abs();
      }
      
      // 达到阈值触发动作
      if (_dragDistance > widget.threshold && !_actionTriggered) {
        _triggerAction();
      }
    });
  }
  
  void _onDragEnd(DragEndDetails details) {
    _resetState();
  }
}

/// 手势导航包装器 - 在整个应用中添加边缘手势导航功能
class GestureNavigationWrapper extends StatelessWidget {
  final Widget child;
  final bool enableLeftEdgeBack;
  final bool enableRightEdgeForward;
  final bool enableBottomEdgeHome;
  final VoidCallback? onLeftEdge;
  final VoidCallback? onRightEdge;
  final VoidCallback? onBottomEdge;
  final double edgeWidth;
  final bool enableHapticFeedback;
  final bool showVisualFeedback;
  
  const GestureNavigationWrapper({
    Key? key,
    required this.child,
    this.enableLeftEdgeBack = true,
    this.enableRightEdgeForward = false,
    this.enableBottomEdgeHome = false,
    this.onLeftEdge,
    this.onRightEdge,
    this.onBottomEdge,
    this.edgeWidth = 20.0,
    this.enableHapticFeedback = true,
    this.showVisualFeedback = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = child;
    
    // 添加左侧边缘手势
    if (enableLeftEdgeBack) {
      wrappedChild = GestureNavigation(
        position: GestureNavigationPosition.left,
        action: GestureNavigationAction.back,
        width: edgeWidth,
        onAction: onLeftEdge,
        enableHapticFeedback: enableHapticFeedback,
        showVisualFeedback: showVisualFeedback,
        child: wrappedChild,
      );
    }
    
    // 添加右侧边缘手势
    if (enableRightEdgeForward) {
      wrappedChild = GestureNavigation(
        position: GestureNavigationPosition.right,
        action: GestureNavigationAction.forward,
        width: edgeWidth,
        onAction: onRightEdge,
        enableHapticFeedback: enableHapticFeedback,
        showVisualFeedback: showVisualFeedback,
        child: wrappedChild,
      );
    }
    
    // 添加底部边缘手势
    if (enableBottomEdgeHome) {
      wrappedChild = GestureNavigation(
        position: GestureNavigationPosition.bottom,
        action: GestureNavigationAction.home,
        width: edgeWidth,
        onAction: onBottomEdge,
        enableHapticFeedback: enableHapticFeedback,
        showVisualFeedback: showVisualFeedback,
        child: wrappedChild,
      );
    }
    
    return wrappedChild;
  }
}
