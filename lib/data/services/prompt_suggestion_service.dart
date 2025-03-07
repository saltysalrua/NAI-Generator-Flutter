import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

/// 提示词建议类型
enum SuggestionType {
  character,   // 角色相关
  scene,       // 场景相关
  style,       // 风格相关
  composition, // 构图相关
  lighting,    // 光照相关
  color,       // 颜色相关
  attribute,   // 属性/修饰词
  medium,      // 媒介类型
  quality,     // 质量相关
  other,       // 其他
}

/// 提示词建议项
class PromptSuggestion {
  final String text;          // 提示词文本
  final String? translation;  // 中文翻译
  final List<String> tags;    // 标签
  final SuggestionType type;  // 类型
  final double relevance;     // 相关性得分(用于排序)
  final bool isUserCreated;   // 是否是用户创建的
  final int usageCount;       // 使用次数
  
  const PromptSuggestion({
    required this.text,
    this.translation,
    required this.tags,
    required this.type,
    this.relevance = 0.0,
    this.isUserCreated = false,
    this.usageCount = 0,
  });
  
  /// 从JSON创建
  factory PromptSuggestion.fromJson(Map<String, dynamic> json) {
    return PromptSuggestion(
      text: json['text'],
      translation: json['translation'],
      tags: List<String>.from(json['tags'] ?? []),
      type: SuggestionType.values.firstWhere(
        (t) => t.toString() == 'SuggestionType.${json['type']}',
        orElse: () => SuggestionType.other,
      ),
      relevance: json['relevance'] ?? 0.0,
      isUserCreated: json['is_user_created'] ?? false,
      usageCount: json['usage_count'] ?? 0,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'translation': translation,
      'tags': tags,
      'type': type.toString().split('.').last,
      'relevance': relevance,
      'is_user_created': isUserCreated,
      'usage_count': usageCount,
    };
  }
  
  /// 创建用户更新后的副本
  PromptSuggestion copyWithIncrementedUsage() {
    return PromptSuggestion(
      text: text,
      translation: translation,
      tags: tags,
      type: type,
      relevance: relevance,
      isUserCreated: isUserCreated,
      usageCount: usageCount + 1,
    );
  }
}

/// 提示词建议服务
class PromptSuggestionService {
  static const String _suggestionBox = 'promptSuggestionBox';
  static const String _userSuggestionBox = 'userPromptSuggestionBox';
  static const int _maxHistorySuggestions = 50;
  
  late Box _suggestions;
  late Box _userSuggestions;
  
  List<PromptSuggestion> _builtInSuggestions = [];
  List<PromptSuggestion> _userSuggestions = [];
  List<String> _recentlyUsed = [];
  
  /// 初始化
  Future<void> init() async {
    _suggestions = await Hive.openBox(_suggestionBox);
    _userSuggestions = await Hive.openBox(_userSuggestionBox);
    
    await _loadBuiltInSuggestions();
    await _loadUserSuggestions();
    _loadRecentlyUsed();
  }
  
  /// 加载内置提示词
  Future<void> _loadBuiltInSuggestions() async {
    try {
      if (_builtInSuggestions.isEmpty) {
        // 从内置JSON文件加载
        final String jsonStr = await rootBundle.loadString('assets/json/prompt_suggestions.json');
        final List<dynamic> jsonList = json.decode(jsonStr);
        
        _builtInSuggestions = jsonList
            .map((item) => PromptSuggestion.fromJson(item))
            .toList();
        
        // 保存到本地存储以便快速访问
        for (var suggestion in _builtInSuggestions) {
          await _suggestions.put(suggestion.text, json.encode(suggestion.toJson()));
        }
      }
    } catch (e) {
      print('加载内置提示词失败: $e');
      
      // 尝试从本地存储中恢复
      _builtInSuggestions = [];
      for (var key in _suggestions.keys) {
        try {
          final jsonStr = _suggestions.get(key);
          if (jsonStr != null) {
            final suggestion = PromptSuggestion.fromJson(json.decode(jsonStr));
            if (!suggestion.isUserCreated) {
              _builtInSuggestions.add(suggestion);
            }
          }
        } catch (e) {
          print('解析提示词失败: $e');
        }
      }
    }
  }
  
  /// 加载用户自定义提示词
  Future<void> _loadUserSuggestions() async {
    _userSuggestions = [];
    for (var key in _userSuggestions.keys) {
      try {
        final jsonStr = _userSuggestions.get(key);
        if (jsonStr != null) {
          final suggestion = PromptSuggestion.fromJson(json.decode(jsonStr));
          _userSuggestions.add(suggestion);
        }
      } catch (e) {
        print('解析用户提示词失败: $e');
      }
    }
    
    // 排序：使用次数降序
    _userSuggestions.sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }
  
  /// 加载最近使用的提示词
  void _loadRecentlyUsed() {
    final recentlyUsedJson = _suggestions.get('_recently_used');
    if (recentlyUsedJson != null) {
      _recentlyUsed = List<String>.from(json.decode(recentlyUsedJson));
    } else {
      _recentlyUsed = [];
    }
  }
  
  /// 添加最近使用的提示词
  Future<void> _addRecentlyUsed(String text) async {
    if (_recentlyUsed.contains(text)) {
      _recentlyUsed.remove(text);
    }
    
    _recentlyUsed.insert(0, text);
    
    // 限制数量
    if (_recentlyUsed.length > _maxHistorySuggestions) {
      _recentlyUsed = _recentlyUsed.sublist(0, _maxHistorySuggestions);
    }
    
    await _suggestions.put('_recently_used', json.encode(_recentlyUsed));
  }
  
  /// 搜索提示词
  List<PromptSuggestion> searchSuggestions(String query, {SuggestionType? type, int limit = 10}) {
    if (query.isEmpty) {
      // 返回最近使用或按类型
      return _getRecentOrTypedSuggestions(type, limit);
    }
    
    // 搜索算法
    final results = <PromptSuggestion, double>{};
    final queryLower = query.toLowerCase();
    
    // 合并内置和用户提示词
    final allSuggestions = [..._builtInSuggestions, ..._userSuggestions];
    
    for (var suggestion in allSuggestions) {
      // 如果指定了类型且不匹配，则跳过
      if (type != null && suggestion.type != type) {
        continue;
      }
      
      double score = 0;
      
      // 文本匹配
      if (suggestion.text.toLowerCase() == queryLower) {
        score += 100; // 完全匹配
      } else if (suggestion.text.toLowerCase().startsWith(queryLower)) {
        score += 75; // 前缀匹配
      } else if (suggestion.text.toLowerCase().contains(queryLower)) {
        score += 50; // 包含匹配
      }
      
      // 翻译匹配
      if (suggestion.translation != null) {
        if (suggestion.translation!.toLowerCase() == queryLower) {
          score += 90; // 完全匹配翻译
        } else if (suggestion.translation!.toLowerCase().startsWith(queryLower)) {
          score += 65; // 前缀匹配翻译
        } else if (suggestion.translation!.toLowerCase().contains(queryLower)) {
          score += 40; // 包含匹配翻译
        }
      }
      
      // 标签匹配
      for (var tag in suggestion.tags) {
        if (tag.toLowerCase() == queryLower) {
          score += 60; // 完全匹配标签
        } else if (tag.toLowerCase().startsWith(queryLower)) {
          score += 45; // 前缀匹配标签
        } else if (tag.toLowerCase().contains(queryLower)) {
          score += 30; // 包含匹配标签
        }
      }
      
      // 权重调整
      score += suggestion.relevance; // 相关性得分
      score += suggestion.usageCount * 0.5; // 使用频率加成
      score += suggestion.isUserCreated ? 10 : 0; // 用户创建的提示词优先
      
      if (score > 0) {
        results[suggestion] = score;
      }
    }
    
    // 按得分排序并限制数量
    final sortedResults = results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedResults
        .take(limit)
        .map((e) => e.key)
        .toList();
  }
  
  /// 获取最近使用或特定类型的提示词
  List<PromptSuggestion> _getRecentOrTypedSuggestions(SuggestionType? type, int limit) {
    if (type != null) {
      // 按类型筛选，并按使用频率排序
      final typedSuggestions = [..._builtInSuggestions, ..._userSuggestions]
          .where((s) => s.type == type)
          .toList()
        ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
      
      return typedSuggestions.take(limit).toList();
    } else {
      // 返回最近使用的提示词
      final recentSuggestions = <PromptSuggestion>[];
      
      for (var text in _recentlyUsed) {
        // 尝试在内置和用户提示词中查找
        final suggestion = [..._builtInSuggestions, ..._userSuggestions]
            .firstWhere((s) => s.text == text, orElse: () => 
                PromptSuggestion(
                  text: text,
                  tags: [],
                  type: SuggestionType.other,
                  usageCount: 1,
                  isUserCreated: true,
                )
            );
        
        recentSuggestions.add(suggestion);
        
        if (recentSuggestions.length >= limit) {
          break;
        }
      }
      
      return recentSuggestions;
    }
  }
  
  /// 获取所有提示词类型
  List<SuggestionType> getAllTypes() {
    return SuggestionType.values;
  }
  
  /// 按类型获取提示词
  List<PromptSuggestion> getSuggestionsByType(SuggestionType type, {int limit = 20}) {
    final suggestions = [..._builtInSuggestions, ..._userSuggestions]
        .where((s) => s.type == type)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    return suggestions.take(limit).toList();
  }
  
  /// 获取随机提示词
  List<PromptSuggestion> getRandomSuggestions({int count = 5, SuggestionType? type}) {
    final random = Random();
    final suggestions = type != null 
        ? [..._builtInSuggestions, ..._userSuggestions].where((s) => s.type == type).toList()
        : [..._builtInSuggestions, ..._userSuggestions];
    
    if (suggestions.isEmpty) {
      return [];
    }
    
    // 随机抽取
    final result = <PromptSuggestion>[];
    final indices = <int>[];
    
    for (var i = 0; i < count && i < suggestions.length; i++) {
      int index;
      do {
        index = random.nextInt(suggestions.length);
      } while (indices.contains(index) && indices.length < suggestions.length);
      
      if (!indices.contains(index)) {
        indices.add(index);
        result.add(suggestions[index]);
      }
    }
    
    return result;
  }
  
  /// 添加自定义提示词
  Future<void> addUserSuggestion(PromptSuggestion suggestion) async {
    final userSuggestion = PromptSuggestion(
      text: suggestion.text,
      translation: suggestion.translation,
      tags: suggestion.tags,
      type: suggestion.type,
      relevance: suggestion.relevance,
      isUserCreated: true,
      usageCount: suggestion.usageCount,
    );
    
    await _userSuggestions.put(
      suggestion.text,
      json.encode(userSuggestion.toJson()),
    );
    
    _userSuggestions.add(userSuggestion);
  }
  
  /// 删除自定义提示词
  Future<void> removeUserSuggestion(String text) async {
    await _userSuggestions.delete(text);
    _userSuggestions.removeWhere((s) => s.text == text);
  }
  
  /// 更新使用计数
  Future<void> incrementUsageCount(String text) async {
    // 添加到最近使用
    await _addRecentlyUsed(text);
    
    // 查找并更新提示词
    final builtInIndex = _builtInSuggestions.indexWhere((s) => s.text == text);
    if (builtInIndex >= 0) {
      final updated = _builtInSuggestions[builtInIndex].copyWithIncrementedUsage();
      _builtInSuggestions[builtInIndex] = updated;
      await _suggestions.put(text, json.encode(updated.toJson()));
      return;
    }
    
    final userIndex = _userSuggestions.indexWhere((s) => s.text == text);
    if (userIndex >= 0) {
      final updated = _userSuggestions[userIndex].copyWithIncrementedUsage();
      _userSuggestions[userIndex] = updated;
      await _userSuggestions.put(text, json.encode(updated.toJson()));
      return;
    }
    
    // 如果不存在，创建新的用户提示词
    final newSuggestion = PromptSuggestion(
      text: text,
      tags: [],
      type: SuggestionType.other,
      isUserCreated: true,
      usageCount: 1,
    );
    
    await _userSuggestions.put(text, json.encode(newSuggestion.toJson()));
    _userSuggestions.add(newSuggestion);
  }
  
  /// 获取提示词类型名称
  String getTypeName(SuggestionType type) {
    switch (type) {
      case SuggestionType.character:
        return '角色';
      case SuggestionType.scene:
        return '场景';
      case SuggestionType.style:
        return '风格';
      case SuggestionType.composition:
        return '构图';
      case SuggestionType.lighting:
        return '光照';
      case SuggestionType.color:
        return '颜色';
      case SuggestionType.attribute:
        return '属性';
      case SuggestionType.medium:
        return '媒介';
      case SuggestionType.quality:
        return '质量';
      case SuggestionType.other:
        return '其他';
    }
  }
}
