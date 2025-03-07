import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:nai_casrand/data/models/template_model.dart';
import 'package:path_provider/path_provider.dart';

/// 模板服务 - 管理模板的存储和检索
class TemplateService {
  static const String _templateBox = 'templateBox';
  static const String _favoriteBox = 'favoriteBox';
  
  late Box _templates;
  late Box _favorites;
  
  /// 初始化模板服务
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    
    _templates = await Hive.openBox(_templateBox);
    _favorites = await Hive.openBox(_favoriteBox);
    
    // 如果模板为空，加载内置模板
    if (_templates.isEmpty) {
      await _loadBuiltInTemplates();
    }
  }
  
  /// 加载内置模板
  Future<void> _loadBuiltInTemplates() async {
    try {
      // 从资源文件加载内置模板
      final String jsonContent = await rootBundle.loadString('assets/json/built_in_templates.json');
      final List<dynamic> templatesList = json.decode(jsonContent);
      
      // 将内置模板添加到Hive数据库
      for (var templateJson in templatesList) {
        final template = Template.fromJson(templateJson);
        template.isBuiltIn = true;
        await _templates.put(template.id, json.encode(template.toJson()));
      }
    } catch (e) {
      print('加载内置模板失败: $e');
    }
  }
  
  /// 获取所有模板
  Future<List<Template>> getAllTemplates() async {
    try {
      List<Template> templateList = [];
      for (var key in _templates.keys) {
        final templateJson = json.decode(_templates.get(key));
        final template = Template.fromJson(templateJson);
        
        // 检查此模板是否被收藏
        template.isFavorite = _favorites.containsKey(template.id);
        
        templateList.add(template);
      }
      return templateList;
    } catch (e) {
      print('获取模板失败: $e');
      return [];
    }
  }
  
  /// 按类型获取模板
  Future<List<Template>> getTemplatesByType(TemplateType type) async {
    try {
      final allTemplates = await getAllTemplates();
      return allTemplates.where((template) => template.type == type).toList();
    } catch (e) {
      print('按类型获取模板失败: $e');
      return [];
    }
  }
  
  /// 获取收藏的模板
  Future<List<Template>> getFavoriteTemplates() async {
    try {
      List<Template> favoriteList = [];
      for (var key in _favorites.keys) {
        if (_templates.containsKey(key)) {
          final templateJson = json.decode(_templates.get(key));
          final template = Template.fromJson(templateJson);
          template.isFavorite = true;
          favoriteList.add(template);
        }
      }
      return favoriteList;
    } catch (e) {
      print('获取收藏模板失败: $e');
      return [];
    }
  }
  
  /// 添加模板
  Future<bool> addTemplate(Template template) async {
    try {
      await _templates.put(template.id, json.encode(template.toJson()));
      return true;
    } catch (e) {
      print('添加模板失败: $e');
      return false;
    }
  }
  
  /// 更新模板
  Future<bool> updateTemplate(Template template) async {
    try {
      if (_templates.containsKey(template.id)) {
        await _templates.put(template.id, json.encode(template.toJson()));
        return true;
      }
      return false;
    } catch (e) {
      print('更新模板失败: $e');
      return false;
    }
  }
  
  /// 删除模板
  Future<bool> deleteTemplate(String templateId) async {
    try {
      if (_templates.containsKey(templateId)) {
        // 检查是否为内置模板
        final templateJson = json.decode(_templates.get(templateId));
        final template = Template.fromJson(templateJson);
        
        if (template.isBuiltIn) {
          // 内置模板不能删除
          return false;
        }
        
        await _templates.delete(templateId);
        
        // 如果模板被收藏，也移除收藏
        if (_favorites.containsKey(templateId)) {
          await _favorites.delete(templateId);
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('删除模板失败: $e');
      return false;
    }
  }
  
  /// 收藏模板
  Future<bool> favoriteTemplate(String templateId) async {
    try {
      if (_templates.containsKey(templateId)) {
        await _favorites.put(templateId, true);
        return true;
      }
      return false;
    } catch (e) {
      print('收藏模板失败: $e');
      return false;
    }
  }
  
  /// 取消收藏模板
  Future<bool> unfavoriteTemplate(String templateId) async {
    try {
      if (_favorites.containsKey(templateId)) {
        await _favorites.delete(templateId);
        return true;
      }
      return false;
    } catch (e) {
      print('取消收藏模板失败: $e');
      return false;
    }
  }
  
  /// 从当前配置创建新模板
  Future<Template?> createTemplateFromCurrentConfig({
    required String name,
    required String description,
    required TemplateType type,
    required String imageB64,
    required Map<String, dynamic> currentConfig,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      final Template template = Template(
        id: id,
        name: name,
        description: description,
        imageB64: imageB64,
        type: type,
        isBuiltIn: false,
        isFavorite: false,
        createdAt: DateTime.now(),
      );
      
      // 根据传入的配置设置模板内容
      if (currentConfig.containsKey('prompt_config')) {
        template.promptConfig = PromptConfig.fromJson(currentConfig['prompt_config']);
      }
      
      if (currentConfig.containsKey('characters')) {
        template.characters = (currentConfig['characters'] as List)
            .map((c) => CharacterConfig.fromJson(c))
            .toList();
      }
      
      if (currentConfig.containsKey('param_config')) {
        template.paramConfig = ParamConfig.fromJson(currentConfig['param_config']);
      }
      
      // 保存模板
      final success = await addTemplate(template);
      if (success) {
        return template;
      }
      return null;
    } catch (e) {
      print('创建模板失败: $e');
      return null;
    }
  }
}
