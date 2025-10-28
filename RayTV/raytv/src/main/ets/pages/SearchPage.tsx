// 搜索页面组件
// 提供视频搜索、搜索历史、热门搜索等功能

import React, { useState, useEffect, useRef } from 'react';
import { View, Text, TextInput, TouchableOpacity, FlatList, StyleSheet, Keyboard, BackHandler } from '@ohos.universal';
import { AppNavigator } from '../navigation/AppNavigator';
import { SearchService } from '../service/search/SearchService';
import { AnalyticsService } from '../service/analytics/AnalyticsService';
import { CrawlerService } from '../service/spider/CrawlerService';
import { VideoItem } from '../data/bean/Vod.ets';
import { LiveStream } from '../data/bean/Live.ets';

const SearchPage: React.FC = () => {
  const [keyword, setKeyword] = useState('');
  const [searchHistory, setSearchHistory] = useState<string[]>([]);
  const [hotSearches, setHotSearches] = useState<Array<{ keyword: string; count: number }>>([]);
  const [searchSuggestions, setSearchSuggestions] = useState<string[]>([]);
  const [searchResults, setSearchResults] = useState<Array<VideoItem | LiveStream>>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);
  
  const searchInputRef = useRef<TextInput>(null);
  const appNavigator = AppNavigator.getInstance();
  const searchService = SearchService.getInstance();
  const analyticsService = AnalyticsService.getInstance();
  const crawlerService = CrawlerService.getInstance();

  useEffect(() => {
    analyticsService.trackPageView('SearchPage');
    loadSearchData();
    
    // 监听返回键
    const backHandler = BackHandler.addEventListener('hardwareBackPress', handleBackPress);
    
    return () => {
      backHandler.remove();
    };
  }, []);

  // 当组件挂载后，自动聚焦搜索框
  useEffect(() => {
    setTimeout(() => {
      searchInputRef.current?.focus();
    }, 100);
  }, []);

  const handleBackPress = () => {
    if (hasSearched) {
      // 如果已经搜索过，清空结果返回搜索页
      setSearchResults([]);
      setHasSearched(false);
      setKeyword('');
      searchInputRef.current?.focus();
      return true;
    }
    appNavigator.goBack();
    return true;
  };

  const loadSearchData = async () => {
    try {
      // 加载搜索历史
      const history = await searchService.getSearchHistory();
      setSearchHistory(history);
      
      // 加载热门搜索
      const hot = await searchService.getHotSearches();
      setHotSearches(hot.length > 0 ? hot : getMockHotSearches());
    } catch (error) {
      console.error('Failed to load search data:', error);
      // 加载失败时使用模拟数据
      setHotSearches(getMockHotSearches());
    }
  };

  const handleSearch = async (text: string = keyword) => {
    if (!text.trim()) return;
    
    try {
      Keyboard.dismiss();
      setIsSearching(true);
      setHasSearched(true);
      setShowSuggestions(false);
      
      // 保存搜索历史
      await searchService.addToSearchHistory(text);
      setSearchHistory(await searchService.getSearchHistory());
      
      // 记录搜索事件
      analyticsService.trackSearch(text);
      
      // 执行搜索
      const results = await performSearch(text);
      setSearchResults(results);
    } catch (error) {
      console.error('Search failed:', error);
      // 搜索失败时返回模拟数据
      setSearchResults(getMockSearchResults(text));
    } finally {
      setIsSearching(false);
    }
  };

  const performSearch = async (text: string): Promise<Array<VideoItem | LiveStream>> => {
    try {
      // 从爬虫服务搜索
      const sites = await crawlerService.getActiveSites();
      const allResults: Array<VideoItem | LiveStream> = [];
      
      for (const site of sites) {
        try {
          const results = await crawlerService.callSiteMethod<any[]>(site.key, 'search', [text]);
          if (results && Array.isArray(results)) {
            const items = results.slice(0, 5).map(item => ({
              id: item.id || `unknown_${Date.now()}_${Math.random()}`,
              title: item.title || '未知标题',
              cover: item.cover || '',
              siteKey: site.key,
              originalUrl: item.url || '',
              rating: item.rating || 0,
              updateInfo: item.updateInfo || ''
            }));
            allResults.push(...items);
          }
        } catch (error) {
          console.warn(`Search failed for site ${site.name}:`, error);
        }
      }
      
      // 如果没有结果，尝试搜索直播
      if (allResults.length === 0) {
        const liveResults = await crawlerService.callSiteMethod<any[]>('default', 'searchLive', [text]);
        if (liveResults && Array.isArray(liveResults)) {
          const items = liveResults.map(item => ({
            id: item.id || `live_${Date.now()}_${Math.random()}`,
            title: item.title || '未知直播',
            cover: item.cover || '',
            siteKey: 'default',
            url: item.url || '',
            source: item.source || '',
            isLive: true
          }));
          allResults.push(...items);
        }
      }
      
      return allResults.length > 0 ? allResults : getMockSearchResults(text);
    } catch (error) {
      console.error('Perform search failed:', error);
      return getMockSearchResults(text);
    }
  };

  const handleKeywordChange = async (text: string) => {
    setKeyword(text);
    
    if (text.trim()) {
      // 显示搜索建议
      try {
        const suggestions = await searchService.getSearchSuggestions(text);
        setSearchSuggestions(suggestions.length > 0 ? suggestions : getMockSuggestions(text));
        setShowSuggestions(true);
      } catch (error) {
        console.warn('Failed to get search suggestions:', error);
        setSearchSuggestions(getMockSuggestions(text));
        setShowSuggestions(true);
      }
    } else {
      setShowSuggestions(false);
      setSearchSuggestions([]);
    }
  };

  const handleSuggestionPress = (suggestion: string) => {
    setKeyword(suggestion);
    setShowSuggestions(false);
    handleSearch(suggestion);
  };

  const handleHistoryPress = (history: string) => {
    setKeyword(history);
    handleSearch(history);
  };

  const handleHotSearchPress = (hotSearch: { keyword: string; count: number }) => {
    setKeyword(hotSearch.keyword);
    handleSearch(hotSearch.keyword);
  };

  const clearSearchHistory = async () => {
    try {
      await searchService.clearSearchHistory();
      setSearchHistory([]);
    } catch (error) {
      console.error('Failed to clear search history:', error);
    }
  };

  const navigateToDetail = (item: VideoItem | LiveStream) => {
    const isLiveItem = 'isLive' in item && item.isLive;
    
    appNavigator.navigateToDetail({
      id: item.id,
      siteKey: item.siteKey,
      type: isLiveItem ? 'live' : 'vod',
      title: item.title
    });
  };

  // 模拟数据函数
  const getMockHotSearches = () => [
    { keyword: '流浪地球2', count: 123456 },
    { keyword: '满江红', count: 98765 },
    { keyword: '三体', count: 87654 },
    { keyword: '狂飙', count: 76543 },
    { keyword: '去有风的地方', count: 65432 },
    { keyword: '显微镜下的大明', count: 54321 },
    { keyword: '无名', count: 43210 },
    { keyword: '中国奇谭', count: 32100 }
  ];

  const getMockSuggestions = (text: string) => {
    const baseSuggestions = [
      `${text}电影`,
      `${text}电视剧`,
      `${text}动漫`,
      `${text}最新`,
      `${text}高清`,
      ` ${text}`,
      `${text} 在线观看`,
      `${text}完整版`
    ];
    return baseSuggestions;
  };

  const getMockSearchResults = (text: string): Array<VideoItem | LiveStream> => {
    // 生成模拟搜索结果
    const results: Array<VideoItem | LiveStream> = [];
    
    // 添加一些模拟的电影/电视剧结果
    for (let i = 0; i < 8; i++) {
      results.push({
        id: `mock_vod_${i}`,
        title: `${text}相关视频 ${i + 1}`,
        cover: '',
        siteKey: 'mock',
        originalUrl: '',
        rating: 7 + Math.random() * 2,
        updateInfo: i % 2 === 0 ? '全40集' : `更新至${i + 1}集`
      });
    }
    
    // 添加一些模拟的直播结果
    results.push({
      id: 'mock_live_1',
      title: `${text}直播频道`,
      cover: '',
      siteKey: 'mock_live',
      url: '',
      source: '模拟源',
      isLive: true,
      onlineCount: Math.floor(Math.random() * 10000)
    });
    
    return results;
  };

  const renderSearchResults = () => {
    if (isSearching) {
      return (
        <View style={styles.loadingContainer}>
          <Text>搜索中...</Text>
        </View>
      );
    }
    
    if (searchResults.length === 0 && hasSearched) {
      return (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>未找到与「{keyword}」相关的内容</Text>
          <Text style={styles.emptyHint}>请尝试其他关键词</Text>
        </View>
      );
    }
    
    return (
      <FlatList
        data={searchResults}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <SearchResultItem
            item={item}
            onPress={() => navigateToDetail(item)}
          />
        )}
        contentContainerStyle={styles.resultsList}
      />
    );
  };

  const renderSearchPage = () => {
    return (
      <View style={styles.searchPageContainer}>
        {/* 搜索建议 */}
        {showSuggestions && (
          <View style={styles.suggestionsContainer}>
            <FlatList
              data={searchSuggestions}
              keyExtractor={(item, index) => `suggestion_${index}`}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={styles.suggestionItem}
                  onPress={() => handleSuggestionPress(item)}
                >
                  <Text style={styles.suggestionText}>{item}</Text>
                </TouchableOpacity>
              )}
            />
          </View>
        )}
        
        {/* 搜索历史 */}
        {!showSuggestions && searchHistory.length > 0 && (
          <View style={styles.historyContainer}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>搜索历史</Text>
              <TouchableOpacity onPress={clearSearchHistory}>
                <Text style={styles.clearButton}>清除</Text>
              </TouchableOpacity>
            </View>
            <View style={styles.historyList}>
              {searchHistory.map((item, index) => (
                <TouchableOpacity
                  key={`history_${index}`}
                  style={styles.historyItem}
                  onPress={() => handleHistoryPress(item)}
                >
                  <Text style={styles.historyText}>{item}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}
        
        {/* 热门搜索 */}
        <View style={styles.hotContainer}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>热门搜索</Text>
          </View>
          <View style={styles.hotList}>
            {hotSearches.map((item, index) => (
              <TouchableOpacity
                key={`hot_${index}`}
                style={styles.hotItem}
                onPress={() => handleHotSearchPress(item)}
              >
                <View style={[
                  styles.hotRankBadge,
                  index < 3 && styles.hotRankTop
                ]}>
                  <Text style={[
                    styles.hotRankText,
                    index < 3 && styles.hotRankTextTop
                  ]}>{index + 1}</Text>
                </View>
                <Text style={styles.hotKeyword} numberOfLines={1}>{item.keyword}</Text>
                <Text style={styles.hotCount}>热度 {item.count}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {/* 搜索栏 */}
      <View style={styles.searchBarContainer}>
        <TouchableOpacity onPress={handleBackPress} style={styles.backButton}>
          <Text style={styles.backIcon}>←</Text>
        </TouchableOpacity>
        <View style={styles.searchInputContainer}>
          <Text style={styles.searchIcon}>🔍</Text>
          <TextInput
            ref={searchInputRef}
            style={styles.searchInput}
            placeholder="搜索电影、电视剧、综艺、动漫"
            value={keyword}
            onChange={handleKeywordChange}
            onSubmit={handleSearch}
            autoFocus
          />
          {keyword.length > 0 && (
            <TouchableOpacity
              onPress={() => {
                setKeyword('');
                setShowSuggestions(false);
                setHasSearched(false);
                setSearchResults([]);
                searchInputRef.current?.focus();
              }}
              style={styles.clearInputButton}
            >
              <Text style={styles.clearInputIcon}>✕</Text>
            </TouchableOpacity>
          )}
        </View>
        <TouchableOpacity onPress={() => handleSearch()} style={styles.searchButton}>
          <Text style={styles.searchButtonText}>搜索</Text>
        </TouchableOpacity>
      </View>
      
      {/* 内容区域 */}
      {hasSearched ? renderSearchResults() : renderSearchPage()}
    </View>
  );
};

// 搜索结果项组件
interface SearchResultItemProps {
  item: VideoItem | LiveStream;
  onPress: () => void;
}

const SearchResultItem: React.FC<SearchResultItemProps> = ({ item, onPress }) => {
  const isLiveItem = 'isLive' in item && item.isLive;
  
  return (
    <TouchableOpacity style={styles.resultItem} onPress={onPress}>
      <View style={styles.resultCover}>
        {item.cover ? (
          <Image source={{ uri: item.cover }} style={styles.coverImage} />
        ) : (
          <View style={styles.coverPlaceholder}>
            <Text style={styles.coverPlaceholderText}>
              {isLiveItem ? '直' : '影'}
            </Text>
          </View>
        )}
        {isLiveItem && (
          <View style={styles.liveBadge}>
            <Text style={styles.liveBadgeText}>直播</Text>
          </View>
        )}
      </View>
      <View style={styles.resultInfo}>
        <Text style={styles.resultTitle} numberOfLines={2}>{item.title}</Text>
        
        {!isLiveItem && 'rating' in item && item.rating > 0 && (
          <Text style={styles.resultRating}>评分: {item.rating.toFixed(1)}</Text>
        )}
        
        {!isLiveItem && 'updateInfo' in item && item.updateInfo && (
          <Text style={styles.resultUpdateInfo}>{item.updateInfo}</Text>
        )}
        
        {isLiveItem && 'onlineCount' in item && (
          <Text style={styles.resultOnlineCount}>
            在线: {item.onlineCount}
          </Text>
        )}
        
        <Text style={styles.resultSource} numberOfLines={1}>
          来源: {item.siteKey}
        </Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  searchBarContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  backButton: {
    marginRight: 8,
    padding: 4,
  },
  backIcon: {
    fontSize: 24,
    color: '#333',
  },
  searchInputContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f0f0f0',
    borderRadius: 16,
    paddingHorizontal: 12,
    marginRight: 8,
  },
  searchIcon: {
    fontSize: 16,
    marginRight: 8,
    color: '#999',
  },
  searchInput: {
    flex: 1,
    height: 36,
    fontSize: 16,
    color: '#333',
  },
  clearInputButton: {
    padding: 4,
  },
  clearInputIcon: {
    fontSize: 16,
    color: '#999',
  },
  searchButton: {
    paddingHorizontal: 8,
  },
  searchButtonText: {
    fontSize: 16,
    color: '#007aff',
  },
  searchPageContainer: {
    flex: 1,
  },
  suggestionsContainer: {
    backgroundColor: '#fff',
    maxHeight: 300,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  suggestionItem: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  suggestionText: {
    fontSize: 16,
    color: '#333',
  },
  historyContainer: {
    backgroundColor: '#fff',
    paddingVertical: 16,
    marginBottom: 8,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
  },
  clearButton: {
    fontSize: 14,
    color: '#999',
  },
  historyList: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 12,
  },
  historyItem: {
    backgroundColor: '#f0f0f0',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 16,
    marginRight: 12,
    marginBottom: 12,
  },
  historyText: {
    fontSize: 14,
    color: '#333',
  },
  hotContainer: {
    backgroundColor: '#fff',
    paddingVertical: 16,
  },
  hotList: {
    paddingHorizontal: 16,
  },
  hotItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  hotRankBadge: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: '#999',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  hotRankTop: {
    backgroundColor: '#ff4757',
  },
  hotRankText: {
    fontSize: 12,
    color: '#fff',
    fontWeight: 'bold',
  },
  hotRankTextTop: {
    color: '#fff',
  },
  hotKeyword: {
    flex: 1,
    fontSize: 16,
    color: '#333',
  },
  hotCount: {
    fontSize: 14,
    color: '#999',
    marginLeft: 8,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  emptyText: {
    fontSize: 16,
    color: '#333',
    marginBottom: 8,
  },
  emptyHint: {
    fontSize: 14,
    color: '#999',
  },
  resultsList: {
    padding: 16,
  },
  resultItem: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 12,
    marginBottom: 12,
  },
  resultCover: {
    width: 100,
    height: 140,
    marginRight: 12,
    position: 'relative',
  },
  coverImage: {
    width: '100%',
    height: '100%',
    borderRadius: 4,
  },
  coverPlaceholder: {
    width: '100%',
    height: '100%',
    borderRadius: 4,
    backgroundColor: '#e0e0e0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  coverPlaceholderText: {
    fontSize: 24,
    color: '#999',
  },
  liveBadge: {
    position: 'absolute',
    top: 4,
    left: 4,
    backgroundColor: '#ff4757',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 2,
  },
  liveBadgeText: {
    fontSize: 10,
    color: '#fff',
  },
  resultInfo: {
    flex: 1,
    justifyContent: 'space-between',
  },
  resultTitle: {
    fontSize: 16,
    fontWeight: '500',
    color: '#333',
    marginBottom: 8,
  },
  resultRating: {
    fontSize: 14,
    color: '#ff6b00',
    marginBottom: 4,
  },
  resultUpdateInfo: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
  resultOnlineCount: {
    fontSize: 14,
    color: '#ff4757',
    marginBottom: 4,
  },
  resultSource: {
    fontSize: 12,
    color: '#999',
  },
});

// 导入Image组件
const { Image } = require('@ohos.universal');

export default SearchPage;