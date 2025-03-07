import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 快速操作菜单项
class QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool needsConfirmation;
  final String? confirmationText;
  
  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.needsConfirmation = false,
    this.confirmationText,
  });
}

/// 快速操作菜单，适用于移动端常用操作的便捷触发
class QuickActionMenu extends StatelessWidget {
  final List<QuickActionItem> actions;
  final double buttonSize;
  final double menuWidth;
  final EdgeInsets padding;
  final bool enableHapticFeedback;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? labelColor;
  final bool showLabels;
  final bool closeAfterAction;
  final VoidCallback? onClose;
  
  const QuickActionMenu({
    Key? key,
    required this.actions,
    this.buttonSize = 56.0,
    this.menuWidth = 260.0,
    this.padding = const EdgeInsets.all(8.0),
    this.enableHapticFeedback = true,
    this.backgroundColor,
    this.iconColor,
    this.labelColor,
    this.showLabels = true,
    this.closeAfterAction = true,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface;
    final textColor = labelColor ?? theme.colorScheme.onSurface;
    
    return Container(
      width: menuWidth,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('quick_actions'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (onClose != null) {
                      onClose!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // 操作按钮列表
          Padding(
            padding: padding,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: actions.map((action) {
                return _buildActionButton(context, action);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建操作按钮
  Widget _buildActionButton(BuildContext context, QuickActionItem action) {
    return InkWell(
      onTap: () => _handleActionTap(context, action),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: buttonSize * 1.5,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: action.color?.withOpacity(0.1) ?? 
                       Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                color: action.color ?? iconColor ?? Theme.of(context).colorScheme.primary,
                size: buttonSize / 2,
              ),
            ),
            if (showLabels) ...[
              const SizedBox(height: 4),
              Text(
                action.label,
                style: TextStyle(
                  color: labelColor ?? Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 处理操作点击
  void _handleActionTap(BuildContext context, QuickActionItem action) {
    if (enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    
    if (action.needsConfirmation) {
      // 需要确认的操作
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('confirm_action')),
          content: Text(action.confirmationText ?? 
                        tr('confirm_action_message', namedArgs: {'action': action.label})),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                action.onTap();
                if (closeAfterAction) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(tr('confirm')),
            ),
          ],
        ),
      );
    } else {
      // 直接执行操作
      action.onTap();
      if (closeAfterAction) {
        Navigator.of(context).pop();
      }
    }
  }
  
  /// 显示快速操作菜单
  static Future<void> show(
    BuildContext context, {
    required List<QuickActionItem> actions,
    double buttonSize = 56.0,
    double menuWidth = 260.0,
    EdgeInsets padding = const EdgeInsets.all(8.0),
    bool enableHapticFeedback = true,
    Color? backgroundColor,
    Color? iconColor,
    Color? labelColor,
    bool showLabels = true,
    bool closeAfterAction = true,
    VoidCallback? onClose,
  }) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Center(
        child: QuickActionMenu(
          actions: actions,
          buttonSize: buttonSize,
          menuWidth: menuWidth,
          padding: padding,
          enableHapticFeedback: enableHapticFeedback,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
          labelColor: labelColor,
          showLabels: showLabels,
          closeAfterAction: closeAfterAction,
          onClose: onClose,
        ),
      ),
    );
  }
  
  /// 以指定位置显示快速操作菜单（上下文菜单）
  static Future<void> showAtPosition(
    BuildContext context, {
    required Offset position,
    required List<QuickActionItem> actions,
    double buttonSize = 56.0,
    double menuWidth = 260.0,
    EdgeInsets padding = const EdgeInsets.all(8.0),
    bool enableHapticFeedback = true,
    Color? backgroundColor,
    Color? iconColor,
    Color? labelColor,
    bool showLabels = true,
    bool closeAfterAction = true,
    VoidCallback? onClose,
  }) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    final menuHeight = (actions.length / 3).ceil() * (buttonSize + 24) + 60;
    final screenSize = MediaQuery.of(context).size;
    
    final left = position.dx + menuWidth > screenSize.width
        ? screenSize.width - menuWidth - 8
        : position.dx;
        
    final top = position.dy + menuHeight > screenSize.height
        ? position.dy - menuHeight - 8
        : position.dy;
    
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          // 背景遮罩
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              if (onClose != null) {
                onClose();
              }
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
          
          // 菜单
          Positioned(
            left: left,
            top: top,
            child: QuickActionMenu(
              actions: actions,
              buttonSize: buttonSize,
              menuWidth: menuWidth,
              padding: padding,
              enableHapticFeedback: enableHapticFeedback,
              backgroundColor: backgroundColor,
              iconColor: iconColor,
              labelColor: labelColor,
              showLabels: showLabels,
              closeAfterAction: closeAfterAction,
              onClose: onClose,
            ),
          ),
        ],
      ),
    );
  }
}
