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
  
  // 分类数据存储
  private categories: Map<string, Category> = new Map();
  private groups: Map<string, CategoryGroup> = new Map();
  private followedCategories: Set<string> = new Set();
  private customOrder: Map<string, number> = new Map();
  
  // 统计信息
  private stats: CategoryStats = {
    totalCategories: 0,
    activeCategories: 0,
    featuredCategories: 0,
    followedCategories: 0,
    byType: new Map(),
    byVisibility: new Map(),
    totalContentCount: 0,
    lastUpdated: 0
  };
  
  // 同步状态
  private lastSyncTime: number = 0;
  private isSyncing: boolean = false;
  private syncTimer: number | null = null;
  
  // 初始化状态
  private initialized: boolean = false;
  
  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('CategoryRepository initialized');
    this.setupEventListeners();
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
   * @param config 存储配置
   */
  public async initialize(config?: Partial<CategoryStorageConfig>): Promise<void> {
    try {
      if (this.initialized) {
        this.logger.warn('CategoryRepository already initialized');
        return;
      }
      
      // 更新配置
      if (config) {
        this.storageConfig = { ...this.storageConfig, ...config };
      }
      
      // 加载本地数据
      await this.loadLocalData();
      
      // 启动自动同步
      if (this.storageConfig.autoSync) {
        this.startAutoSync();
      }
      
      this.initialized = true;
      this.logger.info('CategoryRepository initialized successfully', {
        persistCategories: this.storageConfig.persistCategories,
        autoSync: this.storageConfig.autoSync,
        offlineMode: this.storageConfig.offlineMode
      });
      
      // 发布加载完成事件
      this.eventBus.emit(CategoryEventType.LOADED, {
        type: CategoryEventType.LOADED,
        timestamp: Date.now(),
        categories: Array.from(this.categories.values())
      });
    } catch (error) {
      this.logger.error('Failed to initialize CategoryRepository', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听网络状态变化
    this.eventBus.on('network:online', () => {
      this.onNetworkOnline();
    });
    
    this.eventBus.on('network:offline', () => {
      this.onNetworkOffline();
    });
    
    // 监听应用退出事件
    this.eventBus.on('app:exit', async () => {
      await this.shutdown();
    });
  }

  /**
   * 加载本地数据
   */
  private async loadLocalData(): Promise<void> {
    try {
      // 加载分类数据
      const categoriesData = await this.storageUtil.get(LocalStorageType.CATEGORIES);
      if (categoriesData) {
        const categories = JSON.parse(categoriesData) as Category[];
        this.categories.clear();
        categories.forEach(category => {
          this.categories.set(category.id, category);
        });
      }
      
      // 加载分组数据
      const groupsData = await this.storageUtil.get(LocalStorageType.CATEGORY_GROUPS);
      if (groupsData) {
        const groups = JSON.parse(groupsData) as CategoryGroup[];
        this.groups.clear();
        groups.forEach(group => {
          this.groups.set(group.id, group);
        });
      }
      
      // 加载关注分类
      const followedData = await this.storageUtil.get(LocalStorageType.FOLLOWED_CATEGORIES);
      if (followedData) {
        const followed = JSON.parse(followedData) as string[];
        this.followedCategories = new Set(followed);
      }
      
      // 加载自定义排序
      const orderData = await this.storageUtil.get(LocalStorageType.CATEGORY_CUSTOM_ORDER);
      if (orderData) {
        const order = JSON.parse(orderData) as Record<string, number>;
        this.customOrder.clear();
        Object.entries(order).forEach(([id, index]) => {
          this.customOrder.set(id, index);
        });
      }
      
      // 加载统计信息
      const statsData = await this.storageUtil.get(LocalStorageType.CATEGORY_STATS);
      if (statsData) {
        this.stats = JSON.parse(statsData) as CategoryStats;
      }
      
      // 加载最后同步时间
      const syncTimeData = await this.storageUtil.get(LocalStorageType.LAST_SYNC_TIME);
      if (syncTimeData) {
        this.lastSyncTime = parseInt(syncTimeData);
      }
      
      // 更新统计信息
      this.updateStats();
      
      this.logger.info('Local category data loaded', {
        categories: this.categories.size,
        groups: this.groups.size,
        followed: this.followedCategories.size
      });
    } catch (error) {
      this.logger.warn('Failed to load local category data', error as Error);
    }
  }

  /**
   * 保存本地数据
   */
  private async saveLocalData(): Promise<void> {
    if (!this.storageConfig.persistCategories) {
      return;
    }
    
    try {
      // 保存分类数据
      const categories = Array.from(this.categories.values());
      await this.storageUtil.set(
        LocalStorageType.CATEGORIES,
        JSON.stringify(categories)
      );
      
      // 保存分组数据
      const groups = Array.from(this.groups.values());
      await this.storageUtil.set(
        LocalStorageType.CATEGORY_GROUPS,
        JSON.stringify(groups)
      );
      
      // 保存关注分类
      const followed = Array.from(this.followedCategories);
      await this.storageUtil.set(
        LocalStorageType.FOLLOWED_CATEGORIES,
        JSON.stringify(followed)
      );
      
      // 保存自定义排序
      const order = Object.fromEntries(this.customOrder);
      await this.storageUtil.set(
        LocalStorageType.CATEGORY_CUSTOM_ORDER,
        JSON.stringify(order)
      );
      
      // 保存统计信息
      await this.storageUtil.set(
        LocalStorageType.CATEGORY_STATS,
        JSON.stringify(this.stats)
      );
      
      // 保存最后同步时间
      await this.storageUtil.set(
        LocalStorageType.LAST_SYNC_TIME,
        this.lastSyncTime.toString()
      );
      
      this.logger.debug('Local category data saved');
    } catch (error) {
      this.logger.warn('Failed to save local category data', error as Error);
    }
  }

  /**
   * 启动自动同步
   */
  private startAutoSync(): void {
    if (this.syncTimer) {
      clearInterval(this.syncTimer);
    }
    
    this.syncTimer = setInterval(async () => {
      if (!this.isSyncing && this.shouldSync()) {
        await this.syncCategories();
      }
    }, this.storageConfig.syncInterval) as unknown as number;
  }

  /**
   * 停止自动同步
   */
  private stopAutoSync(): void {
    if (this.syncTimer) {
      clearInterval(this.syncTimer);
      this.syncTimer = null;
    }
  }

  /**
   * 检查是否需要同步
   */
  private shouldSync(): boolean {
    const now = Date.now();
    const timeSinceLastSync = now - this.lastSyncTime;
    return timeSinceLastSync >= this.storageConfig.cacheTTL;
  }

  /**
   * 网络在线处理
   */
  private onNetworkOnline(): void {
    this.logger.info('Network online, checking for category sync');
    
    if (this.shouldSync()) {
      this.syncCategories();
    }
  }

  /**
   * 网络离线处理
   */
  private onNetworkOffline(): void {
    this.logger.info('Network offline, category sync paused');
    this.storageConfig.offlineMode = true;
  }

  /**
   * 同步分类数据
   */
  public async syncCategories(): Promise<void> {
    if (this.isSyncing) {
      this.logger.warn('Category sync already in progress');
      return;
    }
    
    if (this.storageConfig.offlineMode) {
      this.logger.info('Category sync skipped (offline mode)');
      return;
    }
    
    this.isSyncing = true;
    
    try {
      this.logger.info('Starting category sync');
      
      // 从API获取分类数据
      const response = await this.fetchCategoriesFromAPI();
      
      if (response) {
        // 更新分类数据
        await this.updateCategories(response.categories);
        
        // 更新分组数据
        if (response.groups) {
          await this.updateGroups(response.groups);
        }
        
        // 更新最后同步时间
        this.lastSyncTime = Date.now();
        
        // 保存本地数据
        await this.saveLocalData();
        
        // 发布同步完成事件
        this.eventBus.emit(CategoryEventType.SYNCED, {
          type: CategoryEventType.SYNCED,
          timestamp: this.lastSyncTime,
          categories: response.categories,
          cacheHit: response.cacheHit
        });
        
        this.logger.info('Category sync completed', {
          categories: response.categories.length,
          groups: response.groups?.length || 0,
          cacheHit: response.cacheHit
        });
      }
    } catch (error) {
      this.logger.error('Category sync failed', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * 从API获取分类数据
   */
  private async fetchCategoriesFromAPI(): Promise<CategoryResponse | null> {
    try {
      // 构建请求URL
      const url = '/api/categories';
      const cacheKey = `categories:${Date.now()}`;
      
      // 尝试从缓存获取
      const cachedResponse = await this.cacheService.getCache<CategoryResponse>(cacheKey);
      if (cachedResponse) {
        this.logger.debug('Category data loaded from cache');
        return { ...cachedResponse, cacheHit: true };
      }
      
      // 从网络获取
      const response = await this.networkUtil.get(url);
      
      if (response.success && response.data) {
        const categoryResponse = response.data as CategoryResponse;
        
        // 缓存响应数据
        await this.cacheService.setCache(cacheKey, categoryResponse, {
          expiry: this.storageConfig.cacheTTL,
          type: CacheType.MEMORY_DISK,
          policy: CachePolicy.STANDARD
        });
        
        return categoryResponse;
      }
      
      return null;
    } catch (error) {
      this.logger.error('Failed to fetch categories from API', error as Error);
      throw error;
    }
  }

  /**
   * 更新分类数据
   */
  private async updateCategories(newCategories: Category[]): Promise<void> {
    const updatedCategories: Category[] = [];
    const createdCategories: Category[] = [];
    
    for (const newCategory of newCategories) {
      const existingCategory = this.categories.get(newCategory.id);
      
      if (existingCategory) {
        // 更新现有分类
        const updatedCategory = { ...existingCategory, ...newCategory };
        this.categories.set(newCategory.id, updatedCategory);
        updatedCategories.push(updatedCategory);
      } else {
        // 添加新分类
        this.categories.set(newCategory.id, newCategory);
        createdCategories.push(newCategory);
      }
    }
    
    // 发布事件
    if (createdCategories.length > 0) {
      this.eventBus.emit(CategoryEventType.CREATED, {
        type: CategoryEventType.CREATED,
        timestamp: Date.now(),
        categories: createdCategories
      });
    }
    
    if (updatedCategories.length > 0) {
      this.eventBus.emit(CategoryEventType.UPDATED, {
        type: CategoryEventType.UPDATED,
        timestamp: Date.now(),
        categories: updatedCategories
      });
    }
    
    // 更新统计信息
    this.updateStats();
  }

  /**
   * 更新分组数据
   */
  private async updateGroups(newGroups: CategoryGroup[]): Promise<void> {
    const updatedGroups: CategoryGroup[] = [];
    const createdGroups: CategoryGroup[] = [];
    
    for (const newGroup of newGroups) {
      const existingGroup = this.groups.get(newGroup.id);
      
      if (existingGroup) {
        // 更新现有分组
        const updatedGroup = { ...existingGroup, ...newGroup };
        this.groups.set(newGroup.id, updatedGroup);
        updatedGroups.push(updatedGroup);
      } else {
        // 添加新分组
        this.groups.set(newGroup.id, newGroup);
        createdGroups.push(newGroup);
      }
    }
    
    // 发布事件
    if (createdGroups.length > 0) {
      this.eventBus.emit(CategoryEventType.GROUP_CREATED, {
        type: CategoryEventType.GROUP_CREATED,
        timestamp: Date.now(),
        groups: createdGroups
      });
    }
    
    if (updatedGroups.length > 0) {
      this.eventBus.emit(CategoryEventType.GROUP_UPDATED, {
        type: CategoryEventType.GROUP_UPDATED,
        timestamp: Date.now(),
        groups: updatedGroups
      });
    }
  }

  /**
   * 更新统计信息
   */
  private updateStats(): void {
    const now = Date.now();
    
    // 重置统计信息
    this.stats = {
      totalCategories: this.categories.size,
      activeCategories: 0,
      featuredCategories: 0,
      followedCategories: this.followedCategories.size,
      byType: new Map(),
      byVisibility: new Map(),
      totalContentCount: 0,
      lastUpdated: now
    };
    
    // 计算统计信息
    for (const category of this.categories.values()) {
      // 按类型统计
      const typeCount = this.stats.byType.get(category.type) || 0;
      this.stats.byType.set(category.type, typeCount + 1);
      
      // 按可见性统计
      const visibilityCount = this.stats.byVisibility.get(category.visibility) || 0;
      this.stats.byVisibility.set(category.visibility, visibilityCount + 1);
      
      // 统计活跃分类
      if (category.status === 'active') {
        this.stats.activeCategories++;
      }
      
      // 统计精选分类
      if (category.metadata.isFeatured) {
        this.stats.featuredCategories++;
      }
      
      // 统计内容总数
      this.stats.totalContentCount += category.metadata.contentCount;
    }
    
    // 发布统计更新事件
    this.eventBus.emit(CategoryEventType.CONTENT_COUNT_CHANGED, {
      type: CategoryEventType.CONTENT_COUNT_CHANGED,
      timestamp: now,
      contentCount: this.stats.totalContentCount
    });
  }

  /**
   * 获取分类列表
   * @param request 分类请求
   */
  public async getCategories(request?: CategoryRequest): Promise<CategoryResponse> {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    try {
      // 检查是否需要同步
      if (this.shouldSync() && !this.isSyncing) {
        this.syncCategories();
      }
      
      // 获取所有分类
      let categories = Array.from(this.categories.values());
      
      // 应用过滤器
      if (request?.filter) {
        categories = this.filterCategories(categories, request.filter);
      }
      
      // 应用排序
      categories = this.sortCategories(categories, request?.filter?.sortBy);
      
      // 应用分页
      const limit = request?.filter?.limit || 50;
      const offset = request?.filter?.offset || 0;
      const paginatedCategories = categories.slice(offset, offset + limit);
      
      // 构建响应
      const response: CategoryResponse = {
        categories: paginatedCategories,
        totalCount: categories.length,
        hasMore: offset + limit < categories.length,
        timestamp: Date.now()
      };
      
      // 包含分组信息
      if (request?.includeGroups) {
        response.groups = Array.from(this.groups.values());
      }
      
      this.logger.debug('Categories retrieved', {
        total: categories.length,
        returned: paginatedCategories.length,
        hasMore: response.hasMore
      });
      
      return response;
    } catch (error) {
      this.logger.error('Failed to get categories', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 根据ID获取分类
   * @param id 分类ID
   */
  public getCategoryById(id: string): Category | null {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    return this.categories.get(id) || null;
  }

  /**
   * 根据slug获取分类
   * @param slug 分类slug
   */
  public getCategoryBySlug(slug: string): Category | null {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    for (const category of this.categories.values()) {
      if (category.slug === slug) {
        return category;
      }
    }
    
    return null;
  }

  /**
   * 获取分类组列表
   */
  public getCategoryGroups(): CategoryGroup[] {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    return Array.from(this.groups.values());
  }

  /**
   * 获取分类统计信息
   */
  public getCategoryStats(): CategoryStats {
    return { ...this.stats };
  }

  /**
   * 关注分类
   * @param categoryId 分类ID
   */
  public async followCategory(categoryId: string): Promise<void> {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    try {
      const category = this.categories.get(categoryId);
      if (!category) {
        throw new Error(`Category not found: ${categoryId}`);
      }
      
      // 添加关注
      this.followedCategories.add(categoryId);
      
      // 更新分类元数据
      category.metadata.isFollowing = true;
      category.metadata.followerCount++;
      
      // 保存本地数据
      await this.saveLocalData();
      
      // 发布关注事件
      this.eventBus.emit(CategoryEventType.FOLLOWED, {
        type: CategoryEventType.FOLLOWED,
        timestamp: Date.now(),
        category,
        contentCount: category.metadata.contentCount
      });
      
      this.logger.info(`Category followed: ${category.name}`);
    } catch (error) {
      this.logger.error(`Failed to follow category: ${categoryId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 取消关注分类
   * @param categoryId 分类ID
   */
  public async unfollowCategory(categoryId: string): Promise<void> {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    try {
      const category = this.categories.get(categoryId);
      if (!category) {
        throw new Error(`Category not found: ${categoryId}`);
      }
      
      // 移除关注
      this.followedCategories.delete(categoryId);
      
      // 更新分类元数据
      category.metadata.isFollowing = false;
      category.metadata.followerCount = Math.max(0, category.metadata.followerCount - 1);
      
      // 保存本地数据
      await this.saveLocalData();
      
      // 发布取消关注事件
      this.eventBus.emit(CategoryEventType.UNFOLLOWED, {
        type: CategoryEventType.UNFOLLOWED,
        timestamp: Date.now(),
        category,
        contentCount: category.metadata.contentCount
      });
      
      this.logger.info(`Category unfollowed: ${category.name}`);
    } catch (error) {
      this.logger.error(`Failed to unfollow category: ${categoryId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 检查是否已关注分类
   * @param categoryId 分类ID
   */
  public isCategoryFollowed(categoryId: string): boolean {
    if (!this.initialized) {
      return false;
    }
    
    return this.followedCategories.has(categoryId);
  }

  /**
   * 获取已关注的分类列表
   */
  public getFollowedCategories(): Category[] {
    if (!this.initialized) {
      return [];
    }
    
    const followed: Category[] = [];
    
    for (const categoryId of this.followedCategories) {
      const category = this.categories.get(categoryId);
      if (category) {
        followed.push(category);
      }
    }
    
    return followed;
  }

  /**
   * 设置分类自定义排序
   * @param categoryId 分类ID
   * @param orderIndex 排序索引
   */
  public async setCategoryOrder(categoryId: string, orderIndex: number): Promise<void> {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    try {
      const category = this.categories.get(categoryId);
      if (!category) {
        throw new Error(`Category not found: ${categoryId}`);
      }
      
      // 更新排序索引
      this.customOrder.set(categoryId, orderIndex);
      category.orderIndex = orderIndex;
      
      // 保存本地数据
      await this.saveLocalData();
      
      // 发布重新排序事件
      this.eventBus.emit(CategoryEventType.REORDERED, {
        type: CategoryEventType.REORDERED,
        timestamp: Date.now(),
        category,
        previousOrderIndex: category.orderIndex
      });
      
      this.logger.debug(`Category order updated: ${category.name} -> ${orderIndex}`);
    } catch (error) {
      this.logger.error(`Failed to set category order: ${categoryId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 批量更新分类
   * @param categories 分类列表
   */
  public async updateCategoriesBatch(categories: Category[]): Promise<void> {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    try {
      const updatedCategories: Category[] = [];
      
      for (const category of categories) {
        const existingCategory = this.categories.get(category.id);
        
        if (existingCategory) {
          // 更新现有分类
          const updatedCategory = { ...existingCategory, ...category };
          this.categories.set(category.id, updatedCategory);
          updatedCategories.push(updatedCategory);
        } else {
          // 添加新分类
          this.categories.set(category.id, category);
          updatedCategories.push(category);
        }
      }
      
      // 保存本地数据
      await this.saveLocalData();
      
      // 发布批量更新事件
      this.eventBus.emit(CategoryEventType.BATCH_UPDATED, {
        type: CategoryEventType.BATCH_UPDATED,
        timestamp: Date.now(),
        categories: updatedCategories
      });
      
      this.logger.info(`Categories batch updated: ${updatedCategories.length} categories`);
    } catch (error) {
      this.logger.error('Failed to update categories batch', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 过滤分类
   */
  private filterCategories(categories: Category[], filter: CategoryFilter): Category[] {
    return categories.filter(category => {
      // 检查类型
      if (filter.types && filter.types.length > 0 && !filter.types.includes(category.type)) {
        return false;
      }
      
      // 检查可见性
      if (filter.visibility && filter.visibility.length > 0 && !filter.visibility.includes(category.visibility)) {
        return false;
      }
      
      // 检查搜索词
      if (filter.searchTerm) {
        const searchTerm = filter.searchTerm.toLowerCase();
        const nameMatch = category.name.toLowerCase().includes(searchTerm);
        const slugMatch = category.slug.toLowerCase().includes(searchTerm);
        const descMatch = category.metadata.description?.toLowerCase().includes(searchTerm);
        
        if (!nameMatch && !slugMatch && !descMatch) {
          return false;
        }
      }
      
      // 检查父分类ID
      if (filter.parentId && category.metadata.parentCategoryId !== filter.parentId) {
        return false;
      }
      
      // 检查子分类
      if (filter.childOf && (!category.metadata.childCategoryIds || !category.metadata.childCategoryIds.includes(filter.childOf))) {
        return false;
      }
      
      // 检查状态
      if (filter.status && filter.status.length > 0 && !filter.status.includes(category.status)) {
        return false;
      }
      
      // 检查精选状态
      if (filter.featured !== undefined && category.metadata.isFeatured !== filter.featured) {
        return false;
      }
      
      // 检查关注状态
      if (filter.followed !== undefined && this.followedCategories.has(category.id) !== filter.followed) {
        return false;
      }
      
      // 检查内容数量范围
      if (filter.contentCountMin && category.metadata.contentCount < filter.contentCountMin) {
        return false;
      }
      
      if (filter.contentCountMax && category.metadata.contentCount > filter.contentCountMax) {
        return false;
      }
      
      // 检查标签
      if (filter.tags && filter.tags.length > 0) {
        const hasMatchingTag = filter.tags.some(tag => category.metadata.tags?.includes(tag));
        if (!hasMatchingTag) {
          return false;
        }
      }
      
      // 检查语言
      if (filter.lang && category.localization && !category.localization[filter.lang]) {
        return false;
      }
      
      // 检查地区
      if (filter.region && category.metadata.restrictedCountries?.includes(filter.region)) {
        return false;
      }
      
      return true;
    });
  }

  /**
   * 排序分类
   */
  private sortCategories(categories: Category[], sortBy?: CategorySortType): Category[] {
    if (!sortBy) {
      return categories;
    }
    
    return [...categories].sort((a, b) => {
      switch (sortBy) {
        case CategorySortType.NAME_ASC:
          return a.name.localeCompare(b.name);
        
        case CategorySortType.NAME_DESC:
          return b.name.localeCompare(a.name);
        
        case CategorySortType.POPULARITY:
          return (b.metadata.viewCount || 0) - (a.metadata.viewCount || 0);
        
        case CategorySortType.TRENDING:
          // 简化实现：基于最后更新时间
          return (b.metadata.lastUpdated || 0) - (a.metadata.lastUpdated || 0);
        
        case CategorySortType.RECENTLY_ADDED:
          return (b.metadata.createdAt || 0) - (a.metadata.createdAt || 0);
        
        case CategorySortType.CONTENT_COUNT:
          return (b.metadata.contentCount || 0) - (a.metadata.contentCount || 0);
        
        case CategorySortType.CUSTOM:
          const aOrder = this.customOrder.get(a.id) || a.orderIndex || 0;
          const bOrder = this.customOrder.get(b.id) || b.orderIndex || 0;
          return aOrder - bOrder;
        
        default:
          return 0;
      }
    });
  }

  /**
   * 关闭分类仓库
   */
  public async shutdown(): Promise<void> {
    if (!this.initialized) {
      return;
    }
    
    try {
      // 停止自动同步
      this.stopAutoSync();
      
      // 保存本地数据
      await this.saveLocalData();
      
      // 清空数据
      this.categories.clear();
      this.groups.clear();
      this.followedCategories.clear();
      this.customOrder.clear();
      
      this.initialized = false;
      this.logger.info('CategoryRepository shutdown');
    } catch (error) {
      this.logger.error('Failed to shutdown CategoryRepository', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
      
      throw error;
    }
  }
}