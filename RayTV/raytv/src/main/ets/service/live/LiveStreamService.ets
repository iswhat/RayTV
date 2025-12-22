// LiveStreamService - 直播流服务类
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import DateUtil from '../../common/util/DateUtil';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import DatabaseRepository from '../../data/repository/DatabaseRepository';
import NetworkRepository from '../../data/repository/NetworkRepository';
import { ConfigParser } from '../config/ConfigParser';
import { ConfigLoader } from '../config/ConfigLoader';

// 导入模型和DTO
import ApiResponse, { ResponseCode } from '../../data/dto/ApiResponse';
import Movie, { VideoSource, VideoType, VideoQuality } from '../../data/model/Movie';
import { LiveCollection } from '../../data/bean/Config';

// 常量定义
const TAG = 'LiveStreamService';
const LIVE_FAVORITES_KEY = 'live_favorites';
const LIVE_CATEGORY_CACHE_KEY = 'live_categories';
const LIVE_CHANNEL_CACHE_KEY = 'live_channels';
const CACHE_EXPIRY_TIME = 30 * 60 * 1000; // 30分钟缓存有效�?
// 直播状态枚�?export enum LiveStatus {
  OFFLINE = 'offline',    // 离线
  LIVE = 'live',         // 直播�?  UPCOMING = 'upcoming',  // 即将开�?  ENDING = 'ending',      // 即将结束
  ERROR = 'error'         // 错误
}

// 直播质量枚举
export enum LiveQuality {
  AUTO = 'auto',         // 自动
  LOW = 'low',          // 低清晰度
  SD = 'sd',           // 标清
  HD = 'hd',           // 高清
  FHD = 'fhd',         // 全高�?  UHD = 'uhd'          // 超高�?}

// 直播分类接口
export interface LiveCategory {
  id: string;           // 分类ID
  name: string;         // 分类名称
  icon?: string;        // 分类图标
  order: number;        // 排序
  channelCount: number; // 频道数量
}

// 直播频道接口
export interface LiveChannel {
  id: string;          // 频道ID
  name: string;        // 频道名称
  logo?: string;       // 频道logo
  description?: string; // 频道描述
  categoryId: string;  // 分类ID
  categoryName: string; // 分类名称
  status: LiveStatus;  // 直播状�?  url?: string;        // 直播源URL
  qualities?: LiveQuality[]; // 可用清晰�?  currentProgram?: LiveProgram; // 当前节目
  nextProgram?: LiveProgram;   // 下一个节�?  tags?: string[];     // 标签
  isFavorite: boolean; // 是否收藏
  viewCount?: number;  // 观看人数
  country?: string;    // 国家/地区
  language?: string;   // 语言
  isLocked?: boolean;  // 是否锁定
}

// 直播节目接口
export interface LiveProgram {
  id: string;          // 节目ID
  title: string;       // 节目标题
  startTime: number;   // 开始时间（时间戳）
  endTime: number;     // 结束时间（时间戳�?  description?: string; // 节目描述
  cover?: string;      // 节目封面
  genre?: string[];    // 节目类型
  actors?: string[];   // 演员
  director?: string;   // 导演
}

// 直播事件接口
export interface LiveEvent {
  id: string;          // 事件ID
  title: string;       // 事件标题
  description: string; // 事件描述
  startTime: number;   // 开始时�?  endTime: number;     // 结束时间
  coverImage?: string; // 封面�?  channelId: string;   // 所属频道ID
  channelName: string; // 所属频道名�?  status: LiveStatus;  // 直播状�?  isHighlight?: boolean; // 是否高亮
}

// 直播源信息接�?export interface LiveSource {
  id: string;          // 源ID
  url: string;         // 源URL
  quality: LiveQuality; // 清晰�?  isDefault: boolean;  // 是否默认
  bitrate?: number;    // 比特�?  codec?: string;      // 编码格式
  protocol?: string;   // 协议类型
  resolution?: string; // 分辨�?}

// 直播筛选条件接�?export interface LiveFilter {
  categories?: string[]; // 分类ID列表
  search?: string;       // 搜索关键�?  status?: LiveStatus[]; // 直播状�?  countries?: string[];  // 国家/地区
  languages?: string[];  // 语言
  favoritesOnly?: boolean; // 仅显示收�?}

// 直播排序类型枚举
export enum LiveSortType {
  DEFAULT = 'default',     // 默认排序
  NAME_ASC = 'name_asc',    // 名称升序
  NAME_DESC = 'name_desc',  // 名称降序
  VIEW_COUNT = 'view_count', // 观看人数
  STATUS = 'status'        // 状�?}

// 频道组接�?export interface ChannelGroup {
  id: string;          // 组ID
  name: string;        // 组名�?  channelIds: string[]; // 频道ID列表
  order: number;       // 排序
  isDefault?: boolean;  // 是否默认�?}

// 直播统计信息接口
export interface LiveStatistics {
  totalChannels: number;  // 总频道数
  liveChannels: number;   // 直播中频道数
  offlineChannels: number; // 离线频道�?  totalCategories: number; // 总分类数
  favoriteChannels: number; // 收藏频道�?  recentViews: number;    // 最近观看数
}

/**
 * 直播流服务类
 * 负责管理直播相关功能
 */
export default class LiveStreamService {
  private static instance: LiveStreamService;
  private databaseRepo: DatabaseRepository;
  private networkRepo: NetworkRepository;
  private configParser: ConfigParser;
  private configLoader: ConfigLoader;
  
  private favoriteChannels: Set<string> = new Set();
  private channelGroups: Map<string, ChannelGroup> = new Map();
  private isInitialized: boolean = false;
  
  // 缓存数据
  private cachedCategories: {
    data: LiveCategory[];
    timestamp: number;
  } | null = null;
  
  private cachedChannels: Map<string, {
    data: LiveChannel[];
    timestamp: number;
  }> = new Map();
  
  // 监听�?  private favoriteListeners: Array<(channelId: string, isFavorite: boolean) => void> = [];
  private channelGroupListeners: Array<(groups: ChannelGroup[]) => void> = [];
  private statusListeners: Map<string, Array<(status: LiveStatus) => void>> = new Map();

  /**
   * 构造函数（私有，防止外部实例化�?   */
  private constructor() {
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
    this.networkRepo = RepositoryFactory.getRepository('network') as NetworkRepository;
    this.configParser = ConfigParser.getInstance();
    this.configLoader = ConfigLoader.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): LiveStreamService {
    if (!LiveStreamService.instance) {
      LiveStreamService.instance = new LiveStreamService();
    }
    return LiveStreamService.instance;
  }

  /**
   * 初始化直播服�?   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing live stream service...');
      
      // 加载收藏频道
      await this.loadFavoriteChannels();
      
      // 加载频道�?      await this.loadChannelGroups();
      
      // 加载缓存数据
      await this.loadCachedData();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Live stream service initialized successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize live stream service', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
    }
  }
  
  /**
   * 从配置文件加载直播列�?   * @param configUrl 配置文件URL
   */
  public async loadLiveChannelsFromConfig(configUrl: string): Promise<ApiResponse<LiveCategory[]>> {
    try {
      Logger.info(TAG, `Loading live channels from config: ${configUrl}`);
      
      // 加载配置文件内容
      const configContent = await this.configLoader.loadFromUrl(configUrl);
      
      // 解析lives配置
      const liveCollection = this.configParser.parseLives(configContent);
      
      // 转换为直播分类和频道数据
      const categories: LiveCategory[] = [];
      const channelMap: Map<string, LiveChannel[]> = new Map();
      
      let categoryId = 1;
      let channelId = 1;
      
      for (const liveItem of liveCollection.lives) {
        if ('group' in liveItem) {
          // 分组格式
          const category: LiveCategory = {
            id: `category_${categoryId++}`,
            name: liveItem.group,
            icon: undefined,
            order: categoryId,
            channelCount: liveItem.channels.length
          };
          categories.push(category);
          
          // 转换频道数据
          const channels: LiveChannel[] = liveItem.channels.map(channel => {
            return {
              id: `channel_${channelId++}`,
              name: channel.name,
              logo: channel.logo,
              description: undefined,
              categoryId: category.id,
              categoryName: category.name,
              status: LiveStatus.LIVE,
              url: channel.url || channel.urls?.[0] || '',
              qualities: [LiveQuality.AUTO, LiveQuality.HD, LiveQuality.SD],
              isFavorite: this.favoriteChannels.has(`channel_${channelId}`),
              viewCount: Math.floor(Math.random() * 1000),
              country: undefined,
              language: undefined,
              isLocked: false
            };
          });
          
          channelMap.set(category.id, channels);
        } else {
          // 直接直播源格式
          const category: LiveCategory = {
            id: `category_${categoryId++}`,
            name: liveItem.name,
            icon: liveItem.logo,
            order: categoryId,
            channelCount: 1
          };
          categories.push(category);
          
          // 创建频道数据
          const channel: LiveChannel = {
            id: `channel_${channelId++}`,
            name: liveItem.name,
            logo: liveItem.logo,
            description: undefined,
            categoryId: category.id,
            categoryName: category.name,
            status: LiveStatus.LIVE,
            url: liveItem.url || '',
            qualities: [LiveQuality.AUTO, LiveQuality.HD, LiveQuality.SD],
            isFavorite: this.favoriteChannels.has(`channel_${channelId}`),
            viewCount: Math.floor(Math.random() * 1000),
            country: undefined,
            language: undefined,
            isLocked: false
          };
          
          channelMap.set(category.id, [channel]);
        }
      }
      
      // 更新缓存
      this.cachedCategories = {
        data: categories,
        timestamp: Date.now()
      };
      
      // 保存频道到缓存
      channelMap.forEach((channels, categoryId) => {
        this.cachedChannels.set(`category_${categoryId}`, {
          data: channels,
          timestamp: Date.now()
        });
      });
      
      await this.saveCachedData();
      
      return ApiResponse.success(categories, '从配置文件加载直播列表成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to load live channels from config', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '从配置文件加载直播列表失败');
    }
  }

  /**
   * 加载收藏频道
   */
  private async loadFavoriteChannels(): Promise<void> {
    try {
      // 从存储中加载收藏列表
      const favoritesJson = await StorageUtil.getString(LIVE_FAVORITES_KEY);
      if (favoritesJson) {
        const favorites = JSON.parse(favoritesJson) as string[];
        favorites.forEach(channelId => this.favoriteChannels.add(channelId));
      }
      
      Logger.info(TAG, `Loaded ${this.favoriteChannels.size} favorite channels`);
    } catch (error) {
      Logger.error(TAG, 'Failed to load favorite channels', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.favoriteChannels = new Set();
    }
  }

  /**
   * 保存收藏频道
   */
  private async saveFavoriteChannels(): Promise<void> {
    try {
      const favoritesJson = JSON.stringify(Array.from(this.favoriteChannels));
      await StorageUtil.setString(LIVE_FAVORITES_KEY, favoritesJson);
      Logger.debug(TAG, 'Saved favorite channels');
    } catch (error) {
      Logger.error(TAG, 'Failed to save favorite channels', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
    }
  }

  /**
   * 加载频道�?   */
  private async loadChannelGroups(): Promise<void> {
    try {
      // 从数据库加载频道�?      const result = await this.databaseRepo.getLiveChannelGroups();
      if (result.isSuccess() && result.data) {
        result.data.forEach(group => {
          this.channelGroups.set(group.id, group);
        });
      }
      
      Logger.info(TAG, `Loaded ${this.channelGroups.size} channel groups`);
    } catch (error) {
      Logger.error(TAG, 'Failed to load channel groups', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
    }
  }

  /**
   * 加载缓存数据
   */
  private async loadCachedData(): Promise<void> {
    try {
      // 加载分类缓存
      const categoryCacheJson = await StorageUtil.getString(LIVE_CATEGORY_CACHE_KEY);
      if (categoryCacheJson) {
        const cacheData = JSON.parse(categoryCacheJson);
        this.cachedCategories = cacheData;
      }
      
      // 加载频道缓存
      const channelCacheJson = await StorageUtil.getString(LIVE_CHANNEL_CACHE_KEY);
      if (channelCacheJson) {
        const cacheData = JSON.parse(channelCacheJson);
        Object.entries(cacheData).forEach(([key, value]) => {
          this.cachedChannels.set(key, value);
        });
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to load cached data', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
    }
  }

  /**
   * 保存缓存数据
   */
  private async saveCachedData(): Promise<void> {
    try {
      // 保存分类缓存
      if (this.cachedCategories) {
        await StorageUtil.setString(
          LIVE_CATEGORY_CACHE_KEY,
          JSON.stringify(this.cachedCategories)
        );
      }
      
      // 保存频道缓存
      const channelsCache = Object.fromEntries(this.cachedChannels.entries());
      await StorageUtil.setString(
        LIVE_CHANNEL_CACHE_KEY,
        JSON.stringify(channelsCache)
      );
    } catch (error) {
      Logger.error(TAG, 'Failed to save cached data', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
    }
  }

  /**
   * 检查缓存是否有�?   */
  private isCacheValid(timestamp: number): boolean {
    return Date.now() - timestamp < CACHE_EXPIRY_TIME;
  }

  /**
   * 获取所有直播分�?   */
  public async getCategories(): Promise<ApiResponse<LiveCategory[]>> {
    try {
      // 检查缓�?      if (this.cachedCategories && this.isCacheValid(this.cachedCategories.timestamp)) {
        Logger.debug(TAG, 'Returning categories from cache');
        return ApiResponse.success(this.cachedCategories.data, '获取分类成功（缓存）');
      }
      
      // 从网络获取分�?      Logger.debug(TAG, 'Fetching categories from network');
      const result = await this.networkRepo.getLiveCategories();
      
      if (result.isSuccess() && result.data) {
        // 更新缓存
        this.cachedCategories = {
          data: result.data,
          timestamp: Date.now()
        };
        
        // 保存缓存到本�?        await this.saveCachedData();
        
        return ApiResponse.success(result.data, '获取分类成功');
      } else {
        // 如果网络请求失败，尝试使用缓存数�?        if (this.cachedCategories) {
          Logger.warn(TAG, 'Network failed, using cached categories');
          return ApiResponse.success(this.cachedCategories.data, '获取分类成功（缓存）');
        }
        
        return ApiResponse.error(result.code, result.message || '获取分类失败');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get categories', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      
      // 如果发生异常，尝试使用缓存数�?      if (this.cachedCategories) {
        Logger.warn(TAG, 'Error occurred, using cached categories');
        return ApiResponse.success(this.cachedCategories.data, '获取分类成功（缓存）');
      }
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取分类失败');
    }
  }

  /**
   * 根据分类获取频道列表
   */
  public async getChannelsByCategory(categoryId: string): Promise<ApiResponse<LiveChannel[]>> {
    try {
      // 检查缓�?      const cacheKey = `category_${categoryId}`;
      const cached = this.cachedChannels.get(cacheKey);
      if (cached && this.isCacheValid(cached.timestamp)) {
        Logger.debug(TAG, `Returning channels for category ${categoryId} from cache`);
        const channelsWithFavoriteStatus = cached.data.map(channel => ({
          ...channel,
          isFavorite: this.favoriteChannels.has(channel.id)
        }));
        return ApiResponse.success(channelsWithFavoriteStatus, '获取频道成功（缓存）');
      }
      
      // 从网络获取频�?      Logger.debug(TAG, `Fetching channels for category ${categoryId} from network`);
      const result = await this.networkRepo.getLiveChannelsByCategory(categoryId);
      
      if (result.isSuccess() && result.data) {
        // 更新收藏状�?        const channelsWithFavoriteStatus = result.data.map(channel => ({
          ...channel,
          isFavorite: this.favoriteChannels.has(channel.id)
        }));
        
        // 更新缓存
        this.cachedChannels.set(cacheKey, {
          data: channelsWithFavoriteStatus,
          timestamp: Date.now()
        });
        
        // 保存缓存到本�?        await this.saveCachedData();
        
        return ApiResponse.success(channelsWithFavoriteStatus, '获取频道成功');
      } else {
        // 如果网络请求失败，尝试使用缓存数�?        if (cached) {
          Logger.warn(TAG, `Network failed, using cached channels for category ${categoryId}`);
          const channelsWithFavoriteStatus = cached.data.map(channel => ({
            ...channel,
            isFavorite: this.favoriteChannels.has(channel.id)
          }));
          return ApiResponse.success(channelsWithFavoriteStatus, '获取频道成功（缓存）');
        }
        
        return ApiResponse.error(result.code, result.message || '获取频道失败');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get channels for category ${categoryId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      
      // 如果发生异常，尝试使用缓存数�?      const cacheKey = `category_${categoryId}`;
      const cached = this.cachedChannels.get(cacheKey);
      if (cached) {
        Logger.warn(TAG, `Error occurred, using cached channels for category ${categoryId}`);
        const channelsWithFavoriteStatus = cached.data.map(channel => ({
          ...channel,
          isFavorite: this.favoriteChannels.has(channel.id)
        }));
        return ApiResponse.success(channelsWithFavoriteStatus, '获取频道成功（缓存）');
      }
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道失败');
    }
  }

  /**
   * 获取所有直播频道（分页�?   */
  public async getAllChannels(
    page: number = 1,
    pageSize: number = 50
  ): Promise<ApiResponse<{ channels: LiveChannel[], total: number }>> {
    try {
      const result = await this.networkRepo.getLiveChannels(page, pageSize);
      
      if (result.isSuccess() && result.data) {
        // 更新收藏状�?        const channelsWithFavoriteStatus = result.data.channels.map(channel => ({
          ...channel,
          isFavorite: this.favoriteChannels.has(channel.id)
        }));
        
        return ApiResponse.success(
          { 
            channels: channelsWithFavoriteStatus,
            total: result.data.total
          }, 
          '获取所有频道成�?
        );
      } else {
        return ApiResponse.error(result.code, result.message || '获取频道失败');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get all channels', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道失败');
    }
  }

  /**
   * 根据ID获取直播频道详情
   */
  public async getChannelById(channelId: string): Promise<ApiResponse<LiveChannel>> {
    try {
      // 先尝试从缓存中查�?      let channel: LiveChannel | undefined;
      for (const cache of this.cachedChannels.values()) {
        const found = cache.data.find(c => c.id === channelId);
        if (found) {
          channel = found;
          break;
        }
      }
      
      if (channel && this.isCacheValid(cache.timestamp)) {
        // 更新收藏状�?        channel.isFavorite = this.favoriteChannels.has(channel.id);
        Logger.debug(TAG, `Returning channel ${channelId} from cache`);
        return ApiResponse.success(channel, '获取频道详情成功（缓存）');
      }
      
      // 从网络获取频道详�?      Logger.debug(TAG, `Fetching channel ${channelId} from network`);
      const result = await this.networkRepo.getLiveChannelById(channelId);
      
      if (result.isSuccess() && result.data) {
        // 更新收藏状�?        const channelWithFavoriteStatus: Record<string, string | number | boolean | null> = { ... };
        
        return ApiResponse.success(channelWithFavoriteStatus, '获取频道详情成功');
      } else {
        // 如果网络请求失败，但缓存中有数据
        if (channel) {
          Logger.warn(TAG, `Network failed, using cached channel ${channelId}`);
          channel.isFavorite = this.favoriteChannels.has(channel.id);
          return ApiResponse.success(channel, '获取频道详情成功（缓存）');
        }
        
        return ApiResponse.error(result.code, result.message || '获取频道详情失败');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get channel by id: ${channelId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道详情失败');
    }
  }

  /**
   * 搜索直播频道
   */
  public async searchChannels(
    keyword: string,
    filter?: LiveFilter,
    sortBy: LiveSortType = LiveSortType.DEFAULT
  ): Promise<ApiResponse<LiveChannel[]>> {
    try {
      if (!keyword || keyword.trim().length === 0) {
        return ApiResponse.validationError([
          { field: 'keyword', message: '搜索关键词不能为�? }
        ]);
      }
      
      // 构建搜索参数
      const searchParams: Record<string, string | number | boolean | null> = { ... };
      
      // 从网络搜索频�?      Logger.debug(TAG, `Searching channels with keyword: ${keyword}`);
      const result = await this.networkRepo.searchLiveChannels(searchParams);
      
      if (result.isSuccess() && result.data) {
        // 更新收藏状�?        const channelsWithFavoriteStatus = result.data.map(channel => ({
          ...channel,
          isFavorite: this.favoriteChannels.has(channel.id)
        }));
        
        return ApiResponse.success(channelsWithFavoriteStatus, '搜索频道成功');
      } else {
        return ApiResponse.error(result.code, result.message || '搜索频道失败');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to search channels with keyword: ${keyword}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '搜索频道失败');
    }
  }

  /**
   * 获取直播频道的播放源
   */
  public async getChannelSources(channelId: string): Promise<ApiResponse<LiveSource[]>> {
    try {
      // 从网络获取播放源
      Logger.debug(TAG, `Fetching sources for channel: ${channelId}`);
      const result = await this.networkRepo.getLiveChannelSources(channelId);
      
      if (result.isSuccess() && result.data) {
        return ApiResponse.success(result.data, '获取播放源成�?);
      } else {
        return ApiResponse.error(result.code, result.message || '获取播放源失�?);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get sources for channel: ${channelId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      
      // 尝试从频道信息中提取播放�?      const channelResult = await this.getChannelById(channelId);
      if (channelResult.isSuccess() && channelResult.data && channelResult.data.url) {
        const sources: LiveSource[] = [{
          id: `${channelId}_default`,
          url: channelResult.data.url,
          quality: LiveQuality.AUTO,
          isDefault: true
        }];
        
        return ApiResponse.success(sources, '获取播放源成功（从频道信息）');
      }
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取播放源失�?);
    }
  }

  /**
   * 获取频道节目�?   */
  public async getChannelPrograms(
    channelId: string,
    date: Date = new Date()
  ): Promise<ApiResponse<LiveProgram[]>> {
    try {
      // 格式化日期为YYYY-MM-DD
      const formattedDate = DateUtil.formatDate(date, 'YYYY-MM-DD');
      
      // 从网络获取节目单
      Logger.debug(TAG, `Fetching programs for channel: ${channelId} on date: ${formattedDate}`);
      const result = await this.networkRepo.getLiveChannelPrograms(channelId, formattedDate);
      
      if (result.isSuccess() && result.data) {
        return ApiResponse.success(result.data, '获取节目单成�?);
      } else {
        return ApiResponse.error(result.code, result.message || '获取节目单失�?);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get programs for channel: ${channelId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取节目单失�?);
    }
  }

  /**
   * 获取直播事件列表
   */
  public async getLiveEvents(
    page: number = 1,
    pageSize: number = 20,
    isUpcoming: boolean = false
  ): Promise<ApiResponse<{ events: LiveEvent[], total: number }>> {
    try {
      // 从网络获取直播事�?      Logger.debug(TAG, `Fetching live events (upcoming: ${isUpcoming})`);
      const result = await this.networkRepo.getLiveEvents(page, pageSize, isUpcoming);
      
      if (result.isSuccess() && result.data) {
        return ApiResponse.success(result.data, '获取直播事件成功');
      } else {
        return ApiResponse.error(result.code, result.message || '获取直播事件失败');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get live events', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取直播事件失败');
    }
  }

  /**
   * 添加/移除收藏频道
   */
  public async toggleFavoriteChannel(channelId: string): Promise<ApiResponse<{ isFavorite: boolean }>> {
    try {
      // 切换收藏状�?      const isFavorite = this.favoriteChannels.has(channelId);
      
      if (isFavorite) {
        this.favoriteChannels.delete(channelId);
      } else {
        this.favoriteChannels.add(channelId);
      }
      
      // 保存到存�?      await this.saveFavoriteChannels();
      
      // 通知监听�?      this.notifyFavoriteChanged(channelId, !isFavorite);
      
      // 更新缓存中的收藏状�?      this.updateFavoriteStatusInCache(channelId, !isFavorite);
      
      Logger.info(TAG, `${!isFavorite ? 'Added' : 'Removed'} channel ${channelId} from favorites`);
      return ApiResponse.success(
        { isFavorite: !isFavorite },
        `频道${!isFavorite ? '已添加到' : '已从'}收藏`
      );
    } catch (error) {
      Logger.error(TAG, `Failed to toggle favorite for channel: ${channelId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新收藏状态失�?);
    }
  }

  /**
   * 获取收藏频道列表
   */
  public async getFavoriteChannels(): Promise<ApiResponse<LiveChannel[]>> {
    try {
      if (this.favoriteChannels.size === 0) {
        return ApiResponse.success([], '收藏频道列表为空');
      }
      
      const favoriteIds = Array.from(this.favoriteChannels);
      const favoriteChannels: LiveChannel[] = [];
      
      // 尝试从缓存中获取频道信息
      for (const cache of this.cachedChannels.values()) {
        const cachedChannels = cache.data.filter(channel => favoriteIds.includes(channel.id));
        favoriteChannels.push(...cachedChannels);
      }
      
      // 对于缓存中没有的频道，从网络获取
      const missingIds = favoriteIds.filter(id => !favoriteChannels.some(c => c.id === id));
      
      if (missingIds.length > 0) {
        // 这里可以批量获取频道信息，为简化代码，我们使用循环单条获取
        for (const id of missingIds) {
          const channelResult = await this.getChannelById(id);
          if (channelResult.isSuccess() && channelResult.data) {
            favoriteChannels.push(channelResult.data);
          }
        }
      }
      
      // 确保所有频道都标记为收�?      favoriteChannels.forEach(channel => {
        channel.isFavorite = true;
      });
      
      return ApiResponse.success(favoriteChannels, '获取收藏频道成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get favorite channels', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取收藏频道失败');
    }
  }

  /**
   * 创建频道�?   */
  public async createChannelGroup(name: string): Promise<ApiResponse<ChannelGroup>> {
    try {
      if (!name || name.trim().length === 0) {
        return ApiResponse.validationError([
          { field: 'name', message: '频道组名称不能为�? }
        ]);
      }
      
      // 创建新的频道�?      const newGroup: ChannelGroup = {
        id: `group_${Date.now()}`,
        name: name.trim(),
        channelIds: [],
        order: this.channelGroups.size + 1,
        isDefault: this.channelGroups.size === 0
      };
      
      // 添加到内�?      this.channelGroups.set(newGroup.id, newGroup);
      
      // 保存到数据库
      await this.databaseRepo.saveLiveChannelGroup(newGroup);
      
      // 通知监听�?      this.notifyChannelGroupsChanged();
      
      Logger.info(TAG, `Created new channel group: ${newGroup.name} (${newGroup.id})`);
      return ApiResponse.success(newGroup, '创建频道组成�?);
    } catch (error) {
      Logger.error(TAG, 'Failed to create channel group', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '创建频道组失�?);
    }
  }

  /**
   * 更新频道�?   */
  public async updateChannelGroup(
    groupId: string,
    updates: Partial<ChannelGroup>
  ): Promise<ApiResponse<ChannelGroup>> {
    try {
      const group = this.channelGroups.get(groupId);
      if (!group) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '频道组不存在');
      }
      
      // 更新频道�?      const updatedGroup: ChannelGroup = {
        ...group,
        ...updates
      };
      
      // 更新内存
      this.channelGroups.set(groupId, updatedGroup);
      
      // 保存到数据库
      await this.databaseRepo.updateLiveChannelGroup(updatedGroup);
      
      // 通知监听�?      this.notifyChannelGroupsChanged();
      
      Logger.info(TAG, `Updated channel group: ${groupId}`);
      return ApiResponse.success(updatedGroup, '更新频道组成�?);
    } catch (error) {
      Logger.error(TAG, `Failed to update channel group: ${groupId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新频道组失�?);
    }
  }

  /**
   * 删除频道�?   */
  public async deleteChannelGroup(groupId: string): Promise<ApiResponse<boolean>> {
    try {
      if (!this.channelGroups.has(groupId)) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '频道组不存在');
      }
      
      // 移除内存中的频道�?      this.channelGroups.delete(groupId);
      
      // 从数据库删除
      await this.databaseRepo.deleteLiveChannelGroup(groupId);
      
      // 调整排序
      let order = 1;
      for (const group of this.getSortedChannelGroups()) {
        group.order = order++;
        await this.databaseRepo.updateLiveChannelGroup(group);
      }
      
      // 通知监听�?      this.notifyChannelGroupsChanged();
      
      Logger.info(TAG, `Deleted channel group: ${groupId}`);
      return ApiResponse.success(true, '删除频道组成�?);
    } catch (error) {
      Logger.error(TAG, `Failed to delete channel group: ${groupId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '删除频道组失�?);
    }
  }

  /**
   * 获取所有频道组
   */
  public getChannelGroups(): ApiResponse<ChannelGroup[]> {
    try {
      const groups = this.getSortedChannelGroups();
      return ApiResponse.success(groups, '获取频道组成�?);
    } catch (error) {
      Logger.error(TAG, 'Failed to get channel groups', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道组失�?);
    }
  }

  /**
   * 获取排序后的频道�?   */
  private getSortedChannelGroups(): ChannelGroup[] {
    return Array.from(this.channelGroups.values())
      .sort((a, b) => a.order - b.order);
  }

  /**
   * 更新频道组中的频�?   */
  public async updateGroupChannels(
    groupId: string,
    channelIds: string[]
  ): Promise<ApiResponse<ChannelGroup>> {
    try {
      const group = this.channelGroups.get(groupId);
      if (!group) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '频道组不存在');
      }
      
      // 更新频道ID列表
      group.channelIds = channelIds;
      
      // 保存到数据库
      await this.databaseRepo.updateLiveChannelGroup(group);
      
      // 通知监听�?      this.notifyChannelGroupsChanged();
      
      Logger.info(TAG, `Updated channels in group: ${groupId}, count: ${channelIds.length}`);
      return ApiResponse.success(group, '更新频道组成员成�?);
    } catch (error) {
      Logger.error(TAG, `Failed to update channels in group: ${groupId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新频道组成员失�?);
    }
  }

  /**
   * 获取频道组中的频道列�?   */
  public async getGroupChannels(groupId: string): Promise<ApiResponse<LiveChannel[]>> {
    try {
      const group = this.channelGroups.get(groupId);
      if (!group) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '频道组不存在');
      }
      
      if (group.channelIds.length === 0) {
        return ApiResponse.success([], '频道组为�?);
      }
      
      const channels: LiveChannel[] = [];
      
      // 获取频道信息
      for (const channelId of group.channelIds) {
        const channelResult = await this.getChannelById(channelId);
        if (channelResult.isSuccess() && channelResult.data) {
          channels.push(channelResult.data);
        }
      }
      
      return ApiResponse.success(channels, '获取频道组成员成�?);
    } catch (error) {
      Logger.error(TAG, `Failed to get channels in group: ${groupId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道组成员失�?);
    }
  }

  /**
   * 获取直播统计信息
   */
  public async getStatistics(): Promise<ApiResponse<LiveStatistics>> {
    try {
      // 先尝试从网络获取统计信息
      const result = await this.networkRepo.getLiveStatistics();
      
      if (result.isSuccess() && result.data) {
        // 合并本地统计数据
        const statistics: LiveStatistics = {
          ...result.data,
          favoriteChannels: this.favoriteChannels.size
        };
        
        return ApiResponse.success(statistics, '获取统计信息成功');
      }
      
      // 如果网络请求失败，生成简单的统计信息
      const categoriesResult = await this.getCategories();
      const allChannelsResult = await this.getAllChannels(1, 1); // 只获取第一页用于统�?      
      const statistics: LiveStatistics = {
        totalChannels: allChannelsResult.isSuccess() ? allChannelsResult.data.total : 0,
        liveChannels: 0, // 没有实时数据，设�?
        offlineChannels: 0,
        totalCategories: categoriesResult.isSuccess() ? categoriesResult.data.length : 0,
        favoriteChannels: this.favoriteChannels.size,
        recentViews: 0
      };
      
      return ApiResponse.success(statistics, '获取统计信息成功（本地计算）');
    } catch (error) {
      Logger.error(TAG, 'Failed to get statistics', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      
      // 返回基本统计信息
      const statistics: LiveStatistics = {
        totalChannels: 0,
        liveChannels: 0,
        offlineChannels: 0,
        totalCategories: 0,
        favoriteChannels: this.favoriteChannels.size,
        recentViews: 0
      };
      
      return ApiResponse.success(statistics, '获取统计信息成功（简化版�?);
    }
  }

  /**
   * 刷新频道状�?   */
  public async refreshChannelStatus(channelIds: string[]): Promise<ApiResponse<Map<string, LiveStatus>>> {
    try {
      // 从网络刷新频道状�?      const result = await this.networkRepo.refreshLiveChannelStatus(channelIds);
      
      if (result.isSuccess() && result.data) {
        // 通知状态变�?        result.data.forEach((status, channelId) => {
          this.notifyChannelStatusChanged(channelId, status);
        });
        
        return ApiResponse.success(result.data, '刷新频道状态成�?);
      } else {
        return ApiResponse.error(result.code, result.message || '刷新频道状态失�?);
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to refresh channel status', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '刷新频道状态失�?);
    }
  }

  /**
   * 清除缓存
   */
  public async clearCache(): Promise<ApiResponse<boolean>> {
    try {
      // 清除内存中的缓存
      this.cachedCategories = null;
      this.cachedChannels.clear();
      
      // 清除存储中的缓存
      await StorageUtil.remove(LIVE_CATEGORY_CACHE_KEY);
      await StorageUtil.remove(LIVE_CHANNEL_CACHE_KEY);
      
      Logger.info(TAG, 'Cleared all live stream cache');
      return ApiResponse.success(true, '清除缓存成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to clear cache', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '清除缓存失败');
    }
  }

  /**
   * 通知收藏状态变�?   */
  private notifyFavoriteChanged(channelId: string, isFavorite: boolean): void {
    for (const listener of this.favoriteListeners) {
      try {
        listener(channelId, isFavorite);
      } catch (error) {
        Logger.error(TAG, 'Error in favorite listener', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      }
    }
  }

  /**
   * 通知频道组变�?   */
  private notifyChannelGroupsChanged(): void {
    const groups = this.getSortedChannelGroups();
    for (const listener of this.channelGroupListeners) {
      try {
        listener(groups);
      } catch (error) {
        Logger.error(TAG, 'Error in channel group listener', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      }
    }
  }

  /**
   * 通知频道状态变�?   */
  private notifyChannelStatusChanged(channelId: string, status: LiveStatus): void {
    if (!this.statusListeners.has(channelId)) return;
    
    const listeners = this.statusListeners.get(channelId)!;
    for (const listener of listeners) {
      try {
        listener(status);
      } catch (error) {
        Logger.error(TAG, `Error in status listener for channel ${channelId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      }
    }
  }

  /**
   * 更新缓存中的收藏状�?   */
  private updateFavoriteStatusInCache(channelId: string, isFavorite: boolean): void {
    for (const [key, cache] of this.cachedChannels.entries()) {
      const channelIndex = cache.data.findIndex(channel => channel.id === channelId);
      if (channelIndex >= 0) {
        cache.data[channelIndex].isFavorite = isFavorite;
      }
    }
  }

  /**
   * 添加收藏状态监听器
   */
  public addFavoriteListener(
    listener: (channelId: string, isFavorite: boolean) => void
  ): () => void {
    this.favoriteListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.favoriteListeners.indexOf(listener);
      if (index > -1) {
        this.favoriteListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加频道组监听器
   */
  public addChannelGroupListener(
    listener: (groups: ChannelGroup[]) => void
  ): () => void {
    this.channelGroupListeners.push(listener);
    
    // 立即回调当前频道�?    listener(this.getSortedChannelGroups());
    
    // 返回取消监听函数
    return () => {
      const index = this.channelGroupListeners.indexOf(listener);
      if (index > -1) {
        this.channelGroupListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加频道状态监听器
   */
  public addChannelStatusListener(
    channelId: string,
    listener: (status: LiveStatus) => void
  ): () => void {
    if (!this.statusListeners.has(channelId)) {
      this.statusListeners.set(channelId, []);
    }
    
    const listeners = this.statusListeners.get(channelId)!;
    listeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    };
  }

  /**
   * 导出频道列表
   */
  public async exportChannelList(format: 'm3u' | 'json' = 'json'): Promise<ApiResponse<string>> {
    try {
      // 获取所有频�?      const allChannelsResult = await this.getAllChannels(1, 1000);
      if (!allChannelsResult.isSuccess() || !allChannelsResult.data) {
        return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道列表失败');
      }
      
      let exportData = '';
      
      if (format === 'm3u') {
        // 导出为M3U格式
        exportData = this.exportToM3U(allChannelsResult.data.channels);
      } else {
        // 导出为JSON格式
        exportData = JSON.stringify(allChannelsResult.data.channels, null, 2);
      }
      
      Logger.info(TAG, `Exported ${allChannelsResult.data.channels.length} channels in ${format} format`);
      return ApiResponse.success(exportData, `导出频道列表成功�?{format}格式）`);
    } catch (error) {
      Logger.error(TAG, `Failed to export channel list in ${format} format`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导出频道列表失败');
    }
  }

  /**
   * 导出为M3U格式
   */
  private exportToM3U(channels: LiveChannel[]): string {
    let m3uContent = '#EXTM3U
';
    
    channels.forEach(channel => {
      if (channel.url) {
        m3uContent += `#EXTINF:-1 tvg-id="${channel.id}" tvg-name="${channel.name}" tvg-logo="${channel.logo || ''}" group-title="${channel.categoryName}",${channel.name}\n`;
        m3uContent += `${channel.url}\n`;
      }
    });
    
    return m3uContent;
  }

  /**
   * 销毁直播服�?   */
  public async destroy(): Promise<void> {
    try {
      Logger.info(TAG, 'Destroying live stream service...');
      
      // 清除监听�?      this.favoriteListeners = [];
      this.channelGroupListeners = [];
      this.statusListeners.clear();
      
      // 清除缓存
      await this.clearCache();
      
      // 重置状�?      this.favoriteChannels.clear();
      this.channelGroups.clear();
      this.cachedCategories = null;
      this.cachedChannels.clear();
      
      Logger.info(TAG, 'Live stream service destroyed successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to destroy live stream service', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
    }
  }
}


