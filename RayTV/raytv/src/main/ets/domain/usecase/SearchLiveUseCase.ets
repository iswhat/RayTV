// SearchLiveUseCase - 搜索直播用例
import Logger from '../../common/util/Logger';
import { Live } from '../../data/bean/Live';
import { LiveRepository } from '../../data/repository/LiveRepository';
import { SearchHistoryRepository } from '../../data/repository/SearchHistoryRepository';
import { CacheRepository } from '../../data/repository/CacheRepository';

const TAG = 'SearchLiveUseCase';
const SEARCH_CACHE_EXPIRY = 5 * 60 * 1000; // 5分钟缓存过期时间

/**
 * 搜索直播内容的业务用�?
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
   * 搜索直播频道
   * @param keyword 搜索关键�?
   * @param includeHistory 是否包含历史记录搜索
   * @returns 搜索结果
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
      
      // 生成缓存�?
      const cacheKey = `live_search_${keyword.toLowerCase()}`;
      
      // 尝试从缓存获�?
      const cachedResult = await this.getSearchCache(cacheKey);
      if (cachedResult) {
        Logger.info(TAG, `Using cached search results for: ${keyword}`);
        return cachedResult;
      }
      
      // 并行执行搜索
      const [channels, historyMatches] = await Promise.all([
        this.liveRepository.searchLiveChannels(keyword),
        includeHistory ? this.searchInHistory(keyword) : Promise.resolve([])
      ]);
      
      const result: Record<string, string | number | boolean | null> = { ... };
      
      // 缓存结果
      await this.cacheSearchResult(cacheKey, result);
      
      // 保存搜索历史
      await this.saveSearchHistory(keyword);
      
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to search live: ${error}`);
      return { channels: [], historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 instanceof Error ? historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10 : new Error(String(historyMatches: [] };
    }
  }
  
  /**
   * 获取热门搜索关键�?
   * @param limit 限制数量
   * @returns 热门关键词列�?
   */
  public async getHotKeywords(limit: number = 10))))))): Promise<string[]> {
    try {
      Logger.info(TAG, 'Loading hot keywords');
      
      // 先尝试从缓存获取
      const cachedKeywords = await this.cacheRepository.getObject<string[]>(
        'live_hot_keywords'
      );
      
      if (cachedKeywords) {
        return cachedKeywords.slice(0, limit);
      }
      
      // 从数据库获取热门搜索词（基于搜索频率�?
      const hotKeywords = await this.searchHistoryRepository.getHotKeywords(
        'live',
        limit
      );
      
      // 如果没有足够的历史搜索，使用默认热门�?
      const defaultKeywords = [
        '中央电视�?, '卫视', '体育', '电影', '新闻', '电视�?, '综艺', '动画', '音乐', '少儿'
      ];
      
      const result = hotKeywords.length > 0 ? hotKeywords : defaultKeywords;
      
      // 缓存结果
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
   * 获取搜索历史
   * @param limit 限制数量
   * @returns 搜索历史列表
   */
  public async getSearchHistory(limit: number = 20): Promise<string[]> {
    try {
      Logger.info(TAG, 'Loading search history' instanceof Error ? 'Loading search history' : new Error(String('Loading search history' instanceof Error ? 'Loading search history' instanceof Error ? 'Loading search history' : new Error(String('Loading search history' : new Error(String('Loading search history' instanceof Error ? 'Loading search history' : new Error(String('Loading search history' instanceof Error ? 'Loading search history' instanceof Error ? 'Loading search history' : new Error(String('Loading search history' instanceof Error ? 'Loading search history' instanceof Error ? 'Loading search history' : new Error(String('Loading search history' : new Error(String('Loading search history' instanceof Error ? 'Loading search history' : new Error(String('Loading search history' : new Error(String('Loading search history' instanceof Error ? 'Loading search history' : new Error(String('Loading search history' instanceof Error ? 'Loading search history' instanceof Error ? 'Loading search history' : new Error(String('Loading search history' : new Error(String('Loading search history' instanceof Error ? 'Loading search history' : new Error(String('Loading search history')))))));
      return await this.searchHistoryRepository.getSearchHistory('live', limit);
    } catch (error) {
      Logger.error(TAG, `Failed to load search history: ${error}`);
      return [];
    }
  }
  
  /**
   * 清除搜索历史
   */
  public async clearSearchHistory(): Promise<void> {
    try {
      Logger.info(TAG, 'Clearing search history' instanceof Error ? 'Clearing search history' : new Error(String('Clearing search history' instanceof Error ? 'Clearing search history' instanceof Error ? 'Clearing search history' : new Error(String('Clearing search history' : new Error(String('Clearing search history' instanceof Error ? 'Clearing search history' : new Error(String('Clearing search history' instanceof Error ? 'Clearing search history' instanceof Error ? 'Clearing search history' : new Error(String('Clearing search history' instanceof Error ? 'Clearing search history' instanceof Error ? 'Clearing search history' : new Error(String('Clearing search history' : new Error(String('Clearing search history' instanceof Error ? 'Clearing search history' : new Error(String('Clearing search history' : new Error(String('Clearing search history' instanceof Error ? 'Clearing search history' : new Error(String('Clearing search history' instanceof Error ? 'Clearing search history' instanceof Error ? 'Clearing search history' : new Error(String('Clearing search history' : new Error(String('Clearing search history' instanceof Error ? 'Clearing search history' : new Error(String('Clearing search history')))))));
      await this.searchHistoryRepository.clearSearchHistory('live');
      
      // 清除相关缓存
      await this.clearSearchCache();
    } catch (error) {
      Logger.error(TAG, `Failed to clear search history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 删除单条搜索历史
   * @param keyword 要删除的关键�?
   */
  public async removeFromHistory(keyword: string): Promise<void> {
    try {
      Logger.info(TAG, `Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}` instanceof Error ? `Removing keyword from history: ${keyword}` : new Error(String(`Removing keyword from history: ${keyword}`)))))));
      await this.searchHistoryRepository.removeFromHistory('live', keyword);
    } catch (error) {
      Logger.error(TAG, `Failed to remove from history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 智能搜索建议
   * @param prefix 搜索前缀
   * @param limit 建议数量
   * @returns 搜索建议列表
   */
  public async getSearchSuggestions(prefix: string, limit: number = 5 instanceof Error ? limit: number = 5 : new Error(String(limit: number = 5 instanceof Error ? limit: number = 5 instanceof Error ? limit: number = 5 : new Error(String(limit: number = 5 : new Error(String(limit: number = 5 instanceof Error ? limit: number = 5 : new Error(String(limit: number = 5 instanceof Error ? limit: number = 5 instanceof Error ? limit: number = 5 : new Error(String(limit: number = 5 instanceof Error ? limit: number = 5 instanceof Error ? limit: number = 5 : new Error(String(limit: number = 5 : new Error(String(limit: number = 5 instanceof Error ? limit: number = 5 : new Error(String(limit: number = 5 : new Error(String(limit: number = 5 instanceof Error ? limit: number = 5 : new Error(String(limit: number = 5 instanceof Error ? limit: number = 5 instanceof Error ? limit: number = 5 : new Error(String(limit: number = 5 : new Error(String(limit: number = 5 instanceof Error ? limit: number = 5 : new Error(String(limit: number = 5))))))): Promise<string[]> {
    try {
      if (!prefix || prefix.length < 2) {
        return [];
      }
      
      Logger.info(TAG, `Getting search suggestions for: ${prefix}`);
      
      // 从历史和频道名称中获取建�?
      const [historySuggestions, channelSuggestions] = await Promise.all([
        this.searchHistoryRepository.getSuggestions('live', prefix, limit),
        this.liveRepository.getChannelNameSuggestions(prefix, limit)
      ]);
      
      // 合并去重
      const suggestions = [...new Set([...historySuggestions, ...channelSuggestions])];
      
      return suggestions.slice(0, limit);
    } catch (error) {
      Logger.error(TAG, `Failed to get search suggestions: ${error}`);
      return [];
    }
  }
  
  /**
   * 保存搜索历史
   * @param keyword 搜索关键�?
   */
  private async saveSearchHistory(keyword: string): Promise<void> {
    try {
      await this.searchHistoryRepository.addSearchHistory('live', keyword instanceof Error ? keyword : new Error(String(keyword instanceof Error ? keyword instanceof Error ? keyword : new Error(String(keyword : new Error(String(keyword instanceof Error ? keyword : new Error(String(keyword instanceof Error ? keyword instanceof Error ? keyword : new Error(String(keyword instanceof Error ? keyword instanceof Error ? keyword : new Error(String(keyword : new Error(String(keyword instanceof Error ? keyword : new Error(String(keyword : new Error(String(keyword instanceof Error ? keyword : new Error(String(keyword instanceof Error ? keyword instanceof Error ? keyword : new Error(String(keyword : new Error(String(keyword instanceof Error ? keyword : new Error(String(keyword)))))));
      
      // 清除热门关键词缓存，以便下次获取最新的
      await this.cacheRepository.removeObject('live_hot_keywords');
    } catch (error) {
      // 保存历史失败不应该影响搜索结�?
      Logger.warn(TAG, `Failed to save search history: ${error}`);
    }
  }
  
  /**
   * 在历史记录中搜索
   * @param keyword 搜索关键�?
   * @returns 匹配的频�?
   */
  private async searchInHistory(keyword: string): Promise<Live[]> {
    try {
      // 获取最近观看的直播频道
      const recentWatched = await this.liveRepository.getRecentWatchedLiveChannels(10);
      
      // 过滤匹配关键词的频道
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
   * 缓存搜索结果
   */
  private async cacheSearchResult<T>(key: string, result: T): Promise<void> {
    try {
      await this.cacheRepository.saveObject(key, result, SEARCH_CACHE_EXPIRY);
    } catch (error) {
      Logger.warn(TAG, `Failed to cache search result: ${error}`);
    }
  }
  
  /**
   * 获取缓存的搜索结�?
   */
  private async getSearchCache(key: string): Promise<LiveChannel[] | null> {
    try {
      return await this.cacheRepository.getObject(key);
    } catch (error) {
      Logger.warn(TAG, `Failed to get search cache: ${error}`);
      return null;
    }
  }
  
  /**
   * 清除搜索缓存
   */
  private async clearSearchCache(): Promise<void> {
    try {
      // 清除所有直播搜索相关的缓存
      const keys = await this.cacheRepository.getAllKeys();
      const searchKeys = keys.filter(key => key.startsWith('live_search_'));
      
      for (const key of searchKeys) {
        await this.cacheRepository.removeObject(key);
      }
      
      // 清除热门关键词缓�?
      await this.cacheRepository.removeObject('live_hot_keywords');
    } catch (error) {
      Logger.warn(TAG, `Failed to clear search cache: ${error}`);
    }
  }
}


