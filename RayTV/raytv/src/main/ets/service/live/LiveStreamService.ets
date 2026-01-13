// LiveStreamService - 直播流服务类 | Live stream service class
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import DateUtil from '../../common/util/DateUtil';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import DatabaseRepository from '../../data/repository/DatabaseRepository';
import NetworkRepository from '../../data/repository/NetworkRepository';
import { ConfigParser } from '../config/ConfigParser';
import { ConfigLoader } from '../config/ConfigLoader';

// 导入类型和DTO | Import types and DTO
import ApiResponse, { ResponseCode } from '../../data/dto/ApiResponse';
import Movie, { VideoSource, VideoType, VideoQuality } from '../../data/model/Movie';
import { LiveCollection } from '../../data/bean/Config';

// 常量定义 | Constant definitions
const TAG = 'LiveStreamService';
const LIVE_FAVORITES_KEY = 'live_favorites';
const LIVE_CATEGORY_CACHE_KEY = 'live_categories';
const LIVE_CHANNEL_CACHE_KEY = 'live_channels';
const CACHE_EXPIRY_TIME = 30 * 60 * 1000; // 30分钟缓存有效期 | 30 minutes cache expiry time

// 直播状态枚举 | Live status enum
export enum LiveStatus {
  OFFLINE = 'offline',    // 离线 | Offline
  LIVE = 'live',         // 直播中 | Live
  UPCOMING = 'upcoming',  // 即将开始 | Upcoming
  ENDING = 'ending',      // 即将结束 | Ending
  ERROR = 'error'         // 错误 | Error
}

// 直播质量枚举 | Live quality enum
export enum LiveQuality {
  AUTO = 'auto',         // 自动 | Auto
  LOW = 'low',          // 低清晰度 | Low quality
  SD = 'sd',           // 标清 | Standard definition
  HD = 'hd',           // 高清 | High definition
  FHD = 'fhd',         // 全高清 | Full high definition
  UHD = 'uhd'          // 超高清 | Ultra high definition
}

// 直播分类接口 | Live category interface
export interface LiveCategory {
  id: string;           // 分类ID | Category ID
  name: string;         // 分类名称 | Category name
  icon?: string;        // 分类图标 | Category icon
  order: number;        // 排序 | Order
  channelCount: number; // 频道数量 | Channel count
}

// 直播频道接口 | Live channel interface
export interface LiveChannel {
  id: string;          // 频道ID | Channel ID
  name: string;        // 频道名称 | Channel name
  logo?: string;       // 频道logo | Channel logo
  description?: string; // 频道描述 | Channel description
  categoryId: string;  // 分类ID | Category ID
  categoryName: string; // 分类名称 | Category name
  status: LiveStatus;  // 直播状态 | Live status
  url?: string;        // 直播流URL | Live stream URL
  qualities?: LiveQuality[]; // 可用清晰度 | Available qualities
  currentProgram?: LiveProgram; // 当前节目 | Current program
  nextProgram?: LiveProgram;   // 下一个节目 | Next program
  tags?: string[];     // 标签 | Tags
  isFavorite: boolean; // 是否收藏 | Whether favorite
  viewCount?: number;  // 观看人数 | View count
  country?: string;    // 国家/地区 | Country/region
  language?: string;   // 语言 | Language
  isLocked?: boolean;  // 是否锁定 | Whether locked
}

// 直播节目接口 | Live program interface
export interface LiveProgram {
  id: string;          // 节目ID | Program ID
  title: string;       // 节目标题 | Program title
  startTime: number;   // 开始时间（时间戳）| Start time (timestamp)
  endTime: number;     // 结束时间（时间戳）| End time (timestamp)
  description?: string; // 节目描述 | Program description
  cover?: string;      // 节目封面 | Program cover
  genre?: string[];    // 节目类型 | Program genre
  actors?: string[];   // 演员 | Actors
  director?: string;   // 导演 | Director
}

// 直播事件接口 | Live event interface
export interface LiveEvent {
  id: string;          // 事件ID | Event ID
  title: string;       // 事件标题 | Event title
  description: string; // 事件描述 | Event description
  startTime: number;   // 开始时间 | Start time
  endTime: number;     // 结束时间 | End time
  coverImage?: string; // 封面图 | Cover image
  channelId: string;   // 所属频道ID | Channel ID
  channelName: string; // 所属频道名称 | Channel name
  status: LiveStatus;  // 直播状态 | Live status
  isHighlight?: boolean; // 是否高亮 | Whether highlight
}

// 直播源信息接口 | Live source interface
export interface LiveSource {
  id: string;          // 源ID | Source ID
  url: string;         // 源URL | Source URL
  quality: LiveQuality; // 清晰度 | Quality
  isDefault: boolean;  // 是否默认 | Whether default
  bitrate?: number;    // 比特率 | Bitrate
  codec?: string;      // 编码格式 | Codec
  protocol?: string;   // 协议类型 | Protocol
  resolution?: string; // 分辨率 | Resolution
}

// 直播筛选条件接口 | Live filter interface
export interface LiveFilter {
  categories?: string[]; // 分类ID列表 | Category ID list
  search?: string;       // 搜索关键词 | Search keyword
  status?: LiveStatus[]; // 直播状态 | Live status
  countries?: string[];  // 国家/地区 | Country/region
  languages?: string[];  // 语言 | Language
  favoritesOnly?: boolean; // 仅显示收藏 | Only favorites
}

// 直播排序类型枚举 | Live sort type enum
export enum LiveSortType {
  DEFAULT = 'default',     // 默认排序 | Default sort
  NAME_ASC = 'name_asc',    // 名称升序 | Name ascending
  NAME_DESC = 'name_desc',  // 名称降序 | Name descending
  VIEW_COUNT = 'view_count', // 观看人数 | View count
  STATUS = 'status'        // 状态 | Status
}

// 频道组接口 | Channel group interface
export interface ChannelGroup {
  id: string;          // 组ID | Group ID
  name: string;        // 组名称 | Group name
  channelIds: string[]; // 频道ID列表 | Channel ID list
  order: number;       // 排序 | Order
  isDefault?: boolean;  // 是否默认组 | Whether default group
}

// 直播统计信息接口 | Live statistics interface
export interface LiveStatistics {
  totalChannels: number;  // 总频道数 | Total channels
  liveChannels: number;   // 直播中频道数 | Live channels
  offlineChannels: number; // 离线频道数 | Offline channels
  totalCategories: number; // 总分类数 | Total categories
  favoriteChannels: number; // 收藏频道数 | Favorite channels
  recentViews: number;    // 最近观看数 | Recent views
}

/**
 * 直播流服务类 | Live stream service class
 * 提供管理直播相关功能 | Provides live stream management functionality
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
  
  // 缓存数据 | Cache data
  private cachedCategories: {
    data: LiveCategory[];
    timestamp: number;
  } | null = null;
  
  private cachedChannels: Map<string, {
    data: LiveChannel[];
    timestamp: number;
  }> = new Map();
  
  // 监听器 | Listeners
  private favoriteListeners: Array<(channelId: string, isFavorite: boolean) => void> = [];
  private channelGroupListeners: Array<(groups: ChannelGroup[]) => void> = [];
  private statusListeners: Map<string, Array<(status: LiveStatus) => void>> = new Map();

  /**
   * 构造函数（私有，防止外部实例化） | Constructor (private, prevent external instantiation)
   */
  private constructor() {
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
    this.networkRepo = RepositoryFactory.getRepository('network') as NetworkRepository;
    this.configParser = ConfigParser.getInstance();
    this.configLoader = ConfigLoader.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): LiveStreamService {
    if (!LiveStreamService.instance) {
      LiveStreamService.instance = new LiveStreamService();
    }
    return LiveStreamService.instance;
  }

  /**
   * 初始化直播流服务 | Initialize live stream service
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing live stream service...');
      
      // 加载收藏频道 | Load favorite channels
      await this.loadFavoriteChannels();
      
      // 加载频道组 | Load channel groups
      await this.loadChannelGroups();
      
      // 加载缓存数据 | Load cached data
      await this.loadCachedData();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Live stream service initialized successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize live stream service', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  /**
   * 从配置文件加载直播频道列表 | Load live channels from config file
   * @param configUrl 配置文件URL | Config file URL
   */
  public async loadLiveChannelsFromConfig(configUrl: string): Promise<ApiResponse<LiveCategory[]>> {
    try {
      Logger.info(TAG, `Loading live channels from config: ${configUrl}`);
      
      // 加载配置文件内容 | Load config file content
      const configContent = await this.configLoader.loadFromUrl(configUrl);
      
      // 解析lives配置 | Parse lives config
      const liveCollection = this.configParser.parseLives(configContent);
      
      // 转换为直播分类和频道数据 | Convert to live categories and channels data
      const categories: LiveCategory[] = [];
      const channelMap: Map<string, LiveChannel[]> = new Map();
      
      let categoryId = 1;
      let channelId = 1;
      
      for (const liveItem of liveCollection.lives) {
        if ('group' in liveItem) {
          // 分组格式 | Group format
          const category: LiveCategory = {
            id: `category_${categoryId++}`,
            name: liveItem.group,
            icon: undefined,
            order: categoryId,
            channelCount: liveItem.channels.length
          };
          categories.push(category);
          
          // 转换频道数据 | Convert channel data
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
          // 直接直播源格式 | Direct live source format
          const category: LiveCategory = {
            id: `category_${categoryId++}`,
            name: liveItem.name,
            icon: liveItem.logo,
            order: categoryId,
            channelCount: 1
          };
          categories.push(category);
          
          // 创建频道数据 | Create channel data
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
      
      // 更新缓存 | Update cache
      this.cachedCategories = {
        data: categories,
        timestamp: Date.now()
      };
      
      // 存储频道到缓存 | Store channels to cache
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
   * 加载收藏频道 | Load favorite channels
   */
  private async loadFavoriteChannels(): Promise<void> {
    try {
      // 从存储中加载收藏列表 | Load favorite list from storage
      const favoritesJson = await StorageUtil.getString(LIVE_FAVORITES_KEY);
      if (favoritesJson) {
        const favorites = JSON.parse(favoritesJson) as string[];
        favorites.forEach(channelId => this.favoriteChannels.add(channelId));
      }
      
      Logger.info(TAG, `Loaded ${this.favoriteChannels.size} favorite channels`);
    } catch (error) {
      Logger.error(TAG, 'Failed to load favorite channels', error instanceof Error ? error : new Error(String(error)));
      this.favoriteChannels = new Set();
    }
  }

  /**
   * 保存收藏频道 | Save favorite channels
   */
  private async saveFavoriteChannels(): Promise<void> {
    try {
      const favoritesJson = JSON.stringify(Array.from(this.favoriteChannels));
      await StorageUtil.setString(LIVE_FAVORITES_KEY, favoritesJson);
      Logger.debug(TAG, 'Saved favorite channels');
    } catch (error) {
      Logger.error(TAG, 'Failed to save favorite channels', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 加载频道组 | Load channel groups
   */
  private async loadChannelGroups(): Promise<void> {
    try {
      // 从数据库加载频道组 | Load channel groups from database
      const result = await this.databaseRepo.getLiveChannelGroups();
      if (result.isSuccess() && result.data) {
        result.data.forEach(group => {
          this.channelGroups.set(group.id, group);
        });
      }
      
      Logger.info(TAG, `Loaded ${this.channelGroups.size} channel groups`);
    } catch (error) {
      Logger.error(TAG, 'Failed to load channel groups', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 加载缓存数据 | Load cached data
   */
  private async loadCachedData(): Promise<void> {
    try {
      // 加载分类缓存 | Load category cache
      const categoryCacheJson = await StorageUtil.getString(LIVE_CATEGORY_CACHE_KEY);
      if (categoryCacheJson) {
        const cacheData = JSON.parse(categoryCacheJson);
        this.cachedCategories = cacheData;
      }
      
      // 加载频道缓存 | Load channel cache
      const channelCacheJson = await StorageUtil.getString(LIVE_CHANNEL_CACHE_KEY);
      if (channelCacheJson) {
        const cacheData = JSON.parse(channelCacheJson);
        Object.entries(cacheData).forEach(([key, value]) => {
          this.cachedChannels.set(key, value);
        });
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to load cached data', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 保存缓存数据 | Save cached data
   */
  private async saveCachedData(): Promise<void> {
    try {
      // 保存分类缓存 | Save category cache
      if (this.cachedCategories) {
        await StorageUtil.setString(
          LIVE_CATEGORY_CACHE_KEY,
          JSON.stringify(this.cachedCategories)
        );
      }
      
      // 保存频道缓存 | Save channel cache
      const channelsCache = Object.fromEntries(this.cachedChannels.entries());
      await StorageUtil.setString(
        LIVE_CHANNEL_CACHE_KEY,
        JSON.stringify(channelsCache)
      );
    } catch (error) {
      Logger.error(TAG, 'Failed to save cached data', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 检查缓存是否有效 | Check if cache is valid
   */
  private isCacheValid(timestamp: number): boolean {
    return Date.now() - timestamp < CACHE_EXPIRY_TIME;
  }

  /**
   * 获取所有直播分类 | Get all live categories
   */
  public async getCategories(): Promise<ApiResponse<LiveCategory[]>> {
    try {
      // 检查缓存 | Check cache
      if (this.cachedCategories && this.isCacheValid(this.cachedCategories.timestamp)) {
        Logger.debug(TAG, 'Returning categories from cache');
        return ApiResponse.success(this.cachedCategories.data, '获取分类成功（缓存）');
      }
      
      // 从网络获取分类 | Get categories from network
      Logger.debug(TAG, 'Fetching categories from network');
      const result = await this.networkRepo.getLiveCategories();
      
      if (result.isSuccess() && result.data) {
        // 更新缓存 | Update cache
        this.cachedCategories = {
          data: result.data,
          timestamp: Date.now()
        };
        
        // 保存缓存到本地 | Save cache to local
        await this.saveCachedData();
        
        return ApiResponse.success(result.data, '获取分类成功');
      } else {
        // 如果网络请求失败，尝试使用缓存数据 | If network request fails, try to use cached data
        if (this.cachedCategories) {
          Logger.warn(TAG, 'Network failed, using cached categories');
          return ApiResponse.success(this.cachedCategories.data, '获取分类成功（缓存）');
        }
        
        return ApiResponse.error(result.code, result.message || '获取分类失败');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get categories', error instanceof Error ? error : new Error(String(error)));
      
      // 如果发生错误，尝试使用缓存数据 | If error occurs, try to use cached data
      if (this.cachedCategories) {
        Logger.warn(TAG, 'Error occurred, using cached categories');
        return ApiResponse.success(this.cachedCategories.data, '获取分类成功（缓存）');
      }
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取分类失败');
    }
  }

  /**
   * 根据分类获取频道列表 | Get channel list by category
   */
  public async getChannelsByCategory(categoryId: string): Promise<ApiResponse<LiveChannel[]>> {
    try {
      // 检查缓存 | Check cache
      const cacheKey = `category_${categoryId}`;
      const cached = this.cachedChannels.get(cacheKey);
      if (cached && this.isCacheValid(cached.timestamp)) {
        Logger.debug(TAG, `Returning channels for category ${categoryId} from cache`);
        const channelsWithFavoriteStatus = cached.data.map(channel => ({
          ...channel,
          isFavorite: this.favoriteChannels.has(channel.id)
        }));
        return ApiResponse.success(channelsWithFavoriteStatus, '获取频道成功（缓存）');
      }
      
      // 从网络获取频道 | Get channels from network
      Logger.debug(TAG, `Fetching channels for category ${categoryId} from network`);
      const result = await this.networkRepo.getLiveChannelsByCategory(categoryId);
      
      if (result.isSuccess() && result.data) {
        // 更新收藏状态 | Update favorite status
        const channelsWithFavoriteStatus = result.data.map(channel => ({
          ...channel,
          isFavorite: this.favoriteChannels.has(channel.id)
        }));
        
        // 更新缓存 | Update cache
        this.cachedChannels.set(cacheKey, {
          data: channelsWithFavoriteStatus,
          timestamp: Date.now()
        });
        
        // 保存缓存到本地 | Save cache to local
        await this.saveCachedData();
        
        return ApiResponse.success(channelsWithFavoriteStatus, '获取频道成功');
      } else {
        // 如果网络请求失败，尝试使用缓存数据 | If network request fails, try to use cached data
        if (cached) {
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
      Logger.error(TAG, `Failed to get channels for category ${categoryId}`, error instanceof Error ? error : new Error(String(error)));
      
      // 如果发生错误，尝试使用缓存数据 | If error occurs, try to use cached data
      const cacheKey = `category_${categoryId}`;
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
   * 获取所有直播频道（分页）| Get all live channels (paged)
   */
  public async getAllChannels(
    page: number = 1,
    pageSize: number = 50
  ): Promise<ApiResponse<{ channels: LiveChannel[], total: number }>> {
    try {
      const result = await this.networkRepo.getLiveChannels(page, pageSize);
      
      if (result.isSuccess() && result.data) {
        // 更新收藏状态 | Update favorite status
        const channelsWithFavoriteStatus = result.data.channels.map(channel => ({
          ...channel,
          isFavorite: this.favoriteChannels.has(channel.id)
        }));
        
        return ApiResponse.success(
          { 
            channels: channelsWithFavoriteStatus,
            total: result.data.total
          }, 
          '获取所有频道成功'
        );
      } else {
        return ApiResponse.error(result.code, result.message || '获取频道失败');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get all channels', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道失败');
    }
  }

  /**
   * 根据ID获取直播频道详情 | Get live channel details by ID
   */
  public async getChannelById(channelId: string): Promise<ApiResponse<LiveChannel>> {
    try {
      // 先尝试从缓存中查找 | First try to find in cache
      let channel: LiveChannel | undefined;
      for (const cache of this.cachedChannels.values()) {
        const found = cache.data.find(c => c.id === channelId);
        if (found) {
          channel = found;
          break;
        }
      }
      
      if (channel && this.isCacheValid(cache.timestamp)) {
        // 更新收藏状态 | Update favorite status
        channel.isFavorite = this.favoriteChannels.has(channel.id);
        Logger.debug(TAG, `Returning channel ${channelId} from cache`);
        return ApiResponse.success(channel, '获取频道详情成功（缓存）');
      }
      
      // 从网络获取频道信息 | Get channel info from network
      Logger.debug(TAG, `Fetching channel ${channelId} from network`);
      const result = await this.networkRepo.getLiveChannelById(channelId);
      
      if (result.isSuccess() && result.data) {
        // 更新收藏状态 | Update favorite status
        const channelWithFavoriteStatus = {
          ...result.data,
          isFavorite: this.favoriteChannels.has(result.data.id)
        };
        
        return ApiResponse.success(channelWithFavoriteStatus, '获取频道详情成功');
      } else {
        // 如果网络请求失败，但缓存中有数据 | If network request fails but has cached data
        if (channel) {
          Logger.warn(TAG, `Network failed, using cached channel ${channelId}`);
          channel.isFavorite = this.favoriteChannels.has(channel.id);
          return ApiResponse.success(channel, '获取频道详情成功（缓存）');
        }
        
        return ApiResponse.error(result.code, result.message || '获取频道详情失败');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get channel by id: ${channelId}`, error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道详情失败');
    }
  }

  /**
   * 搜索直播频道 | Search live channels
   */
  public async searchChannels(
    keyword: string,
    filter?: LiveFilter,
    sortBy: LiveSortType = LiveSortType.DEFAULT
  ): Promise<ApiResponse<LiveChannel[]>> {
    try {
      if (!keyword || keyword.trim().length === 0) {
        return ApiResponse.validationError([
        { field: 'keyword', message: '搜索关键词不能为空' }
      ]);
      }
      
      // 构建搜索参数 | Build search parameters
      const searchParams = {
        keyword: keyword.trim(),
        filter: filter,
        sortBy: sortBy
      };
      
      // 从网络搜索频道 | Search channels from network
      Logger.debug(TAG, `Searching channels with keyword: ${keyword}`);
      const result = await this.networkRepo.searchLiveChannels(searchParams);
      
      if (result.isSuccess() && result.data) {
        // 更新收藏状态 | Update favorite status
        const channelsWithFavoriteStatus = result.data.map(channel => ({
          ...channel,
          isFavorite: this.favoriteChannels.has(channel.id)
        }));
        
        return ApiResponse.success(channelsWithFavoriteStatus, '搜索频道成功');
      } else {
        return ApiResponse.error(result.code, result.message || '搜索频道失败');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to search channels with keyword: ${keyword}`, error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '搜索频道失败');
    }
  }

  /**
   * 获取直播频道的播放源 | Get live channel playback sources
   */
  public async getChannelSources(channelId: string): Promise<ApiResponse<LiveSource[]>> {
    try {
      // 从网络获取播放源 | Get playback sources from network
      Logger.debug(TAG, `Fetching sources for channel: ${channelId}`);
      const result = await this.networkRepo.getLiveChannelSources(channelId);
      
      if (result.isSuccess() && result.data) {
        return ApiResponse.success(result.data, '获取播放源成功');
      } else {
        return ApiResponse.error(result.code, result.message || '获取播放源失败');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get sources for channel: ${channelId}`, error instanceof Error ? error : new Error(String(error)));
      
      // 尝试从频道信息中提取播放源 | Try to extract playback source from channel info
      const channelResult = await this.getChannelById(channelId);
      if (channelResult.isSuccess() && channelResult.data && channelResult.data.url) {
        const sources: LiveSource[] = [{
          id: `${channelId}_default`,
          url: channelResult.data.url,
          quality: LiveQuality.AUTO,
          isDefault: true
        }];
        
        return ApiResponse.success(sources, '获取播放源成功（从频道信息）');
      }
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取播放源失败');
    }
  }

  /**
   * 获取频道节目单 | Get channel programs
   */
  public async getChannelPrograms(
    channelId: string,
    date: Date = new Date()
  ): Promise<ApiResponse<LiveProgram[]>> {
    try {
      // 格式化日期为YYYY-MM-DD | Format date to YYYY-MM-DD
      const formattedDate = DateUtil.formatDate(date, 'YYYY-MM-DD');
      
      // 从网络获取节目单 | Get program list from network
      Logger.debug(TAG, `Fetching programs for channel: ${channelId} on date: ${formattedDate}`);
      const result = await this.networkRepo.getLiveChannelPrograms(channelId, formattedDate);
      
      if (result.isSuccess() && result.data) {
        return ApiResponse.success(result.data, '获取节目单成功');
      } else {
        return ApiResponse.error(result.code, result.message || '获取节目单失败');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get programs for channel: ${channelId}`, error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取节目单失败');
    }
  }

  /**
   * 获取直播事件列表 | Get live event list
   */
  public async getLiveEvents(
    page: number = 1,
    pageSize: number = 20,
    isUpcoming: boolean = false
  ): Promise<ApiResponse<{ events: LiveEvent[], total: number }>> {
    try {
      // 从网络获取直播事件 | Get live events from network
      Logger.debug(TAG, `Fetching live events (upcoming: ${isUpcoming})`);
      const result = await this.networkRepo.getLiveEvents(page, pageSize, isUpcoming);
      
      if (result.isSuccess() && result.data) {
        return ApiResponse.success(result.data, '获取直播事件成功');
      } else {
        return ApiResponse.error(result.code, result.message || '获取直播事件失败');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get live events', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取直播事件失败');
    }
  }

  /**
   * 添加/移除收藏频道 | Add/remove favorite channel
   */
  public async toggleFavoriteChannel(channelId: string): Promise<ApiResponse<{ isFavorite: boolean }>> {
    try {
      // 切换收藏状态 | Toggle favorite status
      const isFavorite = this.favoriteChannels.has(channelId);
      
      if (isFavorite) {
        this.favoriteChannels.delete(channelId);
      } else {
        this.favoriteChannels.add(channelId);
      }
      
      // 保存到存储 | Save to storage
      await this.saveFavoriteChannels();
      
      // 通知监听器 | Notify listeners
      this.notifyFavoriteChanged(channelId, !isFavorite);
      
      // 更新缓存中的收藏状态 | Update favorite status in cache
      this.updateFavoriteStatusInCache(channelId, !isFavorite);
      
      Logger.info(TAG, `${!isFavorite ? 'Added' : 'Removed'} channel ${channelId} from favorites`);
      return ApiResponse.success(
        { isFavorite: !isFavorite },
        `频道${!isFavorite ? '已添加到' : '已从'}收藏`
      );
    } catch (error) {
      Logger.error(TAG, `Failed to toggle favorite for channel: ${channelId}`, error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新收藏状态失败');
    }
  }

  /**
   * 获取收藏频道列表 | Get favorite channel list
   */
  public async getFavoriteChannels(): Promise<ApiResponse<LiveChannel[]>> {
    try {
      if (this.favoriteChannels.size === 0) {
        return ApiResponse.success([], '收藏频道列表为空');
      }
      
      const favoriteIds = Array.from(this.favoriteChannels);
      const favoriteChannels: LiveChannel[] = [];
      
      // 尝试从缓存中获取频道信息 | Try to get channel info from cache
      for (const cache of this.cachedChannels.values()) {
        const cachedChannels = cache.data.filter(channel => favoriteIds.includes(channel.id));
        favoriteChannels.push(...cachedChannels);
      }
      
      // 对于缓存中没有的频道，从网络获取 | For channels not in cache, get from network
      const missingIds = favoriteIds.filter(id => !favoriteChannels.some(c => c.id === id));
      
      if (missingIds.length > 0) {
        // 这里可以批量获取频道信息，为简化代码，我们使用循环单条获取 | Can batch get channel info, use loop for simplicity
        for (const id of missingIds) {
          const channelResult = await this.getChannelById(id);
          if (channelResult.isSuccess() && channelResult.data) {
            favoriteChannels.push(channelResult.data);
          }
        }
      }
      
      // 确保所有频道都标记为收藏 | Ensure all channels are marked as favorite
      favoriteChannels.forEach(channel => {
        channel.isFavorite = true;
      });
      
      return ApiResponse.success(favoriteChannels, '获取收藏频道成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get favorite channels', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取收藏频道失败');
    }
  }

  /**
   * 创建频道组 | Create channel group
   */
  public async createChannelGroup(name: string): Promise<ApiResponse<ChannelGroup>> {
    try {
      if (!name || name.trim().length === 0) {
        return ApiResponse.validationError([
          { field: 'name', message: '频道组名称不能为空' }
        ]);
      }
      
      // 创建新的频道组 | Create new channel group
      const newGroup: ChannelGroup = {
        id: `group_${Date.now()}`,
        name: name.trim(),
        channelIds: [],
        order: this.channelGroups.size + 1,
        isDefault: this.channelGroups.size === 0
      };
      
      // 添加到内存 | Add to memory
      this.channelGroups.set(newGroup.id, newGroup);
      
      // 保存到数据库 | Save to database
      await this.databaseRepo.saveLiveChannelGroup(newGroup);
      
      // 通知监听器 | Notify listeners
      this.notifyChannelGroupsChanged();
      
      Logger.info(TAG, `Created new channel group: ${newGroup.name} (${newGroup.id})`);
      return ApiResponse.success(newGroup, '创建频道组成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to create channel group', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '创建频道组失败');
    }
  }

  /**
   * 更新频道组 | Update channel group
   */
  public async updateChannelGroup(
    groupId: string,
    updates: Partial<ChannelGroup>
  ): Promise<ApiResponse<ChannelGroup>> {
    try {
      const group = this.channelGroups.get(groupId);
      if (!group) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '频道组不存在');
      }
      
      // 更新频道组 | Update channel group
      const updatedGroup: ChannelGroup = {
        ...group,
        ...updates
      };
      
      // 更新内存 | Update memory
      this.channelGroups.set(groupId, updatedGroup);
      
      // 保存到数据库 | Save to database
      await this.databaseRepo.updateLiveChannelGroup(updatedGroup);
      
      // 通知监听器 | Notify listeners
      this.notifyChannelGroupsChanged();
      
      Logger.info(TAG, `Updated channel group: ${groupId}`);
      return ApiResponse.success(updatedGroup, '更新频道组成功');
    } catch (error) {
      Logger.error(TAG, `Failed to update channel group: ${groupId}`, error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新频道组失败');
    }
  }

  /**
   * 删除频道组 | Delete channel group
   */
  public async deleteChannelGroup(groupId: string): Promise<ApiResponse<boolean>> {
    try {
      if (!this.channelGroups.has(groupId)) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '频道组不存在');
      }
      
      // 从内存中删除频道组 | Delete channel group from memory
      this.channelGroups.delete(groupId);
      
      // 从数据库删除 | Delete from database
      await this.databaseRepo.deleteLiveChannelGroup(groupId);
      
      // 调整排序 | Adjust order
      let order = 1;
      for (const group of this.getSortedChannelGroups()) {
        group.order = order++;
        await this.databaseRepo.updateLiveChannelGroup(group);
      }
      
      // 通知监听器 | Notify listeners
      this.notifyChannelGroupsChanged();
      
      Logger.info(TAG, `Deleted channel group: ${groupId}`);
      return ApiResponse.success(true, '删除频道组成功');
    } catch (error) {
      Logger.error(TAG, `Failed to delete channel group: ${groupId}`, error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '删除频道组失败');
    }
  }

  /**
   * 获取所有频道组 | Get all channel groups
   */
  public getChannelGroups(): ApiResponse<ChannelGroup[]> {
    try {
      const groups = this.getSortedChannelGroups();
      return ApiResponse.success(groups, '获取频道组成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get channel groups', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道组失败');
    }
  }

  /**
   * 获取排序后的频道组 | Get sorted channel groups
   */
  private getSortedChannelGroups(): ChannelGroup[] {
    return Array.from(this.channelGroups.values())
      .sort((a, b) => a.order - b.order);
  }

  /**
   * 更新频道组中的频道 | Update channels in channel group
   */
  public async updateGroupChannels(
    groupId: string,
    channelIds: string[]
  ): Promise<ApiResponse<ChannelGroup>> {
    try {
      const group = this.channelGroups.get(groupId);
      if (!group) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '频道组不存在');
      }
      
      // 更新频道ID列表 | Update channel ID list
      group.channelIds = channelIds;
      
      // 保存到数据库 | Save to database
      await this.databaseRepo.updateLiveChannelGroup(group);
      
      // 通知监听器 | Notify listeners
      this.notifyChannelGroupsChanged();
      
      Logger.info(TAG, `Updated channels in group: ${groupId}, count: ${channelIds.length}`);
      return ApiResponse.success(group, '更新频道组成员成功');
    } catch (error) {
      Logger.error(TAG, `Failed to update channels in group: ${groupId}`, error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新频道组成员失败');
    }
  }

  /**
   * 获取频道组中的频道列表 | Get channel list in channel group
   */
  public async getGroupChannels(groupId: string): Promise<ApiResponse<LiveChannel[]>> {
    try {
      const group = this.channelGroups.get(groupId);
      if (!group) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '频道组不存在');
      }
      
      if (group.channelIds.length === 0) {
        return ApiResponse.success([], '频道组为空');
      }
      
      const channels: LiveChannel[] = [];
      
      // 获取频道信息 | Get channel info
      for (const channelId of group.channelIds) {
        const channelResult = await this.getChannelById(channelId);
        if (channelResult.isSuccess() && channelResult.data) {
          channels.push(channelResult.data);
        }
      }
      
      return ApiResponse.success(channels, '获取频道组成员成功');
    } catch (error) {
      Logger.error(TAG, `Failed to get channels in group: ${groupId}`, error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道组成员失败');
    }
  }

  /**
   * 获取直播统计信息 | Get live statistics
   */
  public async getStatistics(): Promise<ApiResponse<LiveStatistics>> {
    try {
      // 先尝试从网络获取统计信息 | First try to get statistics from network
      const result = await this.networkRepo.getLiveStatistics();
      
      if (result.isSuccess() && result.data) {
        // 合并本地统计数据 | Merge local statistics
        const statistics: LiveStatistics = {
          ...result.data,
          favoriteChannels: this.favoriteChannels.size
        };
        
        return ApiResponse.success(statistics, '获取统计信息成功');
      }
      
      // 如果网络请求失败，生成简单的统计信息 | If network request fails, generate simple statistics
      const categoriesResult = await this.getCategories();
      const allChannelsResult = await this.getAllChannels(1, 1); // 只获取第一页用于统计 | Only get first page for statistics
      
      const statistics: LiveStatistics = {
        totalChannels: allChannelsResult.isSuccess() ? allChannelsResult.data.total : 0,
        liveChannels: 0, // 没有实时数据，设为0 | No real-time data, set to 0
        offlineChannels: 0,
        totalCategories: categoriesResult.isSuccess() ? categoriesResult.data.length : 0,
        favoriteChannels: this.favoriteChannels.size,
        recentViews: 0
      };
      
      return ApiResponse.success(statistics, '获取统计信息成功（本地计算）');
    } catch (error) {
      Logger.error(TAG, 'Failed to get statistics', error instanceof Error ? error : new Error(String(error)));
      
      // 返回基本统计信息 | Return basic statistics
      const statistics: LiveStatistics = {
        totalChannels: 0,
        liveChannels: 0,
        offlineChannels: 0,
        totalCategories: 0,
        favoriteChannels: this.favoriteChannels.size,
        recentViews: 0
      };
      
      return ApiResponse.success(statistics, '获取统计信息成功（简化版）');
    }
  }

  /**
   * 刷新频道状态 | Refresh channel status
   */
  public async refreshChannelStatus(channelIds: string[]): Promise<ApiResponse<Map<string, LiveStatus>>> {
    try {
      // 从网络更新频道状态 | Update channel status from network
      const result = await this.networkRepo.refreshLiveChannelStatus(channelIds);
      
      if (result.isSuccess() && result.data) {
        // 通知状态变化 | Notify status changes
        result.data.forEach((status, channelId) => {
          this.notifyChannelStatusChanged(channelId, status);
        });
        
        return ApiResponse.success(result.data, '刷新频道状态成功');
      } else {
        return ApiResponse.error(result.code, result.message || '刷新频道状态失败');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to refresh channel status', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '刷新频道状态失败');
    }
  }

  /**
   * 清除缓存 | Clear cache
   */
  public async clearCache(): Promise<ApiResponse<boolean>> {
    try {
      // 清除内存中的缓存 | Clear cache in memory
      this.cachedCategories = null;
      this.cachedChannels.clear();
      
      // 清除存储中的缓存 | Clear cache in storage
      await StorageUtil.remove(LIVE_CATEGORY_CACHE_KEY);
      await StorageUtil.remove(LIVE_CHANNEL_CACHE_KEY);
      
      Logger.info(TAG, 'Cleared all live stream cache');
      return ApiResponse.success(true, '清除缓存成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to clear cache', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '清除缓存失败');
    }
  }

  /**
   * 通知收藏状态变化 | Notify favorite status change
   */
  private notifyFavoriteChanged(channelId: string, isFavorite: boolean): void {
    for (const listener of this.favoriteListeners) {
      try {
        listener(channelId, isFavorite);
      } catch (error) {
        Logger.error(TAG, 'Error in favorite listener', error instanceof Error ? error : new Error(String(error)));
      }
    }
  }

  /**
   * 通知频道组变化 | Notify channel group change
   */
  private notifyChannelGroupsChanged(): void {
    const groups = this.getSortedChannelGroups();
    for (const listener of this.channelGroupListeners) {
      try {
        listener(groups);
      } catch (error) {
        Logger.error(TAG, 'Error in channel group listener', error instanceof Error ? error : new Error(String(error)));
      }
    }
  }

  /**
   * 通知频道状态变化 | Notify channel status change
   */
  private notifyChannelStatusChanged(channelId: string, status: LiveStatus): void {
    if (!this.statusListeners.has(channelId)) return;
    
    const listeners = this.statusListeners.get(channelId)!;
    for (const listener of listeners) {
      try {
        listener(status);
      } catch (error) {
        Logger.error(TAG, `Error in status listener for channel ${channelId}`, error instanceof Error ? error : new Error(String(error)));
      }
    }
  }

  /**
   * 更新缓存中的收藏状态 | Update favorite status in cache
   */
  private updateFavoriteStatusInCache(channelId: string, isFavorite: boolean): void {
    for (const [key, cache] of this.cachedChannels.entries()) {
      const channelIndex = cache.data.findIndex(channel => channel.id === channelId);
      if (channelIndex >= 0) {
        cache.data[channelIndex].isFavorite = isFavorite;
      }
    }
  }

  /**
   * 添加收藏状态监听器 | Add favorite status listener
   */
  public addFavoriteListener(
    listener: (channelId: string, isFavorite: boolean) => void
  ): () => void {
    this.favoriteListeners.push(listener);
    
    // 返回取消监听函数 | Return unsubscribe function
    return () => {
      const index = this.favoriteListeners.indexOf(listener);
      if (index > -1) {
        this.favoriteListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加频道组监听器 | Add channel group listener
   */
  public addChannelGroupListener(
    listener: (groups: ChannelGroup[]) => void
  ): () => void {
    this.channelGroupListeners.push(listener);
    
    // 立即回调当前频道组 | Immediately callback current channel groups
    listener(this.getSortedChannelGroups());
    
    // 返回取消监听函数 | Return unsubscribe function
    return () => {
      const index = this.channelGroupListeners.indexOf(listener);
      if (index > -1) {
        this.channelGroupListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加频道状态监听器 | Add channel status listener
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
    
    // 返回取消监听函数 | Return unsubscribe function
    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    };
  }

  /**
   * 导出频道列表 | Export channel list
   */
  public async exportChannelList(format: 'm3u' | 'json' = 'json'): Promise<ApiResponse<string>> {
    try {
      // 获取所有频道 | Get all channels
      const allChannelsResult = await this.getAllChannels(1, 1000);
      if (!allChannelsResult.isSuccess() || !allChannelsResult.data) {
        return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取频道列表失败');
      }
      
      let exportData = '';
      
      if (format === 'm3u') {
        // 导出为M3U格式 | Export as M3U format
        exportData = this.exportToM3U(allChannelsResult.data.channels);
      } else {
        // 导出为JSON格式 | Export as JSON format
        exportData = JSON.stringify(allChannelsResult.data.channels, null, 2);
      }
      
      Logger.info(TAG, `Exported ${allChannelsResult.data.channels.length} channels in ${format} format`);
      return ApiResponse.success(exportData, `导出频道列表成功（${format}格式）`);
    } catch (error) {
      Logger.error(TAG, `Failed to export channel list in ${format} format`, error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导出频道列表失败');
    }
  }

  /**
   * 导出为M3U格式 | Export to M3U format
   */
  private exportToM3U(channels: LiveChannel[]): string {
    let m3uContent = '#EXTM3U\n';
    
    channels.forEach(channel => {
      if (channel.url) {
        m3uContent += `#EXTINF:-1 tvg-id="${channel.id}" tvg-name="${channel.name}" tvg-logo="${channel.logo || ''}" group-title="${channel.categoryName}",${channel.name}\n`;
        m3uContent += `${channel.url}\n`;
      }
    });
    
    return m3uContent;
  }

  /**
   * 销毁直播流服务 | Destroy live stream service
   */
  public async destroy(): Promise<void> {
    try {
      Logger.info(TAG, 'Destroying live stream service...');
      
      // 清除监听器 | Clear listeners
      this.favoriteListeners = [];
      this.channelGroupListeners = [];
      this.statusListeners.clear();
      
      // 清除缓存 | Clear cache
      await this.clearCache();
      
      // 重置状态 | Reset status
      this.favoriteChannels.clear();
      this.channelGroups.clear();
      this.cachedCategories = null;
      this.cachedChannels.clear();
      
      Logger.info(TAG, 'Live stream service destroyed successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to destroy live stream service', error instanceof Error ? error : new Error(String(error)));
    }
  }
}
