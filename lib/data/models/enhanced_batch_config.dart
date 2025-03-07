import 'dart:math';

/// 批处理变量类型
enum BatchVariableType {
  scale,          // 缩放比例
  steps,          // 步数
  cfgRescale,     // CFG重缩放
  seed,           // 种子值
  prompt,         // 提示词
  negativePrompt, // 负面提示词
  width,          // 宽度
  height,         // 高度
}

/// 批处理变量范围
class BatchVariableRange {
  final BatchVariableType type;
  final dynamic startValue;
  final dynamic endValue;
  final int steps;
  final bool useLongitudinal; // 是否为纵向变化(为false则横向变化)

  BatchVariableRange({
    required this.type,
    required this.startValue,
    required this.endValue,
    this.steps = 5,
    this.useLongitudinal = true,
  });

  /// 获取第n步的值
  dynamic getValueAtStep(int step) {
    if (step < 0) step = 0;
    if (step >= steps) step = steps - 1;
    
    if (startValue is double && endValue is double) {
      return startValue + (endValue - startValue) * step / (steps - 1);
    } else if (startValue is int && endValue is int) {
      return startValue + ((endValue - startValue) * step / (steps - 1)).round();
    } else if (type == BatchVariableType.seed) {
      // 种子值特殊处理，随机生成
      if (startValue == -1 || endValue == -1) {
        return Random().nextInt(1 << 32 - 1);
      } else {
        return startValue + ((endValue - startValue) * step / (steps - 1)).round();
      }
    } else if (type == BatchVariableType.prompt || type == BatchVariableType.negativePrompt) {
      // 提示词特殊处理，不支持渐变，直接返回第step个提示词
      if (startValue is List && step < startValue.length) {
        return startValue[step];
      }
      return startValue;
    }
    
    return startValue;
  }

  /// 将BatchVariableRange转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'start_value': startValue,
      'end_value': endValue,
      'steps': steps,
      'use_longitudinal': useLongitudinal,
    };
  }

  /// 从JSON创建BatchVariableRange
  factory BatchVariableRange.fromJson(Map<String, dynamic> json) {
    return BatchVariableRange(
      type: BatchVariableType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BatchVariableType.scale,
      ),
      startValue: json['start_value'],
      endValue: json['end_value'],
      steps: json['steps'] ?? 5,
      useLongitudinal: json['use_longitudinal'] ?? true,
    );
  }
}

/// 批处理配置
class EnhancedBatchConfig {
  final List<BatchVariableRange> variables;
  final DateTime? scheduledTime; // 预定执行时间(为null则立即执行)
  final bool compareResults; // 是否比较结果
  final bool saveAsGrid; // 是否将结果保存为网格图片
  final bool stopOnError; // 是否在出错时停止

  EnhancedBatchConfig({
    required this.variables,
    this.scheduledTime,
    this.compareResults = true,
    this.saveAsGrid = true,
    this.stopOnError = false,
  });

  /// 获取批处理任务的总数
  int getTotalJobs() {
    if (variables.isEmpty) return 0;
    
    int longitudinalSteps = 1;
    int transverseSteps = 1;
    
    for (var variable in variables) {
      if (variable.useLongitudinal) {
        longitudinalSteps = max(longitudinalSteps, variable.steps);
      } else {
        transverseSteps = max(transverseSteps, variable.steps);
      }
    }
    
    return longitudinalSteps * transverseSteps;
  }

  /// 将EnhancedBatchConfig转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'variables': variables.map((v) => v.toJson()).toList(),
      'scheduled_time': scheduledTime?.toIso8601String(),
      'compare_results': compareResults,
      'save_as_grid': saveAsGrid,
      'stop_on_error': stopOnError,
    };
  }

  /// 从JSON创建EnhancedBatchConfig
  factory EnhancedBatchConfig.fromJson(Map<String, dynamic> json) {
    return EnhancedBatchConfig(
      variables: (json['variables'] as List)
          .map((v) => BatchVariableRange.fromJson(v))
          .toList(),
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'])
          : null,
      compareResults: json['compare_results'] ?? true,
      saveAsGrid: json['save_as_grid'] ?? true,
      stopOnError: json['stop_on_error'] ?? false,
    );
  }
}
