import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/ui/core/utils/screen_utils.dart';
import 'package:nai_casrand/ui/navigation/view_models/navigation_view_model.dart';
import 'package:nai_casrand/ui/navigation/widgets/navigation_appbar.dart';
import 'package:nai_casrand/ui/settings_page/view_models/custom_settings_viewmodel.dart';

/// 适应不同屏幕尺寸和设备的主布局
class AdaptiveMainLayout extends StatefulWidget {
  final NavigationViewModel viewModel;
  final List<Widget> pageWidgets;
  final List<BottomNavigationBarItem> navItems;

  const AdaptiveMainLayout({
    Key? key,
    required this.viewModel,
    required this.pageWidgets,
    required this.navItems,
  }) : super(key: key);

  @override
  State<AdaptiveMainLayout> createState() => _AdaptiveMainLayoutState();
}

class _AdaptiveMainLayoutState extends State<AdaptiveMainLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFabExpanded = false;
  final CustomSettingsViewModel _settingsViewModel = CustomSettingsViewModel(
    payloadConfig: GetIt.instance<PayloadConfig>(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.pageWidgets.length,
      vsync: this,
      initialIndex: widget.viewModel.currentPageIndex,
    );
    _tabController.addListener(_handleTabChange);
    _settingsViewModel.init();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// 处理标签变化
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      widget.viewModel.changeIndex(_tabController.index);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 检查是否为移动设备和横屏模式
    final isSmallScreen = ScreenUtils.isSmallScreen(context);
    final isLandscape = ScreenUtils.isLandscape(context);
    final useBottomNavigation = isSmallScreen && !isLandscape;
    final useNavigationRail = !useBottomNavigation;
    
    final appBarTitle = widget.viewModel.currentPageIndex < widget.navItems.length
        ? widget.navItems[widget.viewModel.currentPageIndex].label
        : '';

    if (useBottomNavigation) {
      // 小屏幕设备（竖屏手机）
      return _buildBottomNavLayout(context, appBarTitle!);
    } else {
      // 大屏幕或横屏设备
      return _buildNavigationRailLayout(context);
    }
  }

  /// 构建底部导航布局（适合手机竖屏）
  Widget _buildBottomNavLayout(BuildContext context, String title) {
    return Scaffold(
      appBar: NavigationAppBar(title: title),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // 禁用滑动切换，防止与内部滚动冲突
        children: widget.pageWidgets,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabController.index,
        items: widget.navItems,
        onTap: (index) {
          _tabController.animateTo(index);
        },
        type: BottomNavigationBarType.fixed, // 固定布局
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      floatingActionButton: _buildAdaptiveFAB(context),
    );
  }

  /// 构建边栏导航布局（适合平板或横屏）
  Widget _buildNavigationRailLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 导航栏
          NavigationRail(
            selectedIndex: _tabController.index,
            onDestinationSelected: (index) {
              _tabController.animateTo(index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: widget.navItems.map((item) {
              return NavigationRailDestination(
                icon: item.icon,
                label: Text(item.label ?? ''),
              );
            }).toList(),
            // 顶部添加应用栏
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      // 显示应用菜单
                      _showAppMenu(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  const CircleAvatar(
                    child: Icon(Icons.palette),
                  ),
                ],
              ),
            ),
          ),
          
          // 内容区
          Expanded(
            child: Column(
              children: [
                // 自定义应用栏
                AppBar(
                  title: Text(
                    widget.navItems[_tabController.index].label ?? '',
                  ),
                  actions: [
                    // 按需添加操作按钮
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        // 打开设置
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: () {
                        // 显示帮助
                      },
                    ),
                  ],
                ),
                
                // 页面内容
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: widget.pageWidgets,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAdaptiveFAB(context),
    );
  }

  /// 构建自适应浮动操作按钮
  Widget _buildAdaptiveFAB(BuildContext context) {
    // 根据当前页面决定是否显示FAB
    if (_tabController.index == 0) { // 生成页面
      return _buildExpandableFAB(context);
    } 
    return const SizedBox.shrink(); // 其他页面暂不显示FAB
  }

  /// 构建可展开的浮动操作按钮
  Widget _buildExpandableFAB(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 展开后显示的子按钮
        if (_isFabExpanded) ...[
          // 保存当前配置
          FloatingActionButton.small(
            heroTag: 'fab_save',
            onPressed: () {
              // 保存配置操作
              _showSaveTemplateDialog(context);
            },
            tooltip: tr('save_current_config'),
            child: const Icon(Icons.save),
          ),
          const SizedBox(height: 8),
          
          // 批处理
          FloatingActionButton.small(
            heroTag: 'fab_batch',
            onPressed: () {
              // 批处理操作
            },
            tooltip: tr('batch_processing'),
            child: const Icon(Icons.queue_play_next),
          ),
          const SizedBox(height: 8),
        ],
        
        // 主FAB按钮
        FloatingActionButton(
          heroTag: 'fab_main',
          onPressed: () {
            setState(() {
              _isFabExpanded = !_isFabExpanded;
            });
          },
          tooltip: _isFabExpanded ? tr('collapse') : tr('expand'),
          child: Icon(_isFabExpanded ? Icons.close : Icons.add),
        ),
      ],
    );
  }

  /// 显示应用菜单
  void _showAppMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(tr('toggle_theme')),
              onTap: () {
                // 切换主题
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(tr('change_language')),
              onTap: () {
                // 切换语言
                Navigator.pop(context);
                _showLanguageSelectionDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: Text(tr('help')),
              onTap: () {
                // 显示帮助
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(tr('about')),
              onTap: () {
                // 显示关于信息
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示语言选择对话框
  void _showLanguageSelectionDialog(BuildContext context) {
    final locales = context.supportedLocales;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: locales.map((locale) {
            final String languageName;
            if (locale.languageCode == 'en') {
              languageName = 'English';
            } else if (locale.languageCode == 'zh') {
              languageName = '中文';
            } else {
              languageName = locale.languageCode;
            }
            
            return ListTile(
              title: Text(languageName),
              onTap: () {
                context.setLocale(locale);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
        ],
      ),
    );
  }

  /// 显示保存模板对话框
  void _showSaveTemplateDialog(BuildContext context) {
    // 实现保存模板的对话框
  }
}
