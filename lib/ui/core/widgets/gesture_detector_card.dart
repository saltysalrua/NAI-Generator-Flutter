import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 多手势检测卡片，支持各种手势操作
class GestureDetectorCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final Function(DragUpdateDetails)? onPanUpdate;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final Function(ScaleUpdateDetails)? onScaleUpdate;
  final VoidCallback? onTapFavorite; // 快捷收藏操作
  final bool enableHapticFeedback;
  final bool isSelected;
  final double swipeThreshold;
  final bool enableSwipe;
  final bool enableScale;
  final double elevation;
  final double borderRadius;
  final BoxShadow? customShadow;
  final Color? color;
  final HitTestBehavior behavior;
  
  const GestureDetectorCard({
    Key? key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onPanUpdate,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onScaleUpdate,
    this.onTapFavorite,
    this.enableHapticFeedback = true,
    this.isSelected = false,
    this.swipeThreshold = 20.0,
    this.enableSwipe = true,
    this.enableScale = false,
    this.elevation = 2.0,
    this.borderRadius = 8.0,
    this.customShadow,
    this.color,
    this.behavior = HitTestBehavior.opaque,
  }) : super(key: key);

  @override
  State<GestureDetectorCard> createState() => _GestureDetectorCardState();
}

class _GestureDetectorCardState extends State<GestureDetectorCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  Offset _dragStart = Offset.zero;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _triggerHapticFeedback() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _scaleAnimation.value * _scale,
      child: Transform.translate(
        offset: _offset,
        child: Card(
          elevation: widget.elevation,
          color: widget.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            side: widget.isSelected 
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0)
                : BorderSide.none,
          ),
          shadowColor: widget.customShadow?.color,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: _buildGestureDetector(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGestureDetector() {
    if (widget.enableScale) {
      return GestureDetector(
        behavior: widget.behavior,
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        onLongPress: _handleLongPress,
        child: ScaleGestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: widget.child,
        ),
      );
    } else if (widget.enableSwipe) {
      return GestureDetector(
        behavior: widget.behavior,
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        onLongPress: _handleLongPress,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: widget.child,
      );
    } else {
      return GestureDetector(
        behavior: widget.behavior,
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        onLongPress: _handleLongPress,
        child: widget.child,
      );
    }
  }
  
  void _handleTap() {
    _triggerHapticFeedback();
    
    // 播放按下动画
    _controller.forward().then((_) {
      _controller.reverse();
    });
    
    widget.onTap?.call();
  }
  
  void _handleDoubleTap() {
    _triggerHapticFeedback();
    widget.onDoubleTap?.call();
  }
  
  void _handleLongPress() {
    _triggerHapticFeedback();
    widget.onLongPress?.call();
  }
  
  void _handlePanStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = Offset(details.delta.dx / 2, details.delta.dy / 2);
    });
    
    widget.onPanUpdate?.call(details);
  }
  
  void _handlePanEnd(DragEndDetails details) {
    // 恢复位置
    setState(() {
      _offset = Offset.zero;
    });
    
    // 计算拖动距离和方向
    final dragEnd = details.velocity.pixelsPerSecond;
    final dragDistance = dragEnd.distance;
    
    // 如果拖动速度很小，认为是点击而非滑动
    if (dragDistance < widget.swipeThreshold) {
      return;
    }
    
    // 确定滑动方向
    final dx = dragEnd.dx;
    final dy = dragEnd.dy;
    
    if (dx.abs() > dy.abs()) {
      // 水平滑动
      if (dx > 0) {
        // 向右滑动
        _triggerHapticFeedback();
        widget.onSwipeRight?.call();
      } else {
        // 向左滑动
        _triggerHapticFeedback();
        widget.onSwipeLeft?.call();
      }
    } else {
      // 垂直滑动
      if (dy > 0) {
        // 向下滑动
        _triggerHapticFeedback();
        widget.onSwipeDown?.call();
      } else {
        // 向上滑动
        _triggerHapticFeedback();
        widget.onSwipeUp?.call();
      }
    }
  }
  
  void _handleScaleStart(ScaleStartDetails details) {
    _scale = 1.0;
  }
  
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = details.scale.clamp(0.8, 2.0);
    });
    
    widget.onScaleUpdate?.call(details);
  }
  
  void _handleScaleEnd(ScaleEndDetails details) {
    // 恢复缩放
    setState(() {
      _scale = 1.0;
    });
  }
}

/// 自定义缩放手势检测器
class ScaleGestureDetector extends StatelessWidget {
  final Widget child;
  final Function(ScaleStartDetails) onScaleStart;
  final Function(ScaleUpdateDetails) onScaleUpdate;
  final Function(ScaleEndDetails) onScaleEnd;
  
  const ScaleGestureDetector({
    Key? key,
    required this.child,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      child: child,
    );
  }
}
