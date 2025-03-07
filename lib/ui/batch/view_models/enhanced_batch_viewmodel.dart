import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/models/enhanced_batch_config.dart';
import 'package:nai_casrand/data/models/info_card_content.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/data/services/api_service.dart';
import 'package:nai_casrand/data/services/enhanced_batch_service.dart';
import 'package:nai_casrand/data/services/image_service.dart';
import 'package:nai_casrand/data/use_cases/generate_payload_use_case.dart';

/// 增强型批处理视图模型
class EnhancedBatchViewModel extends ChangeNotifier {
  final EnhancedBatchService _batchService;
  final PayloadConfig payloadConfig;
  
  List<BatchVariableRange> _variables = [];
  DateTime? _scheduledTime;
  bool _compareResults = true;
  bool _saveAsGrid = true;
  bool _stopOnError = false;
  
  String _progressMessage = '';
  int _currentProgress = 0;
  int _totalProgress = 0;
  bool _isRunning = false;
  List<InfoCardContent> _results = [];
  String _error = '';
  
  List<EnhancedBatchConfig> _savedConfigs = [];
  List<EnhancedBatchConfig> _scheduledTasks = [];
  
  // Getters
  List<BatchVariableRange> get variables => _variables;
  DateTime? get scheduledTime => _scheduledTime;
  bool get compareResults => _compareResults;
  bool get saveAsGrid => _saveAsGrid;
  bool get stopOnError => _stopOnError;
  
  String get progressMessage => _progressMessage;
  int get currentProgress => _currentProgress;
  int get totalProgress => _totalProgress;
  bool get isRunning => _isRunning;
  List<InfoCardContent> get results => _results;
  String get error => _error;
  
  List<EnhancedBatchConfig> get savedConfigs => _savedConfigs;
  List<EnhancedBatchConfig> get scheduledTasks => _scheduledTasks;
  
  EnhancedBatchViewModel({
    required this.payloadConfig,
    EnhancedBatchService? batchService,
  }) : _batchService = batchService ?? GetIt.instance<EnhancedBatchService>();
  
  /// 初始化视图模型
  Future<void> init() async {
    await _batchService.init();
    await _loadSavedConfigs();
    await _loadScheduledTasks();
  }
  
  /// 加载保存的配置
  Future<void> _loadSavedConfigs() async {
    _savedConfigs = await _batchService.getAllBatchConfigs();
    notifyListeners();
  }
  
  /// 加载计划任务
  Future<void> _loadScheduledTasks() async {
    _scheduledTasks = await _batchService.getAllScheduledTasks();
    notifyListeners();
  }
  
  /// 添加变量
  void addVariable(BatchVariableRange variable) {
    _variables.add(variable);
    notifyListeners();
  }
  
  /// 更新变量
  void updateVariable(int index, BatchVariableRange variable) {
    if (index >= 0 && index < _variables.length) {
      _variables[index] = variable;
      notifyListeners();
    }
  }
  
  /// 删除变量
  void removeVariable(int index) {
    if (index >= 0 && index < _variables.length) {
      _variables.removeAt(index);
      notifyListeners();
    }
  }
  
  /// 设置计划时间
  void setScheduledTime(DateTime? time) {
    _scheduledTime = time;
    notifyListeners();
  }
  
  /// 设置是否比较结果
  void setCompareResults(bool value) {
    _compareResults = value;
    notifyListeners();
  }
  
  /// 设置是否保存为网格
  void setSaveAsGrid(bool value) {
    _saveAsGrid = value;
    notifyListeners();
  }
  
  /// 设置是否在出错时停止
  void setStopOnError(bool value) {
    _stopOnError = value;
    notifyListeners();
  }
  
  /// 创建批处理配置
  EnhancedBatchConfig createBatchConfig() {
    return EnhancedBatchConfig(
      variables: List.from(_variables),
      scheduledTime: _scheduledTime,
      compareResults: _compareResults,
      saveAsGrid: _saveAsGrid,
      stopOnError: _stopOnError,
    );
  }
  
  /// 加载批处理配置
  void loadBatchConfig(EnhancedBatchConfig config) {
    _variables = List.from(config.variables);
    _scheduledTime = config.scheduledTime;
    _compareResults = config.compareResults;
    _saveAsGrid = config.saveAsGrid;
    _stopOnError = config.stopOnError;
    notifyListeners();
  }
  
  /// 保存批处理配置
  Future<String> saveBatchConfig() async {
    final config = createBatchConfig();
    final id = await _batchService.saveBatchConfig(config);
    await _loadSavedConfigs();
    await _loadScheduledTasks();
    return id;
  }
  
  /// 删除批处理配置
  Future<void> deleteBatchConfig(String id) async {
    await _batchService.deleteBatchConfig(id);
    await _loadSavedConfigs();
    await _loadScheduledTasks();
  }
  
  /// 执行批处理
  Future<void> executeBatch() async {
    if (_isRunning) {
      return;
    }
    
    if (_variables.isEmpty) {
      _error = '请添加至少一个变量进行批处理';
      notifyListeners();
      return;
    }
    
    _isRunning = true;
    _currentProgress = 0;
    _totalProgress = 0;
    _progressMessage = '准备中...';
    _results = [];
    _error = '';
    notifyListeners();
    
    final config = createBatchConfig();
    
    await _batchService.executeBatchTask(
      config,
      payloadConfig,
      _generateImage,
      (current, total, message) {
        _currentProgress = current;
        _totalProgress = total;
        _progressMessage = message;
        notifyListeners();
      },
      (results) {
        _results = results;
        _isRunning = false;
        _progressMessage = '完成';
        notifyListeners();
      },
      (error) {
        _error = error;
        _isRunning = false;
        notifyListeners();
      },
    );
  }
  
  /// 取消批处理
  void cancelBatch() {
    if (_isRunning) {
      _batchService.cancelBatch();
      _isRunning = false;
      _progressMessage = '已取消';
      notifyListeners();
    }
  }
  
  /// 生成图片的函数
  Future<InfoCardContent> _generateImage(PayloadConfig config) async {
    try {
      final imageService = GetIt.instance<ImageService>();
      final apiService = GetIt.instance<ApiService>();
      
      final generator = GeneratePayloadUseCase(
        rootPromptConfig: config.rootPromptConfig,
        characterConfigList: config.characterConfigList,
        vibeConfigList: config.vibeConfigList,
        paramConfig: config.paramConfig,
        fileNameKey: config.settings.fileNamePrefixKey,
      );
      
      final payloadResult = generator();
      final endpoint = config.settings.debugApiEnabled
          ? config.settings.debugApiPath
          : 'https://image.novelai.net/ai/generate-image';
      
      final request = ApiRequest(
        endpoint: endpoint,
        proxy: config.settings.proxy,
        headers: config.getHeaders(),
        payload: payloadResult.payload,
      );
      
      final response = await apiService.fetchData(request);
      var imageBytes = imageService.processResponse(response.data);
      
      // 添加自定义元数据
      if (config.settings.metadataEraseEnabled) {
        final metadataString = config.settings.customMetadataEnabled
            ? config.settings.customMetadataContent
            : '';
        imageBytes = await imageService.embedMetadata(imageBytes, metadataString);
      }
      
      return InfoCardContent(
        title: '批处理生成',
        info: payloadResult.comment,
        additionalInfo: payloadResult.payload,
        imageBytes: imageBytes,
      );
    } catch (e) {
      print('生成图片失败: $e');
      throw Exception('生成图片失败: $e');
    }
  }
}
