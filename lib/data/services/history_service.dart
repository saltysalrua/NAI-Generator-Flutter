import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:nai_casrand/data/models/history_entry.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/data/models/info_card_content.dart';

/// 历史记录服务 - 管理生成历史
class HistoryService {
  static const String _historyBox = 'historyBox';
  static const String _favoriteBox = 'historyFavoriteBox';
  static const int _thumbnailSize = 200; // 缩略图尺寸
  
  late Box _history;
  late Box _favorites;
  late Directory _imageDir;
  
  /// 初始化历史记录服务
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    
    _history = await Hive.openBox(_historyBox);
    _favorites = await Hive.openBox(_favoriteBox);
    
    // 确保图片目录存在
    _imageDir = Directory('${appDir.path}/history_images');
    if (!await _imageDir.exists()) {
      await _imageDir.create(recursive: true);
    }
  }
  
  /// 创建新的历史记录条目
  Future<HistoryEntry?> createHistoryEntry(
    InfoCardContent infoCardContent,
    PayloadConfig payloadConfig,
  ) async {
    try {
      if (infoCardContent.imageBytes == null) {
        // 没有图片，不创建历史记录
        return null;
      }
      
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = DateTime.now();
      
      // 保存图片文件
      final fileName = '${id}.png';
      final imagePath = '${_imageDir.path}/$fileName';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(infoCardContent.imageBytes!);
      
      // 生成缩略图
      final thumbnail = await _generateThumbnail(infoCardContent.imageBytes!);
      
      final historyEntry = HistoryEntry(
        id: id,
        timestamp: timestamp,
        imageFilePath: imagePath,
        thumbnailB64: thumbnail,
        promptComment: infoCardContent.info,
        negativePrompt: payloadConfig.paramConfig.negativePrompt,
        parameters: infoCardContent.additionalInfo,
        promptConfig: payloadConfig.rootPromptConfig,
        characterConfigs: List.from(payloadConfig.characterConfigList),
        paramConfig: payloadConfig.paramConfig,
      );
      
      // 保存历史记录
      await _history.put(id, json.encode(historyEntry.toJson()));
      
      return historyEntry;
    } catch (e) {
      print('创建历史记录失败: $e');
      return null;
    }
  }
  
  /// 获取所有历史记录
  Future<List<HistoryEntry>> getAllHistory({int limit = 100, int offset = 0}) async {
    try {
      final keys = _history.keys.toList();
      keys.sort((a, b) => b.toString().compareTo(a.toString())); // 按ID降序排序（最新的先显示）
      
      // 应用分页
      final pagedKeys = keys.skip(offset).take(limit).toList();
      
      List<HistoryEntry> historyList = [];
      for (var key in pagedKeys) {
        final historyJson = json.decode(_history.get(key));
        final entry = HistoryEntry.fromJson(historyJson);
        
        // 检查此记录是否被收藏
        if (_favorites.containsKey(entry.id)) {
          historyList.add(entry.copyWithFavorite(true));
        } else {
          historyList.add(entry);
        }
      }
      
      return historyList;
    } catch (e) {
      print('获取历史记录失败: $e');
      return [];
    }
  }
  
  /// 获取收藏的历史记录
  Future<List<HistoryEntry>> getFavoriteHistory() async {
    try {
      List<HistoryEntry> favoriteList = [];
      for (var key in _favorites.keys) {
        if (_history.containsKey(key)) {
          final historyJson = json.decode(_history.get(key));
          final entry = HistoryEntry.fromJson(historyJson);
          favoriteList.add(entry.copyWithFavorite(true));
        }
      }
      
      // 按时间戳降序排序（最新的先显示）
      favoriteList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return favoriteList;
    } catch (e) {
      print('获取收藏历史记录失败: $e');
      return [];
    }
  }
  
  /// 获取单个历史记录
  Future<HistoryEntry?> getHistoryEntry(String id) async {
    try {
      if (_history.containsKey(id)) {
        final historyJson = json.decode(_history.get(id));
        final entry = HistoryEntry.fromJson(historyJson);
        
        // 检查此记录是否被收藏
        if (_favorites.containsKey(entry.id)) {
          return entry.copyWithFavorite(true);
        }
        
        return entry;
      }
      return null;
    } catch (e) {
      print('获取历史记录失败: $e');
      return null;
    }
  }
  
  /// 收藏历史记录
  Future<bool> favoriteHistoryEntry(String id) async {
    try {
      if (_history.containsKey(id)) {
        await _favorites.put(id, true);
        return true;
      }
      return false;
    } catch (e) {
      print('收藏历史记录失败: $e');
      return false;
    }
  }
  
  /// 取消收藏历史记录
  Future<bool> unfavoriteHistoryEntry(String id) async {
    try {
      if (_favorites.containsKey(id)) {
        await _favorites.delete(id);
        return true;
      }
      return false;
    } catch (e) {
      print('取消收藏历史记录失败: $e');
      return false;
    }
  }
  
  /// 删除历史记录
  Future<bool> deleteHistoryEntry(String id) async {
    try {
      if (_history.containsKey(id)) {
        // 获取历史记录
        final historyJson = json.decode(_history.get(id));
        final entry = HistoryEntry.fromJson(historyJson);
        
        // 删除图片文件
        final imageFile = File(entry.imageFilePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        
        // 删除历史记录
        await _history.delete(id);
        
        // 如果被收藏，也删除收藏
        if (_favorites.containsKey(id)) {
          await _favorites.delete(id);
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('删除历史记录失败: $e');
      return false;
    }
  }
  
  /// 清空历史记录
  Future<bool> clearHistory() async {
    try {
      // 获取所有历史记录
      final keys = _history.keys.toList();
      
      // 删除所有图片文件
      for (var key in keys) {
        final historyJson = json.decode(_history.get(key));
        final entry = HistoryEntry.fromJson(historyJson);
        
        final imageFile = File(entry.imageFilePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }
      
      // 清空历史记录和收藏
      await _history.clear();
      await _favorites.clear();
      
      return true;
    } catch (e) {
      print('清空历史记录失败: $e');
      return false;
    }
  }
  
  /// 搜索历史记录
  Future<List<HistoryEntry>> searchHistory(String query) async {
    try {
      final allHistory = await getAllHistory(limit: 1000); // 获取足够多的历史记录
      
      // 在提示词和参数中搜索
      return allHistory.where((entry) {
        // 转为小写以支持不区分大小写搜索
        final lowerQuery = query.toLowerCase();
        final lowerPrompt = entry.promptComment.toLowerCase();
        final lowerNegative = entry.negativePrompt.toLowerCase();
        
        // 在提示词和负面提示词中搜索
        if (lowerPrompt.contains(lowerQuery) || lowerNegative.contains(lowerQuery)) {
          return true;
        }
        
        // 在参数中搜索
        for (var param in entry.parameters.entries) {
          if (param.value.toString().toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
        
        return false;
      }).toList();
    } catch (e) {
      print('搜索历史记录失败: $e');
      return [];
    }
  }
  
  /// 生成缩略图
  Future<String?> _generateThumbnail(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;
      
      // 缩放图片
      final thumbnail = img.copyResize(
        image,
        width: _thumbnailSize,
        height: (image.height * _thumbnailSize / image.width).round(),
        interpolation: img.Interpolation.average,
      );
      
      // 编码为JPEG以减小大小
      final thumbBytes = img.encodeJpg(thumbnail, quality: 85);
      
      // 转换为Base64
      return base64Encode(thumbBytes);
    } catch (e) {
      print('生成缩略图失败: $e');
      return null;
    }
  }
}
