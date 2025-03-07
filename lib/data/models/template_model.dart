import 'dart:convert';

import 'package:nai_casrand/data/models/prompt_config.dart';
import 'package:nai_casrand/data/models/character_config.dart';
import 'package:nai_casrand/data/models/param_config.dart';

/// 模板类型枚举
enum TemplateType {
  character,    // 角色模板
  scene,        // 场景模板
  style,        // 风格模板
  custom,       // 自定义模板
}

/// 模板模型
class Template {
  String id;          // 唯一标识符
  String name;        // 模板名称
  String description; // 模板描述
  String imageB64;    // 模板示例图片的Base64编码
  TemplateType type;  // 模板类型
  bool isBuiltIn;     // 是否是内置模板
  bool isFavorite;    // 是否被收藏
  DateTime createdAt; // 创建时间
  
  PromptConfig? promptConfig;        // 提示词配置
  List<CharacterConfig>? characters; // 角色配置
  ParamConfig? paramConfig;          // 参数配置

  Template({
    required this.id,
    required this.name,
    required this.description,
    required this.imageB64,
    required this.type,
    this.isBuiltIn = false,
    this.isFavorite = false,
    required this.createdAt,
    this.promptConfig,
    this.characters,
    this.paramConfig,
  });

  /// 从JSON构建模板对象
  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageB64: json['image_b64'],
      type: TemplateType.values.byName(json['type']),
      isBuiltIn: json['is_built_in'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      promptConfig: json['prompt_config'] != null 
          ? PromptConfig.fromJson(json['prompt_config']) 
          : null,
      characters: json['characters'] != null
          ? (json['characters'] as List)
              .map((c) => CharacterConfig.fromJson(c))
              .toList()
          : null,
      paramConfig: json['param_config'] != null
          ? ParamConfig.fromJson(json['param_config'])
          : null,
    );
  }

  /// 将模板对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_b64': imageB64,
      'type': type.name,
      'is_built_in': isBuiltIn,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'prompt_config': promptConfig?.toJson(),
      'characters': characters?.map((c) => c.toJson()).toList(),
      'param_config': paramConfig?.toJson(),
    };
  }

  /// 导出模板为分享码
  String exportShareCode() {
    final Map<String, dynamic> shareData = {
      'name': name,
      'description': description,
      'type': type.name,
      'prompt_config': promptConfig?.toJson(),
      'characters': characters?.map((c) => c.toJson()).toList(),
      'param_config': paramConfig?.toJson(),
    };
    
    return base64Encode(utf8.encode(json.encode(shareData)));
  }
  
  /// 从分享码导入模板
  static Template? importFromShareCode(String shareCode) {
    try {
      final shareData = json.decode(
        utf8.decode(base64Decode(shareCode))
      );
      
      return Template(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: shareData['name'],
        description: shareData['description'],
        imageB64: '', // 导入的模板没有示例图片
        type: TemplateType.values.byName(shareData['type']),
        isBuiltIn: false,
        isFavorite: false,
        createdAt: DateTime.now(),
        promptConfig: shareData['prompt_config'] != null 
            ? PromptConfig.fromJson(shareData['prompt_config']) 
            : null,
        characters: shareData['characters'] != null
            ? (shareData['characters'] as List)
                .map((c) => CharacterConfig.fromJson(c))
                .toList()
            : null,
        paramConfig: shareData['param_config'] != null
            ? ParamConfig.fromJson(shareData['param_config'])
            : null,
      );
    } catch (e) {
      print('导入模板失败: $e');
      return null;
    }
  }
}
