import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:nai_casrand/ui/core/utils/flushbar.dart';
import 'package:nai_casrand/ui/core/widgets/editable_list_tile.dart';
import 'package:nai_casrand/ui/core/widgets/slider_list_tile.dart';
import 'package:nai_casrand/ui/settings_page/view_models/custom_settings_viewmodel.dart';
import 'package:provider/provider.dart';

/// 自定义设置界面
class CustomSettingsView extends StatelessWidget {
  final CustomSettingsViewModel viewmodel;

  const CustomSettingsView({super.key, required this.viewmodel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewmodel,
      child: Consumer<CustomSettingsViewModel>(
        builder: (context, viewmodel, child) => SingleChildScrollView(
          child: Column(
            children: [
              _buildThemeSettings(context, viewmodel),
              _buildLayoutSettings(context, viewmodel),
              _buildAccessibilitySettings(context, viewmodel),
              _buildNetworkSettings(context, viewmodel),
              _buildPerformanceSettings(context, viewmodel),
              _buildActionButtons(context, viewmodel),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建主题设置
  Widget _buildThemeSettings(BuildContext context, CustomSettingsViewModel viewmodel) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.color_lens),
        title: Text(tr('theme_settings')),
        children: [
          ListTile(
            title: Text(tr('primary_color')),
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: viewmodel.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
            onTap: () => _showColorPicker(
              context,
              viewmodel.primaryColor,
              (color) => viewmodel.setPrimaryColor(color),
              tr('primary_color'),
            ),
          ),
          ListTile(
            title: Text(tr('accent_color')),
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: viewmodel.accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
            onTap: () => _showColorPicker(
              context,
              viewmodel.accentColor,
              (color) => viewmodel.setAccentColor(color),
              tr('accent_color'),
            ),
          ),
          SwitchListTile(
            title: Text(tr('use_system_theme')),
            subtitle: Text(tr('use_system_theme_desc')),
            value: viewmodel.useSystemTheme,
            onChanged: (value) => viewmodel.setUseSystemTheme(value),
          ),
          if (!viewmodel.useSystemTheme)
            SwitchListTile(
              title: Text(tr('dark_mode')),
              subtitle: Text(tr('dark_mode_desc')),
              value: viewmodel.useDarkMode,
              onChanged: (value) => viewmodel.setUseDarkMode(value),
            ),
        ],
      ),
    );
  }

  /// 构建布局设置
  Widget _buildLayoutSettings(BuildContext context, CustomSettingsViewModel viewmodel) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: const Icon(Icons.view_quilt),
        title: Text(tr('layout_settings')),
        children: [
          SwitchListTile(
            title: Text(tr('compact_layout')),
            subtitle: Text(tr('compact_layout_desc')),
            value: viewmodel.compactLayout,
            onChanged: (value) => viewmodel.setCompactLayout(value),
          ),
          ListTile(
            title: Text(tr('cards_per_row')),
            subtitle: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 4,
              ),
              child: Slider(
                value: viewmodel.cardsPerRow.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                label: viewmodel.cardsPerRow.toString(),
                onChanged: (value) => viewmodel.setCardsPerRow(value.toInt()),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(tr('show_labels')),
            subtitle: Text(tr('show_labels_desc')),
            value: viewmodel.showLabels,
            onChanged: (value) => viewmodel.setShowLabels(value),
          ),
        ],
      ),
    );
  }

  /// 构建可访问性设置
  Widget _buildAccessibilitySettings(BuildContext context, CustomSettingsViewModel viewmodel) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: const Icon(Icons.accessibility),
        title: Text(tr('accessibility_settings')),
        children: [
          ListTile(
            title: Text(tr('text_scale_factor')),
            subtitle: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 4,
              ),
              child: Slider(
                value: viewmodel.textScaleFactor,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                label: viewmodel.textScaleFactor.toStringAsFixed(1),
                onChanged: (value) => viewmodel.setTextScaleFactor(value),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(tr('high_contrast')),
            subtitle: Text(tr('high_contrast_desc')),
            value: viewmodel.highContrast,
            onChanged: (value) => viewmodel.setHighContrast(value),
          ),
          ListTile(
            title: Text(tr('animation_speed')),
            subtitle: DropdownButton<int>(
              value: viewmodel.animationSpeed,
              isExpanded: true,
              underline: Container(),
              onChanged: (value) {
                if (value != null) {
                  viewmodel.setAnimationSpeed(value);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(tr('animation_disabled')),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text(tr('animation_normal')),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(tr('animation_slow')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建网络设置
  Widget _buildNetworkSettings(BuildContext context, CustomSettingsViewModel viewmodel) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: const Icon(Icons.network_check),
        title: Text(tr('network_settings')),
        children: [
          ListTile(
            title: Text(tr('connection_timeout')),
            subtitle: Text('${viewmodel.connectionTimeout} ${tr('seconds')}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: viewmodel.connectionTimeout > 5
                      ? () => viewmodel.setConnectionTimeout(viewmodel.connectionTimeout - 5)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => viewmodel.setConnectionTimeout(viewmodel.connectionTimeout + 5),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(tr('max_retries')),
            subtitle: Text('${viewmodel.maxRetries}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: viewmodel.maxRetries > 0
                      ? () => viewmodel.setMaxRetries(viewmodel.maxRetries - 1)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => viewmodel.setMaxRetries(viewmodel.maxRetries + 1),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: Text(tr('auto_retry')),
            subtitle: Text(tr('auto_retry_desc')),
            value: viewmodel.autoRetry,
            onChanged: (value) => viewmodel.setAutoRetry(value),
          ),
        ],
      ),
    );
  }

  /// 构建性能设置
  Widget _buildPerformanceSettings(BuildContext context, CustomSettingsViewModel viewmodel) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: const Icon(Icons.speed),
        title: Text(tr('performance_settings')),
        children: [
          SwitchListTile(
            title: Text(tr('low_memory_mode')),
            subtitle: Text(tr('low_memory_mode_desc')),
            value: viewmodel.lowMemoryMode,
            onChanged: (value) => viewmodel.setLowMemoryMode(value),
          ),
          ListTile(
            title: Text(tr('max_history_entries')),
            subtitle: Text('${viewmodel.maxHistoryEntries}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: viewmodel.maxHistoryEntries > 50
                      ? () => viewmodel.setMaxHistoryEntries(viewmodel.maxHistoryEntries - 50)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => viewmodel.setMaxHistoryEntries(viewmodel.maxHistoryEntries + 50),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(tr('max_cache_size')),
            subtitle: Text('${viewmodel.maxCacheSize} MB'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: viewmodel.maxCacheSize > 100
                      ? () => viewmodel.setMaxCacheSize(viewmodel.maxCacheSize - 100)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => viewmodel.setMaxCacheSize(viewmodel.maxCacheSize + 100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context, CustomSettingsViewModel viewmodel) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('settings_actions'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _exportSettings(context, viewmodel),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save),
                      Text(tr('export_settings')),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _importSettings(context, viewmodel),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.file_upload),
                      Text(tr('import_settings')),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _resetSettings(context, viewmodel),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restore),
                      Text(tr('reset_settings')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 显示颜色选择器
  void _showColorPicker(
      BuildContext context, Color currentColor, Function(Color) onColorChanged, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color pickerColor = currentColor;
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(tr('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(tr('select')),
              onPressed: () {
                onColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// 导出设置
  void _exportSettings(BuildContext context, CustomSettingsViewModel viewmodel) async {
    final settings = viewmodel.exportSettingsToJson();

    if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台：复制到剪贴板
      await Clipboard.setData(ClipboardData(text: settings));
      if (!context.mounted) return;
      showInfoBar(context, tr('settings_copied_to_clipboard'));
    } else {
      // 桌面平台：保存文件
      final result = await FilePicker.platform.saveFile(
        fileName: 'nai_settings.json',
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(settings);
        if (!context.mounted) return;
        showInfoBar(context, tr('settings_exported'));
      }
    }
  }

  /// 导入设置
  void _importSettings(BuildContext context, CustomSettingsViewModel viewmodel) async {
    String? settingsJson;

    if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台：从剪贴板读取
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      settingsJson = clipboardData?.text;
    } else {
      // 桌面平台：选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        settingsJson = await file.readAsString();
      }
    }

    if (settingsJson != null && settingsJson.isNotEmpty) {
      try {
        await viewmodel.importSettingsFromJson(settingsJson);
        if (!context.mounted) return;
        showInfoBar(context, tr('settings_imported'));
      } catch (e) {
        if (!context.mounted) return;
        showErrorBar(context, tr('invalid_settings_file'));
      }
    }
  }

  /// 重置设置
  void _resetSettings(BuildContext context, CustomSettingsViewModel viewmodel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('reset_settings')),
        content: Text(tr('reset_settings_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await viewmodel.resetAllSettings();
              if (!context.mounted) return;
              showInfoBar(context, tr('settings_reset'));
            },
            child: Text(
              tr('reset'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
