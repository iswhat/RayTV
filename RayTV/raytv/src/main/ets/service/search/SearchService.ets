// 搜索服务
// 提供跨站点搜索、搜索历史管理、热门搜索等功能

import { StorageUtil } from '../../common/util/StorageUtil';
import { SiteManager } from '../spider/SiteManager';
import { VideoItem } from '../../data/bean/Vod.ets';
import { LiveChannel } from '../../data/bean/Live.ets';
import { AnalyticsService } from '../analytics/AnalyticsService';

export class SearchService {
  private static instance: SearchService;
  private storageUtil: StorageUtil;
  private siteManager: SiteManager;
  private analyticsService: AnalyticsService;
  private searchHistory: SearchHistoryItem[] = [];
  private searchCache: Map<string, SearchResult> = new Map();
  private maxHistoryCount = 50;
  private maxCacheSize = 20;

  private constructor() {
    this.storageUtil = StorageUtil.getInstance();
    this.siteManager = SiteManager.getInstance();
    this.analyticsService = AnalyticsService.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): SearchService {
    if (!SearchService.instance) {
      SearchService.instance = new SearchService();
    }
    return SearchService.instance;
  }

  /**
   * 初始化搜索服务
   */
  private async initialize(): Promise<void> {
    await this.loadSearchHistory();
  }

  /**
   * 搜索视频
   * @param keyword 搜索关键词
   * @param options 搜索选项
   */
  public async search(keyword: string, options?: SearchOptions): Promise<SearchResult> {
    try {
      if (!keyword.trim()) {
        throw new Error('搜索关键词不能为空');
      }

      // 记录搜索事件
      this.analyticsService.trackSearch(keyword);

      // 检查缓存
      const cacheKey = this.getCacheKey(keyword, options);
      if (this.searchCache.has(cacheKey)) {
        const cachedResult = this.searchCache.get(cacheKey)!;
        this.addToHistory(keyword, 'vod');
        return cachedResult;
      }

      const { siteKeys = [], limitPerSite = 20, timeout = 10000 } = options || {};
      
      // 获取要搜索的站点
      const sites = await this.getSearchableSites(siteKeys);
      
      // 执行搜索
      const searchResults = await this.searchInSites(keyword, sites, limitPerSite, timeout);
      
      // 合并结果
      const mergedResults = this.mergeSearchResults(searchResults);
      
      // 保存到历史
      this.addToHistory(keyword, 'vod');
      
      // 缓存结果
      this.cacheResult(cacheKey, mergedResults);
      
      return mergedResults;
    } catch (error) {
      console.error('Search failed:', error);
      throw error;
    }
  }

  /**
   * 搜索直播频道
   * @param keyword 搜索关键词
   * @param options 搜索选项
   */
  public async searchLiveChannels(keyword: string, options?: SearchOptions): Promise<LiveSearchResult> {
    try {
      if (!keyword.trim()) {
        throw new Error('搜索关键词不能为空');
      }

      // 记录搜索事件
      this.analyticsService.trackSearch(keyword, undefined, 0);

      // 获取所有活跃的直播站点
      const sites = await this.siteManager.getActiveSites();
      const liveSites = sites.filter(site => site.type === 'LIVE' || site.supportedFeatures?.includes('live'));
      
      // 执行搜索
      const results: LiveChannel[] = [];
      
      for (const site of liveSites) {
        try {
          const channelResults = await this.siteManager.callSiteMethod<LiveChannel[]>(
            site.key,
            'searchLiveChannels',
            [keyword],
            { timeout: 5000 }
          );
          
          if (channelResults && Array.isArray(channelResults)) {
            channelResults.forEach(channel => {
              if (channel) {
                channel.siteKey = site.key;
                channel.siteName = site.name;
                results.push(channel);
              }
            });
          }
        } catch (error) {
          console.warn(`Search in site ${site.name} failed:`, error);
        }
      }

      // 保存到历史
      this.addToHistory(keyword, 'live');
      
      return {
        channels: results,
        total: results.length,
        keyword
      };
    } catch (error) {
      console.error('Live channel search failed:', error);
      throw error;
    }
  }

  /**
   * 在多个站点中执行搜索
   */
  private async searchInSites(keyword: string, sites: any[], limitPerSite: number, timeout: number): Promise<SiteSearchResult[]> {
    const promises: Promise<SiteSearchResult>[] = sites.map(async (site) => {
      try {
        const results = await Promise.race([
          this.siteManager.callSiteMethod<any>(
            site.key,
            'search',
            [keyword, { limit: limitPerSite }],
            { timeout }
          ),
          new Promise((_, reject) => setTimeout(() => reject(new Error('Search timeout')), timeout))
        ]);

        // 转换结果格式
        const videoItems = this.convertToVideoItems(results, site);
        
        return {
          siteKey: site.key,
          siteName: site.name,
          results: videoItems,
          success: true
        };
      } catch (error) {
        console.warn(`Search in site ${site.name} failed:`, error);
        return {
          siteKey: site.key,
          siteName: site.name,
          results: [],
          success: false,
          error: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    });

    return Promise.all(promises);
  }

  /**
   * 转换为统一的视频项格式
   */
  private convertToVideoItems(results: any, site: any): VideoItem[] {
    if (!results || !Array.isArray(results)) {
      return [];
    }

    return results.map((item: any) => ({
      id: item.id || item.vodId || `unknown_${Date.now()}_${Math.random()}`,
      title: item.title || item.name || '未知标题',
      cover: item.cover || item.img || item.pic || '',
      rating: item.rating || item.score || 0,
      updateInfo: item.updateInfo || item.desc || '',
      tags: item.tags || [],
      category: item.category || item.type || '',
      siteKey: site.key,
      originalUrl: item.url || '',
      isFavorite: false
    }));
  }

  /**
   * 合并搜索结果
   */
  private mergeSearchResults(siteResults: SiteSearchResult[]): SearchResult {
    const allResults: SearchItem[] = [];
    let totalCount = 0;
    let successSites = 0;

    siteResults.forEach(siteResult => {
      if (siteResult.success) {
        successSites++;
        siteResult.results.forEach(item => {
          allResults.push({
            ...item,
            siteName: siteResult.siteName
          });
        });
      }
      totalCount += siteResult.results.length;
    });

    // 排序（可以根据评分、标题等进行排序）
    allResults.sort((a, b) => {
      // 先按评分降序
      if (b.rating !== a.rating) {
        return b.rating - a.rating;
      }
      // 再按标题升序
      return a.title.localeCompare(b.title);
    });

    return {
      results: allResults,
      total: totalCount,
      successSites,
      totalSites: siteResults.length
    };
  }

  /**
   * 获取可搜索的站点
   */
  private async getSearchableSites(siteKeys: string[]): Promise<any[]> {
    const allSites = await this.siteManager.getActiveSites();
    
    if (siteKeys.length > 0) {
      return allSites.filter(site => siteKeys.includes(site.key));
    }
    
    // 返回所有支持搜索的站点
    return allSites.filter(site => site.supportedFeatures?.includes('search') || true);
  }

  /**
   * 添加到搜索历史
   */
  private async addToHistory(keyword: string, type: 'vod' | 'live'): Promise<void> {
    // 移除重复项
    this.searchHistory = this.searchHistory.filter(
      item => !(item.keyword === keyword && item.type === type)
    );

    // 添加到开头
    const historyItem: SearchHistoryItem = {
      keyword,
      type,
      timestamp: Date.now()
    };
    this.searchHistory.unshift(historyItem);

    // 限制数量
    if (this.searchHistory.length > this.maxHistoryCount) {
      this.searchHistory = this.searchHistory.slice(0, this.maxHistoryCount);
    }

    await this.saveSearchHistory();
  }

  /**
   * 获取搜索历史
   */
  public async getSearchHistory(): Promise<SearchHistoryItem[]> {
    await this.loadSearchHistory();
    return [...this.searchHistory];
  }

  /**
   * 清除搜索历史
   */
  public async clearSearchHistory(): Promise<void> {
    this.searchHistory = [];
    await this.saveSearchHistory();
  }

  /**
   * 删除指定搜索历史
   */
  public async deleteSearchHistory(keyword: string): Promise<void> {
    this.searchHistory = this.searchHistory.filter(item => item.keyword !== keyword);
    await this.saveSearchHistory();
  }

  /**
   * 加载搜索历史
   */
  private async loadSearchHistory(): Promise<void> {
    try {
      const history = await this.storageUtil.get<SearchHistoryItem[]>('searchHistory', []);
      this.searchHistory = history || [];
    } catch (error) {
      console.error('Failed to load search history:', error);
      this.searchHistory = [];
    }
  }

  /**
   * 保存搜索历史
   */
  private async saveSearchHistory(): Promise<void> {
    try {
      await this.storageUtil.save('searchHistory', this.searchHistory);
    } catch (error) {
      console.error('Failed to save search history:', error);
    }
  }

  /**
   * 获取缓存键
   */
  private getCacheKey(keyword: string, options?: SearchOptions): string {
    const siteKeys = options?.siteKeys?.join(',') || 'all';
    return `${keyword}_${siteKeys}_${options?.limitPerSite || 20}`;
  }

  /**
   * 缓存搜索结果
   */
  private cacheResult(key: string, result: SearchResult): void {
    // 限制缓存大小
    if (this.searchCache.size >= this.maxCacheSize) {
      // 删除最早的缓存
      const firstKey = this.searchCache.keys().next().value;
      this.searchCache.delete(firstKey);
    }
    this.searchCache.set(key, result);
  }

  /**
   * 获取热门搜索词（模拟）
   */
  public async getHotSearches(): Promise<string[]> {
    // 这里可以从服务器获取热门搜索词
    // 现在返回模拟数据
    return [
      '最新电影',
      '热播电视剧',
      '动漫',
      '综艺节目',
      '纪录片',
      '动作片',
      '科幻片',
      '喜剧片'
    ];
  }

  /**
   * 获取搜索建议
   * @param keyword 关键词
   */
  public async getSearchSuggestions(keyword: string): Promise<string[]> {
    if (!keyword.trim()) return [];

    // 从历史记录中获取建议
    const historySuggestions = this.searchHistory
      .filter(item => item.keyword.toLowerCase().includes(keyword.toLowerCase()))
      .map(item => item.keyword);

    // 去重
    const uniqueSuggestions = [...new Set(historySuggestions)];
    
    return uniqueSuggestions.slice(0, 5);
  }
}

/**
 * 搜索选项
 */
export interface SearchOptions {
  siteKeys?: string[];
  limitPerSite?: number;
  timeout?: number;
  type?: 'vod' | 'live';
}

/**
 * 搜索结果
 */
export interface SearchResult {
  results: SearchItem[];
  total: number;
  successSites: number;
  totalSites: number;
}

/**
 * 搜索项
 */
export interface SearchItem extends VideoItem {
  siteName?: string;
}

/**
 * 站点搜索结果
 */
export interface SiteSearchResult {
  siteKey: string;
  siteName: string;
  results: VideoItem[];
  success: boolean;
  error?: string;
}

/**
 * 直播搜索结果
 */
export interface LiveSearchResult {
  channels: LiveChannel[];
  total: number;
  keyword?: string;
  category?: string;
}

/**
 * 搜索历史项
 */
export interface SearchHistoryItem {
  keyword: string;
  type: 'vod' | 'live';
  timestamp: number;
}