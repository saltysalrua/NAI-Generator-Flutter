import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nai_casrand/data/models/history_entry.dart';
import 'package:nai_casrand/data/models/payload_config.dart';
import 'package:nai_casrand/data/services/history_service.dart';
import 'package:share_plus/share_plus.dart';

/// 历史记录页面的视图模型
class HistoryViewModel extends ChangeNotifier {
  final HistoryService _historyService;
  final ScrollController scrollController = ScrollController();
  
  List<HistoryEntry> _historyEntries = [];
  List<HistoryEntry> _filteredEntries = [];
  
  bool _isLoading = false;
  bool _showOnlyFavorites = false;
  String _searchQuery = '';
  bool _hasMoreData = true;
  int _currentOffset = 0;
  final int _pageSize = 20; // 每页加载的历史记录数量
  
  HistoryViewModel({HistoryService? historyService}) 
      : _historyService = historyService ?? GetIt.instance<HistoryService>();
  
  // Getters
  List<HistoryEntry> get historyEntries => _filteredEntries;
  bool get isLoading => _isLoading;
  bool get showOnlyFavorites => _showOnlyFavorites;
  String get searchQuery => _searchQuery;
  bool get hasMoreData => _hasMoreData;
  
  /// 初始化视图模型
  Future<void> init() async {
    _setLoading(true);
    
    await _historyService.init();
    scrollController.addListener(_scrollListener);
    
    // 加载初始数据
    await _loadInitialData();
    
    _setLoading(false);
  }
  
  /// 释放资源
  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }
  
  /// 加载初始数据
  Future<void> _loadInitialData() async {
    _currentOffset = 0;
    _hasMoreData = true;
    
    if (_showOnlyFavorites) {
      _historyEntries = await _historyService.getFavoriteHistory();
      _hasMoreData = false; // 收藏不支持分页加载
    } else if (_searchQuery.isNotEmpty) {
      _historyEntries = await _historyService.searchHistory(_searchQuery);
      _hasMoreData = false; // 搜索不支持分页加载
    } else {
      _historyEntries = await _historyService.getAllHistory(limit: _pageSize, offset: 0);
      _hasMoreData = _historyEntries.length >= _pageSize;
      _currentOffset = _historyEntries.length;
    }
    
    _filterEntries();
  }
  
  /// 加载更多数据
  Future<void> _loadMoreData() async {
    if (!_hasMoreData || _showOnlyFavorites || _searchQuery.isNotEmpty) {
      return;
    }
    
    _setLoading(true);
    
    final newEntries = await _historyService.getAllHistory(
      limit: _pageSize, 
      offset: _currentOffset
    );
    
    if (newEntries.isEmpty) {
      _hasMoreData = false;
    } else {
      _historyEntries.addAll(newEntries);
      _currentOffset += newEntries.length;
      _hasMoreData = newEntries.length >= _pageSize;
      _filterEntries();
    }
    
    _setLoading(false);
  }
  
  /// 滚动监听
  void _scrollListener() {
    if (scrollController.position.pixels >= 
        scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 设置搜索查询
  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await _loadInitialData();
  }
  
  /// 切换是否只显示收藏
  Future<void> toggleShowOnlyFavorites() async {
    _showOnlyFavorites = !_showOnlyFavorites;
    await _loadInitialData();
  }
  
  /// 切换收藏状态
  Future<void> toggleFavorite(HistoryEntry entry) async {
    if (entry.isFavorite) {
      await _historyService.unfavoriteHistoryEntry(entry.id);
    } else {
      await _historyService.favoriteHistoryEntry(entry.id);
    }
    
    // 更新条目
    final index = _historyEntries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _historyEntries[index] = _historyEntries[index].copyWithFavorite(!entry.isFavorite);
      
      // 如果只显示收藏，则需要重新过滤
      if (_showOnlyFavorites) {
        await _loadInitialData();
      } else {
        _filterEntries();
      }
    }
  }
  
  /// 删除历史记录
  Future<bool> deleteHistoryEntry(String id) async {
    final result = await _historyService.deleteHistoryEntry(id);
    if (result) {
      _historyEntries.removeWhere((entry) => entry.id == id);
      _filterEntries();
    }
    return result;
  }
  
  /// 清空历史记录
  Future<bool> clearHistory() async {
    final result = await _historyService.clearHistory();
    if (result) {
      _historyEntries.clear();
      _filterEntries();
    }
    return result;
  }
  
  /// 应用历史记录配置
  Future<void> applyHistoryConfiguration(HistoryEntry entry, PayloadConfig payloadConfig) async {
    if (entry.promptConfig != null) {
      payloadConfig.rootPromptConfig = entry.promptConfig!;
    }
    
    if (entry.characterConfigs != null && entry.characterConfigs!.isNotEmpty) {
      payloadConfig.characterConfigList = entry.characterConfigs!;
    }
    
    if (entry.paramConfig != null) {
      payloadConfig.paramConfig = entry.paramConfig!;
    }
    
    notifyListeners();
  }
  
  /// 分享历史记录
  Future<void> shareHistoryEntry(HistoryEntry entry) async {
    final file = File(entry.imageFilePath);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(entry.imageFilePath)],
        text: entry.promptComment,
      );
    }
  }
  
  /// 根据当前筛选条件过滤历史记录
  void _filterEntries() {
    _filteredEntries = _historyEntries;
    notifyListeners();
  }
  
  /// 获取单个历史记录
  Future<HistoryEntry?> getHistoryEntry(String id) async {
    return await _historyService.getHistoryEntry(id);
  }
}
