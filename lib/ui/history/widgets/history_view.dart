import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/models/history_entry.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/ui/core/utils/flushbar.dart';
import 'package:nai_casrand/ui/history/view_models/history_viewmodel.dart';
import 'package:provider/provider.dart';

/// 历史记录页面
class HistoryView extends StatelessWidget {
  final HistoryViewModel viewmodel;
  
  const HistoryView({super.key, required this.viewmodel});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewmodel,
      child: Consumer<HistoryViewModel>(
        builder: (context, viewmodel, child) {
          return Scaffold(
            appBar: _buildAppBar(context, viewmodel),
            body: _buildBody(context, viewmodel),
          );
        },
      ),
    );
  }
  
  /// 构建应用栏
  AppBar _buildAppBar(BuildContext context, HistoryViewModel viewmodel) {
    return AppBar(
      title: Text(tr('history')),
      actions: [
        // 搜索按钮
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            _showSearchDialog(context, viewmodel);
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
        // 清空历史记录按钮
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: () {
            _showClearHistoryDialog(context, viewmodel);
          },
        ),
      ],
    );
  }
  
  /// 构建页面主体
  Widget _buildBody(BuildContext context, HistoryViewModel viewmodel) {
    if (viewmodel.historyEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              viewmodel.showOnlyFavorites
                  ? tr('no_favorite_history')
                  : tr('no_history_records'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (viewmodel.showOnlyFavorites)
              ElevatedButton(
                onPressed: () {
                  viewmodel.toggleShowOnlyFavorites();
                },
                child: Text(tr('show_all_history')),
              ),
          ],
        ),
      );
    }
    
    // 使用网格视图显示历史记录
    return GridView.builder(
      controller: viewmodel.scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: viewmodel.historyEntries.length + (viewmodel.hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == viewmodel.historyEntries.length) {
          // 加载更多指示器
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final entry = viewmodel.historyEntries[index];
        return _buildHistoryCard(context, viewmodel, entry);
      },
    );
  }
  
  /// 构建历史记录卡片
  Widget _buildHistoryCard(BuildContext context, HistoryViewModel viewmodel, HistoryEntry entry) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showHistoryDetailsDialog(context, viewmodel, entry);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片
            Stack(
              children: [
                if (entry.thumbnailB64 != null && entry.thumbnailB64!.isNotEmpty)
                  Image.memory(
                    base64Decode(entry.thumbnailB64!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  Image.file(
                    File(entry.imageFilePath),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                // 收藏按钮
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: entry.isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      onPressed: () {
                        viewmodel.toggleFavorite(entry);
                      },
                    ),
                  ),
                ),
              ],
            ),
            // 信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 日期
                    Text(
                      DateFormat.yMMMd().add_Hm().format(entry.timestamp),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 提示词
                    Expanded(
                      child: Text(
                        entry.promptComment,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 显示搜索对话框
  void _showSearchDialog(BuildContext context, HistoryViewModel viewmodel) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: viewmodel.searchQuery);
        return AlertDialog(
          title: Text(tr('search_history')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: tr('enter_search_terms'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) {
              // 在用户输入时暂不触发搜索
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
  
  /// 显示清空历史记录对话框
  void _showClearHistoryDialog(BuildContext context, HistoryViewModel viewmodel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('clear_history')),
          content: Text(tr('clear_history_confirm')),
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
                
                final result = await viewmodel.clearHistory();
                if (!context.mounted) return;
                
                if (result) {
                  showInfoBar(context, tr('history_cleared'));
                } else {
                  showErrorBar(context, tr('clear_history_failed'));
                }
              },
              child: Text(
                tr('clear'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// 显示历史记录详情对话框
  void _showHistoryDetailsDialog(BuildContext context, HistoryViewModel viewmodel, HistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图片
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.file(
                  File(entry.imageFilePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              // 信息
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日期
                      Text(
                        DateFormat.yMMMd().add_Hm().format(entry.timestamp),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 提示词
                      Text(
                        tr('prompt'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.promptComment,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // 负面提示词
                      Text(
                        tr('negative_prompt'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.negativePrompt,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // 参数
                      Text(
                        tr('parameters'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...entry.parameters.entries.map((param) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${param.key}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  param.value.toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              // 按钮
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 删除按钮
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showDeleteHistoryDialog(context, viewmodel, entry);
                      },
                      tooltip: tr('delete'),
                    ),
                    // 收藏按钮
                    IconButton(
                      icon: Icon(
                        entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: entry.isFavorite ? Colors.red : null,
                      ),
                      onPressed: () {
                        viewmodel.toggleFavorite(entry);
                        Navigator.of(context).pop();
                      },
                      tooltip: entry.isFavorite ? tr('unfavorite') : tr('favorite'),
                    ),
                    // 分享按钮
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        Navigator.of(context).pop();
                        viewmodel.shareHistoryEntry(entry);
                      },
                      tooltip: tr('share'),
                    ),
                    // 应用配置按钮
                    IconButton(
                      icon: const Icon(Icons.settings_applications),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showApplyConfigDialog(context, viewmodel, entry);
                      },
                      tooltip: tr('apply_configuration'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 显示删除历史记录对话框
  void _showDeleteHistoryDialog(BuildContext context, HistoryViewModel viewmodel, HistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('delete_history')),
          content: Text(tr('delete_history_confirm')),
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
                
                final result = await viewmodel.deleteHistoryEntry(entry.id);
                if (!context.mounted) return;
                
                if (result) {
                  showInfoBar(context, tr('history_deleted'));
                } else {
                  showErrorBar(context, tr('delete_history_failed'));
                }
              },
              child: Text(
                tr('delete'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// 显示应用配置对话框
  void _showApplyConfigDialog(BuildContext context, HistoryViewModel viewmodel, HistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('apply_configuration')),
          content: Text(tr('apply_configuration_confirm')),
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
                
                final payloadConfig = GetIt.instance<PayloadConfig>();
                await viewmodel.applyHistoryConfiguration(entry, payloadConfig);
                
                if (!context.mounted) return;
                
                showInfoBar(context, tr('configuration_applied'));
              },
              child: Text(tr('apply')),
            ),
          ],
        );
      },
    );
  }
}
