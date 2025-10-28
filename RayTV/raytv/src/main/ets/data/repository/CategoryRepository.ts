// CategoryRepository - 分类仓库类
// 负责管理视频和直播的分类数据

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType, CachePolicy } from '../model/CacheModel';

/**
 * 分类类型枚举
 */
export enum CategoryType {
  VIDEO = 'video',
  LIVE = 'live',
  BOTH = 'both',
  GENRE = 'genre',
  TOPIC = 'topic',
  TAG = 'tag',
  COLLECTION = 'collection',
  CHANNEL = 'channel',
  FORMAT = 'format',
  LANGUAGE = 'language',
  REGION = 'region',
  UNKNOWN = 'unknown'
}

/**
 * 分类可见性枚举
 */
export enum CategoryVisibility {
  PUBLIC = 'public',
  PRIVATE = 'private',
  RESTRICTED = 'restricted',
  FEATURED = 'featured',
  HIDDEN = 'hidden'
}

/**
 * 分类排序类型枚举
 */
export enum CategorySortType {
  NAME_ASC = 'name_asc',
  NAME_DESC = 'name_desc',
  POPULARITY = 'popularity',
  TRENDING = 'trending',
  RECENTLY_ADDED = 'recently_added',
  CONTENT_COUNT = 'content_count',
  CUSTOM = 'custom'
}

/**
 * 分类图标类型枚举
 */
export enum CategoryIconType {
  ICON_FONT = 'icon_font',
  IMAGE = 'image',
  SVG = 'svg',
  EMOJI = 'emoji',
  GRADIENT = 'gradient',
  NONE = 'none'
}

/**
 * 分类图标接口
 */
export interface CategoryIcon {
  type: CategoryIconType;
  value: string; // 图标名称、图片URL或emoji
  color?: string;
  backgroundColor?: string;
  size?: number;
}

/**
 * 分类元数据接口
 */
export interface CategoryMetadata {
  viewCount: number; // 浏览次数
  contentCount: number; // 内容数量
  followerCount: number; // 关注者数量
  isFollowing?: boolean; // 当前用户是否关注
  isFeatured?: boolean; // 是否精选
  lastUpdated: number; // 最后更新时间
  createdAt: number; // 创建时间
  updatedBy?: string; // 更新者ID
  createdBy?: string; // 创建者ID
  parentCategoryId?: string; // 父分类ID
  childCategoryIds?: string[]; // 子分类ID列表
  relatedCategoryIds?: string[]; // 相关分类ID列表
  allowedUserIds?: string[]; // 允许访问的用户ID列表（私有分类）
  restrictedCountries?: string[]; // 限制访问的国家列表
  tags?: string[]; // 分类标签
  description?: string; // 详细描述
  coverImageUrl?: string; // 封面图片URL
  bannerImageUrl?: string; // 横幅图片URL
  icon?: CategoryIcon; // 分类图标
}

/**
 * 分类接口
 */
export interface Category {
  id: string; // 分类ID
  name: string; // 分类名称
  type: CategoryType; // 分类类型
  visibility: CategoryVisibility; // 可见性
  slug: string; // URL友好的标识
  metadata: CategoryMetadata; // 元数据
  orderIndex?: number; // 排序索引
  status: 'active' | 'inactive' | 'pending' | 'deprecated'; // 状态
  localization?: Record<string, { // 本地化数据
    name: string;
    description?: string;
    slug?: string;
  }>;
}

/**
 * 分类组接口
 */
export interface CategoryGroup {
  id: string; // 组ID
  name: string; // 组名称
  description?: string; // 组描述
  categoryIds: string[]; // 分类ID列表
  orderIndex?: number; // 排序索引
  isExpanded?: boolean; // 是否展开
  icon?: CategoryIcon; // 组图标
  createdAt: number; // 创建时间
  updatedAt: number; // 更新时间
}

/**
 * 分类事件类型
 */
export const CategoryEventType = {
  // 分类生命周期事件
  CREATED: 'category:created',
  UPDATED: 'category:updated',
  DELETED: 'category:deleted',
  ACTIVATED: 'category:activated',
  DEACTIVATED: 'category:deactivated',
  
  // 状态变更事件
  VISIBILITY_CHANGED: 'category:visibilityChanged',
  FOLLOWED: 'category:followed',
  UNFOLLOWED: 'category:unfollowed',
  
  // 内容事件
  CONTENT_ADDED: 'category:contentAdded',
  CONTENT_REMOVED: 'category:contentRemoved',
  CONTENT_COUNT_CHANGED: 'category:contentCountChanged',
  
  // 组事件
  GROUP_CREATED: 'category:groupCreated',
  GROUP_UPDATED: 'category:groupUpdated',
  GROUP_DELETED: 'category:groupDeleted',
  
  // 批量事件
  BATCH_UPDATED: 'category:batchUpdated',
  REORDERED: 'category:reordered',
  
  // 加载事件
  LOADED: 'category:loaded',
  SYNCED: 'category:synced',
  
  // 错误事件
  ERROR: 'category:error'
} as const;

/**
 * 分类事件数据
 */
export interface CategoryEvent {
  type: string;
  timestamp: number;
  category?: Category;
  categories?: Category[];
  categoryIds?: string[];
  group?: CategoryGroup;
  groups?: CategoryGroup[];
  visibility?: CategoryVisibility;
  previousVisibility?: CategoryVisibility;
  contentId?: string;
  contentCount?: number;
  error?: Error;
}

/**
 * 分类过滤条件接口
 */
export interface CategoryFilter {
  types?: CategoryType[]; // 分类类型
  visibility?: CategoryVisibility[]; // 可见性
  searchTerm?: string; // 搜索词
  parentId?: string; // 父分类ID
  childOf?: string; // 子分类筛选
  status?: string[]; // 状态
  featured?: boolean; // 是否精选
  followed?: boolean; // 是否已关注
  contentCountMin?: number; // 内容数量下限
  contentCountMax?: number; // 内容数量上限
  tags?: string[]; // 标签筛选
  sortBy?: CategorySortType; // 排序方式
  limit?: number; // 数量限制
  offset?: number; // 偏移量
  lang?: string; // 语言筛选
  region?: string; // 地区筛选
}

/**
 * 分类请求接口
 */
export interface CategoryRequest {
  filter?: CategoryFilter;
  includeMetadata?: boolean; // 是否包含元数据
  includeGroups?: boolean; // 是否包含分组
  includeLocalization?: boolean; // 是否包含本地化
  includeChildCategories?: boolean; // 是否包含子分类
  includeContentCount?: boolean; // 是否包含内容计数
  cachePolicy?: CachePolicy; // 缓存策略
}

/**
 * 分类响应接口
 */
export interface CategoryResponse {
  categories: Category[];
  totalCount: number;
  hasMore: boolean;
  groups?: CategoryGroup[];
  timestamp: number;
  cacheHit?: boolean;
}

/**
 * 分类统计接口
 */
export interface CategoryStats {
  totalCategories: number;
  activeCategories: number;
  featuredCategories: number;
  followedCategories: number;
  byType: Map<CategoryType, number>;
  byVisibility: Map<CategoryVisibility, number>;
  totalContentCount: number;
  lastUpdated: number;
}

/**
 * 分类存储配置接口
 */
export interface CategoryStorageConfig {
  cacheTTL: number; // 缓存过期时间（毫秒）
  maxCacheItems: number; // 最大缓存项数
  persistCategories: boolean; // 是否持久化分类
  autoSync: boolean; // 是否自动同步
  syncInterval: number; // 同步间隔（毫秒）
  offlineMode: boolean; // 离线模式
}

/**
 * 分类仓库类
 */
export class CategoryRepository {
  private static instance: CategoryRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  
  // 存储键配置
  private storageKeys = {
    categories: 'category:categories',
    groups: 'category:groups',
    stats: 'category:stats',
    followed: 'category:followed',
    config: 'category:config',
    lastSyncTime: 'category:lastSyncTime',
    customOrder: 'category:customOrder'
  };
  
  // 默认存储配置
  private defaultStorageConfig: CategoryStorageConfig = {
    cacheTTL: 3600000, // 1小时
    maxCacheItems: 1000,
    persistCategories: true,
    autoSync: true,
    syncInterval: 1800000, // 30分钟
    offlineMode: false
  };
  
  // 存储配置
  private storageConfig: CategoryStorageConfig = { ...this.defaultStorageConfig };
  
  // 分类数据
  private categories: Map<string, Category> = new Map();
  
  // 分类组
  private categoryGroups: Map<string, CategoryGroup> = new Map();
  
  // 关注的分类ID列表
  private followedCategoryIds: Set<string> = new Set();
  
  // 分类统计
  private categoryStats: CategoryStats = this.getEmptyStats();
  
  // 上次同步时间
  private lastSyncTime: number = 0;
  
  // 同步定时器
  private syncTimer: number | null = null;
  
  // 是否正在同步
  private isSyncing: boolean = false;
  
  // 过滤器缓存
  private filterCache: Map<string, CategoryResponse> = new Map();
  
  // 最大过滤器缓存项
  private maxFilterCacheItems: number = 10;
  
  // 自定义排序
  private customOrder: string[] = [];

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('CategoryRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取CategoryRepository单例实例
   */
  public static getInstance(): CategoryRepository {
    if (!CategoryRepository.instance) {
      CategoryRepository.instance = new CategoryRepository();
    }
    return CategoryRepository.instance;
  }

  /**
   * 初始化分类仓库
   */
  private async initialize(): Promise<void> {
    try {
      // 加载存储配置
      await this.loadStorageConfig();
      
      // 加载分类数据
      await this.loadCategories();
      
      // 加载分类组
      await this.loadGroups();
      
      // 加载关注的分类
      await this.loadFollowedCategories();
      
      // 加载统计
      await this.loadStats();
      
      // 加载自定义排序
      await this.loadCustomOrder();
      
      // 启动自动同步
      if (this.storageConfig.autoSync && !this.storageConfig.offlineMode) {
        this.startAutoSync();
      }
      
      // 检查缓存是否过期
      if (!this.isCacheValid() && !this.storageConfig.offlineMode) {
        this.syncCategories().catch(err => {
          this.logger.warn('Failed to sync categories on initialization', err);
        });
      }
      
      this.logger.info(`CategoryRepository initialization completed with ${this.categories.size} categories`);
    } catch (error) {
      this.logger.error('Failed to initialize CategoryRepository', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听网络状态变化
    this.eventBus.on('network:statusChanged', async (status: { isConnected: boolean }) => {
      if (status.isConnected && this.storageConfig.autoSync) {
        // 网络恢复时同步
        this.syncCategories().catch(err => {
          this.logger.warn('Failed to sync categories when network connected', err);
        });
      }
    });
    
    // 监听用户登录/登出事件
    this.eventBus.on('auth:loggedIn', async () => {
      // 用户登录后，重新加载关注的分类
      await this.loadFollowedCategories();
      // 同步分类数据
      this.syncCategories().catch(err => {
        this.logger.warn('Failed to sync categories after login', err);
      });
    });
    
    this.eventBus.on('auth:loggedOut', async () => {
      // 用户登出后，清空关注的分类
      this.followedCategoryIds.clear();
      await this.saveFollowedCategories();
    });
  }

  /**
   * 加载存储配置
   */
  private async loadStorageConfig(): Promise<void> {
    try {
      const config = await this.storageUtil.getObject<CategoryStorageConfig>(
        this.storageKeys.config,
        LocalStorageType.DEFAULT
      );
      
      if (config) {
        this.storageConfig = { ...this.defaultStorageConfig, ...config };
      }
      
      this.logger.debug('Category storage configuration loaded');
    } catch (error) {
      this.logger.error('Failed to load category storage config', error as Error);
    }
  }

  /**
   * 设置存储配置
   */
  public async setStorageConfig(config: Partial<CategoryStorageConfig>): Promise<CategoryStorageConfig> {
    try {
      this.storageConfig = { ...this.storageConfig, ...config };
      
      // 保存配置
      await this.storageUtil.setObject(
        this.storageKeys.config,
        this.storageConfig,
        LocalStorageType.DEFAULT
      );
      
      // 更新自动同步状态
      if (this.storageConfig.autoSync && !this.storageConfig.offlineMode) {
        this.startAutoSync();
      } else {
        this.stopAutoSync();
      }
      
      this.logger.info('Category storage configuration updated');
      
      return { ...this.storageConfig };
    } catch (error) {
      this.logger.error('Failed to set category storage config', error as Error);
      throw error;
    }
  }

  /**
   * 加载分类数据
   */
  private async loadCategories(): Promise<void> {
    try {
      if (this.storageConfig.persistCategories) {
        const categoriesData = await this.storageUtil.getObject<Record<string, Category>>(
          this.storageKeys.categories,
          LocalStorageType.DEFAULT
        );
        
        if (categoriesData) {
          this.categories = new Map(Object.entries(categoriesData));
          this.logger.debug(`Loaded ${this.categories.size} categories from storage`);
        }
      }
      
      // 如果没有分类数据，使用默认分类
      if (this.categories.size === 0) {
        await this.initializeDefaultCategories();
      }
    } catch (error) {
      this.logger.error('Failed to load categories', error as Error);
      // 尝试使用默认分类
      await this.initializeDefaultCategories();
    }
  }

  /**
   * 初始化默认分类
   */
  private async initializeDefaultCategories(): Promise<void> {
    try {
      const defaultCategories: Category[] = [
        // 视频分类
        {
          id: 'cat_1',
          name: 'Movies',
          type: CategoryType.VIDEO,
          visibility: CategoryVisibility.PUBLIC,
          slug: 'movies',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            isFeatured: true,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            childCategoryIds: ['cat_1_1', 'cat_1_2', 'cat_1_3'],
            description: 'Latest and popular movies',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '🎬'
            }
          },
          status: 'active',
          orderIndex: 1
        },
        {
          id: 'cat_1_1',
          name: 'Action',
          type: CategoryType.GENRE,
          visibility: CategoryVisibility.PUBLIC,
          slug: 'action',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            parentCategoryId: 'cat_1',
            description: 'Action-packed movies',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '⚔️'
            }
          },
          status: 'active'
        },
        {
          id: 'cat_1_2',
          name: 'Comedy',
          type: CategoryType.GENRE,
          visibility: CategoryVisibility.PUBLIC,
          slug: 'comedy',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            parentCategoryId: 'cat_1',
            description: 'Funny and entertaining movies',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '😂'
            }
          },
          status: 'active'
        },
        {
          id: 'cat_1_3',
          name: 'Drama',
          type: CategoryType.GENRE,
          visibility: CategoryVisibility.PUBLIC,
          slug: 'drama',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            parentCategoryId: 'cat_1',
            description: 'Emotional and serious movies',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '🎭'
            }
          },
          status: 'active'
        },
        // 直播分类
        {
          id: 'cat_2',
          name: 'Live Streams',
          type: CategoryType.LIVE,
          visibility: CategoryVisibility.PUBLIC,
          slug: 'live-streams',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            isFeatured: true,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            childCategoryIds: ['cat_2_1', 'cat_2_2', 'cat_2_3'],
            description: 'Live broadcasts and streams',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '📹'
            }
          },
          status: 'active',
          orderIndex: 2
        },
        {
          id: 'cat_2_1',
          name: 'Gaming',
          type: CategoryType.TOPIC,
          visibility: CategoryVisibility.PUBLIC,
          slug: 'gaming',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            parentCategoryId: 'cat_2',
            description: 'Live gaming streams',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '🎮'
            }
          },
          status: 'active'
        },
        {
          id: 'cat_2_2',
          name: 'Music',
          type: CategoryType.TOPIC,
          visibility: CategoryVisibility.PUBLIC,
          slug: 'music',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            parentCategoryId: 'cat_2',
            description: 'Live music performances',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '🎵'
            }
          },
          status: 'active'
        },
        {
          id: 'cat_2_3',
          name: 'Talk Shows',
          type: CategoryType.FORMAT,
          visibility: CategoryVisibility.PUBLIC,
          slug: 'talk-shows',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            parentCategoryId: 'cat_2',
            description: 'Live talk shows and discussions',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '🗣️'
            }
          },
          status: 'active'
        },
        // 通用分类
        {
          id: 'cat_3',
          name: 'Trending',
          type: CategoryType.BOTH,
          visibility: CategoryVisibility.FEATURED,
          slug: 'trending',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            isFeatured: true,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            description: 'Currently trending content',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '🔥'
            }
          },
          status: 'active',
          orderIndex: 3
        },
        {
          id: 'cat_4',
          name: 'New Releases',
          type: CategoryType.BOTH,
          visibility: CategoryVisibility.PUBLIC,
          slug: 'new-releases',
          metadata: {
            viewCount: 0,
            contentCount: 0,
            followerCount: 0,
            lastUpdated: Date.now(),
            createdAt: Date.now(),
            description: 'Recently added content',
            icon: {
              type: CategoryIconType.EMOJI,
              value: '🆕'
            }
          },
          status: 'active',
          orderIndex: 4
        }
      ];
      
      // 添加默认分类
      defaultCategories.forEach(category => {
        this.categories.set(category.id, category);
      });
      
      // 保存默认分类
      await this.saveCategories();
      
      this.logger.info('Initialized default categories');
    } catch (error) {
      this.logger.error('Failed to initialize default categories', error as Error);
    }
  }

  /**
   * 保存分类数据
   */
  private async saveCategories(): Promise<void> {
    try {
      if (this.storageConfig.persistCategories) {
        // 转换Map为对象以便存储
        const categoriesObject: Record<string, Category> = {};
        this.categories.forEach((category, id) => {
          categoriesObject[id] = category;
        });
        
        await this.storageUtil.setObject(
          this.storageKeys.categories,
          categoriesObject,
          LocalStorageType.DEFAULT
        );
        
        this.logger.debug(`Saved ${this.categories.size} categories to storage`);
      }
    } catch (error) {
      this.logger.error('Failed to save categories', error as Error);
    }
  }

  /**
   * 加载分类组
   */
  private async loadGroups(): Promise<void> {
    try {
      const groupsData = await this.storageUtil.getObject<Record<string, CategoryGroup>>(
        this.storageKeys.groups,
        LocalStorageType.DEFAULT
      );
      
      if (groupsData) {
        this.categoryGroups = new Map(Object.entries(groupsData));
        this.logger.debug(`Loaded ${this.categoryGroups.size} category groups`);
      } else {
        // 初始化默认组
        await this.initializeDefaultGroups();
      }
    } catch (error) {
      this.logger.error('Failed to load category groups', error as Error);
      // 尝试使用默认组
      await this.initializeDefaultGroups();
    }
  }

  /**
   * 初始化默认组
   */
  private async initializeDefaultGroups(): Promise<void> {
    try {
      const defaultGroups: CategoryGroup[] = [
        {
          id: 'group_1',
          name: 'Movie Genres',
          description: 'Browse by movie genres',
          categoryIds: ['cat_1_1', 'cat_1_2', 'cat_1_3'],
          orderIndex: 1,
          isExpanded: true,
          createdAt: Date.now(),
          updatedAt: Date.now()
        },
        {
          id: 'group_2',
          name: 'Live Stream Topics',
          description: 'Browse live streams by topic',
          categoryIds: ['cat_2_1', 'cat_2_2', 'cat_2_3'],
          orderIndex: 2,
          isExpanded: true,
          createdAt: Date.now(),
          updatedAt: Date.now()
        },
        {
          id: 'group_3',
          name: 'Featured',
          description: 'Featured categories',
          categoryIds: ['cat_3', 'cat_1', 'cat_2'],
          orderIndex: 0,
          isExpanded: true,
          createdAt: Date.now(),
          updatedAt: Date.now()
        }
      ];
      
      // 添加默认组
      defaultGroups.forEach(group => {
        this.categoryGroups.set(group.id, group);
      });
      
      // 保存默认组
      await this.saveGroups();
      
      this.logger.info('Initialized default category groups');
    } catch (error) {
      this.logger.error('Failed to initialize default category groups', error as Error);
    }
  }

  /**
   * 保存分类组
   */
  private async saveGroups(): Promise<void> {
    try {
      // 转换Map为对象以便存储
      const groupsObject: Record<string, CategoryGroup> = {};
      this.categoryGroups.forEach((group, id) => {
        groupsObject[id] = group;
      });
      
      await this.storageUtil.setObject(
        this.storageKeys.groups,
        groupsObject,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save category groups', error as Error);
    }
  }

  /**
   * 加载关注的分类
   */
  private async loadFollowedCategories(): Promise<void> {
    try {
      const followedIds = await this.storageUtil.getStringArray(
        this.storageKeys.followed,
        LocalStorageType.DEFAULT
      );
      
      if (followedIds && Array.isArray(followedIds)) {
        this.followedCategoryIds = new Set(followedIds);
        this.logger.debug(`Loaded ${this.followedCategoryIds.size} followed categories`);
      }
    } catch (error) {
      this.logger.error('Failed to load followed categories', error as Error);
      this.followedCategoryIds = new Set();
    }
  }

  /**
   * 保存关注的分类
   */
  private async saveFollowedCategories(): Promise<void> {
    try {
      const followedIds = Array.from(this.followedCategoryIds);
      await this.storageUtil.setStringArray(
        this.storageKeys.followed,
        followedIds,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save followed categories', error as Error);
    }
  }

  /**
   * 加载统计
   */
  private async loadStats(): Promise<void> {
    try {
      const statsData = await this.storageUtil.getObject<{
        totalCategories: number;
        activeCategories: number;
        featuredCategories: number;
        followedCategories: number;
        byType: [CategoryType, number][];
        byVisibility: [CategoryVisibility, number][];
        totalContentCount: number;
        lastUpdated: number;
      }>(
        this.storageKeys.stats,
        LocalStorageType.DEFAULT
      );
      
      if (statsData) {
        this.categoryStats = {
          ...statsData,
          byType: new Map(statsData.byType),
          byVisibility: new Map(statsData.byVisibility)
        };
      } else {
        // 计算统计数据
        await this.updateStats();
      }
    } catch (error) {
      this.logger.warn('Failed to load category stats', error as Error);
      this.resetStats();
    }
  }

  /**
   * 加载自定义排序
   */
  private async loadCustomOrder(): Promise<void> {
    try {
      const order = await this.storageUtil.getStringArray(
        this.storageKeys.customOrder,
        LocalStorageType.DEFAULT
      );
      
      if (order && Array.isArray(order)) {
        this.customOrder = order;
      }
    } catch (error) {
      this.logger.error('Failed to load custom order', error as Error);
    }
  }

  /**
   * 保存自定义排序
   */
  private async saveCustomOrder(): Promise<void> {
    try {
      await this.storageUtil.setStringArray(
        this.storageKeys.customOrder,
        this.customOrder,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save custom order', error as Error);
    }
  }

  /**
   * 启动自动同步
   */
  private startAutoSync(): void {
    // 停止现有的同步
    this.stopAutoSync();
    
    // 设置定期同步
    this.syncTimer = setInterval(() => {
      this.syncCategories().catch(err => {
        this.logger.warn('Failed to sync categories in auto-sync timer', err);
      });
    }, this.storageConfig.syncInterval);
    
    this.logger.debug('Auto-sync for categories started');
  }

  /**
   * 停止自动同步
   */
  private stopAutoSync(): void {
    if (this.syncTimer !== null) {
      clearInterval(this.syncTimer);
      this.syncTimer = null;
      this.logger.debug('Auto-sync for categories stopped');
    }
  }

  /**
   * 同步分类数据
   */
  public async syncCategories(): Promise<boolean> {
    try {
      // 防止并发同步
      if (this.isSyncing || this.storageConfig.offlineMode) {
        return false;
      }
      
      this.isSyncing = true;
      
      // 在实际应用中，这里应该调用服务器API获取最新的分类数据
      // 这里简化处理，模拟同步
      
      // 模拟API调用延迟
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // 更新同步时间
      this.lastSyncTime = Date.now();
      await this.storageUtil.setNumber(
        this.storageKeys.lastSyncTime,
        this.lastSyncTime,
        LocalStorageType.DEFAULT
      );
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布同步事件
      this.eventBus.emit(CategoryEventType.SYNCED, {
        type: CategoryEventType.SYNCED,
        timestamp: Date.now()
      } as CategoryEvent);
      
      this.logger.info('Categories synced successfully');
      
      return true;
    } catch (error) {
      this.logger.error('Failed to sync categories', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return false;
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * 检查缓存是否有效
   */
  private isCacheValid(): boolean {
    const now = Date.now();
    const cacheAge = now - this.lastSyncTime;
    return cacheAge < this.storageConfig.cacheTTL;
  }

  /**
   * 获取所有分类
   */
  public async getAllCategories(request?: CategoryRequest): Promise<CategoryResponse> {
    try {
      const filter = request?.filter || {};
      
      // 生成过滤缓存键
      const cacheKey = JSON.stringify(filter);
      
      // 检查缓存
      if (request?.cachePolicy !== CachePolicy.NETWORK_ONLY && this.filterCache.has(cacheKey)) {
        const cachedResponse = this.filterCache.get(cacheKey)!;
        return {
          ...cachedResponse,
          cacheHit: true
        };
      }
      
      // 转换为数组进行过滤
      let categories = Array.from(this.categories.values());
      
      // 应用过滤条件
      if (filter.types && filter.types.length > 0) {
        categories = categories.filter(cat => filter.types!.includes(cat.type));
      }
      
      if (filter.visibility && filter.visibility.length > 0) {
        categories = categories.filter(cat => filter.visibility!.includes(cat.visibility));
      }
      
      if (filter.searchTerm) {
        const searchLower = filter.searchTerm.toLowerCase();
        categories = categories.filter(cat => 
          cat.name.toLowerCase().includes(searchLower) ||
          cat.slug.toLowerCase().includes(searchLower) ||
          (cat.metadata.description && cat.metadata.description.toLowerCase().includes(searchLower))
        );
      }
      
      if (filter.parentId) {
        categories = categories.filter(cat => cat.metadata.parentCategoryId === filter.parentId);
      }
      
      if (filter.childOf) {
        const parent = this.categories.get(filter.childOf);
        if (parent && parent.metadata.childCategoryIds) {
          categories = categories.filter(cat => parent.metadata.childCategoryIds!.includes(cat.id));
        } else {
          categories = [];
        }
      }
      
      if (filter.status && filter.status.length > 0) {
        categories = categories.filter(cat => filter.status!.includes(cat.status));
      }
      
      if (filter.featured !== undefined) {
        categories = categories.filter(cat => cat.metadata.isFeatured === filter.featured);
      }
      
      if (filter.followed !== undefined) {
        categories = categories.filter(cat => 
          this.followedCategoryIds.has(cat.id) === filter.followed
        );
      }
      
      if (filter.contentCountMin !== undefined) {
        categories = categories.filter(cat => 
          cat.metadata.contentCount >= filter.contentCountMin!
        );
      }
      
      if (filter.contentCountMax !== undefined) {
        categories = categories.filter(cat => 
          cat.metadata.contentCount <= filter.contentCountMax!
        );
      }
      
      if (filter.tags && filter.tags.length > 0) {
        categories = categories.filter(cat => 
          cat.metadata.tags && filter.tags!.some(tag => cat.metadata.tags!.includes(tag))
        );
      }
      
      // 应用排序
      if (filter.sortBy) {
        categories = this.sortCategories(categories, filter.sortBy);
      } else {
        // 默认按排序索引和名称排序
        categories = this.sortCategories(categories, CategorySortType.NAME_ASC);
      }
      
      // 应用分页
      const totalCount = categories.length;
      let offset = filter.offset || 0;
      let limit = filter.limit || totalCount;
      
      const pagedCategories = categories.slice(offset, offset + limit);
      
      // 创建响应
      const response: CategoryResponse = {
        categories: pagedCategories,
        totalCount,
        hasMore: offset + limit < totalCount,
        timestamp: Date.now()
      };
      
      // 如果需要，添加分组信息
      if (request?.includeGroups) {
        response.groups = await this.getAllGroups();
      }
      
      // 更新缓存
      if (request?.cachePolicy !== CachePolicy.NETWORK_ONLY) {
        this.updateFilterCache(cacheKey, response);
      }
      
      // 发布加载事件
      this.eventBus.emit(CategoryEventType.LOADED, {
        type: CategoryEventType.LOADED,
        timestamp: Date.now(),
        categories: pagedCategories
      } as CategoryEvent);
      
      return response;
    } catch (error) {
      this.logger.error('Failed to get categories', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return {
        categories: [],
        totalCount: 0,
        hasMore: false,
        timestamp: Date.now()
      };
    }
  }

  /**
   * 对分类进行排序
   */
  private sortCategories(categories: Category[], sortBy: CategorySortType): Category[] {
    const sorted = [...categories];
    
    switch (sortBy) {
      case CategorySortType.NAME_ASC:
        return sorted.sort((a, b) => {
          // 先按排序索引排序
          if (a.orderIndex !== undefined && b.orderIndex !== undefined) {
            if (a.orderIndex !== b.orderIndex) {
              return a.orderIndex - b.orderIndex;
            }
          } else if (a.orderIndex !== undefined) {
            return -1;
          } else if (b.orderIndex !== undefined) {
            return 1;
          }
          
          // 然后按名称排序
          return a.name.localeCompare(b.name);
        });
        
      case CategorySortType.NAME_DESC:
        return sorted.sort((a, b) => {
          // 先按排序索引排序
          if (a.orderIndex !== undefined && b.orderIndex !== undefined) {
            if (a.orderIndex !== b.orderIndex) {
              return a.orderIndex - b.orderIndex;
            }
          } else if (a.orderIndex !== undefined) {
            return -1;
          } else if (b.orderIndex !== undefined) {
            return 1;
          }
          
          // 然后按名称排序
          return b.name.localeCompare(a.name);
        });
        
      case CategorySortType.POPULARITY:
        return sorted.sort((a, b) => b.metadata.viewCount - a.metadata.viewCount);
        
      case CategorySortType.TRENDING:
        // 简单实现：基于观看次数和更新时间
        return sorted.sort((a, b) => {
          const aScore = a.metadata.viewCount + (Date.now() - a.metadata.lastUpdated) / 1000000;
          const bScore = b.metadata.viewCount + (Date.now() - b.metadata.lastUpdated) / 1000000;
          return bScore - aScore;
        });
        
      case CategorySortType.RECENTLY_ADDED:
        return sorted.sort((a, b) => b.metadata.createdAt - a.metadata.createdAt);
        
      case CategorySortType.CONTENT_COUNT:
        return sorted.sort((a, b) => b.metadata.contentCount - a.metadata.contentCount);
        
      case CategorySortType.CUSTOM:
        // 使用自定义排序
        return sorted.sort((a, b) => {
          const aIndex = this.customOrder.indexOf(a.id);
          const bIndex = this.customOrder.indexOf(b.id);
          
          if (aIndex !== -1 && bIndex !== -1) {
            return aIndex - bIndex;
          } else if (aIndex !== -1) {
            return -1;
          } else if (bIndex !== -1) {
            return 1;
          }
          
          // 默认按名称排序
          return a.name.localeCompare(b.name);
        });
        
      default:
        return sorted;
    }
  }

  /**
   * 更新过滤器缓存
   */
  private updateFilterCache(key: string, response: CategoryResponse): void {
    // 限制缓存大小
    if (this.filterCache.size >= this.maxFilterCacheItems && !this.filterCache.has(key)) {
      // 移除最早的缓存项
      const firstKey = this.filterCache.keys().next().value;
      this.filterCache.delete(firstKey);
    }
    
    this.filterCache.set(key, response);
  }

  /**
   * 清除过滤器缓存
   */
  private clearFilterCache(): void {
    this.filterCache.clear();
  }

  /**
   * 获取分类详情
   */
  public async getCategoryById(id: string): Promise<Category | null> {
    try {
      const category = this.categories.get(id);
      
      if (category) {
        // 更新观看次数
        category.metadata.viewCount++;
        await this.saveCategories();
        
        // 返回深拷贝
        return JSON.parse(JSON.stringify(category));
      }
      
      return null;
    } catch (error) {
      this.logger.error(`Failed to get category by id: ${id}`, error as Error);
      return null;
    }
  }

  /**
   * 通过slug获取分类
   */
  public async getCategoryBySlug(slug: string): Promise<Category | null> {
    try {
      const category = Array.from(this.categories.values()).find(cat => cat.slug === slug);
      
      if (category) {
        // 更新观看次数
        category.metadata.viewCount++;
        await this.saveCategories();
        
        // 返回深拷贝
        return JSON.parse(JSON.stringify(category));
      }
      
      return null;
    } catch (error) {
      this.logger.error(`Failed to get category by slug: ${slug}`, error as Error);
      return null;
    }
  }

  /**
   * 获取所有分类组
   */
  public async getAllGroups(): Promise<CategoryGroup[]> {
    try {
      return Array.from(this.categoryGroups.values())
        .sort((a, b) => (a.orderIndex || 0) - (b.orderIndex || 0));
    } catch (error) {
      this.logger.error('Failed to get category groups', error as Error);
      return [];
    }
  }

  /**
   * 获取分类组详情
   */
  public async getGroupById(id: string): Promise<CategoryGroup | null> {
    try {
      const group = this.categoryGroups.get(id);
      return group ? { ...group } : null;
    } catch (error) {
      this.logger.error(`Failed to get group by id: ${id}`, error as Error);
      return null;
    }
  }

  /**
   * 添加新分类
   */
  public async addCategory(category: Omit<Category, 'id' | 'metadata'>): Promise<Category> {
    try {
      const newCategory: Category = {
        ...category,
        id: `category_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        metadata: {
          viewCount: 0,
          contentCount: 0,
          followerCount: 0,
          isFeatured: category.visibility === CategoryVisibility.FEATURED,
          lastUpdated: Date.now(),
          createdAt: Date.now(),
          tags: category.metadata?.tags || [],
          description: category.metadata?.description || '',
          icon: category.metadata?.icon || {
            type: CategoryIconType.NONE,
            value: ''
          }
        }
      };
      
      // 添加到分类列表
      this.categories.set(newCategory.id, newCategory);
      
      // 如果有父分类，更新父分类的子分类列表
      if (newCategory.metadata.parentCategoryId) {
        const parent = this.categories.get(newCategory.metadata.parentCategoryId);
        if (parent) {
          if (!parent.metadata.childCategoryIds) {
            parent.metadata.childCategoryIds = [];
          }
          if (!parent.metadata.childCategoryIds.includes(newCategory.id)) {
            parent.metadata.childCategoryIds.push(newCategory.id);
          }
        }
      }
      
      // 保存分类
      await this.saveCategories();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布创建事件
      this.eventBus.emit(CategoryEventType.CREATED, {
        type: CategoryEventType.CREATED,
        timestamp: Date.now(),
        category: newCategory
      } as CategoryEvent);
      
      this.logger.info(`Category created: ${newCategory.name} (${newCategory.id})`);
      
      return newCategory;
    } catch (error) {
      this.logger.error('Failed to add category', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      throw error;
    }
  }

  /**
   * 更新分类
   */
  public async updateCategory(id: string, updates: Partial<Category>): Promise<Category | null> {
    try {
      const category = this.categories.get(id);
      
      if (!category) {
        return null;
      }
      
      const oldCategory = { ...category };
      
      // 更新分类属性
      const updatedCategory: Category = {
        ...category,
        ...updates,
        metadata: {
          ...category.metadata,
          ...updates.metadata,
          lastUpdated: Date.now()
        }
      };
      
      // 处理可见性变更
      if (updates.visibility !== undefined && updates.visibility !== oldCategory.visibility) {
        this.eventBus.emit(CategoryEventType.VISIBILITY_CHANGED, {
          type: CategoryEventType.VISIBILITY_CHANGED,
          timestamp: Date.now(),
          category: updatedCategory,
          visibility: updates.visibility!,
          previousVisibility: oldCategory.visibility
        } as CategoryEvent);
      }
      
      // 处理状态变更
      if (updates.status === 'active' && oldCategory.status !== 'active') {
        this.eventBus.emit(CategoryEventType.ACTIVATED, {
          type: CategoryEventType.ACTIVATED,
          timestamp: Date.now(),
          category: updatedCategory
        } as CategoryEvent);
      } else if (updates.status === 'inactive' && oldCategory.status === 'active') {
        this.eventBus.emit(CategoryEventType.DEACTIVATED, {
          type: CategoryEventType.DEACTIVATED,
          timestamp: Date.now(),
          category: updatedCategory
        } as CategoryEvent);
      }
      
      // 更新父分类关系
      if (updates.metadata?.parentCategoryId && 
          updates.metadata.parentCategoryId !== oldCategory.metadata.parentCategoryId) {
        
        // 从旧父分类移除
        if (oldCategory.metadata.parentCategoryId) {
          const oldParent = this.categories.get(oldCategory.metadata.parentCategoryId);
          if (oldParent && oldParent.metadata.childCategoryIds) {
            oldParent.metadata.childCategoryIds = 
              oldParent.metadata.childCategoryIds.filter(childId => childId !== id);
          }
        }
        
        // 添加到新父分类
        const newParent = this.categories.get(updates.metadata.parentCategoryId!);
        if (newParent) {
          if (!newParent.metadata.childCategoryIds) {
            newParent.metadata.childCategoryIds = [];
          }
          if (!newParent.metadata.childCategoryIds.includes(id)) {
            newParent.metadata.childCategoryIds.push(id);
          }
        }
      }
      
      // 更新分类
      this.categories.set(id, updatedCategory);
      
      // 保存分类
      await this.saveCategories();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布更新事件
      this.eventBus.emit(CategoryEventType.UPDATED, {
        type: CategoryEventType.UPDATED,
        timestamp: Date.now(),
        category: updatedCategory
      } as CategoryEvent);
      
      this.logger.info(`Category updated: ${updatedCategory.name} (${id})`);
      
      return updatedCategory;
    } catch (error) {
      this.logger.error(`Failed to update category: ${id}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return null;
    }
  }

  /**
   * 删除分类
   */
  public async deleteCategory(id: string): Promise<boolean> {
    try {
      const category = this.categories.get(id);
      
      if (!category) {
        return false;
      }
      
      // 检查是否有子分类
      if (category.metadata.childCategoryIds && category.metadata.childCategoryIds.length > 0) {
        throw new Error('Cannot delete category with child categories');
      }
      
      // 从父分类移除
      if (category.metadata.parentCategoryId) {
        const parent = this.categories.get(category.metadata.parentCategoryId);
        if (parent && parent.metadata.childCategoryIds) {
          parent.metadata.childCategoryIds = 
            parent.metadata.childCategoryIds.filter(childId => childId !== id);
        }
      }
      
      // 从关注列表移除
      this.followedCategoryIds.delete(id);
      await this.saveFollowedCategories();
      
      // 从分类组移除
      for (const group of this.categoryGroups.values()) {
        if (group.categoryIds.includes(id)) {
          group.categoryIds = group.categoryIds.filter(catId => catId !== id);
        }
      }
      await this.saveGroups();
      
      // 从自定义排序移除
      this.customOrder = this.customOrder.filter(catId => catId !== id);
      await this.saveCustomOrder();
      
      // 从分类列表移除
      const removed = this.categories.delete(id);
      
      // 保存分类
      await this.saveCategories();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布删除事件
      this.eventBus.emit(CategoryEventType.DELETED, {
        type: CategoryEventType.DELETED,
        timestamp: Date.now(),
        category
      } as CategoryEvent);
      
      this.logger.info(`Category deleted: ${category.name} (${id})`);
      
      return removed;
    } catch (error) {
      this.logger.error(`Failed to delete category: ${id}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return false;
    }
  }

  /**
   * 批量更新分类
   */
  public async updateMultipleCategories(
    updates: Array<{ id: string; changes: Partial<Category> }>
  ): Promise<number> {
    try {
      let updatedCount = 0;
      const updatedCategories: Category[] = [];
      
      for (const { id, changes } of updates) {
        const updated = await this.updateCategory(id, changes);
        if (updated) {
          updatedCount++;
          updatedCategories.push(updated);
        }
      }
      
      if (updatedCount > 0) {
        // 发布批量更新事件
        this.eventBus.emit(CategoryEventType.BATCH_UPDATED, {
          type: CategoryEventType.BATCH_UPDATED,
          timestamp: Date.now(),
          categories: updatedCategories
        } as CategoryEvent);
      }
      
      this.logger.info(`Updated ${updatedCount} categories in batch`);
      
      return updatedCount;
    } catch (error) {
      this.logger.error('Failed to update multiple categories', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return 0;
    }
  }

  /**
   * 添加分类组
   */
  public async addGroup(group: Omit<CategoryGroup, 'id' | 'createdAt' | 'updatedAt'>): Promise<CategoryGroup> {
    try {
      const newGroup: CategoryGroup = {
        ...group,
        id: `group_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      
      // 添加到组列表
      this.categoryGroups.set(newGroup.id, newGroup);
      
      // 保存组
      await this.saveGroups();
      
      // 发布创建事件
      this.eventBus.emit(CategoryEventType.GROUP_CREATED, {
        type: CategoryEventType.GROUP_CREATED,
        timestamp: Date.now(),
        group: newGroup
      } as CategoryEvent);
      
      this.logger.info(`Category group created: ${newGroup.name} (${newGroup.id})`);
      
      return newGroup;
    } catch (error) {
      this.logger.error('Failed to add category group', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      throw error;
    }
  }

  /**
   * 更新分类组
   */
  public async updateGroup(id: string, updates: Partial<CategoryGroup>): Promise<CategoryGroup | null> {
    try {
      const group = this.categoryGroups.get(id);
      
      if (!group) {
        return null;
      }
      
      const updatedGroup: CategoryGroup = {
        ...group,
        ...updates,
        updatedAt: Date.now()
      };
      
      // 更新组
      this.categoryGroups.set(id, updatedGroup);
      
      // 保存组
      await this.saveGroups();
      
      // 发布更新事件
      this.eventBus.emit(CategoryEventType.GROUP_UPDATED, {
        type: CategoryEventType.GROUP_UPDATED,
        timestamp: Date.now(),
        group: updatedGroup
      } as CategoryEvent);
      
      this.logger.info(`Category group updated: ${updatedGroup.name} (${id})`);
      
      return updatedGroup;
    } catch (error) {
      this.logger.error(`Failed to update category group: ${id}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return null;
    }
  }

  /**
   * 删除分类组
   */
  public async deleteGroup(id: string): Promise<boolean> {
    try {
      const group = this.categoryGroups.get(id);
      
      if (!group) {
        return false;
      }
      
      // 从组列表移除
      const removed = this.categoryGroups.delete(id);
      
      // 保存组
      await this.saveGroups();
      
      // 发布删除事件
      this.eventBus.emit(CategoryEventType.GROUP_DELETED, {
        type: CategoryEventType.GROUP_DELETED,
        timestamp: Date.now(),
        group
      } as CategoryEvent);
      
      this.logger.info(`Category group deleted: ${group.name} (${id})`);
      
      return removed;
    } catch (error) {
      this.logger.error(`Failed to delete category group: ${id}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return false;
    }
  }

  /**
   * 关注分类
   */
  public async followCategory(id: string): Promise<boolean> {
    try {
      const category = this.categories.get(id);
      
      if (!category || this.followedCategoryIds.has(id)) {
        return false;
      }
      
      // 添加到关注列表
      this.followedCategoryIds.add(id);
      
      // 更新分类的关注者数量
      category.metadata.followerCount++;
      category.metadata.isFollowing = true;
      
      // 保存关注状态
      await this.saveFollowedCategories();
      await this.saveCategories();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布关注事件
      this.eventBus.emit(CategoryEventType.FOLLOWED, {
        type: CategoryEventType.FOLLOWED,
        timestamp: Date.now(),
        category
      } as CategoryEvent);
      
      this.logger.info(`Followed category: ${category.name} (${id})`);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to follow category: ${id}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return false;
    }
  }

  /**
   * 取消关注分类
   */
  public async unfollowCategory(id: string): Promise<boolean> {
    try {
      const category = this.categories.get(id);
      
      if (!category || !this.followedCategoryIds.has(id)) {
        return false;
      }
      
      // 从关注列表移除
      this.followedCategoryIds.delete(id);
      
      // 更新分类的关注者数量
      category.metadata.followerCount = Math.max(0, category.metadata.followerCount - 1);
      category.metadata.isFollowing = false;
      
      // 保存关注状态
      await this.saveFollowedCategories();
      await this.saveCategories();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布取消关注事件
      this.eventBus.emit(CategoryEventType.UNFOLLOWED, {
        type: CategoryEventType.UNFOLLOWED,
        timestamp: Date.now(),
        category
      } as CategoryEvent);
      
      this.logger.info(`Unfollowed category: ${category.name} (${id})`);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to unfollow category: ${id}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return false;
    }
  }

  /**
   * 检查是否关注了分类
   */
  public async isCategoryFollowed(id: string): Promise<boolean> {
    return this.followedCategoryIds.has(id);
  }

  /**
   * 获取关注的分类
   */
  public async getFollowedCategories(): Promise<Category[]> {
    try {
      return Array.from(this.categories.values())
        .filter(cat => this.followedCategoryIds.has(cat.id))
        .sort((a, b) => b.metadata.lastUpdated - a.metadata.lastUpdated);
    } catch (error) {
      this.logger.error('Failed to get followed categories', error as Error);
      return [];
    }
  }

  /**
   * 更新分类的内容计数
   */
  public async updateContentCount(categoryId: string, delta: number): Promise<boolean> {
    try {
      const category = this.categories.get(categoryId);
      
      if (!category) {
        return false;
      }
      
      // 更新内容计数
      const oldCount = category.metadata.contentCount;
      category.metadata.contentCount = Math.max(0, category.metadata.contentCount + delta);
      
      // 保存分类
      await this.saveCategories();
      
      // 更新统计
      await this.updateStats();
      
      // 发布内容计数变更事件
      this.eventBus.emit(CategoryEventType.CONTENT_COUNT_CHANGED, {
        type: CategoryEventType.CONTENT_COUNT_CHANGED,
        timestamp: Date.now(),
        category,
        contentCount: category.metadata.contentCount
      } as CategoryEvent);
      
      // 如果添加了内容，发布内容添加事件
      if (delta > 0) {
        this.eventBus.emit(CategoryEventType.CONTENT_ADDED, {
          type: CategoryEventType.CONTENT_ADDED,
          timestamp: Date.now(),
          category
        } as CategoryEvent);
      } 
      // 如果移除了内容，发布内容移除事件
      else if (delta < 0) {
        this.eventBus.emit(CategoryEventType.CONTENT_REMOVED, {
          type: CategoryEventType.CONTENT_REMOVED,
          timestamp: Date.now(),
          category
        } as CategoryEvent);
      }
      
      this.logger.debug(`Content count updated for category ${categoryId}: ${oldCount} -> ${category.metadata.contentCount}`);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to update content count for category: ${categoryId}`, error as Error);
      return false;
    }
  }

  /**
   * 重新排序分类
   */
  public async reorderCategories(categoryIds: string[]): Promise<boolean> {
    try {
      // 验证所有ID是否存在
      const invalidIds = categoryIds.filter(id => !this.categories.has(id));
      if (invalidIds.length > 0) {
        throw new Error(`Invalid category IDs: ${invalidIds.join(', ')}`);
      }
      
      // 更新自定义排序
      this.customOrder = categoryIds;
      
      // 更新分类的排序索引
      categoryIds.forEach((id, index) => {
        const category = this.categories.get(id);
        if (category) {
          category.orderIndex = index;
        }
      });
      
      // 保存排序
      await this.saveCustomOrder();
      await this.saveCategories();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布重新排序事件
      this.eventBus.emit(CategoryEventType.REORDERED, {
        type: CategoryEventType.REORDERED,
        timestamp: Date.now(),
        categoryIds
      } as CategoryEvent);
      
      this.logger.info(`Categories reordered: ${categoryIds.length} categories`);
      
      return true;
    } catch (error) {
      this.logger.error('Failed to reorder categories', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      return false;
    }
  }

  /**
   * 获取分类统计
   */
  public async getStats(): Promise<CategoryStats> {
    try {
      // 确保统计是最新的
      await this.updateStats();
      
      return {
        ...this.categoryStats,
        byType: new Map(this.categoryStats.byType),
        byVisibility: new Map(this.categoryStats.byVisibility)
      };
    } catch (error) {
      this.logger.error('Failed to get category stats', error as Error);
      return this.getEmptyStats();
    }
  }

  /**
   * 更新统计数据
   */
  private async updateStats(): Promise<void> {
    try {
      const categories = Array.from(this.categories.values());
      const byType = new Map<CategoryType, number>();
      const byVisibility = new Map<CategoryVisibility, number>();
      
      let activeCount = 0;
      let featuredCount = 0;
      let totalContentCount = 0;
      
      // 统计每个类型和可见性的分类数量
      categories.forEach(category => {
        // 统计类型
        const typeCount = byType.get(category.type) || 0;
        byType.set(category.type, typeCount + 1);
        
        // 统计可见性
        const visibilityCount = byVisibility.get(category.visibility) || 0;
        byVisibility.set(category.visibility, visibilityCount + 1);
        
        // 统计活动分类
        if (category.status === 'active') {
          activeCount++;
        }
        
        // 统计精选分类
        if (category.metadata.isFeatured) {
          featuredCount++;
        }
        
        // 累计内容数量
        totalContentCount += category.metadata.contentCount;
      });
      
      this.categoryStats = {
        totalCategories: categories.length,
        activeCategories: activeCount,
        featuredCategories: featuredCount,
        followedCategories: this.followedCategoryIds.size,
        byType,
        byVisibility,
        totalContentCount,
        lastUpdated: Date.now()
      };
      
      // 保存统计数据
      await this.saveStats();
    } catch (error) {
      this.logger.error('Failed to update category stats', error as Error);
    }
  }

  /**
   * 保存统计数据
   */
  private async saveStats(): Promise<void> {
    try {
      const statsToSave = {
        ...this.categoryStats,
        byType: Array.from(this.categoryStats.byType),
        byVisibility: Array.from(this.categoryStats.byVisibility)
      };
      
      await this.storageUtil.setObject(
        this.storageKeys.stats,
        statsToSave,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save category stats', error as Error);
    }
  }

  /**
   * 获取空的统计对象
   */
  private getEmptyStats(): CategoryStats {
    return {
      totalCategories: 0,
      activeCategories: 0,
      featuredCategories: 0,
      followedCategories: 0,
      byType: new Map(),
      byVisibility: new Map(),
      totalContentCount: 0,
      lastUpdated: Date.now()
    };
  }

  /**
   * 重置统计
   */
  private resetStats(): void {
    this.categoryStats = this.getEmptyStats();
  }

  /**
   * 搜索分类
   */
  public async searchCategories(searchTerm: string, limit: number = 10): Promise<Category[]> {
    try {
      const lowerTerm = searchTerm.toLowerCase();
      
      return Array.from(this.categories.values())
        .filter(category => 
          category.name.toLowerCase().includes(lowerTerm) ||
          category.slug.toLowerCase().includes(lowerTerm) ||
          (category.metadata.description && category.metadata.description.toLowerCase().includes(lowerTerm)) ||
          (category.metadata.tags && category.metadata.tags.some(tag => tag.toLowerCase().includes(lowerTerm)))
        )
        .sort((a, b) => {
          // 优先按名称匹配程度排序
          const aNameMatch = a.name.toLowerCase().includes(lowerTerm) ? 0 : 1;
          const bNameMatch = b.name.toLowerCase().includes(lowerTerm) ? 0 : 1;
          
          if (aNameMatch !== bNameMatch) {
            return aNameMatch - bNameMatch;
          }
          
          // 然后按观看次数排序
          return b.metadata.viewCount - a.metadata.viewCount;
        })
        .slice(0, limit);
    } catch (error) {
      this.logger.error('Failed to search categories', error as Error);
      return [];
    }
  }

  /**
   * 获取热门分类
   */
  public async getPopularCategories(limit: number = 10): Promise<Category[]> {
    try {
      return Array.from(this.categories.values())
        .filter(category => category.status === 'active' && category.visibility !== CategoryVisibility.HIDDEN)
        .sort((a, b) => {
          // 基于观看次数和关注者数量计算流行度
          const aPopularity = a.metadata.viewCount + (a.metadata.followerCount * 10);
          const bPopularity = b.metadata.viewCount + (b.metadata.followerCount * 10);
          return bPopularity - aPopularity;
        })
        .slice(0, limit);
    } catch (error) {
      this.logger.error('Failed to get popular categories', error as Error);
      return [];
    }
  }

  /**
   * 获取精选分类
   */
  public async getFeaturedCategories(): Promise<Category[]> {
    try {
      return Array.from(this.categories.values())
        .filter(category => 
          category.metadata.isFeatured && 
          category.status === 'active' && 
          category.visibility !== CategoryVisibility.HIDDEN
        )
        .sort((a, b) => (a.orderIndex || 0) - (b.orderIndex || 0));
    } catch (error) {
      this.logger.error('Failed to get featured categories', error as Error);
      return [];
    }
  }

  /**
   * 获取分类的子分类
   */
  public async getChildCategories(parentId: string): Promise<Category[]> {
    try {
      const parent = this.categories.get(parentId);
      
      if (!parent || !parent.metadata.childCategoryIds || parent.metadata.childCategoryIds.length === 0) {
        return [];
      }
      
      return parent.metadata.childCategoryIds
        .map(id => this.categories.get(id))
        .filter((category): category is Category => !!category)
        .sort((a, b) => (a.orderIndex || 0) - (b.orderIndex || 0));
    } catch (error) {
      this.logger.error(`Failed to get child categories for parent: ${parentId}`, error as Error);
      return [];
    }
  }

  /**
   * 获取分类的父分类
   */
  public async getParentCategory(categoryId: string): Promise<Category | null> {
    try {
      const category = this.categories.get(categoryId);
      
      if (!category || !category.metadata.parentCategoryId) {
        return null;
      }
      
      return this.categories.get(category.metadata.parentCategoryId) || null;
    } catch (error) {
      this.logger.error(`Failed to get parent category for: ${categoryId}`, error as Error);
      return null;
    }
  }

  /**
   * 获取分类的完整路径
   */
  public async getCategoryPath(categoryId: string): Promise<Category[]> {
    try {
      const path: Category[] = [];
      let currentId: string | undefined = categoryId;
      
      // 向上遍历，构建路径
      while (currentId) {
        const category = this.categories.get(currentId);
        
        if (!category) {
          break;
        }
        
        path.unshift(category);
        currentId = category.metadata.parentCategoryId;
      }
      
      return path;
    } catch (error) {
      this.logger.error(`Failed to get category path for: ${categoryId}`, error as Error);
      return [];
    }
  }

  /**
   * 清除所有缓存
   */
  public async clearCache(): Promise<void> {
    try {
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 清除缓存服务中的分类数据
      await this.cacheService.clearByType(CacheType.CATEGORY);
      
      // 重置同步时间，强制下次重新加载
      this.lastSyncTime = 0;
      await this.storageUtil.setNumber(
        this.storageKeys.lastSyncTime,
        this.lastSyncTime,
        LocalStorageType.DEFAULT
      );
      
      this.logger.info('Category cache cleared');
    } catch (error) {
      this.logger.error('Failed to clear category cache', error as Error);
    }
  }

  /**
   * 导出分类数据
   */
  public async exportCategories(): Promise<{
    categories: Category[];
    groups: CategoryGroup[];
    stats: CategoryStats;
    exportTime: number;
  }> {
    try {
      return {
        categories: Array.from(this.categories.values()),
        groups: Array.from(this.categoryGroups.values()),
        stats: await this.getStats(),
        exportTime: Date.now()
      };
    } catch (error) {
      this.logger.error('Failed to export categories', error as Error);
      throw error;
    }
  }

  /**
   * 导入分类数据
   */
  public async importCategories(data: {
    categories: Category[];
    groups?: CategoryGroup[];
    overwrite?: boolean;
  }): Promise<{
    importedCategories: number;
    importedGroups: number;
  }> {
    try {
      const { categories, groups, overwrite = false } = data;
      
      let importedCategories = 0;
      let importedGroups = 0;
      
      // 导入分类
      if (overwrite) {
        // 清空现有分类
        this.categories.clear();
      }
      
      categories.forEach(category => {
        this.categories.set(category.id, category);
        importedCategories++;
      });
      
      // 导入分组
      if (groups) {
        if (overwrite) {
          // 清空现有分组
          this.categoryGroups.clear();
        }
        
        groups.forEach(group => {
          this.categoryGroups.set(group.id, group);
          importedGroups++;
        });
      }
      
      // 保存数据
      await this.saveCategories();
      await this.saveGroups();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      this.logger.info(`Imported ${importedCategories} categories and ${importedGroups} groups`);
      
      return {
        importedCategories,
        importedGroups
      };
    } catch (error) {
      this.logger.error('Failed to import categories', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CategoryEvent);
      
      throw error;
    }
  }

  /**
   * 销毁仓库实例
   */
  public async destroy(): Promise<void> {
    try {
      // 停止自动同步
      this.stopAutoSync();
      
      // 清除缓存
      await this.clearCache();
      
      // 清空数据
      this.categories.clear();
      this.categoryGroups.clear();
      this.followedCategoryIds.clear();
      this.filterCache.clear();
      this.customOrder = [];
      
      // 重置统计
      this.resetStats();
      
      this.logger.info('CategoryRepository destroyed');
    } catch (error) {
      this.logger.error('Failed to destroy CategoryRepository', error as Error);
    }
  }

  /**
   * 检查分类名称是否已存在
   */
  public async isCategoryNameExists(name: string, excludeId?: string): Promise<boolean> {
    return Array.from(this.categories.values()).some(category => {
      return category.name.toLowerCase() === name.toLowerCase() && 
             (!excludeId || category.id !== excludeId);
    });
  }

  /**
   * 检查分类slug是否已存在
   */
  public async isCategorySlugExists(slug: string, excludeId?: string): Promise<boolean> {
    return Array.from(this.categories.values()).some(category => {
      return category.slug.toLowerCase() === slug.toLowerCase() && 
             (!excludeId || category.id !== excludeId);
    });
  }

  /**
   * 生成唯一的分类slug
   */
  public generateCategorySlug(name: string): string {
    let slug = name.toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '') // 移除特殊字符
      .replace(/\s+/g, '-') // 将空格替换为连字符
      .replace(/-+/g, '-') // 合并多个连字符
      .trim();
    
    // 如果slug为空，使用默认值
    if (!slug) {
      slug = 'category';
    }
    
    // 确保slug唯一
    let counter = 1;
    let originalSlug = slug;
    
    while (this.isCategorySlugExists(slug)) {
      slug = `${originalSlug}-${counter}`;
      counter++;
    }
    
    return slug;
  }
}

// 导出CategoryEventType常量
export { CategoryEventType };