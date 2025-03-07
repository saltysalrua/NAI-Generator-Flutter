import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/services/prompt_suggestion_service.dart';

/// 高级文本输入框，支持提示词建议和其他增强功能
class AdvancedTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final SuggestionType? suggestionType; // 建议类型，如果为null则不提供建议
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enableSuggestions;
  final bool? showCursor;
  final bool readOnly;
  final bool showWordCount;
  final TextStyle? style;
  final EdgeInsetsGeometry? contentPadding;
  final int wordCountLimit; // 限制字数，0表示不限制
  final bool enableBracketTracking; // 跟踪括号平衡
  final bool enableTranslation; // 启用翻译功能
  final bool enableQuickClear; // 启用快速清除按钮
  
  const AdvancedTextField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onSubmitted,
    this.onChanged,
    this.onEditingComplete,
    this.suggestionType,
    this.prefixIcon,
    this.suffixIcon,
    this.enableSuggestions = true,
    this.showCursor,
    this.readOnly = false,
    this.showWordCount = false,
    this.style,
    this.contentPadding,
    this.wordCountLimit = 0,
    this.enableBracketTracking = false,
    this.enableTranslation = false,
    this.enableQuickClear = true,
  }) : super(key: key);

  @override
  State<AdvancedTextField> createState() => _AdvancedTextFieldState();
}

class _AdvancedTextFieldState extends State<AdvancedTextField> {
  final PromptSuggestionService _suggestionService = GetIt.instance<PromptSuggestionService>();
  
  List<PromptSuggestion> _suggestions = [];
  FocusNode? _focusNode;
  LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  
  int _wordCount = 0;
  bool _hasBracketImbalance = false;
  bool _showSuggestions = false;
  String _currentQuery = '';
  
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode!.addListener(_onFocusChange);
    
    // 添加文本监听
    widget.controller.addListener(_onTextChanged);
    
    // 初始状态计算字数
    _calcWordCount();
    
    // 初始状态检查括号平衡
    if (widget.enableBracketTracking) {
      _checkBracketBalance();
    }
  }
  
  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode?.removeListener(_onFocusChange);
      _focusNode?.dispose();
    }
    
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
  
  /// 焦点变化处理
  void _onFocusChange() {
    if (_focusNode!.hasFocus) {
      // 获取焦点时显示建议
      if (widget.enableSuggestions && widget.suggestionType != null) {
        _updateSuggestions();
      }
    } else {
      // 失去焦点时关闭建议
      _removeOverlay();
    }
  }
  
  /// 文本变化处理
  void _onTextChanged() {
    // 计算字数
    if (widget.showWordCount) {
      _calcWordCount();
    }
    
    // 检查括号平衡
    if (widget.enableBracketTracking) {
      _checkBracketBalance();
    }
    
    // 更新建议
    if (widget.enableSuggestions && widget.suggestionType != null && _focusNode!.hasFocus) {
      _updateSuggestions();
    }
  }
  
  /// 计算字数
  void _calcWordCount() {
    final text = widget.controller.text;
    setState(() {
      _wordCount = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    });
  }
  
  /// 检查括号平衡
  void _checkBracketBalance() {
    final text = widget.controller.text;
    
    int roundOpen = 0;   // (
    int roundClose = 0;  // )
    int squareOpen = 0;  // [
    int squareClose = 0; // ]
    int curlyOpen = 0;   // {
    int curlyClose = 0;  // }
    
    for (int i = 0; i < text.length; i++) {
      switch (text[i]) {
        case '(': roundOpen++; break;
        case ')': roundClose++; break;
        case '[': squareOpen++; break;
        case ']': squareClose++; break;
        case '{': curlyOpen++; break;
        case '}': curlyClose++; break;
      }
    }
    
    setState(() {
      _hasBracketImbalance = roundOpen != roundClose || 
                              squareOpen != squareClose || 
                              curlyOpen != curlyClose;
    });
  }
  
  /// 更新建议列表
  void _updateSuggestions() {
    if (!widget.enableSuggestions || widget.suggestionType == null) {
      return;
    }
    
    // 获取当前光标位置的词
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    // 如果没有有效的选择，直接返回
    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _removeOverlay();
      return;
    }
    
    // 找到光标位置的单词
    final cursorPos = selection.baseOffset;
    
    // 向前查找空格或逗号
    int start = cursorPos;
    while (start > 0 && text[start - 1] != ' ' && text[start - 1] != ',') {
      start--;
    }
    
    // 当前输入的查询词
    String query = text.substring(start, cursorPos).trim();
    
    // 如果查询词为空或太短，关闭建议
    if (query.isEmpty) {
      _removeOverlay();
      _currentQuery = '';
      return;
    }
    
    // 如果查询词没变，不更新
    if (query == _currentQuery && _overlayEntry != null) {
      return;
    }
    
    _currentQuery = query;
    
    // 搜索建议
    _suggestions = _suggestionService.searchSuggestions(
      query,
      type: widget.suggestionType,
      limit: 5,
    );
    
    // 如果有建议，显示建议弹窗
    if (_suggestions.isNotEmpty) {
      _removeOverlay();
      _addOverlay();
      setState(() {
        _showSuggestions = true;
      });
    } else {
      _removeOverlay();
      setState(() {
        _showSuggestions = false;
      });
    }
  }
  
  /// 添加悬浮建议框
  void _addOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width * 0.9,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 50), // 根据输入框高度调整
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(suggestion.text),
                  subtitle: suggestion.translation != null 
                      ? Text(suggestion.translation!, style: const TextStyle(fontSize: 12))
                      : null,
                  onTap: () => _applySuggestion(suggestion),
                );
              },
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  /// 移除悬浮建议框
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    if (_showSuggestions) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }
  
  /// 应用选中的建议
  void _applySuggestion(PromptSuggestion suggestion) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    // 找到当前单词的范围
    final cursorPos = selection.baseOffset;
    
    // 向前查找空格或逗号
    int start = cursorPos;
    while (start > 0 && text[start - 1] != ' ' && text[start - 1] != ',') {
      start--;
    }
    
    // 替换当前单词
    final newText = text.replaceRange(start, cursorPos, suggestion.text);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + suggestion.text.length),
    );
    
    // 更新使用计数
    _suggestionService.incrementUsageCount(suggestion.text);
    
    // 关闭建议框
    _removeOverlay();
    
    // 触发onChange回调
    widget.onChanged?.call(newText);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            onSubmitted: widget.onSubmitted,
            onChanged: (value) {
              widget.onChanged?.call(value);
            },
            onEditingComplete: widget.onEditingComplete,
            readOnly: widget.readOnly,
            showCursor: widget.showCursor,
            style: widget.style,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: _buildSuffixIcon(),
              contentPadding: widget.contentPadding,
              enabledBorder: _hasBracketImbalance
                  ? OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade300),
                    )
                  : null,
              focusedBorder: _hasBracketImbalance
                  ? OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade500),
                    )
                  : null,
            ),
          ),
        ),
        
        // 字数统计
        if (widget.showWordCount)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                widget.wordCountLimit > 0
                    ? '$_wordCount / ${widget.wordCountLimit}'
                    : '$_wordCount ${tr('words')}',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.wordCountLimit > 0 && _wordCount > widget.wordCountLimit
                      ? Colors.red
                      : Colors.grey,
                ),
              ),
            ),
          ),
        
        // 括号不平衡提示
        if (_hasBracketImbalance)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              tr('bracket_imbalance_warning'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade500,
              ),
            ),
          ),
      ],
    );
  }
  
  /// 构建后缀图标（如清除按钮）
  Widget? _buildSuffixIcon() {
    if (!widget.enableQuickClear || widget.controller.text.isEmpty) {
      return widget.suffixIcon;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 清除按钮
        IconButton(
          icon: const Icon(Icons.clear, size: 18),
          onPressed: () {
            widget.controller.clear();
            widget.onChanged?.call('');
          },
        ),
        
        // 原始后缀图标
        if (widget.suffixIcon != null)
          widget.suffixIcon!,
      ],
    );
  }
}
