import 'package:nai_casrand/data/models/prompt_config.dart';
import 'package:nai_casrand/data/models/character_config.dart';
import 'package:nai_casrand/data/models/param_config.dart';

/// 历史记录条目
class HistoryEntry {
  final String id;                // 唯一标识符
  final DateTime timestamp;       // 创建时间戳
  final String imageFilePath;     // 图片文件路径
  final String? thumbnailB64;     // 缩略图Base64编码(可选，用于快速加载)
  final String promptComment;     // 提示词注释
  final String negativePrompt;    // 负面提示词
  final bool isFavorite;          // 是否被收藏
  final Map<String, dynamic> parameters; // 生成参数
  
  // 可选的完整配置，用于重新应用
  final PromptConfig? promptConfig;
  final List<CharacterConfig>? characterConfigs;
  final ParamConfig? paramConfig;
  
  HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.imageFilePath,
    this.thumbnailB64,
    required this.promptComment,
    required this.negativePrompt,
    this.isFavorite = false,
    required this.parameters,
    this.promptConfig,
    this.characterConfigs,
    this.paramConfig,
  });
  
  /// 从JSON构建历史记录条目对象
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      imageFilePath: json['image_file_path'],
      thumbnailB64: json['thumbnail_b64'],
      promptComment: json['prompt_comment'],
      negativePrompt: json['negative_prompt'],
      isFavorite: json['is_favorite'] ?? false,
      parameters: json['parameters'],
      promptConfig: json['prompt_config'] != null 
          ? PromptConfig.fromJson(json['prompt_config']) 
          : null,
      characterConfigs: json['character_configs'] != null
          ? (json['character_configs'] as List)
              .map((c) => CharacterConfig.fromJson(c))
              .toList()
          : null,
      paramConfig: json['param_config'] != null
          ? ParamConfig.fromJson(json['param_config'])
          : null,
    );
  }
  
  /// 将历史记录条目对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'image_file_path': imageFilePath,
      'thumbnail_b64': thumbnailB64,
      'prompt_comment': promptComment,
      'negative_prompt': negativePrompt,
      'is_favorite': isFavorite,
      'parameters': parameters,
      'prompt_config': promptConfig?.toJson(),
      'character_configs': characterConfigs?.map((c) => c.toJson()).toList(),
      'param_config': paramConfig?.toJson(),
    };
  }
  
  /// 创建带有收藏标记的新实例
  HistoryEntry copyWithFavorite(bool favorite) {
    return HistoryEntry(
      id: id,
      timestamp: timestamp,
      imageFilePath: imageFilePath,
      thumbnailB64: thumbnailB64,
      promptComment: promptComment,
      negativePrompt: negativePrompt,
      isFavorite: favorite,
      parameters: parameters,
      promptConfig: promptConfig,
      characterConfigs: characterConfigs,
      paramConfig: paramConfig,
    );
  }
}
