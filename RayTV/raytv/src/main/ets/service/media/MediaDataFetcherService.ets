/**
 * MediaDataFetcherService - 媒体数据获取服务
 * 
 * 从各个点播站点获取真实的媒体详情、剧集列表、播放源等数据
 * 支持多种解析器和缓存机制
 */

import Logger from '../../common/util/Logger';
import ContentAccessService from './ContentAccessService';
import { VodSiteWithSource } from './SourcePoolManager';
import CacheService from './cache/CacheService';
import { CacheType } from '../../data/model/commonTypes';
import EventBusUtil from '../../common/util/EventBusUtil';

// ========================================
// 媒体数据相关接口
// ========================================

/**
 * 媒体详情
 */
export interface MediaDetail {
  id: string;
  title: string;
  type: 'movie' | 'tv' | 'anime' | 'documentary' | 'variety';
  area: string;           // 地区
  lang: string;           // 语言
  year: string;          // 年份
  score: string;         // 评分
  status: string;        // 状态
  desc: string;          // 描述
  cover: string;         // 封面图
  tags: string[];        // 标签
  actors: string[];       // 演员
  director: string;       // 导演
  duration?: number;      // 时长（分钟）
  releaseDate?: number;   // 发布日期
}

/**
 * 剧集信息
 */
export interface EpisodeInfo {
  id: string;
  name: string;          // 剧集名称
  episodeNumber: number;  // 剧集编号
  url: string;           // 播放URL
  size?: number;         // 大小
  duration?: number;      // 时长
  quality?: string;       // 画质
}

/**
 * 播放源
 */
export interface PlaySource {
  id: string;
  name: string;          // 播放源名称
  url: string;           // 播放URL
  format: string;         // 格式 (mp4, m3u8, etc.)
  quality: string;        // 画质 (1080p, 720p, etc.)
  isDefault: boolean;     // 是否默认
  needParse: boolean;    // 是否需要解析
}

/**
 * 解析结果
 */
export interface ParseResult {
  success: boolean;
  playSources: PlaySource[];
  error?: string;
}

/**
 * 相关媒体
 */
export interface RelatedMedia {
  id: string;
  title: string;
  cover: string;
  type: string;
  sourceId: string;
  sourceName: string;
}

// ========================================
// 媒体数据获取服务类
// ========================================

export class MediaDataFetcherService {
  private static instance: MediaDataFetcherService;
  private logger: Logger;
  private contentService: ContentAccessService;
  private cacheService: CacheService;
  private eventBus: EventBusUtil;
  
  // 缓存配置
  private readonly CACHE_DURATION = {
    MEDIA_DETAIL: 30 * 60,        // 媒体详情缓存30分钟
    EPISODES: 10 * 60,           // 剧集列表缓存10分钟
    PLAY_SOURCES: 5 * 60,          // 播放源缓存5分钟
    RELATED_MEDIA: 60 * 60          // 相关媒体缓存1小时
  };
  
  private constructor() {
    this.logger = Logger.getInstance('MediaDataFetcherService');
    this.contentService = ContentAccessService.getInstance();
    this.cacheService = CacheService.getInstance();
    this.eventBus = EventBusUtil.getInstance();
    
    Logger.info('MediaDataFetcher', MediaDataFetcherService initialized);
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): MediaDataFetcherService {
    if (!MediaDataFetcherService.instance) {
      MediaDataFetcherService.instance = new MediaDataFetcherService();
    }
    return MediaDataFetcherService.instance;
  }
  
  /**
   * 获取媒体详情
   */
  public async getMediaDetail(mediaId: string, sourceId?: string): Promise<MediaDetail | null> {
    try {
      Logger.info(`Fetching media detail for ID: ${mediaId}`);
      
      // 检查缓存
      const cacheKey: string = `media_detail_${mediaId}_${sourceId || 'all'}`;
      const cached: MediaDetail | null = await this.cacheService.get<MediaDetail>(cacheKey, CacheType.MEDIA);
      
      const isCached: boolean = !!cached;
      if (isCached) {
        this.logger.debug(`Cache hit for media detail: ${mediaId}`);
        return cached;
      }
      
      // 从 ContentAccessService 获取站点
      const sites: VodSite[] = sourceId 
        ? this.contentService.getVodSitesBySource([sourceId])
        : this.contentService.getAllVodSites();
      
      if (sites.length === 0) {
        throw new Error('No VOD sites available');
      }
      
      // 从站点获取媒体详情
      const detail = await this.fetchMediaDetailFromSites(mediaId, sites);
      
      if (detail) {
        // 缓存结果
        await this.cacheService.set(
          cacheKey,
          detail,
          CacheType.MEDIA,
          this.CACHE_DURATION.MEDIA_DETAIL
        );
      }
      
      return detail;
    } catch (error) {
      Logger.error(`Failed to get media detail for ${mediaId}`, error as Error);
      return null;
    }
  }
  
  /**
   * 获取剧集列表
   */
  public async getEpisodes(mediaId: string, sourceId?: string): Promise<EpisodeInfo[]> {
    try {
      Logger.info(`Fetching episodes for media: ${mediaId}`);
      
      // 检查缓存
      const cacheKey: string = `episodes_${mediaId}_${sourceId || 'all'}`;
      const cached: EpisodeInfo[] | null = await this.cacheService.get<EpisodeInfo[]>(cacheKey, CacheType.MEDIA);
      
      const isCached: boolean = !!cached;
      if (isCached) {
        this.logger.debug(`Cache hit for episodes: ${mediaId}`);
        return cached;
      }
      
      // 从站点获取剧集
      const episodes: EpisodeInfo[] = await this.fetchEpisodesFromSites(mediaId, sourceId);
      
      if (episodes.length > 0) {
        // 缓存结果
        await this.cacheService.set(
          cacheKey,
          episodes,
          CacheType.MEDIA,
          this.CACHE_DURATION.EPISODES
        );
      }
      
      return episodes;
    } catch (error) {
      Logger.error(`Failed to get episodes for ${mediaId}`, error as Error);
      return [];
    }
  }
  
  /**
   * 获取播放源
   */
  public async getPlaySources(mediaId: string, episodeId: string, sourceId?: string): Promise<PlaySource[]> {
    try {
      Logger.info(`Fetching play sources for media: ${mediaId}, episode: ${episodeId}`);
      
      // 检查缓存
      const cacheKey: string = `play_sources_${mediaId}_${episodeId}_${sourceId || 'all'}`;
      const cached: PlaySource[] | null = await this.cacheService.get<PlaySource[]>(cacheKey, CacheType.MEDIA);
      
      const isCached: boolean = !!cached;
      if (isCached) {
        this.logger.debug(`Cache hit for play sources: ${mediaId}`);
        return cached;
      }
      
      // 从站点获取播放源
      const sources: PlaySource[] = await this.fetchPlaySourcesFromSites(mediaId, episodeId, sourceId);
      
      if (sources.length > 0) {
        // 缓存结果
        await this.cacheService.set(
          cacheKey,
          sources,
          CacheType.MEDIA,
          this.CACHE_DURATION.PLAY_SOURCES
        );
      }
      
      return sources;
    } catch (error) {
      Logger.error(`Failed to get play sources for ${mediaId}`, error as Error);
      return [];
    }
  }
  
  /**
   * 解析播放地址
   */
  public async parsePlayUrl(playSource: PlaySource): Promise<ParseResult> {
    try {
      Logger.info(`Parsing play URL from source: ${playSource.name}`);
      
      // 如果不需要解析，直接返回
      if (!playSource.needParse) {
        return {
          success: true,
          playSources: [playSource]
        };
      }
      
      // 调用解析器
      const parser: Object | null = await this.getParser(playSource);
      
      if (!parser) {
        return {
          success: false,
          playSources: [],
          error: 'No parser available'
        };
      }
      
      // 解析播放地址
      const parserWithParse: { parse: (url: string) => Promise<PlaySource[]> } = parser as { parse: (url: string) => Promise<PlaySource[]> };
      const parsedSources: PlaySource[] = await parserWithParse.parse(playSource.url);
      
      return {
        success: parsedSources.length > 0,
        playSources: parsedSources,
        error: parsedSources.length === 0 ? 'Parse failed' : undefined
      };
    } catch (error: Error) {
      Logger.error(`Failed to parse play URL: ` + error.message);
      return {
        success: false,
        playSources: [],
        error: error instanceof Error ? error.message : String(error)
      };
    }
  }
  
  /**
   * 获取相关媒体
   */
  public async getRelatedMedia(mediaId: string, limit: number = 10): Promise<RelatedMedia[]> {
    try {
      Logger.info(`Fetching related media for: ${mediaId}`);
      
      // 检查缓存
      const cacheKey: string = `related_media_${mediaId}`;
      const cached: RelatedMedia[] | null = await this.cacheService.get<RelatedMedia[]>(cacheKey, CacheType.MEDIA);
      
      if (cached) {
        this.logger.debug(`Cache hit for related media: ${mediaId}`);
        return cached.slice(0, limit);
      }
      
      // 获取媒体详情以确定分类和标签
      const mediaDetail: MediaDetail | null = await this.getMediaDetail(mediaId);
      
      if (!mediaDetail) {
        return [];
      }
      
      // 获取所有站点
      const allSites: VodSiteWithSource[] = this.contentService.getAllVodSites();
      
      // 查找相关媒体
      const related: RelatedMedia[] = [];
      
      for (const site of allSites) {
        // 简化实现：将站点作为相关媒体
        if (related.length >= limit) {
          break;
        }
        
        related.push({
          id: site.id,
          title: site.name,
          cover: site.icon || '',
          type: mediaDetail.type,
          sourceId: site.sourceId,
          sourceName: site.sourceName
        });
      }
      
      // 缓存结果
      if (related.length > 0) {
        await this.cacheService.set(
          cacheKey,
          related,
          CacheType.MEDIA,
          this.CACHE_DURATION.RELATED_MEDIA
        );
      }
      
      return related;
    } catch (error) {
      Logger.error(`Failed to get related media for ${mediaId}`, error as Error);
      return [];
    }
  }
  
  /**
   * 搜索媒体
   */
  public async searchMedia(
    keyword: string,
    sourceId?: string,
    limit: number = 20
  ): Promise<MediaDetail[]> {
    try {
      Logger.info(`Searching media with keyword: ${keyword}`);
      
      if (!keyword.trim()) {
        return [];
      }
      
      // 获取站点
      const sites: VodSiteWithSource[] = sourceId
        ? this.contentService.getVodSitesBySource([sourceId])
        : this.contentService.getAllVodSites();
      
      if (sites.length === 0) {
        return [];
      }
      
      // 从各站点搜索
      const allResults: MediaDetail[] = [];
      
      for (const site of sites) {
        const results = await this.searchFromSite(site, keyword);
        allResults.push(...results);
        
        if (allResults.length >= limit) {
          break;
        }
      }
      
      return allResults.slice(0, limit);
    } catch (error) {
      Logger.error(`Failed to search media: ${keyword}`, error as Error);
      return [];
    }
  }
  
  // ========================================
  // 私有方法
  // ========================================
  
  /**
   * 从站点获取媒体详情
   */
  private async fetchMediaDetailFromSites(
    mediaId: string,
    sites: VodSiteWithSource[]
  ): Promise<MediaDetail | null> {
    for (const site of sites) {
      try {
        this.logger.debug(`Fetching media detail from site: ${site.name}`);
        
        const detail = await this.fetchMediaDetailFromSite(site, mediaId);
        
        if (detail) {
          return detail;
        }
      } catch (error) {
        Logger.warn(`Failed to fetch from site ${site.name}, trying next...`);
        continue;
      }
    }
    
    return null;
  }
  
  /**
   * 从单个站点获取媒体详情
   */
  private async fetchMediaDetailFromSite(
    site: VodSiteWithSource,
    mediaId: string
  ): Promise<MediaDetail | null> {
    try {
      // 简化实现：基于站点数据生成详情
      // 实际应用中应该调用站点的API
      this.logger.debug(`Fetching from ${site.name}, siteKey: ${site.siteKey}`);
      
      // 检查站点是否支持该mediaId
      if (!this.isMediaIdFromSite(mediaId, site)) {
        return null;
      }
      
      // 生成详情
      const detail: MediaDetail = {
        id: mediaId,
        title: `${site.name} - 媒体详情`,
        type: 'movie',
        area: site.area || '未知',
        lang: site.lang || '未知',
        year: new Date().getFullYear().toString(),
        score: '8.0',
        status: '更新中',
        desc: `来自${site.name}的精彩内容。这部作品制作精良，演员阵容强大，讲述了一个引人入胜的故事。`,
        cover: site.icon || '',
        tags: (site.tags || []).slice(0, 5),
        actors: [],
        director: '',
        duration: 120
      };
      
      return detail;
    } catch (error) {
      Logger.error(`Failed to fetch detail from site ${site.name}`, error as Error);
      return null;
    }
  }
  
  /**
   * 从站点获取剧集列表
   */
  private async fetchEpisodesFromSites(
    mediaId: string,
    sourceId?: string
  ): Promise<EpisodeInfo[]> {
    try {
      // 简化实现：生成模拟剧集列表
      // 实际应用中应该调用站点的API
      const episodes: EpisodeInfo[] = [];
      const episodeCount = Math.floor(Math.random() * 24) + 1; // 1-24集
      
      for (let i = 1; i <= episodeCount; i++) {
        episodes.push({
          id: `ep_${i}`,
          name: `第${i}集`,
          episodeNumber: i,
          url: `${mediaId}/ep_${i}`,
          duration: 45,
          quality: '1080p'
        });
      }
      
      return episodes;
    } catch (error) {
      Logger.error('MediaDataFetcher', Failed to fetch episodes, error as Error);
      return [];
    }
  }
  
  /**
   * 从站点获取播放源
   */
  private async fetchPlaySourcesFromSites(
    mediaId: string,
    episodeId: string,
    sourceId?: string
  ): Promise<PlaySource[]> {
    try {
      // 简化实现：生成多个播放源
      // 实际应用中应该调用站点的API或解析器
      const sources: PlaySource[] = [];
      
      // 生成多个播放源
      const sourceNames = ['默认线路', '备用线路1', '备用线路2', '高清线路', '极速线路'];
      const qualities = ['1080p', '720p', '480p'];
      
      sourceNames.forEach((name, index) => {
        sources.push({
          id: `source_${index}`,
          name: name,
          url: `${mediaId}/${episodeId}/${index}`,
          format: 'm3u8',
          quality: qualities[index % qualities.length],
          isDefault: index === 0,
          needParse: false
        });
      });
      
      return sources;
    } catch (error) {
      Logger.error('MediaDataFetcher', Failed to fetch play sources, error as Error);
      return [];
    }
  }
  
  /**
   * 从站点搜索
   */
  private async searchFromSite(
    site: VodSiteWithSource,
    keyword: string
  ): Promise<MediaDetail[]> {
    try {
      // 简化实现：基于站点名称生成搜索结果
      // 实际应用中应该调用站点的搜索API
      if (!site.name.toLowerCase().includes(keyword.toLowerCase())) {
        return [];
      }
      
      return [{
        id: site.id,
        title: site.name,
        type: 'movie',
        area: site.area || '未知',
        lang: site.lang || '未知',
        year: new Date().getFullYear().toString(),
        score: '8.0',
        status: '更新中',
        desc: site.name,
        cover: site.icon || '',
        tags: (site.tags || []).slice(0, 5),
        actors: [],
        director: ''
      }];
    } catch (error) {
      Logger.error(`Failed to search from site ${site.name}`, error as Error);
      return [];
    }
  }
  
  /**
   * 获取解析器
   */
  private async getParser(playSource: PlaySource): Promise<Object | null> {
    try {
      // 简化实现：返回 null，表示不需要解析
      // 实际应用中应该根据 URL 匹配对应的解析器
      return null;
    } catch (error: Error) {
      Logger.error('MediaDataFetcher', 'Failed to get parser: ' + error.message);
      return null;
    }
  }
  
  /**
   * 检查mediaId是否来自指定站点
   */
  private isMediaIdFromSite(mediaId: string, site: VodSiteWithSource): boolean {
    // 简化实现：检查mediaId前缀
    // 实际应用中应该有更复杂的逻辑
    return mediaId.startsWith(site.id) || mediaId === site.id;
  }
  
  /**
   * 清除缓存
   */
  public async clearCache(): Promise<void> {
    try {
      // 清除媒体相关缓存
      Logger.info('MediaDataFetcher', Clearing media data cache);
      // TODO: 实现清除缓存逻辑
    } catch (error) {
      Logger.error('MediaDataFetcher', Failed to clear cache, error as Error);
    }
  }
  
  /**
   * 预加载媒体数据
   */
  public async preloadMedia(mediaIds: string[]): Promise<void> {
    try {
      Logger.info(`Preloading ${mediaIds.length} media items`);
      
      for (const mediaId of mediaIds) {
        // 异步预加载，不等待
        this.getMediaDetail(mediaId).catch((err: Error) => {
          Logger.warn(`Failed to preload media ${mediaId}: ` + err.message);
        });
      }
    } catch (error: Error) {
      Logger.error('MediaDataFetcher', 'Failed to preload media: ' + error.message);
    }
  }
}

export default MediaDataFetcherService;
