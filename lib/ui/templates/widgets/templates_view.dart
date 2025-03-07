import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/data/models/template_model.dart';
import 'package:nai_casrand/ui/core/utils/flushbar.dart';
import 'package:nai_casrand/ui/templates/view_models/templates_viewmodel.dart';
import 'package:nai_casrand/ui/templates/widgets/create_template_dialog.dart';
import 'package:nai_casrand/ui/templates/widgets/import_template_dialog.dart';
import 'package:nai_casrand/ui/templates/widgets/template_card.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

/// 模板页面
class TemplatesView extends StatelessWidget {
  final TemplatesViewModel viewmodel;
  
  const TemplatesView({super.key, required this.viewmodel});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewmodel,
      child: Consumer<TemplatesViewModel>(
        builder: (context, viewmodel, child) {
          return Scaffold(
            appBar: _buildAppBar(context, viewmodel),
            body: _buildBody(context, viewmodel),
            floatingActionButton: _buildFloatingActionButton(context, viewmodel),
          );
        },
      ),
    );
  }
  
  /// 构建应用栏
  AppBar _buildAppBar(BuildContext context, TemplatesViewModel viewmodel) {
    return AppBar(
      title: Text(tr('templates')),
      actions: [
        // 搜索按钮
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            _showSearchDialog(context, viewmodel);
          },
        ),
        // 筛选按钮
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            _showFilterDialog(context, viewmodel);
          },
        ),
        // 收藏筛选按钮
        IconButton(
          icon: Icon(viewmodel.showOnlyFavorites 
              ? Icons.favorite 
              : Icons.favorite_border),
          onPressed: () {
            viewmodel.toggleShowOnlyFavorites();
          },
        ),
      ],
    );
  }
  
  /// 构建页面主体
  Widget _buildBody(BuildContext context, TemplatesViewModel viewmodel) {
    if (viewmodel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (viewmodel.templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              viewmodel.showOnlyFavorites
                  ? tr('no_favorite_templates')
                  : tr('no_templates_found'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (viewmodel.showOnlyFavorites) {
                  viewmodel.toggleShowOnlyFavorites();
                } else {
                  _showCreateTemplateDialog(context, viewmodel);
                }
              },
              child: Text(
                viewmodel.showOnlyFavorites
                    ? tr('show_all_templates')
                    : tr('create_template'),
              ),
            ),
          ],
        ),
      );
    }
    
    // 使用网格视图显示模板
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: viewmodel.templates.length,
        itemBuilder: (context, index) {
          final template = viewmodel.templates[index];
          return TemplateCard(
            template: template,
            onTap: () {
              _showTemplateOptionsDialog(context, viewmodel, template);
            },
            onFavoriteToggle: () {
              viewmodel.toggleFavorite(template);
            },
          );
        },
      ),
    );
  }
  
  /// 构建浮动操作按钮
  Widget _buildFloatingActionButton(BuildContext context, TemplatesViewModel viewmodel) {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: const IconThemeData(size: 22.0),
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      tooltip: tr('options'),
      heroTag: 'template-speed-dial',
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 8.0,
      shape: const CircleBorder(),
      children: [
        // 创建模板
        SpeedDialChild(
          child: const Icon(Icons.add),
          backgroundColor: Colors.green,
          label: tr('create_template'),
          labelStyle: const TextStyle(fontSize: 16.0),
          onTap: () => _showCreateTemplateDialog(context, viewmodel),
        ),
        // 导入模板
        SpeedDialChild(
          child: const Icon(Icons.file_download),
          backgroundColor: Colors.blue,
          label: tr('import_template'),
          labelStyle: const TextStyle(fontSize: 16.0),
          onTap: () => _showImportTemplateDialog(context, viewmodel),
        ),
      ],
    );
  }
  
  /// 显示搜索对话框
  void _showSearchDialog(BuildContext context, TemplatesViewModel viewmodel) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: viewmodel.searchQuery);
        return AlertDialog(
          title: Text(tr('search_templates')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: tr('enter_search_terms'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) {
              viewmodel.setSearchQuery(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                viewmodel.setSearchQuery(controller.text);
                Navigator.of(context).pop();
              },
              child: Text(tr('search')),
            ),
          ],
        );
      },
    );
  }
  
  /// 显示筛选对话框
  void _showFilterDialog(BuildContext context, TemplatesViewModel viewmodel) {
    showDialog(
      context: context,
      builder: (context) {
        TemplateType? selectedType = viewmodel.selectedType;
        return AlertDialog(
          title: Text(tr('filter_templates')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...TemplateType.values.map((type) {
                return RadioListTile<TemplateType>(
                  title: Text(tr('template_type_${type.name}')),
                  value: type,
                  groupValue: selectedType,
                  onChanged: (value) {
                    selectedType = value;
                  },
                );
              }).toList(),
              // 添加"全部"选项
              RadioListTile<TemplateType?>(
                title: Text(tr('all_types')),
                value: null,
                groupValue: selectedType,
                onChanged: (value) {
                  selectedType = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                viewmodel.setSelectedType(selectedType);
                Navigator.of(context).pop();
              },
              child: Text(tr('apply')),
            ),
          ],
        );
      },
    );
  }
  
  /// 显示模板选项对话框
  void _showTemplateOptionsDialog(
      BuildContext context, TemplatesViewModel viewmodel, Template template) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(template.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (template.imageB64.isNotEmpty)
                Image.memory(
                  base64Decode(template.imageB64),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text(
                template.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                tr('template_type_${template.type.name}'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                tr('created_at', namedArgs: {
                  'date': DateFormat.yMMMd().format(template.createdAt)
                }),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            // 删除按钮（内置模板不可删除）
            if (!template.isBuiltIn)
              TextButton(
                onPressed: () async {
                  final result = await viewmodel.deleteTemplate(template.id);
                  if (!context.mounted) return;
                  
                  Navigator.of(context).pop();
                  
                  if (result) {
                    showInfoBar(context, tr('template_deleted'));
                  } else {
                    showErrorBar(context, tr('delete_template_failed'));
                  }
                },
                child: Text(
                  tr('delete'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            // 分享按钮
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                final shareCode = viewmodel.getShareCode(template);
                Share.share(
                  tr('share_template_message', namedArgs: {
                    'name': template.name, 
                    'code': shareCode
                  }),
                  subject: tr('share_template_subject'),
                );
              },
              child: Text(tr('share')),
            ),
            // 应用按钮
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyTemplate(context, viewmodel, template);
              },
              child: Text(tr('apply')),
            ),
          ],
        );
      },
    );
  }
  
  /// 显示创建模板对话框
  void _showCreateTemplateDialog(BuildContext context, TemplatesViewModel viewmodel) {
    showDialog(
      context: context,
      builder: (context) {
        return CreateTemplateDialog(
          onCreateTemplate: (name, description, type) async {
            Navigator.of(context).pop();
            
            final payloadConfig = GetIt.instance<PayloadConfig>();
            final template = await viewmodel.createTemplateFromCurrentConfig(
              name: name,
              description: description,
              type: type,
              payloadConfig: payloadConfig,
            );
            
            if (!context.mounted) return;
            
            if (template != null) {
              showInfoBar(context, tr('template_created'));
            } else {
              showErrorBar(context, tr('create_template_failed'));
            }
          },
        );
      },
    );
  }
  
  /// 显示导入模板对话框
  void _showImportTemplateDialog(BuildContext context, TemplatesViewModel viewmodel) {
    showDialog(
      context: context,
      builder: (context) {
        return ImportTemplateDialog(
          onImportTemplate: (shareCode) async {
            Navigator.of(context).pop();
            
            final result = await viewmodel.importFromShareCode(shareCode);
            
            if (!context.mounted) return;
            
            if (result) {
              showInfoBar(context, tr('template_imported'));
            } else {
              showErrorBar(context, tr('import_template_failed'));
            }
          },
        );
      },
    );
  }
  
  /// 应用模板
  void _applyTemplate(BuildContext context, TemplatesViewModel viewmodel, Template template) {
    final payloadConfig = GetIt.instance<PayloadConfig>();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('apply_template')),
          content: Text(tr('apply_template_confirm')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                await viewmodel.applyTemplate(template, payloadConfig);
                
                if (!context.mounted) return;
                
                showInfoBar(context, tr('template_applied'));
              },
              child: Text(tr('apply')),
            ),
          ],
        );
      },
    );
  }
}
