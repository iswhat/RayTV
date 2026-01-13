// SearchVodUseCase.ets - 搜索点播用例 // Search VOD use case
import Logger from '../../common/util/Logger';
import { Vod } from '../../data/bean/Vod';
import { SearchResult } from '../../data/model/SearchResult';
import { VodRepository } from '../../data/repository/VodRepository';
import { SearchRepository } from '../../data/repository/SearchRepository';
import { SearchHistoryRepository } from '../../data/repository/SearchHistoryRepository';

const TAG = 'SearchVodUseCase';

/**
 * 搜索点播内容的业务用例 // Business use case for searching VOD content
 */
export class SearchVodUseCase {
  private vodRepository: VodRepository;
  private searchRepository: SearchRepository;
  private searchHistoryRepository: SearchHistoryRepository;
  
  constructor(
    vodRepository: VodRepository,
    searchRepository: SearchRepository,
    searchHistoryRepository: SearchHistoryRepository
  ) {
    this.vodRepository = vodRepository;
    this.searchRepository = searchRepository;
    this.searchHistoryRepository = searchHistoryRepository;
  }
  
  /**
   * 搜索点播内容 // Search VOD content
   * @param keyword 搜索关键词 // Search keyword
   * @param page 页码 // Page number
   * @param pageSize 每页数量 // Page size
   * @param siteKey 可选的站点过滤 // Optional site filter
   * @returns 搜索结果 // Search result
   */
  public async search(
    keyword: string,
    page: number = 1,
    pageSize: number = 20,
    siteKey?: string
  ): Promise<SearchResult<Vod>> {
    try {
      Logger.info(TAG, `Searching vod with keyword: ${keyword}, page: ${page}`);
      
      // 参数验证 // Parameter validation
      if (!keyword || keyword.trim().length === 0) {
        throw new Error('搜索关键词不能为空 // Search keyword cannot be empty');
      }
      
      // 保存搜索历史 // Save search history
      await this.searchHistoryRepository.saveSearchHistory(keyword);
      
      // 执行搜索 // Execute search
      const result = await this.searchRepository.searchVod(
        keyword,
        page,
        pageSize,
        siteKey
      );
      
      // 缓存搜索结果 // Cache search result
      if (result.items && result.items.length > 0) {
        await this.vodRepository.cacheVods(result.items);
      }
      
      Logger.info(TAG, `Search completed, found ${result.items?.length} items`);
      return result;
    } catch (error) {
      Logger.error(TAG, `Search failed: ${error}`);
      throw error;
    }
  }
  
  /**
   * 按分类搜索点播内容 // Search VOD content by category
   * @param category 分类 // Category
   * @param page 页码 // Page number
   * @param pageSize 每页数量 // Page size
   * @param filters 筛选条件 // Filter conditions
   * @returns 搜索结果 // Search result
   */
  public async searchByCategory(
    category: string, 
    page: number = 1,
    pageSize: number = 20,
    filters?: Record<string, string>
  ): Promise<SearchResult<Vod>> {
    try {
      Logger.info(TAG, `Searching vod by category: ${category}, page: ${page}`);
      
      const result = await this.searchRepository.searchVodByCategory(
        category,
        page,
        pageSize,
        filters
      );
      
      // 缓存搜索结果 // Cache search result
      if (result.items && result.items.length > 0) {
        await this.vodRepository.cacheVods(result.items);
      }
      
      return result;
    } catch (error) {
      Logger.error(TAG, `Category search failed: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取热门搜索关键词 // Get hot search keywords
   * @param limit 数量限制 // Limit count
   * @returns 热门搜索关键词列表 // Hot search keywords list
   */
  public async getHotSearchKeywords(limit: number = 10): Promise<string[]> {
    try {
      return await this.searchRepository.getHotSearchKeywords(limit);
    } catch (error) {
      Logger.error(TAG, `Failed to get hot search keywords: ${error}`);
      return [];
    }
  }
  
  /**
   * 清除搜索历史 // Clear search history
   */
  public async clearSearchHistory(): Promise<void> {
    try {
      await this.searchHistoryRepository.clearSearchHistory();
      Logger.info(TAG, 'Search history cleared');
    } catch (error) {
      Logger.error(TAG, `Failed to clear search history: ${error}`);
    }
  }
}
