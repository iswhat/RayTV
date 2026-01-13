// SearchLiveUseCase.ets - 搜索直播用例 // Search live use case
import Logger from '../../common/util/Logger';
import { Live } from '../../data/bean/Live';
import { LiveRepository } from '../../data/repository/LiveRepository';
import { SearchHistoryRepository } from '../../data/repository/SearchHistoryRepository';
import { CacheRepository } from '../../data/repository/CacheRepository';

const TAG = 'SearchLiveUseCase';
const SEARCH_CACHE_EXPIRY = 5 * 60 * 1000; // 5分钟缓存过期时间 // 5 minutes cache expiry time

/**
 * 搜索直播内容的业务用例 // Business use case for searching live content
 */
export class SearchLiveUseCase {
  private liveRepository: LiveRepository;
  private searchHistoryRepository: SearchHistoryRepository;
  private cacheRepository: CacheRepository;
  
  constructor(
    liveRepository: LiveRepository,
    searchHistoryRepository: SearchHistoryRepository,
    cacheRepository: CacheRepository
  ) {
    this.liveRepository = liveRepository;
    this.searchHistoryRepository = searchHistoryRepository;
    this.cacheRepository = cacheRepository;
  }
  
  /**
   * 搜索直播频道 // Search live channels
   * @param keyword 搜索关键词 // Search keyword
   * @param includeHistory 是否包含历史记录搜索 // Whether to include history search
   * @returns 搜索结果 // Search results
   */
  public async searchLive(keyword: string, includeHistory: boolean = true): Promise<{
    channels: Live[];
    historyMatches: Live[];
  }> {
    try {
      Logger.info(TAG, `Searching live with keyword: ${keyword}`);
      
      if (!keyword || keyword.trim().length === 0) {
        return { channels: [], historyMatches: [] };
      }
      
      // 生成缓存键 // Generate cache key
      const cacheKey = `live_search_${keyword.toLowerCase()}`;
      
      // 尝试从缓存获取 // Try to get from cache
      const cachedResult = await this.getSearchCache(cacheKey);
      if (cachedResult) {
        Logger.info(TAG, `Using cached search results for: ${keyword}`);
        return cachedResult;
      }
      
      // 并行执行搜索 // Execute search in parallel
      const [channels, historyMatches] = await Promise.all([
        this.liveRepository.searchLiveChannels(keyword),
        includeHistory ? this.searchInHistory(keyword) : Promise.resolve([])
      ]);
      
      const result = {
        channels,
        historyMatches
      };
      
      // 缓存结果 // Cache result
      await this.cacheSearchResult(cacheKey, result);
      
      // 保存搜索历史 // Save search history
      await this.saveSearchHistory(keyword);
      
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to search live: ${error}`);
      return { channels: [], historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键词 // Get hot search keywords
   * @param limit 限制数量 // Limit count
   * @returns 热门关键词列表 // Hot keywords list
   */
  public async getHotKeywords(limit: number = 10): Promise<string[]> {
    try {
      Logger.info(TAG, 'Loading hot keywords');
      
      // 先尝试从缓存获取 // First try to get from cache
      const cachedKeywords = await this.cacheRepository.getObject<string[]>(
        'live_hot_keywords'
      );
      
      if (cachedKeywords) {
        return cachedKeywords.slice(0, limit);
      }
      
      // 从数据库获取热门搜索词（基于搜索频率） // Get hot search terms from database (based on search frequency)
      const hotKeywords = await this.searchHistoryRepository.getHotKeywords(
        'live',
        limit
      );
      
      // 如果没有足够的搜索记录，使用默认热门词 // If not enough search records, use default hot terms
      const defaultKeywords = [
        '中央电视台', '卫视', '体育', '电影', '新闻', '电视剧', '综艺', '动漫', '音乐', '少儿'
      ];
      
      const result = hotKeywords.length > 0 ? hotKeywords : defaultKeywords;
      
      // 缓存结果 // Cache result
      await this.cacheRepository.saveObject(
        'live_hot_keywords',
        result,
        SEARCH_CACHE_EXPIRY
      );
      
      return result.slice(0, limit);
    } catch (error) {
      Logger.error(TAG, `Failed to load hot keywords: ${error}`);
      return [];
    }
  }
  
  /**
   * 获取搜索历史 // Get search history
   * @param limit 限制数量 // Limit count
   * @returns 搜索历史列表 // Search history list
   */
  public async getSearchHistory(limit: number = 20): Promise<string[]> {
    try {
      Logger.info(TAG, 'Loading search history');
      return await this.searchHistoryRepository.getSearchHistory('live', limit);
    } catch (error) {
      Logger.error(TAG, `Failed to load search history: ${error}`);
      return [];
    }
  }
  
  /**
   * 清除搜索历史 // Clear search history
   */
  public async clearSearchHistory(): Promise<void> {
    try {
      Logger.info(TAG, 'Clearing search history');
      await this.searchHistoryRepository.clearSearchHistory('live');
      
      // 清除相关缓存 // Clear related cache
      await this.clearSearchCache();
    } catch (error) {
      Logger.error(TAG, `Failed to clear search history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 删除单条搜索历史 // Delete single search history
   * @param keyword 要删除的关键词 // Keyword to delete
   */
  public async removeFromHistory(keyword: string): Promise<void> {
    try {
      Logger.info(TAG, `Removing keyword from history: ${keyword}`);
      await this.searchHistoryRepository.removeFromHistory('live', keyword);
    } catch (error) {
      Logger.error(TAG, `Failed to remove from history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 智能搜索建议 // Smart search suggestions
   * @param prefix 搜索前缀 // Search prefix
   * @param limit 建议数量 // Suggestion count
   * @returns 搜索建议列表 // Search suggestions list
   */
  public async getSearchSuggestions(prefix: string, limit: number = 5): Promise<string[]> {
    try {
      if (!prefix || prefix.length < 2) {
        return [];
      }
      
      Logger.info(TAG, `Getting search suggestions for: ${prefix}`);
      
      // 从历史和频道名称中获取建议 // Get suggestions from history and channel names
      const [historySuggestions, channelSuggestions] = await Promise.all([
        this.searchHistoryRepository.getSuggestions('live', prefix, limit),
        this.liveRepository.getChannelNameSuggestions(prefix, limit)
      ]);
      
      // 合并去重 // Merge and deduplicate
      const suggestions = [...new Set([...historySuggestions, ...channelSuggestions])];
      
      return suggestions.slice(0, limit);
    } catch (error) {
      Logger.error(TAG, `Failed to get search suggestions: ${error}`);
      return [];
    }
  }
  
  /**
   * 保存搜索历史 // Save search history
   * @param keyword 搜索关键词 // Search keyword
   */
  private async saveSearchHistory(keyword: string): Promise<void> {
    try {
      await this.searchHistoryRepository.addSearchHistory('live', keyword);
      
      // 清除热门关键词缓存，以便下次获取最新的 // Clear hot keywords cache to get latest next time
      await this.cacheRepository.removeObject('live_hot_keywords');
    } catch (error) {
      // 保存历史失败不应该影响搜索结果 // Failed to save history should not affect search results
      Logger.warn(TAG, `Failed to save search history: ${error}`);
    }
  }
  
  /**
   * 在观看历史中搜索 // Search in watch history
   * @param keyword 搜索关键词 // Search keyword
   * @returns 匹配的频道 // Matching channels
   */
  private async searchInHistory(keyword: string): Promise<Live[]> {
    try {
      // 获取最近观看的直播频道 // Get recently watched live channels
      const recentWatched = await this.liveRepository.getRecentWatchedLiveChannels(10);
      
      // 过滤匹配关键词的频道 // Filter channels matching keyword
      return recentWatched.filter(channel => 
        channel.name.toLowerCase().includes(keyword.toLowerCase()) ||
        (channel.groupName && channel.groupName.toLowerCase().includes(keyword.toLowerCase()))
      );
    } catch (error) {
      Logger.warn(TAG, `Failed to search in history: ${error}`);
      return [];
    }
  }
  
  /**
   * 缓存搜索结果 // Cache search result
   */
  private async cacheSearchResult<T>(key: string, result: T): Promise<void> {
    try {
      await this.cacheRepository.saveObject(key, result, SEARCH_CACHE_EXPIRY);
    } catch (error) {
      Logger.warn(TAG, `Failed to cache search result: ${error}`);
    }
  }
  
  /**
   * 获取缓存的搜索结果 // Get cached search result
   */
  private async getSearchCache(key: string): Promise<{ channels: Live[]; historyMatches: Live[] } | null> {
    try {
      return await this.cacheRepository.getObject(key);
    } catch (error) {
      Logger.warn(TAG, `Failed to get search cache: ${error}`);
      return null;
    }
  }
  
  /**
   * 清除搜索缓存 // Clear search cache
   */
  private async clearSearchCache(): Promise<void> {
    try {
      // 清除所有直播搜索相关的缓存 // Clear all live search related cache
      const keys = await this.cacheRepository.getAllKeys();
      const searchKeys = keys.filter(key => key.startsWith('live_search_'));
      
      for (const key of searchKeys) {
        await this.cacheRepository.removeObject(key);
      }
      
      // 清除热门关键词缓存 // Clear hot keywords cache
      await this.cacheRepository.removeObject('live_hot_keywords');
    } catch (error) {
      Logger.warn(TAG, `Failed to clear search cache: ${error}`);
    }
  }
}
