// SearchVodUseCase - 搜索点播用例
import Logger from '../../common/util/Logger';
import { Vod } from '../../data/bean/Vod';
import { SearchResult } from '../../data/model/SearchResult';
import { VodRepository } from '../../data/repository/VodRepository';
import { SearchRepository } from '../../data/repository/SearchRepository';
import { SearchHistoryRepository } from '../../data/repository/SearchHistoryRepository';

const TAG = 'SearchVodUseCase';

/**
 * 搜索点播内容的业务用例
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
   * 搜索点播内容
   * @param keyword 搜索关键词
   * @param page 页码
   * @param pageSize 每页数量
   * @param siteKey 可选的站点过滤
   * @returns 搜索结果
   */
  public async search(
    keyword: string,
    page: number = 1,
    pageSize: number = 20,
    siteKey?: string
  ): Promise<SearchResult<Vod>> {
    try {
      Logger.info(TAG, `Searching vod with keyword: ${keyword}, page: ${page}`);
      
      // 参数验证
      if (!keyword || keyword.trim().length === 0) {
        throw new Error('搜索关键词不能为空');
      }
      
      // 保存搜索历史
      await this.searchHistoryRepository.saveSearchHistory(keyword);
      
      // 执行搜索
      const result = await this.searchRepository.searchVod(
        keyword,
        page,
        pageSize,
        siteKey
      );
      
      // 缓存搜索结果
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
   * 按分类搜索点播内容
   * @param category 分类
   * @param page 页码
   * @param pageSize 每页数量
   * @param filters 筛选条件
   * @returns 搜索结果
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
      
      // 缓存搜索结果
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
   * 获取热门搜索关键词
   * @param limit 数量限制
   * @returns 热门搜索关键词列表
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
   * 清除搜索历史
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