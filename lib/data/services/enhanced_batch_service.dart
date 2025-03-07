import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_casrand/data/models/enhanced_batch_config.dart';
import 'package:nai_casrand/data/models/info_card_content.dart';
import 'package:nai_casrand/data/models/param_config.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/data/models/prompt_config.dart';
import 'package:path_provider/path_provider.dart';

/// 批处理服务回调
typedef BatchProgressCallback = void Function(int current, int total, String message);
typedef BatchCompleteCallback = void Function(List<InfoCardContent> results);
typedef BatchErrorCallback = void Function(String error);

/// 增强型批处理服务
class EnhancedBatchService {
  static const String _batchConfigBox = 'batchConfigBox';
  static const String _scheduledBatchBox = 'scheduledBatchBox';
  
  late Box _batchConfigs;
  late Box _scheduledBatches;
  
  List<EnhancedBatchConfig> _scheduledTasks = [];
  Timer? _schedulerTimer;
  
  bool _isRunning = false;
  
  /// 初始化批处理服务
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    
    _batchConfigs = await Hive.openBox(_batchConfigBox);
    _scheduledBatches = await Hive.openBox(_scheduledBatchBox);
    
    _loadScheduledTasks();
    _startScheduler();
  }
  
  /// 加载计划中的任务
  void _loadScheduledTasks() {
    _scheduledTasks = [];
    
    for (var key in _scheduledBatches.keys) {
      try {
        final configJson = _scheduledBatches.get(key);
        final config = EnhancedBatchConfig.fromJson(configJson);
        
        if (config.scheduledTime != null) {
          _scheduledTasks.add(config);
        }
      } catch (e) {
        print('加载计划任务失败: $e');
      }
    }
    
    // 按时间排序
    _scheduledTasks.sort((a, b) => 
        (a.scheduledTime ?? DateTime.now())
        .compareTo(b.scheduledTime ?? DateTime.now()));
  }
  
  /// 启动任务调度器
  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkScheduledTasks();
    });
  }
  
  /// 检查计划中的任务
  void _checkScheduledTasks() {
    final now = DateTime.now();
    
    List<EnhancedBatchConfig> tasksToRun = [];
    
    for (var task in _scheduledTasks) {
      if (task.scheduledTime != null && task.scheduledTime!.isBefore(now)) {
        tasksToRun.add(task);
      }
    }
    
    // 从列表中移除要运行的任务
    for (var task in tasksToRun) {
      _scheduledTasks.remove(task);
    }
    
    // 运行任务
    for (var task in tasksToRun) {
      // 在实际应用中，这里应该触发通知或启动任务
      print('计划任务启动: ${task.scheduledTime}');
    }
  }
  
  /// 保存批处理配置
  Future<String> saveBatchConfig(EnhancedBatchConfig config) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _batchConfigs.put(id, config.toJson());
    
    // 如果是计划任务，添加到计划列表
    if (config.scheduledTime != null) {
      await _scheduledBatches.put(id, config.toJson());
      _loadScheduledTasks();
    }
    
    return id;
  }
  
  /// 获取批处理配置
  Future<EnhancedBatchConfig?> getBatchConfig(String id) async {
    if (_batchConfigs.containsKey(id)) {
      final configJson = _batchConfigs.get(id);
      return EnhancedBatchConfig.fromJson(configJson);
    }
    return null;
  }
  
  /// 删除批处理配置
  Future<void> deleteBatchConfig(String id) async {
    if (_batchConfigs.containsKey(id)) {
      await _batchConfigs.delete(id);
    }
    
    if (_scheduledBatches.containsKey(id)) {
      await _scheduledBatches.delete(id);
      _loadScheduledTasks();
    }
  }
  
  /// 获取所有批处理配置
  Future<List<EnhancedBatchConfig>> getAllBatchConfigs() async {
    List<EnhancedBatchConfig> configs = [];
    
    for (var key in _batchConfigs.keys) {
      try {
        final configJson = _batchConfigs.get(key);
        configs.add(EnhancedBatchConfig.fromJson(configJson));
      } catch (e) {
        print('加载批处理配置失败: $e');
      }
    }
    
    return configs;
  }
  
  /// 获取所有计划任务
  Future<List<EnhancedBatchConfig>> getAllScheduledTasks() async {
    return List.from(_scheduledTasks);
  }
  
  /// 执行批处理任务
  Future<void> executeBatchTask(
    EnhancedBatchConfig config,
    PayloadConfig payloadConfig,
    Future<InfoCardContent> Function(PayloadConfig) generateFunction,
    BatchProgressCallback onProgress,
    BatchCompleteCallback onComplete,
    BatchErrorCallback onError,
  ) async {
    if (_isRunning) {
      onError('已有批处理任务正在运行');
      return;
    }
    
    _isRunning = true;
    
    try {
      final totalJobs = config.getTotalJobs();
      final results = <InfoCardContent>[];
      
      int longitudinalSteps = 1;
      int transverseSteps = 1;
      
      // 计算纵向和横向步数
      for (var variable in config.variables) {
        if (variable.useLongitudinal) {
          longitudinalSteps = max(longitudinalSteps, variable.steps);
        } else {
          transverseSteps = max(transverseSteps, variable.steps);
        }
      }
      
      // 保存原始配置
      final originalParamConfig = ParamConfig.fromJson(payloadConfig.paramConfig.toJson());
      final originalPromptConfig = PromptConfig.fromJson(payloadConfig.rootPromptConfig.toJson());
      
      // 执行生成任务
      var jobCount = 0;
      
      for (var y = 0; y < longitudinalSteps; y++) {
        // 应用纵向变量
        _applyVariableValues(config.variables.where((v) => v.useLongitudinal), y, payloadConfig);
        
        for (var x = 0; x < transverseSteps; x++) {
          // 应用横向变量
          _applyVariableValues(config.variables.where((v) => !v.useLongitudinal), x, payloadConfig);
          
          jobCount++;
          onProgress(jobCount, totalJobs, '正在生成: $jobCount / $totalJobs');
          
          try {
            final result = await generateFunction(payloadConfig);
            results.add(result);
          } catch (e) {
            print('批处理任务生成出错: $e');
            if (config.stopOnError) {
              throw Exception('批处理停止: $e');
            }
          }
        }
      }
      
      // 恢复原始配置
      payloadConfig.paramConfig = originalParamConfig;
      payloadConfig.rootPromptConfig = originalPromptConfig;
      
      // 如果需要保存为网格图片
      if (config.saveAsGrid && results.isNotEmpty) {
        final gridImage = await _createGridImage(results, transverseSteps);
        if (gridImage != null) {
          // 将网格图片添加到结果中
          results.add(InfoCardContent(
            title: '批处理网格结果',
            info: '批处理结果网格图',
            additionalInfo: {
              'grid_rows': longitudinalSteps,
              'grid_cols': transverseSteps,
              'total_images': results.length,
            },
            imageBytes: gridImage,
          ));
        }
      }
      
      onComplete(results);
    } catch (e) {
      onError('批处理执行失败: $e');
    } finally {
      _isRunning = false;
    }
  }
  
  /// 应用变量值到配置
  void _applyVariableValues(
    Iterable<BatchVariableRange> variables,
    int step,
    PayloadConfig payloadConfig,
  ) {
    for (var variable in variables) {
      final value = variable.getValueAtStep(step);
      
      switch (variable.type) {
        case BatchVariableType.scale:
          payloadConfig.paramConfig.scale = value;
          break;
        case BatchVariableType.steps:
          payloadConfig.paramConfig.steps = value;
          break;
        case BatchVariableType.cfgRescale:
          payloadConfig.paramConfig.cfgRescale = value;
          break;
        case BatchVariableType.seed:
          payloadConfig.paramConfig.seed = value;
          payloadConfig.paramConfig.randomSeed = false;
          break;
        case BatchVariableType.prompt:
          // 设置提示词需要特殊处理
          if (value is String) {
            // 简单的字符串提示词
            final promptConfig = PromptConfig();
            promptConfig.type = 'str';
            promptConfig.strs = [value];
            payloadConfig.rootPromptConfig = promptConfig;
          }
          break;
        case BatchVariableType.negativePrompt:
          payloadConfig.paramConfig.negativePrompt = value;
          break;
        case BatchVariableType.width:
          if (payloadConfig.paramConfig.sizes.isNotEmpty) {
            final height = payloadConfig.paramConfig.sizes.first.height;
            payloadConfig.paramConfig.sizes = [GenerationSize(width: value, height: height)];
          }
          break;
        case BatchVariableType.height:
          if (payloadConfig.paramConfig.sizes.isNotEmpty) {
            final width = payloadConfig.paramConfig.sizes.first.width;
            payloadConfig.paramConfig.sizes = [GenerationSize(width: width, height: value)];
          }
          break;
      }
    }
  }
  
  /// 创建网格图片
  Future<Uint8List?> _createGridImage(List<InfoCardContent> results, int columns) async {
    if (results.isEmpty) return null;
    
    final rows = (results.length / columns).ceil();
    
    try {
      // 加载所有图片
      List<img.Image> images = [];
      for (var result in results) {
        if (result.imageBytes != null) {
          final image = img.decodeImage(result.imageBytes!);
          if (image != null) {
            images.add(image);
          }
        }
      }
      
      if (images.isEmpty) return null;
      
      // 计算每个图片的尺寸
      final imageWidth = images.first.width;
      final imageHeight = images.first.height;
      
      // 创建网格图片
      final gridImage = img.Image(
        width: imageWidth * columns,
        height: imageHeight * rows,
      );
      
      // 绘制图片到网格中
      for (var i = 0; i < images.length; i++) {
        final x = (i % columns) * imageWidth;
        final y = (i ~/ columns) * imageHeight;
        
        img.compositeImage(
          gridImage,
          images[i],
          dstX: x,
          dstY: y,
        );
      }
      
      // 编码为PNG格式
      return Uint8List.fromList(img.encodePng(gridImage));
    } catch (e) {
      print('创建网格图片失败: $e');
      return null;
    }
  }
  
  /// 取消当前批处理任务
  void cancelBatch() {
    _isRunning = false;
  }
  
  /// 是否有任务正在运行
  bool isRunning() {
    return _isRunning;
  }
  
  /// 释放资源
  void dispose() {
    _schedulerTimer?.cancel();
  }
}
