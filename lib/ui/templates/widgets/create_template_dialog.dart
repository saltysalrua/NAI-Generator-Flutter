import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nai_casrand/data/models/template_model.dart';

/// 创建模板对话框
class CreateTemplateDialog extends StatefulWidget {
  final Function(String, String, TemplateType) onCreateTemplate;

  const CreateTemplateDialog({Key? key, required this.onCreateTemplate}) : super(key: key);

  @override
  State<CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<CreateTemplateDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  TemplateType _selectedType = TemplateType.custom;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _descriptionController.removeListener(_validateForm);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 验证表单是否有效
  void _validateForm() {
    setState(() {
      _isFormValid = _nameController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                tr('create_template'),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            
            // 名称输入框
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: tr('template_name'),
                hintText: tr('enter_template_name'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 描述输入框
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: tr('template_description'),
                hintText: tr('enter_template_description'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // 模板类型选择
            Text(
              tr('template_type'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            
            const SizedBox(height: 8),
            
            _buildTemplateTypeSelector(),
            
            const SizedBox(height: 16),
            
            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('cancel')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isFormValid
                      ? () => widget.onCreateTemplate(
                            _nameController.text.trim(),
                            _descriptionController.text.trim(),
                            _selectedType,
                          )
                      : null,
                  child: Text(tr('create')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建模板类型选择器
  Widget _buildTemplateTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TemplateType.values.map((type) {
        return ChoiceChip(
          label: Text(tr('template_type_${type.name}')),
          selected: _selectedType == type,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedType = type;
              });
            }
          },
          avatar: Icon(_getIconForType(type)),
        );
      }).toList(),
    );
  }

  /// 获取模板类型对应的图标
  IconData _getIconForType(TemplateType type) {
    switch (type) {
      case TemplateType.character:
        return Icons.person;
      case TemplateType.scene:
        return Icons.landscape;
      case TemplateType.style:
        return Icons.brush;
      case TemplateType.custom:
        return Icons.category;
    }
  }
}
