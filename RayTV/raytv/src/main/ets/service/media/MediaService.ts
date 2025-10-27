import Logger from '../utils/Logger';
import { CrawlerService, CrawlerResponse } from '../spider/CrawlerService';
import { ConfigService } from '../config/ConfigService';
import { SiteInfo } from '../spider/SiteManager';

/**
 * 媒体类型枚举
 */
export enum MediaType {
  MOVIE = 'movie',      // 电影
  TV_SERIES = 'tv',     // 电视剧
  ANIME = 'anime',      // 动漫
  VARIETY = 'variety',  // 综艺
  LIVE = 'live',        // 直播
  CARTOON = 'cartoon',  // 卡通
  DOCUMENTARY = 'doc',  // 纪录片
  MUSIC = 'music',      // 音乐
  SPORT = 'sport',      // 体育
  OTHER = 'other'       // 其他
}

/**
 * 媒体项接口
 */
export interface MediaItem {
  id: string;           // 媒体唯一标识
  siteKey: string;      // 来源站点标识
  title: string;        // 标题
  cover?: string;       // 封面图
  desc?: string;        // 描述
  year?: string;        // 年份
  type: MediaType;      // 媒体类型
  score?: number;       // 评分
  tags?: string[];      // 标签
  regions?: string[];   // 地区
  languages?: string[]; // 语言
  updateTime?: number;  // 更新时间
  playCount?: number;   // 播放次数
  extra?: Record<string, any>; // 其他附加信息
}

/**
 * 剧集项接口
 */
export interface Episode {
  id: string;           // 剧集唯一标识
  title: string;        // 剧集标题
  episodeNum?: number;  // 集数
  seasonNum?: number;   // 季数
  duration?: number;    // 时长（秒）
  cover?: string;       // 封面图
  updateTime?: number;  // 更新时间
  extra?: Record<string, any>; // 其他附加信息
}

/**
 * 播放源接口
 */
export interface PlaySource {
  name: string;         // 源名称
  url: string;          // 播放地址
  format?: string;      // 格式
  quality?: string;     // 清晰度
  size?: number;        // 文件大小（字节）
  subtitles?: Subtitle[]; // 字幕列表
  headers?: Record<string, string>; // 请求头
  extra?: Record<string, any>; // 其他附加信息
}

/**
 * 字幕接口
 */
export interface Subtitle {
  name: string;         // 字幕名称
  url: string;          // 字幕地址
  language?: string;    // 语言
  format?: string;      // 格式
}

/**
 * 搜索参数接口
 */
export interface SearchParams {
  keyword: string;      // 搜索关键词
  type?: MediaType;     // 媒体类型过滤
  page?: number;        // 页码
  pageSize?: number;    // 每页数量
  region?: string;      // 地区过滤
  year?: string;        // 年份过滤
  sortBy?: 'time' | 'score' | 'hot'; // 排序方式
}

/**
 * 搜索结果接口
 */
export interface SearchResult {
  items: MediaItem[];   // 媒体项列表
  total?: number;       // 总数量
  page?: number;        // 当前页码
  pageSize?: number;    // 每页数量
  hasMore?: boolean;    // 是否有更多
}

/**
 * 分类参数接口
 */
export interface CategoryParams {
  type: MediaType;      // 媒体类型
  page?: number;        // 页码
  pageSize?: number;    // 每页数量
  region?: string;      // 地区
  year?: string;        // 年份
  sortBy?: 'time' | 'score' | 'hot'; // 排序方式
  tags?: string[];      // 标签
}

/**
 * 媒体服务
 * 实现媒体相关的业务逻辑
 */
export class MediaService {
  private readonly TAG: string = 'MediaService';
  private static instance: MediaService | null = null;
  private crawlerService: CrawlerService;
  private configService: ConfigService;

  /**
   * 默认搜索参数
   */
  private static readonly DEFAULT_SEARCH_PARAMS: Omit<SearchParams, 'keyword'> = {
    page: 1,
    pageSize: 20,
    sortBy: 'time'
  };

  /**
   * 默认分类参数
   */
  private static readonly DEFAULT_CATEGORY_PARAMS: Omit<CategoryParams, 'type'> = {
    page: 1,
    pageSize: 20,
    sortBy: 'hot'
  };

  /**
   * 获取单例实例
   * @returns MediaService
   */
  public static getInstance(): MediaService {
    if (!MediaService.instance) {
      MediaService.instance = new MediaService();
    }
    return MediaService.instance;
  }

  /**
   * 构造函数
   * 私有构造函数防止外部实例化
   */
  private constructor() {
    this.crawlerService = CrawlerService.getInstance();
    this.configService = ConfigService.getInstance();
    Logger.info(this.TAG, 'MediaService initialized');
  }

  /**
   * 搜索媒体
   * @param params 搜索参数
   * @param siteKeys 指定站点（可选）
   * @returns Promise<SearchResult>
   */
  public async searchMedia(
    params: SearchParams,
    siteKeys?: string[]
  ): Promise<SearchResult> {
    const searchParams = { ...MediaService.DEFAULT_SEARCH_PARAMS, ...params };
    const sites = this.getAvailableSites(siteKeys);
    const results: MediaItem[] = [];

    try {
      Logger.info(this.TAG, `Searching media with params: ${JSON.stringify(searchParams)}`);

      // 并行搜索多个站点
      const searchPromises = sites.map(async (site) => {
        try {
          const response = await this.crawlerService.callSiteMethod<SearchResult>(
            site.key,
            'search',
            searchParams
          );

          if (response.success && response.data?.items) {
            // 添加站点标识并合并结果
            const itemsWithSite = response.data.items.map(item => ({
              ...item,
              siteKey: site.key
            }));
            results.push(...itemsWithSite);
          }
        } catch (error) {
          Logger.warn(this.TAG, `Failed to search on site ${site.key}: ${error}`);
        }
      });

      await Promise.all(searchPromises);

      // 去重处理
      const uniqueResults = this.removeDuplicateMedia(results);

      // 排序处理
      const sortedResults = this.sortMediaResults(uniqueResults, searchParams.sortBy!);

      // 分页处理
      const startIndex = (searchParams.page! - 1) * searchParams.pageSize!;
      const endIndex = startIndex + searchParams.pageSize!;
      const pagedResults = sortedResults.slice(startIndex, endIndex);

      return {
        items: pagedResults,
        total: sortedResults.length,
        page: searchParams.page!,
        pageSize: searchParams.pageSize!,
        hasMore: endIndex < sortedResults.length
      };
    } catch (error) {
      Logger.error(this.TAG, `Search failed: ${error}`);
      throw new Error(`Search failed: ${error}`);
    }
  }

  /**
   * 获取分类媒体列表
   * @param params 分类参数
   * @param siteKeys 指定站点（可选）
   * @returns Promise<SearchResult>
   */
  public async getCategoryList(
    params: CategoryParams,
    siteKeys?: string[]
  ): Promise<SearchResult> {
    const categoryParams = { ...MediaService.DEFAULT_CATEGORY_PARAMS, ...params };
    const sites = this.getAvailableSites(siteKeys);
    const results: MediaItem[] = [];

    try {
      Logger.info(this.TAG, `Getting category list with params: ${JSON.stringify(categoryParams)}`);

      // 并行获取多个站点的分类列表
      const categoryPromises = sites.map(async (site) => {
        try {
          const response = await this.crawlerService.callSiteMethod<SearchResult>(
            site.key,
            'category',
            categoryParams
          );

          if (response.success && response.data?.items) {
            // 添加站点标识并合并结果
            const itemsWithSite = response.data.items.map(item => ({
              ...item,
              siteKey: site.key
            }));
            results.push(...itemsWithSite);
          }
        } catch (error) {
          Logger.warn(this.TAG, `Failed to get category list from site ${site.key}: ${error}`);
        }
      });

      await Promise.all(categoryPromises);

      // 去重处理
      const uniqueResults = this.removeDuplicateMedia(results);

      // 排序处理
      const sortedResults = this.sortMediaResults(uniqueResults, categoryParams.sortBy!);

      // 分页处理
      const startIndex = (categoryParams.page! - 1) * categoryParams.pageSize!;
      const endIndex = startIndex + categoryParams.pageSize!;
      const pagedResults = sortedResults.slice(startIndex, endIndex);

      return {
        items: pagedResults,
        total: sortedResults.length,
        page: categoryParams.page!,
        pageSize: categoryParams.pageSize!,
        hasMore: endIndex < sortedResults.length
      };
    } catch (error) {
      Logger.error(this.TAG, `Get category list failed: ${error}`);
      throw new Error(`Get category list failed: ${error}`);
    }
  }

  /**
   * 获取媒体详情
   * @param siteKey 站点标识
   * @param mediaId 媒体ID
   * @returns Promise<MediaItem>
   */
  public async getMediaDetail(siteKey: string, mediaId: string): Promise<MediaItem> {
    try {
      Logger.info(this.TAG, `Getting media detail for ${siteKey}:${mediaId}`);

      const response = await this.crawlerService.callSiteMethod<MediaItem>(
        siteKey,
        'detail',
        { id: mediaId }
      );

      if (response.success && response.data) {
        return {
          ...response.data,
          siteKey
        };
      } else {
        throw new Error(response.error || 'Failed to get media detail');
      }
    } catch (error) {
      Logger.error(this.TAG, `Get media detail failed: ${error}`);
      throw new Error(`Get media detail failed: ${error}`);
    }
  }

  /**
   * 获取剧集列表
   * @param siteKey 站点标识
   * @param mediaId 媒体ID
   * @returns Promise<Episode[]>
   */
  public async getEpisodes(siteKey: string, mediaId: string): Promise<Episode[]> {
    try {
      Logger.info(this.TAG, `Getting episodes for ${siteKey}:${mediaId}`);

      const response = await this.crawlerService.callSiteMethod<Episode[]>(
        siteKey,
        'episodes',
        { id: mediaId }
      );

      if (response.success && response.data) {
        return response.data;
      } else {
        throw new Error(response.error || 'Failed to get episodes');
      }
    } catch (error) {
      Logger.error(this.TAG, `Get episodes failed: ${error}`);
      throw new Error(`Get episodes failed: ${error}`);
    }
  }

  /**
   * 获取播放源
   * @param siteKey 站点标识
   * @param mediaId 媒体ID
   * @param episodeId 剧集ID（可选）
   * @returns Promise<PlaySource[]>
   */
  public async getPlaySources(
    siteKey: string,
    mediaId: string,
    episodeId?: string
  ): Promise<PlaySource[]> {
    try {
      Logger.info(this.TAG, `Getting play sources for ${siteKey}:${mediaId}${episodeId ? `:${episodeId}` : ''}`);

      const response = await this.crawlerService.callSiteMethod<PlaySource[]>(
        siteKey,
        'playSources',
        { id: mediaId, episodeId }
      );

      if (response.success && response.data) {
        // 过滤无效的播放源
        return response.data.filter(source => source.url && source.url.trim().length > 0);
      } else {
        throw new Error(response.error || 'Failed to get play sources');
      }
    } catch (error) {
      Logger.error(this.TAG, `Get play sources failed: ${error}`);
      throw new Error(`Get play sources failed: ${error}`);
    }
  }

  /**
   * 获取推荐媒体
   * @param type 媒体类型（可选）
   * @param limit 数量限制
   * @param siteKeys 指定站点（可选）
   * @returns Promise<MediaItem[]>
   */
  public async getRecommendMedia(
    type?: MediaType,
    limit: number = 20,
    siteKeys?: string[]
  ): Promise<MediaItem[]> {
    const sites = this.getAvailableSites(siteKeys);
    const results: MediaItem[] = [];

    try {
      Logger.info(this.TAG, `Getting recommend media${type ? ` for type ${type}` : ''}`);

      // 并行获取多个站点的推荐
      const recommendPromises = sites.map(async (site) => {
        try {
          const response = await this.crawlerService.callSiteMethod<MediaItem[]>(
            site.key,
            'recommend',
            { type, limit: Math.ceil(limit / sites.length) }
          );

          if (response.success && response.data) {
            // 添加站点标识并合并结果
            const itemsWithSite = response.data.map(item => ({
              ...item,
              siteKey: site.key
            }));
            results.push(...itemsWithSite);
          }
        } catch (error) {
          Logger.warn(this.TAG, `Failed to get recommend from site ${site.key}: ${error}`);
        }
      });

      await Promise.all(recommendPromises);

      // 去重处理
      const uniqueResults = this.removeDuplicateMedia(results);

      // 随机排序并限制数量
      return uniqueResults
        .sort(() => Math.random() - 0.5)
        .slice(0, limit);
    } catch (error) {
      Logger.error(this.TAG, `Get recommend media failed: ${error}`);
      throw new Error(`Get recommend media failed: ${error}`);
    }
  }

  /**
   * 获取热门搜索关键词
   * @param siteKeys 指定站点（可选）
   * @returns Promise<string[]>
   */
  public async getHotSearchKeywords(siteKeys?: string[]): Promise<string[]> {
    const sites = this.getAvailableSites(siteKeys);
    const keywordsMap = new Map<string, number>();

    try {
      Logger.info(this.TAG, 'Getting hot search keywords');

      // 并行获取多个站点的热门搜索
      const hotSearchPromises = sites.map(async (site) => {
        try {
          const response = await this.crawlerService.callSiteMethod<string[]>(
            site.key,
            'hotSearch'
          );

          if (response.success && response.data) {
            // 统计关键词出现次数
            response.data.forEach(keyword => {
              if (keyword && keyword.trim().length > 0) {
                const trimmed = keyword.trim();
                keywordsMap.set(trimmed, (keywordsMap.get(trimmed) || 0) + 1);
              }
            });
          }
        } catch (error) {
          Logger.warn(this.TAG, `Failed to get hot search from site ${site.key}: ${error}`);
        }
      });

      await Promise.all(hotSearchPromises);

      // 按出现次数排序并返回前20个
      return Array.from(keywordsMap.entries())
        .sort(([,a], [,b]) => b - a)
        .map(([keyword]) => keyword)
        .slice(0, 20);
    } catch (error) {
      Logger.error(this.TAG, `Get hot search keywords failed: ${error}`);
      return [];
    }
  }

  /**
   * 获取可用的站点列表
   * @param siteKeys 指定的站点键列表（可选）
   * @returns SiteInfo[]
   * @private
   */
  private getAvailableSites(siteKeys?: string[]): SiteInfo[] {
    let sites = this.crawlerService.getSites();
    
    // 如果指定了站点，则过滤
    if (siteKeys && siteKeys.length > 0) {
      sites = sites.filter(site => siteKeys.includes(site.key));
    }
    
    // 只返回启用状态的站点
    return sites.filter(site => site.status === 'enabled' || site.status === 1);
  }

  /**
   * 移除重复的媒体项
   * @param items 媒体项列表
   * @returns MediaItem[]
   * @private
   */
  private removeDuplicateMedia(items: MediaItem[]): MediaItem[] {
    const uniqueMap = new Map<string, MediaItem>();
    
    items.forEach(item => {
      // 简单的去重策略：基于标题和年份
      const key = `${item.title.replace(/\s+/g, '').toLowerCase()}_${item.year || ''}`;
      
      // 如果不存在或者当前项更完整，则替换
      const existing = uniqueMap.get(key);
      if (!existing || this.isMoreCompleteMedia(item, existing)) {
        uniqueMap.set(key, item);
      }
    });
    
    return Array.from(uniqueMap.values());
  }

  /**
   * 判断媒体项是否更完整
   * @param newItem 新媒体项
   * @param existing 现有媒体项
   * @returns boolean
   * @private
   */
  private isMoreCompleteMedia(newItem: MediaItem, existing: MediaItem): boolean {
    // 简单的判断逻辑：检查字段完整性
    let newScore = 0;
    let existingScore = 0;
    
    const fields = ['cover', 'desc', 'year', 'score', 'tags', 'regions', 'languages'];
    
    fields.forEach(field => {
      if ((newItem as any)[field]) newScore++;
      if ((existing as any)[field]) existingScore++;
    });
    
    return newScore > existingScore;
  }

  /**
   * 对媒体结果进行排序
   * @param items 媒体项列表
   * @param sortBy 排序方式
   * @returns MediaItem[]
   * @private
   */
  private sortMediaResults(items: MediaItem[], sortBy: 'time' | 'score' | 'hot'): MediaItem[] {
    return [...items].sort((a, b) => {
      switch (sortBy) {
        case 'time':
          return (b.updateTime || 0) - (a.updateTime || 0);
        case 'score':
          return (b.score || 0) - (a.score || 0);
        case 'hot':
          return (b.playCount || 0) - (a.playCount || 0);
        default:
          return 0;
      }
    });
  }

  /**
   * 获取媒体类型的本地化名称
   * @param type 媒体类型
   * @returns string
   */
  public getMediaTypeLabel(type: MediaType): string {
    const labels: Record<MediaType, string> = {
      [MediaType.MOVIE]: '电影',
      [MediaType.TV_SERIES]: '电视剧',
      [MediaType.ANIME]: '动漫',
      [MediaType.VARIETY]: '综艺',
      [MediaType.LIVE]: '直播',
      [MediaType.CARTOON]: '卡通',
      [MediaType.DOCUMENTARY]: '纪录片',
      [MediaType.MUSIC]: '音乐',
      [MediaType.SPORT]: '体育',
      [MediaType.OTHER]: '其他'
    };
    
    return labels[type] || '未知';
  }
}

// 导出媒体服务单例
export const mediaService = MediaService.getInstance();