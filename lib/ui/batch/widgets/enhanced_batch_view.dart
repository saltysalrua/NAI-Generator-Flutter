import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nai_casrand/data/models/enhanced_batch_config.dart';
import 'package:nai_casrand/ui/batch/view_models/enhanced_batch_viewmodel.dart';
import 'package:nai_casrand/ui/batch/widgets/batch_variable_dialog.dart';
import 'package:nai_casrand/ui/core/utils/flushbar.dart';
import 'package:nai_casrand/ui/generation_page/widgets/info_card.dart';
import 'package:provider/provider.dart';
import 'package:date_time_picker/date_time_picker.dart';

/// 增强型批处理视图
class EnhancedBatchView extends StatelessWidget {
  final EnhancedBatchViewModel viewmodel;

  const EnhancedBatchView({Key? key, required this.viewmodel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewmodel,
      child: Consumer<EnhancedBatchViewModel>(
        builder: (context, viewmodel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(tr('enhanced_batch')),
              actions: [
                // 保存配置按钮
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveBatchConfig(context, viewmodel),
                  tooltip: tr('save_batch_config'),
                ),
                // 加载配置按钮
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () => _showLoadConfigDialog(context, viewmodel),
                  tooltip: tr('load_batch_config'),
                ),
              ],
            ),
            body: _buildBody(context, viewmodel),
            floatingActionButton: _buildFloatingActionButton(context, viewmodel),
          );
        },
      ),
    );
  }

  /// 构建页面主体
  Widget _buildBody(BuildContext context, EnhancedBatchViewModel viewmodel) {
    if (viewmodel.isRunning) {
      return _buildProgressView(context, viewmodel);
    }
    
    if (viewmodel.results.isNotEmpty) {
      return _buildResultsView(context, viewmodel);
    }
    
    return _buildConfigView(context, viewmodel);
  }

  /// 构建配置视图
  Widget _buildConfigView(BuildContext context, EnhancedBatchViewModel viewmodel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            tr('batch_variables'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            tr('batch_variables_hint'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          // 变量列表
          if (viewmodel.variables.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    tr('no_variables_added'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            )
          else
            _buildVariableList(context, viewmodel),
          
          const SizedBox(height: 16),
          
          // 添加变量按钮
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(tr('add_variable')),
              onPressed: () => _showAddVariableDialog(context, viewmodel),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 批处理选项
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('batch_options'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // 计划时间
                  Row(
                    children: [
                      Expanded(
                        child: Text(tr('schedule_time')),
                      ),
                      ElevatedButton(
                        onPressed: viewmodel.scheduledTime != null
                            ? () => viewmodel.setScheduledTime(null)
                            : null,
                        child: Text(tr('clear')),
                      ),
                    ],
                  ),
                  DateTimePicker(
                    type: DateTimePickerType.dateTime,
                    initialValue: viewmodel.scheduledTime?.toString(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    dateLabelText: tr('date'),
                    timeLabelText: tr('time'),
                    onChanged: (val) => viewmodel.setScheduledTime(
                      val.isNotEmpty ? DateTime.parse(val) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 其他选项
                  SwitchListTile(
                    title: Text(tr('compare_results')),
                    subtitle: Text(tr('compare_results_hint')),
                    value: viewmodel.compareResults,
                    onChanged: (value) => viewmodel.setCompareResults(value),
                  ),
                  SwitchListTile(
                    title: Text(tr('save_as_grid')),
                    subtitle: Text(tr('save_as_grid_hint')),
                    value: viewmodel.saveAsGrid,
                    onChanged: (value) => viewmodel.setSaveAsGrid(value),
                  ),
                  SwitchListTile(
                    title: Text(tr('stop_on_error')),
                    subtitle: Text(tr('stop_on_error_hint')),
                    value: viewmodel.stopOnError,
                    onChanged: (value) => viewmodel.setStopOnError(value),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 执行按钮
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(tr('execute_batch')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: viewmodel.variables.isEmpty ? null : () => viewmodel.executeBatch(),
            ),
          ),
          
          // 错误信息
          if (viewmodel.error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('error'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(viewmodel.error),
                    ],
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 构建变量列表
  Widget _buildVariableList(BuildContext context, EnhancedBatchViewModel viewmodel) {
    return Column(
      children: viewmodel.variables.asMap().entries.map((entry) {
        final index = entry.key;
        final variable = entry.value;
        
        return Card(
          child: ListTile(
            leading: _getIconForVariableType(variable.type),
            title: Text(_getVariableTitle(variable)),
            subtitle: Text(_getVariableDescription(variable)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditVariableDialog(context, viewmodel, index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => viewmodel.removeVariable(index),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建进度视图
  Widget _buildProgressView(BuildContext context, EnhancedBatchViewModel viewmodel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tr('batch_processing'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(viewmodel.progressMessage),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: viewmodel.totalProgress > 0
                  ? viewmodel.currentProgress / viewmodel.totalProgress
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              '${viewmodel.currentProgress} / ${viewmodel.totalProgress}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => viewmodel.cancelBatch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(tr('cancel')),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建结果视图
  Widget _buildResultsView(BuildContext context, EnhancedBatchViewModel viewmodel) {
    return Column(
      children: [
        // 返回按钮
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: Text(tr('back_to_config')),
                onPressed: () {
                  // 清空结果，返回配置视图
                  viewmodel.results.clear();
                  viewmodel.error = '';
                  viewmodel.notifyListeners();
                },
              ),
              const Spacer(),
              Text(
                '${viewmodel.results.length} ${tr('results')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        
        // 结果网格
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: viewmodel.results.length,
            itemBuilder: (context, index) {
              final result = viewmodel.results[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InfoCard(
                  command: CommandStub(result),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建浮动操作按钮
  Widget _buildFloatingActionButton(BuildContext context, EnhancedBatchViewModel viewmodel) {
    if (viewmodel.isRunning || viewmodel.results.isNotEmpty) {
      return Container(); // 运行中或显示结果时不显示FAB
    }
    
    return FloatingActionButton(
      onPressed: () => _showAddVariableDialog(context, viewmodel),
      tooltip: tr('add_variable'),
      child: const Icon(Icons.add),
    );
  }

  /// 显示添加变量对话框
  void _showAddVariableDialog(BuildContext context, EnhancedBatchViewModel viewmodel) {
    showDialog(
      context: context,
      builder: (context) => BatchVariableDialog(
        onSave: (variable) {
          viewmodel.addVariable(variable);
        },
      ),
    );
  }

  /// 显示编辑变量对话框
  void _showEditVariableDialog(
      BuildContext context, EnhancedBatchViewModel viewmodel, int index) {
    showDialog(
      context: context,
      builder: (context) => BatchVariableDialog(
        initialVariable: viewmodel.variables[index],
        onSave: (variable) {
          viewmodel.updateVariable(index, variable);
        },
      ),
    );
  }

  /// 保存批处理配置
  void _saveBatchConfig(BuildContext context, EnhancedBatchViewModel viewmodel) async {
    if (viewmodel.variables.isEmpty) {
      showWarningBar(context, tr('no_variables_to_save'));
      return;
    }
    
    final id = await viewmodel.saveBatchConfig();
    
    if (!context.mounted) return;
    
    showInfoBar(context, tr('batch_config_saved', namedArgs: {'id': id}));
  }

  /// 显示加载配置对话框
  void _showLoadConfigDialog(BuildContext context, EnhancedBatchViewModel viewmodel) async {
    await viewmodel.init(); // 确保配置已加载
    
    if (!context.mounted) return;
    
    if (viewmodel.savedConfigs.isEmpty) {
      showWarningBar(context, tr('no_saved_configs'));
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('load_batch_config')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: viewmodel.savedConfigs.length,
            itemBuilder: (context, index) {
              final config = viewmodel.savedConfigs[index];
              final varTypes = config.variables
                  .map((v) => _getVariableTypeName(v.type))
                  .join(', ');
              
              return ListTile(
                title: Text('${tr('variables')}: ${config.variables.length}'),
                subtitle: Text(varTypes),
                trailing: Text(
                  config.scheduledTime != null
                      ? DateFormat.yMMMd().add_Hm().format(config.scheduledTime!)
                      : tr('no_schedule'),
                ),
                onTap: () {
                  viewmodel.loadBatchConfig(config);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
        ],
      ),
    );
  }

  /// 获取变量类型的图标
  Icon _getIconForVariableType(BatchVariableType type) {
    switch (type) {
      case BatchVariableType.scale:
        return const Icon(Icons.scale);
      case BatchVariableType.steps:
        return const Icon(Icons.linear_scale);
      case BatchVariableType.cfgRescale:
        return const Icon(Icons.tune);
      case BatchVariableType.seed:
        return const Icon(Icons.casino);
      case BatchVariableType.prompt:
        return const Icon(Icons.text_fields);
      case BatchVariableType.negativePrompt:
        return const Icon(Icons.do_not_disturb_alt);
      case BatchVariableType.width:
        return const Icon(Icons.width_normal);
      case BatchVariableType.height:
        return const Icon(Icons.height);
    }
  }

  /// 获取变量类型名称
  String _getVariableTypeName(BatchVariableType type) {
    switch (type) {
      case BatchVariableType.scale:
        return tr('scale');
      case BatchVariableType.steps:
        return tr('steps');
      case BatchVariableType.cfgRescale:
        return tr('cfg_rescale');
      case BatchVariableType.seed:
        return tr('seed');
      case BatchVariableType.prompt:
        return tr('prompt');
      case BatchVariableType.negativePrompt:
        return tr('negative_prompt');
      case BatchVariableType.width:
        return tr('width');
      case BatchVariableType.height:
        return tr('height');
    }
  }

  /// 获取变量标题
  String _getVariableTitle(BatchVariableRange variable) {
    return _getVariableTypeName(variable.type) +
        (variable.useLongitudinal ? ' (${tr('longitudinal')})' : ' (${tr('transverse')})');
  }

  /// 获取变量描述
  String _getVariableDescription(BatchVariableRange variable) {
    if (variable.type == BatchVariableType.prompt ||
        variable.type == BatchVariableType.negativePrompt) {
      if (variable.startValue is List) {
        final promptCount = (variable.startValue as List).length;
        return tr('prompt_variants', namedArgs: {'count': promptCount.toString()});
      }
      return tr('prompt_value');
    } else {
      return '${variable.startValue} → ${variable.endValue} (${tr('steps')}: ${variable.steps})';
    }
  }
}

/// 命令存根类，用于InfoCard
class CommandStub extends ChangeNotifier {
  final InfoCardContent value;
  final ValueNotifier<bool> isExecuting = ValueNotifier(false);
  
  CommandStub(this.value);
}
