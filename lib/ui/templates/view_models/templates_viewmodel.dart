import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/data/models/template_model.dart';
import 'package:nai_casrand/data/services/template_service.dart';
import 'package:image_picker/image_picker.dart';

/// 模板页面的视图模型
class TemplatesViewModel extends ChangeNotifier {
  final TemplateService _templateService;
  List<Template> _templates = [];
  List<Template> _favoriteTemplates = [];
  List<Template> _filteredTemplates = [];
  String _searchQuery = '';
  TemplateType? _selectedType;
  bool _isLoading = false;
  bool _showOnlyFavorites = false;
  
  TemplatesViewModel({TemplateService? templateService}) 
      : _templateService = templateService ?? GetIt.instance<TemplateService>();
  
  // Getters
  List<Template> get templates => _filteredTemplates;
  List<Template> get favoriteTemplates => _favoriteTemplates;
  bool get isLoading => _isLoading;
  bool get showOnlyFavorites => _showOnlyFavorites;
  String get searchQuery => _searchQuery;
  TemplateType? get selectedType => _selectedType;

  /// 初始化视图模型
  Future<void> init() async {
    _setLoading(true);
    await _templateService.init();
    await _loadTemplates();
    _filterTemplates();
    _setLoading(false);
  }
  
  /// 加载模板
  Future<void> _loadTemplates() async {
    _templates = await _templateService.getAllTemplates();
    _favoriteTemplates = await _templateService.getFavoriteTemplates();
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 根据当前筛选条件过滤模板
  void _filterTemplates() {
    _filteredTemplates = _templates;
    
    // 按类型筛选
    if (_selectedType != null) {
      _filteredTemplates = _filteredTemplates
          .where((template) => template.type == _selectedType)
          .toList();
    }
    
    // 按收藏筛选
    if (_showOnlyFavorites) {
      _filteredTemplates = _filteredTemplates
          .where((template) => template.isFavorite)
          .toList();
    }
    
    // 按搜索词筛选
    if (_searchQuery.isNotEmpty) {
      _filteredTemplates = _filteredTemplates
          .where((template) => 
              template.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
              template.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    notifyListeners();
  }
  
  /// 设置搜索查询
  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterTemplates();
  }
  
  /// 设置选定的模板类型
  void setSelectedType(TemplateType? type) {
    _selectedType = type;
    _filterTemplates();
  }
  
  /// 切换是否只显示收藏
  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    _filterTemplates();
  }
  
  /// 收藏/取消收藏模板
  Future<void> toggleFavorite(Template template) async {
    if (template.isFavorite) {
      await _templateService.unfavoriteTemplate(template.id);
    } else {
      await _templateService.favoriteTemplate(template.id);
    }
    
    // 更新模板状态
    await _loadTemplates();
    _filterTemplates();
  }
  
  /// 删除模板
  Future<bool> deleteTemplate(String templateId) async {
    final result = await _templateService.deleteTemplate(templateId);
    if (result) {
      await _loadTemplates();
      _filterTemplates();
    }
    return result;
  }

  /// 应用模板到当前配置
  Future<void> applyTemplate(Template template, PayloadConfig payloadConfig) async {
    if (template.promptConfig != null) {
      payloadConfig.rootPromptConfig = template.promptConfig!;
    }
    
    if (template.characters != null && template.characters!.isNotEmpty) {
      payloadConfig.characterConfigList = template.characters!;
    }
    
    if (template.paramConfig != null) {
      payloadConfig.paramConfig = template.paramConfig!;
    }
    
    notifyListeners();
  }
  
  /// 从当前配置创建新模板
  Future<Template?> createTemplateFromCurrentConfig({
    required String name,
    required String description,
    required TemplateType type,
    required PayloadConfig payloadConfig,
  }) async {
    _setLoading(true);
    
    try {
      // 尝试获取当前生成的图片作为模板图片
      String imageB64 = '';
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        imageB64 = base64Encode(bytes);
      }
      
      // 从当前配置构建模板数据
      Map<String, dynamic> currentConfig = {
        'prompt_config': payloadConfig.rootPromptConfig.toJson(),
        'characters': payloadConfig.characterConfigList.map((e) => e.toJson()).toList(),
        'param_config': payloadConfig.paramConfig.toJson(),
      };
      
      // 创建模板
      final newTemplate = await _templateService.createTemplateFromCurrentConfig(
        name: name,
        description: description,
        type: type,
        imageB64: imageB64,
        currentConfig: currentConfig,
      );
      
      // 重新加载模板
      await _loadTemplates();
      _filterTemplates();
      
      _setLoading(false);
      return newTemplate;
    } catch (e) {
      print('创建模板失败: $e');
      _setLoading(false);
      return null;
    }
  }
  
  /// 从分享码导入模板
  Future<bool> importFromShareCode(String shareCode) async {
    _setLoading(true);
    
    try {
      final template = Template.importFromShareCode(shareCode);
      if (template != null) {
        final result = await _templateService.addTemplate(template);
        if (result) {
          await _loadTemplates();
          _filterTemplates();
          _setLoading(false);
          return true;
        }
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      print('导入模板失败: $e');
      _setLoading(false);
      return false;
    }
  }
  
  /// 获取模板的分享码
  String getShareCode(Template template) {
    return template.exportShareCode();
  }
}
