import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/models/template_model.dart';
import 'package:nai_casrand/data/services/prompt_suggestion_service.dart';
import 'package:nai_casrand/ui/core/utils/screen_utils.dart';
import 'package:nai_casrand/ui/core/widgets/advanced_text_field.dart';

/// 提示词标签类型
enum PromptTagType {
  character,  // 角色
  quality,    // 质量
  style,      // 风格
  composition,// 构图
  custom,     // 自定义
}

/// 提示词标签
class PromptTag {
  final String text;
  final PromptTagType type;
  final double weight; // 权重，用于花括号或方括号的数量
  final bool isNegative; // 是否是负面提示词
  
  const PromptTag({
    required this.text,
    required this.type,
    this.weight = 0.0,
    this.isNegative = false,
  });
  
  /// 从原始文本创建标签
  factory PromptTag.fromText(String text, {PromptTagType type = PromptTagType.custom}) {
    // 检查权重标记（花括号或方括号）
    int openBracketCount = 0;
    int closeBracketCount = 0;
    double weight = 0.0;
    bool isNegative = false;
    String cleanText = text;
    
    // 计算左花括号数量 (增强权重)
    while (cleanText.startsWith('{')) {
      openBracketCount++;
      cleanText = cleanText.substring(1);
      weight += 0.1;
    }
    
    // 计算右花括号数量
    while (cleanText.endsWith('}')) {
      closeBracketCount++;
      cleanText = cleanText.substring(0, cleanText.length - 1);
    }
    
    // 检查方括号 (减弱权重)
    if (cleanText.startsWith('[') && cleanText.endsWith(']')) {
      isNegative = true;
      cleanText = cleanText.substring(1, cleanText.length - 1);
      weight = -0.1;
    }
    
    // 确保权重正确
    if (openBracketCount != closeBracketCount) {
      // 括号不匹配，重置权重
      weight = 0.0;
    }
    
    return PromptTag(
      text: cleanText.trim(),
      type: type,
      weight: weight,
      isNegative: isNegative,
    );
  }
  
  /// 转换为带权重的文本
  String toWeightedText() {
    String result = text;
    
    if (isNegative) {
      // 负面标签使用方括号
      return '[$result]';
    }
    
    // 正面标签使用花括号
    if (weight > 0) {
      // 每0.1的权重增加一对花括号
      int bracketPairs = (weight / 0.1).round();
      for (int i = 0; i < bracketPairs; i++) {
        result = '{$result}';
      }
    }
    
    return result;
  }
  
  /// 获取标签颜色
  Color getColor(BuildContext context) {
    switch (type) {
      case PromptTagType.character:
        return Colors.blue;
      case PromptTagType.quality:
        return Colors.green;
      case PromptTagType.style:
        return Colors.purple;
      case PromptTagType.composition:
        return Colors.orange;
      case PromptTagType.custom:
        return isNegative 
            ? Colors.red
            : Colors.grey;
    }
  }
}

/// 提示词标签组件
class PromptTagChip extends StatelessWidget {
  final PromptTag tag;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool isSelected;
  
  const PromptTagChip({
    Key? key,
    required this.tag,
    required this.onDelete,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = tag.getColor(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Chip(
        label: Text(
          tag.text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: color.withOpacity(isSelected ? 0.9 : 0.7),
        deleteIcon: const Icon(
          Icons.close,
          size: 16,
          color: Colors.white,
        ),
        onDeleted: onDelete,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 高级提示词编辑器
class PromptEditor extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final bool isNegative; // 是否为负面提示词编辑器
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final SuggestionType? suggestionType; // 建议类型
  
  const PromptEditor({
    Key? key,
    required this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.maxLines = 5,
    this.isNegative = false,
    this.onChanged,
    this.prefixIcon,
    this.suggestionType,
  }) : super(key: key);

  @override
  State<PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<PromptEditor> {
  final PromptSuggestionService _suggestionService = GetIt.instance<PromptSuggestionService>();
  
  final List<PromptTag> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  
  bool _isTagMode = false; // 是否处于标签模式
  int _selectedTagIndex = -1; // 选中的标签索引
  
  @override
  void initState() {
    super.initState();
    _parsePromptText(widget.controller.text);
    
    // 监听文本变化
    widget.controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }
  
  /// 文本变化处理
  void _onTextChanged() {
    if (!_isTagMode) {
      _parsePromptText(widget.controller.text);
    }
  }
  
  /// 解析提示词文本为标签列表
  void _parsePromptText(String text) {
    if (text.isEmpty) {
      setState(() {
        _tags.clear();
      });
      return;
    }
    
    // 按逗号分割
    final parts = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    setState(() {
      _tags.clear();
      
      for (var part in parts) {
        // 根据内容猜测标签类型
        PromptTagType type = _guessTagType(part);
        _tags.add(PromptTag.fromText(part, type: type));
      }
    });
  }
  
  /// 猜测标签类型
  PromptTagType _guessTagType(String text) {
    final cleanText = text
        .replaceAll(RegExp(r'[{}[\]]'), '') // 移除花括号和方括号
        .trim()
        .toLowerCase();
    
    // 基于提示词分析关键字判断类型
    if (_containsCharacterKeywords(cleanText)) {
      return PromptTagType.character;
    } else if (_containsQualityKeywords(cleanText)) {
      return PromptTagType.quality;
    } else if (_containsStyleKeywords(cleanText)) {
      return PromptTagType.style;
    } else if (_containsCompositionKeywords(cleanText)) {
      return PromptTagType.composition;
    }
    
    return PromptTagType.custom;
  }
  
  /// 判断是否包含角色关键字
  bool _containsCharacterKeywords(String text) {
    final keywords = [
      'girl', 'boy', 'man', 'woman', 'child', 'person',
      'hair', 'eyes', 'face', 'skin', 'body',
      '少女', '男孩', '女孩', '男人', '女人', '孩子', '人物',
      '头发', '眼睛', '脸', '皮肤', '身体',
    ];
    
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 判断是否包含质量关键字
  bool _containsQualityKeywords(String text) {
    final keywords = [
      'best quality', 'masterpiece', 'high detail', 'detailed',
      'highly detailed', 'hd', '4k', 'uhd', 'high resolution',
      '高质量', '杰作', '高细节', '细节', '高分辨率',
    ];
    
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 判断是否包含风格关键字
  bool _containsStyleKeywords(String text) {
    final keywords = [
      'style', 'painting', 'illustration', 'drawing', 'anime',
      'realistic', 'watercolor', 'oil painting', 'sketch',
      '风格', '绘画', '插图', '动漫', '写实', '水彩', '油画', '素描',
    ];
    
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 判断是否包含构图关键字
  bool _containsCompositionKeywords(String text) {
    final keywords = [
      'lighting', 'shadow', 'perspective', 'background', 'composition',
      'landscape', 'portrait', 'close-up', 'wide shot', 'angle',
      '光照', '阴影', '透视', '背景', '构图', '景观', '肖像', '特写', '广角', '角度',
    ];
    
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// 更新标签列表至文本
  void _updateTextFromTags() {
    final text = _tags.map((tag) => tag.toWeightedText()).join(', ');
    widget.controller.text = text;
    
    if (widget.onChanged != null) {
      widget.onChanged!(text);
    }
  }
  
  /// 添加新标签
  void _addTag(String text) {
    if (text.isEmpty) return;
    
    final tag = PromptTag.fromText(
      text,
      type: _guessTagType(text),
    );
    
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
    
    _updateTextFromTags();
  }
  
  /// 删除标签
  void _deleteTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
    
    _updateTextFromTags();
  }
  
  /// 选择标签
  void _selectTag(int index) {
    setState(() {
      _selectedTagIndex = index == _selectedTagIndex ? -1 : index;
    });
  }
  
  /// 获取随机提示词
  void _addRandomSuggestions() {
    final suggestions = _suggestionService.getRandomSuggestions(
      count: 3,
      type: widget.suggestionType,
    );
    
    for (var suggestion in suggestions) {
      _addTag(suggestion.text);
    }
  }
  
  /// 切换编辑模式
  void _toggleEditMode() {
    setState(() {
      _isTagMode = !_isTagMode;
      
      if (_isTagMode) {
        // 更新标签列表
        _parsePromptText(widget.controller.text);
      } else {
        // 更新文本
        _updateTextFromTags();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 编辑模式切换
        Row(
          children: [
            Text(
              _isTagMode ? tr('tag_mode') : tr('text_mode'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _isTagMode,
              onChanged: (value) => _toggleEditMode(),
            ),
            const Spacer(),
            if (_isTagMode)
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: tr('add_random_suggestions'),
                onPressed: _addRandomSuggestions,
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 编辑区域
        if (_isTagMode)
          _buildTagEditor()
        else
          _buildTextEditor(),
      ],
    );
  }
  
  /// 构建标签编辑器
  Widget _buildTagEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签输入框
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                focusNode: _tagFocusNode,
                decoration: InputDecoration(
                  labelText: widget.isNegative 
                      ? tr('negative_prompt_tag')
                      : tr('prompt_tag'),
                  hintText: tr('enter_prompt_tag'),
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(_tagController.text),
                  ),
                ),
                onSubmitted: (value) => _addTag(value),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 标签展示区
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _tags.asMap().entries.map((entry) {
            final index = entry.key;
            final tag = entry.value;
            return PromptTagChip(
              tag: tag,
              onDelete: () => _deleteTag(index),
              onTap: () => _selectTag(index),
              isSelected: index == _selectedTagIndex,
            );
          }).toList(),
        ),
        
        if (_tags.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                tr('no_tags_added'),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// 构建文本编辑器
  Widget _buildTextEditor() {
    return AdvancedTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      labelText: widget.labelText,
      hintText: widget.hintText,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      prefixIcon: widget.prefixIcon,
      suggestionType: widget.suggestionType,
      enableBracketTracking: true,
      showWordCount: true,
    );
  }
}
