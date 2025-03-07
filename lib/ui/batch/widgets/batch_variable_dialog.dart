import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nai_casrand/data/models/enhanced_batch_config.dart';

/// 批处理变量编辑对话框
class BatchVariableDialog extends StatefulWidget {
  final BatchVariableRange? initialVariable;
  final Function(BatchVariableRange) onSave;

  const BatchVariableDialog({
    Key? key,
    this.initialVariable,
    required this.onSave,
  }) : super(key: key);

  @override
  State<BatchVariableDialog> createState() => _BatchVariableDialogState();
}

class _BatchVariableDialogState extends State<BatchVariableDialog> {
  late BatchVariableType _type;
  dynamic _startValue;
  dynamic _endValue;
  int _steps = 5;
  bool _useLongitudinal = true;
  
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final List<TextEditingController> _promptControllers = [];
  
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    
    // 初始化值
    _type = widget.initialVariable?.type ?? BatchVariableType.scale;
    _startValue = widget.initialVariable?.startValue ?? 5.0;
    _endValue = widget.initialVariable?.endValue ?? 10.0;
    _steps = widget.initialVariable?.steps ?? 5;
    _useLongitudinal = widget.initialVariable?.useLongitudinal ?? true;
    
    _stepsController.text = _steps.toString();
    
    _updateControllers();
    
    _startController.addListener(_validateForm);
    _endController.addListener(_validateForm);
    _stepsController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _startController.removeListener(_validateForm);
    _endController.removeListener(_validateForm);
    _stepsController.removeListener(_validateForm);
    
    _startController.dispose();
    _endController.dispose();
    _stepsController.dispose();
    
    for (var controller in _promptControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }
  
  /// 更新控制器
  void _updateControllers() {
    // 清空现有的提示词控制器
    for (var controller in _promptControllers) {
      controller.dispose();
    }
    _promptControllers.clear();
    
    if (_type == BatchVariableType.prompt || _type == BatchVariableType.negativePrompt) {
      // 如果是提示词变量，创建多个控制器
      if (_startValue is List) {
        for (var prompt in _startValue) {
          final controller = TextEditingController(text: prompt);
          controller.addListener(_validateForm);
          _promptControllers.add(controller);
        }
      } else {
        // 默认创建步数个控制器
        for (var i = 0; i < _steps; i++) {
          final controller = TextEditingController();
          controller.addListener(_validateForm);
          _promptControllers.add(controller);
        }
        
        // 将_startValue设置为第一个控制器的值
        if (_startValue is String && _promptControllers.isNotEmpty) {
          _promptControllers.first.text = _startValue;
        }
      }
    } else {
      // 对于其他变量类型，使用普通控制器
      _startController.text = _startValue.toString();
      _endController.text = _endValue.toString();
    }
    
    _validateForm();
  }
  
  /// 验证表单
  void _validateForm() {
    setState(() {
      if (_type == BatchVariableType.prompt || _type == BatchVariableType.negativePrompt) {
        // 提示词变量至少需要一个非空值
        _isValid = _promptControllers.any((controller) => controller.text.trim().isNotEmpty);
      } else {
        // 其他变量需要合法的起始值和结束值
        bool startValid = false;
        bool endValid = false;
        bool stepsValid = false;
        
        try {
          switch (_type) {
            case BatchVariableType.scale:
            case BatchVariableType.cfgRescale:
              startValid = double.tryParse(_startController.text) != null;
              endValid = double.tryParse(_endController.text) != null;
              break;
            case BatchVariableType.steps:
            case BatchVariableType.seed:
            case BatchVariableType.width:
            case BatchVariableType.height:
              startValid = int.tryParse(_startController.text) != null;
              endValid = int.tryParse(_endController.text) != null;
              break;
            default:
              startValid = _startController.text.isNotEmpty;
              endValid = _endController.text.isNotEmpty;
          }
          
          stepsValid = int.tryParse(_stepsController.text) != null &&
                      int.parse(_stepsController.text) > 0;
          
          _isValid = startValid && endValid && stepsValid;
        } catch (e) {
          _isValid = false;
        }
      }
    });
  }
  
  /// 保存变量
  void _saveVariable() {
    if (!_isValid) return;
    
    dynamic startValue;
    dynamic endValue;
    
    if (_type == BatchVariableType.prompt || _type == BatchVariableType.negativePrompt) {
      // 提示词变量收集所有非空的提示词
      startValue = _promptControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      endValue = startValue;
    } else {
      // 其他变量解析起始值和结束值
      switch (_type) {
        case BatchVariableType.scale:
        case BatchVariableType.cfgRescale:
          startValue = double.parse(_startController.text);
          endValue = double.parse(_endController.text);
          break;
        case BatchVariableType.steps:
        case BatchVariableType.seed:
        case BatchVariableType.width:
        case BatchVariableType.height:
          startValue = int.parse(_startController.text);
          endValue = int.parse(_endController.text);
          break;
        default:
          startValue = _startController.text;
          endValue = _endController.text;
      }
    }
    
    final variable = BatchVariableRange(
      type: _type,
      startValue: startValue,
      endValue: endValue,
      steps: int.parse(_stepsController.text),
      useLongitudinal: _useLongitudinal,
    );
    
    widget.onSave(variable);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                widget.initialVariable == null
                    ? tr('add_batch_variable')
                    : tr('edit_batch_variable'),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            
            // 变量类型
            Text(
              tr('variable_type'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildVariableTypeSelector(),
            
            const SizedBox(height: 16),
            
            // 变量方向
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('variable_direction'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: _useLongitudinal,
                  onChanged: (value) {
                    setState(() {
                      _useLongitudinal = value;
                    });
                  },
                ),
                Text(
                  _useLongitudinal ? tr('longitudinal') : tr('transverse'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 步数
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('steps'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _stepsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _steps = int.parse(value);
                          // 如果是提示词类型，更新控制器数量
                          if (_type == BatchVariableType.prompt ||
                              _type == BatchVariableType.negativePrompt) {
                            _updateControllers();
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 变量值输入
            _buildVariableValueInput(),
            
            const SizedBox(height: 16),
            
            // 按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('cancel')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValid ? _saveVariable : null,
                  child: Text(tr('save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建变量类型选择器
  Widget _buildVariableTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BatchVariableType.values.map((type) {
        return ChoiceChip(
          label: Text(_getTypeLabel(type)),
          selected: _type == type,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _type = type;
                // 重置值
                switch (type) {
                  case BatchVariableType.scale:
                    _startValue = 5.0;
                    _endValue = 10.0;
                    break;
                  case BatchVariableType.steps:
                    _startValue = 20;
                    _endValue = 28;
                    break;
                  case BatchVariableType.cfgRescale:
                    _startValue = 0.0;
                    _endValue = 1.0;
                    break;
                  case BatchVariableType.seed:
                    _startValue = -1; // 随机种子
                    _endValue = -1;
                    break;
                  case BatchVariableType.prompt:
                  case BatchVariableType.negativePrompt:
                    _startValue = List.filled(_steps, "");
                    _endValue = _startValue;
                    break;
                  case BatchVariableType.width:
                    _startValue = 512;
                    _endValue = 1024;
                    break;
                  case BatchVariableType.height:
                    _startValue = 512;
                    _endValue = 1024;
                    break;
                }
                _updateControllers();
              });
            }
          },
        );
      }).toList(),
    );
  }
  
  /// 构建变量值输入控件
  Widget _buildVariableValueInput() {
    if (_type == BatchVariableType.prompt || _type == BatchVariableType.negativePrompt) {
      // 提示词变量的多个文本框
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('prompts'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._promptControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('${index + 1}:'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: tr('enter_prompt_variant'),
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    } else {
      // 其他变量类型的开始/结束值输入
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('value_range'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('start_value')),
                    TextField(
                      controller: _startController,
                      keyboardType: _getKeyboardTypeForVariableType(),
                      inputFormatters: _getInputFormattersForVariableType(),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('end_value')),
                    TextField(
                      controller: _endController,
                      keyboardType: _getKeyboardTypeForVariableType(),
                      inputFormatters: _getInputFormattersForVariableType(),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 种子值的说明
          if (_type == BatchVariableType.seed)
            Text(
              tr('random_seed_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      );
    }
  }
  
  /// 获取变量类型的标签
  String _getTypeLabel(BatchVariableType type) {
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
  
  /// 获取变量类型对应的键盘类型
  TextInputType _getKeyboardTypeForVariableType() {
    switch (_type) {
      case BatchVariableType.scale:
      case BatchVariableType.cfgRescale:
        return const TextInputType.numberWithOptions(decimal: true);
      case BatchVariableType.steps:
      case BatchVariableType.seed:
      case BatchVariableType.width:
      case BatchVariableType.height:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }
  
  /// 获取变量类型对应的输入格式化器
  List<TextInputFormatter> _getInputFormattersForVariableType() {
    switch (_type) {
      case BatchVariableType.scale:
      case BatchVariableType.cfgRescale:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ];
      case BatchVariableType.steps:
      case BatchVariableType.seed:
      case BatchVariableType.width:
      case BatchVariableType.height:
        return [
          FilteringTextInputFormatter.digitsOnly,
        ];
      default:
        return [];
    }
  }
}
