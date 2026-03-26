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
  
  // 缓存配置 - 根据媒体类型自动调整
  private readonly CACHE_DURATION = {
    // 基础缓存时间（秒）
    BASE: {
      MEDIA_DETAIL: 30 * 60,        // 媒体详情基础缓存30分钟
      EPISODES: 10 * 60,           // 剧集列表基础缓存10分钟
      PLAY_SOURCES: 5 * 60,          // 播放源基础缓存5分钟
      RELATED_MEDIA: 60 * 60          // 相关媒体基础缓存1小时
    },
    // 按媒体类型的缓存系数
    TYPE_FACTOR: {
      movie: 1.5,           // 电影：缓存时间延长50%
      tv: 1.0,             // 电视剧：标准缓存时间
      anime: 0.8,           // 动漫：缓存时间缩短20%
      documentary: 2.0,     // 纪录片：缓存时间延长100%
      variety: 0.5          // 综艺：缓存时间缩短50%
    },
    // 最小缓存时间（秒）
    MIN: {
      MEDIA_DETAIL: 15 * 60,        // 媒体详情最小15分钟
      EPISODES: 5 * 60,            // 剧集列表最小5分钟
      PLAY_SOURCES: 2 * 60,         // 播放源最小2分钟
      RELATED_MEDIA: 30 * 60        // 相关媒体最小30分钟
    },
    // 最大缓存时间（秒）
    MAX: {
      MEDIA_DETAIL: 120 * 60,       // 媒体详情最大2小时
      EPISODES: 30 * 60,           // 剧集列表最大30分钟
      PLAY_SOURCES: 15 * 60,         // 播放源最大15分钟
      RELATED_MEDIA: 180 * 60       // 相关媒体最大3小时
    }
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
        // 计算智能缓存时间
        const cacheDuration = this.calculateCacheDuration('MEDIA_DETAIL', detail.type);
        
        // 缓存结果
        await this.cacheService.set(
          cacheKey,
          detail,
          CacheType.MEDIA,
          cacheDuration
        );
        
        this.logger.debug(`Cached media detail with duration: ${cacheDuration}s (type: ${detail.type})`);
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
        // 获取媒体类型以计算智能缓存时间
        let mediaType: string | undefined;
        try {
          const mediaDetail = await this.getMediaDetail(mediaId, sourceId);
          mediaType = mediaDetail?.type;
        } catch (error) {
          this.logger.debug('Failed to get media type for cache calculation', error as Error);
        }
        
        // 计算智能缓存时间
        const cacheDuration = this.calculateCacheDuration('EPISODES', mediaType);
        
        // 缓存结果
        await this.cacheService.set(
          cacheKey,
          episodes,
          CacheType.MEDIA,
          cacheDuration
        );
        
        this.logger.debug(`Cached episodes with duration: ${cacheDuration}s (type: ${mediaType || 'unknown'})`);
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
        // 获取媒体类型以计算智能缓存时间
        let mediaType: string | undefined;
        try {
          const mediaDetail = await this.getMediaDetail(mediaId, sourceId);
          mediaType = mediaDetail?.type;
        } catch (error) {
          this.logger.debug('Failed to get media type for cache calculation', error as Error);
        }
        
        // 计算智能缓存时间
        const cacheDuration = this.calculateCacheDuration('PLAY_SOURCES', mediaType);
        
        // 缓存结果
        await this.cacheService.set(
          cacheKey,
          sources,
          CacheType.MEDIA,
          cacheDuration
        );
        
        this.logger.debug(`Cached play sources with duration: ${cacheDuration}s (type: ${mediaType || 'unknown'})`);
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
      if (related.length > 0 && mediaDetail) {
        // 计算智能缓存时间
        const cacheDuration = this.calculateCacheDuration('RELATED_MEDIA', mediaDetail.type);
        
        await this.cacheService.set(
          cacheKey,
          related,
          CacheType.MEDIA,
          cacheDuration
        );
        
        this.logger.debug(`Cached related media with duration: ${cacheDuration}s (type: ${mediaDetail.type})`);
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
      this.logger.debug(`Fetching media detail from site: ${site.name}, mediaId: ${mediaId}`);
      
      // 检查站点是否支持该mediaId
      if (!this.isMediaIdFromSite(mediaId, site)) {
        return null;
      }
      
      // 实际应用中应该调用站点的API
      // 这里使用站点的实际数据构建媒体详情
      const detail: MediaDetail = {
        id: mediaId,
        title: site.name,
        type: site.type || 'movie',
        area: site.area || '未知',
        lang: site.lang || '未知',
        year: site.year || new Date().getFullYear().toString(),
        score: site.score || '7.0',
        status: site.status || '更新中',
        desc: site.desc || `来自${site.name}的内容`,
        cover: site.icon || '',
        tags: site.tags || [],
        actors: site.actors || [],
        director: site.director || '',
        duration: site.duration || 90
      };
      
      this.logger.debug(`Fetched media detail: ${detail.title}`);
      return detail;
    } catch (error) {
      this.logger.error(`Failed to fetch detail from site ${site.name}`, error as Error);
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
      this.logger.debug(`Fetching episodes for media: ${mediaId}, source: ${sourceId || 'all'}`);
      
      // 实际应用中应该调用站点的API
      // 这里基于媒体ID和站点信息生成合理的剧集列表
      const episodes: EpisodeInfo[] = [];
      
      // 根据媒体类型确定剧集数量
      // 电影通常只有1集，电视剧有多个集数
      const mediaDetail = await this.getMediaDetail(mediaId, sourceId);
      const episodeCount = mediaDetail?.type === 'movie' ? 1 : 12; // 电影1集，其他12集
      
      for (let i = 1; i <= episodeCount; i++) {
        episodes.push({
          id: `ep_${i}`,
          name: mediaDetail?.type === 'movie' ? '正片' : `第${i}集`,
          episodeNumber: i,
          url: `${mediaId}/ep_${i}`,
          duration: mediaDetail?.duration || 45,
          quality: '1080p'
        });
      }
      
      this.logger.debug(`Fetched ${episodes.length} episodes for media: ${mediaId}`);
      return episodes;
    } catch (error) {
      this.logger.error('Failed to fetch episodes', error as Error);
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
      this.logger.debug(`Fetching play sources for media: ${mediaId}, episode: ${episodeId}`);
      
      // 实际应用中应该调用站点的API或解析器
      const sources: PlaySource[] = [];
      
      // 基于媒体类型和质量级别生成播放源
      const qualities = ['1080p', '720p', '480p'];
      const formats = ['m3u8', 'mp4'];
      
      qualities.forEach((quality, index) => {
        formats.forEach((format, formatIndex) => {
          const sourceName = `${quality} ${format.toUpperCase()}`;
          sources.push({
            id: `source_${index}_${formatIndex}`,
            name: sourceName,
            url: `${mediaId}/${episodeId}/${quality}/${format}`,
            format: format,
            quality: quality,
            isDefault: index === 0 && formatIndex === 0, // 默认使用1080p m3u8
            needParse: format === 'm3u8' // m3u8格式可能需要解析
          });
        });
      });
      
      this.logger.debug(`Fetched ${sources.length} play sources for media: ${mediaId}`);
      return sources;
    } catch (error) {
      this.logger.error('Failed to fetch play sources', error as Error);
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
      this.logger.debug(`Searching from site: ${site.name}, keyword: ${keyword}`);
      
      // 实际应用中应该调用站点的搜索API
      // 这里基于站点信息和关键词生成搜索结果
      const results: MediaDetail[] = [];
      
      // 检查站点名称、标签或描述是否包含关键词
      const keywordLower = keyword.toLowerCase();
      const matchesKeyword = 
        site.name.toLowerCase().includes(keywordLower) ||
        (site.tags && site.tags.some(tag => tag.toLowerCase().includes(keywordLower))) ||
        (site.desc && site.desc.toLowerCase().includes(keywordLower));
      
      if (matchesKeyword) {
        results.push({
          id: site.id,
          title: site.name,
          type: site.type || 'movie',
          area: site.area || '未知',
          lang: site.lang || '未知',
          year: site.year || new Date().getFullYear().toString(),
          score: site.score || '7.0',
          status: site.status || '更新中',
          desc: site.desc || `来自${site.name}的内容`,
          cover: site.icon || '',
          tags: site.tags || [],
          actors: site.actors || [],
          director: site.director || ''
        });
      }
      
      this.logger.debug(`Found ${results.length} results from site: ${site.name}`);
      return results;
    } catch (error) {
      this.logger.error(`Failed to search from site ${site.name}`, error as Error);
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
      this.logger.info('Clearing media data cache');
      await this.cacheService.clear(CacheType.MEDIA);
      this.logger.info('Media data cache cleared successfully');
    } catch (error) {
      this.logger.error('Failed to clear cache', error as Error);
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
  
  /**
   * 批量获取媒体详情
   */
  public async getMediaDetails(mediaIds: string[], sourceId?: string): Promise<Map<string, MediaDetail | null>> {
    try {
      Logger.info(`Fetching details for ${mediaIds.length} media items`);
      
      const results = new Map<string, MediaDetail | null>();
      const fetchPromises = mediaIds.map(async (mediaId) => {
        try {
          const detail = await this.getMediaDetail(mediaId, sourceId);
          results.set(mediaId, detail);
        } catch (error) {
          this.logger.warn(`Failed to fetch detail for ${mediaId}`, error as Error);
          results.set(mediaId, null);
        }
      });
      
      // 并行处理所有请求
      await Promise.all(fetchPromises);
      
      this.logger.debug(`Completed batch fetch for ${mediaIds.length} media items`);
      return results;
    } catch (error) {
      Logger.error('Failed to batch fetch media details', error as Error);
      return new Map();
    }
  }
  
  /**
   * 批量获取剧集列表
   */
  public async getEpisodesList(mediaIds: string[], sourceId?: string): Promise<Map<string, EpisodeInfo[]>> {
    try {
      Logger.info(`Fetching episodes for ${mediaIds.length} media items`);
      
      const results = new Map<string, EpisodeInfo[]>();
      const fetchPromises = mediaIds.map(async (mediaId) => {
        try {
          const episodes = await this.getEpisodes(mediaId, sourceId);
          results.set(mediaId, episodes);
        } catch (error) {
          this.logger.warn(`Failed to fetch episodes for ${mediaId}`, error as Error);
          results.set(mediaId, []);
        }
      });
      
      // 并行处理所有请求
      await Promise.all(fetchPromises);
      
      this.logger.debug(`Completed batch fetch for ${mediaIds.length} episodes lists`);
      return results;
    } catch (error) {
      Logger.error('Failed to batch fetch episodes', error as Error);
      return new Map();
    }
  }
  
  /**
   * 批量获取播放源
   */
  public async getPlaySourcesList(mediaEpisodePairs: Array<{ mediaId: string; episodeId: string }>, sourceId?: string): Promise<Map<string, PlaySource[]>> {
    try {
      Logger.info(`Fetching play sources for ${mediaEpisodePairs.length} media-episode pairs`);
      
      const results = new Map<string, PlaySource[]>();
      const fetchPromises = mediaEpisodePairs.map(async (pair) => {
        try {
          const sources = await this.getPlaySources(pair.mediaId, pair.episodeId, sourceId);
          const key = `${pair.mediaId}_${pair.episodeId}`;
          results.set(key, sources);
        } catch (error) {
          this.logger.warn(`Failed to fetch play sources for ${pair.mediaId}-${pair.episodeId}`, error as Error);
          const key = `${pair.mediaId}_${pair.episodeId}`;
          results.set(key, []);
        }
      });
      
      // 并行处理所有请求
      await Promise.all(fetchPromises);
      
      this.logger.debug(`Completed batch fetch for ${mediaEpisodePairs.length} play sources lists`);
      return results;
    } catch (error) {
      Logger.error('Failed to batch fetch play sources', error as Error);
      return new Map();
    }
  }
  
  /**
   * 计算智能缓存时间
   */
  private calculateCacheDuration(cacheType: keyof typeof this.CACHE_DURATION.BASE, mediaType?: string): number {
    // 获取基础缓存时间
    const baseDuration = this.CACHE_DURATION.BASE[cacheType];
    
    // 根据媒体类型获取缓存系数
    let factor = 1.0;
    if (mediaType && this.CACHE_DURATION.TYPE_FACTOR[mediaType as keyof typeof this.CACHE_DURATION.TYPE_FACTOR]) {
      factor = this.CACHE_DURATION.TYPE_FACTOR[mediaType as keyof typeof this.CACHE_DURATION.TYPE_FACTOR];
    }
    
    // 计算缓存时间
    let duration = baseDuration * factor;
    
    // 确保在最小和最大范围内
    const minDuration = this.CACHE_DURATION.MIN[cacheType];
    const maxDuration = this.CACHE_DURATION.MAX[cacheType];
    
    duration = Math.max(minDuration, Math.min(duration, maxDuration));
    
    return Math.round(duration);
  }
}

export default MediaDataFetcherService;
