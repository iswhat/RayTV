// CategoryRepository - 鍒嗙被浠撳簱
// 璐熻矗绠＄悊瑙嗛鍜岀洿鎾殑鍒嗙被鏁版嵁

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import ObjectUtils from '../../common/util/ark/ObjectUtils';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType, CachePolicy } from '../model/CacheModel';

/**
 * 鍒嗙被绫诲瀷鏋氫妇
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
 * 鍒嗙被鍙鎬ф灇涓?
 */
export enum CategoryVisibility {
  PUBLIC = 'public',
  PRIVATE = 'private',
  RESTRICTED = 'restricted',
  FEATURED = 'featured',
  HIDDEN = 'hidden'
}

/**
 * 鍒嗙被鎺掑簭绫诲瀷鏋氫妇
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
 * 鍒嗙被鍥炬爣绫诲瀷鏋氫妇
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
 * 鍒嗙被鍥炬爣鎺ュ彛
 */
export interface CategoryIcon {
  type: CategoryIconType;
  value: string; // 鍥炬爣鍚嶇О銆佸浘鐗嘦RL鎴杄moji
  color?: string;
  backgroundColor?: string;
  size?: number;
}

/**
 * 鍒嗙被鍏冩暟鎹帴鍙?
 */
export interface CategoryMetadata {
  viewCount: number; // 娴忚娆℃暟
  contentCount: number; // 鍐呭鏁伴噺
  followerCount: number; // 鍏虫敞鑰呮暟閲?
  isFollowing?: boolean; // 褰撳墠鐢ㄦ埛鏄惁鍏虫敞
  isFeatured?: boolean; // 鏄惁绮鹃€?
  lastUpdated: number; // 鏈€鍚庢洿鏂版椂闂?
  createdAt: number; // 鍒涘缓鏃堕棿
  updatedBy?: string; // 鏇存柊鑰匢D
  createdBy?: string; // 鍒涘缓鑰匢D
  parentCategoryId?: string; // 鐖跺垎绫籌D
  childCategoryIds?: string[]; // 瀛愬垎绫籌D鍒楄〃
  relatedCategoryIds?: string[]; // 鐩稿叧鍒嗙被ID鍒楄〃
  allowedUserIds?: string[]; // 鍏佽璁块棶鐨勭敤鎴稩D鍒楄〃锛堢鏈夊垎绫伙級
  restrictedCountries?: string[]; // 闄愬埗璁块棶鐨勫浗瀹跺垪琛?
  tags?: string[]; // 鍒嗙被鏍囩
  description?: string; // 璇︾粏鎻忚堪
  coverImageUrl?: string; // 灏侀潰鍥剧墖URL
  bannerImageUrl?: string; // 妯箙鍥剧墖URL
  icon?: CategoryIcon; // 鍒嗙被鍥炬爣
}

/**
 * 鍒嗙被鎺ュ彛
 */
export interface Category {
  id: string; // 鍒嗙被ID
  name: string; // 鍒嗙被鍚嶇О
  type: CategoryType; // 鍒嗙被绫诲瀷
  visibility: CategoryVisibility; // 鍙鎬?
  slug: string; // URL鍙嬪ソ鐨勬爣璇?
  metadata: CategoryMetadata; // 鍏冩暟鎹?
  orderIndex?: number; // 鎺掑簭绱㈠紩
  status: 'active' | 'inactive' | 'pending' | 'deprecated'; // 鐘舵€?
  localization?: Record<string, { // 鏈湴鍖栨暟鎹?
    name: string;
    description?: string;
    slug?: string;
  }>;
}

/**
 * 鍒嗙被缁勬帴鍙?
 */
export interface CategoryGroup {
  id: string; // 缁処D
  name: string; // 缁勫悕绉?
  description?: string; // 缁勬弿杩?
  categoryIds: string[]; // 鍒嗙被ID鍒楄〃
  orderIndex?: number; // 鎺掑簭绱㈠紩
  isExpanded?: boolean; // 鏄惁灞曞紑
  icon?: CategoryIcon; // 缁勫浘鏍?
  createdAt: number; // 鍒涘缓鏃堕棿
  updatedAt: number; // 鏇存柊鏃堕棿
}

/**
 * 鍒嗙被浜嬩欢绫诲瀷
 */
export const CategoryEventType = {
  // 鍒嗙被鐢熷懡鍛ㄦ湡浜嬩欢
  CREATED: 'category:created',
  UPDATED: 'category:updated',
  DELETED: 'category:deleted',
  ACTIVATED: 'category:activated',
  DEACTIVATED: 'category:deactivated',
  
  // 鐘舵€佸彉鏇翠簨浠?
  VISIBILITY_CHANGED: 'category:visibilityChanged',
  FOLLOWED: 'category:followed',
  UNFOLLOWED: 'category:unfollowed',
  
  // 鍐呭浜嬩欢
  CONTENT_ADDED: 'category:contentAdded',
  CONTENT_REMOVED: 'category:contentRemoved',
  CONTENT_COUNT_CHANGED: 'category:contentCountChanged',
  
  // 缁勪簨浠?
  GROUP_CREATED: 'category:groupCreated',
  GROUP_UPDATED: 'category:groupUpdated',
  GROUP_DELETED: 'category:groupDeleted',
  
  // 鎵归噺浜嬩欢
  BATCH_UPDATED: 'category:batchUpdated',
  REORDERED: 'category:reordered',
  
  // 鍔犺浇浜嬩欢
  LOADED: 'category:loaded',
  SYNCED: 'category:synced',
  
  // 閿欒浜嬩欢
  ERROR: 'category:error'
} as const;

/**
 * 鍒嗙被浜嬩欢鏁版嵁
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
 * 鍒嗙被杩囨护鏉′欢鎺ュ彛
 */
export interface CategoryFilter {
  types?: CategoryType[]; // 鍒嗙被绫诲瀷
  visibility?: CategoryVisibility[]; // 鍙鎬?
  searchTerm?: string; // 鎼滅储璇?
  parentId?: string; // 鐖跺垎绫籌D
  childOf?: string; // 瀛愬垎绫荤瓫閫?
  status?: string[]; // 鐘舵€?
  featured?: boolean; // 鏄惁绮鹃€?
  followed?: boolean; // 鏄惁宸插叧娉?
  contentCountMin?: number; // 鍐呭鏁伴噺涓嬮檺
  contentCountMax?: number; // 鍐呭鏁伴噺涓婇檺
  tags?: string[]; // 鏍囩绛涢€?
  sortBy?: CategorySortType; // 鎺掑簭鏂瑰紡
  limit?: number; // 鏁伴噺闄愬埗
  offset?: number; // 鍋忕Щ閲?
  lang?: string; // 璇█绛涢€?
  region?: string; // 鍦板尯绛涢€?
}

/**
 * 鍒嗙被璇锋眰鎺ュ彛
 */
export interface CategoryRequest {
  filter?: CategoryFilter;
  includeMetadata?: boolean; // 鏄惁鍖呭惈鍏冩暟鎹?
  includeGroups?: boolean; // 鏄惁鍖呭惈鍒嗙粍
  includeLocalization?: boolean; // 鏄惁鍖呭惈鏈湴鍖?
  includeChildCategories?: boolean; // 鏄惁鍖呭惈瀛愬垎绫?
  includeContentCount?: boolean; // 鏄惁鍖呭惈鍐呭璁℃暟
  cachePolicy?: CachePolicy; // 缂撳瓨绛栫暐
}

/**
 * 鍒嗙被鍝嶅簲鎺ュ彛
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
 * 鍒嗙被缁熻鎺ュ彛
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
 * 鍒嗙被瀛樺偍閰嶇疆鎺ュ彛
 */
export interface CategoryStorageConfig {
  cacheTTL: number; // 缂撳瓨杩囨湡鏃堕棿锛堟绉掞級
  maxCacheItems: number; // 鏈€澶х紦瀛橀」鏁?
  persistCategories: boolean; // 鏄惁鎸佷箙鍖栧垎绫?
  autoSync: boolean; // 鏄惁鑷姩鍚屾
  syncInterval: number; // 鍚屾闂撮殧锛堟绉掞級
  offlineMode: boolean; // 绂荤嚎妯″紡
}

/**
 * 鍒嗙被浠撳簱 */
export class CategoryRepository {
  private static instance: CategoryRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  
  // 瀛樺偍閿厤缃?
  private storageKeys = {
    categories: 'category:categories',
    groups: 'category:groups',
    stats: 'category:stats',
    followed: 'category:followed',
    config: 'category:config',
    lastSyncTime: 'category:lastSyncTime',
    customOrder: 'category:customOrder'
  };
  
  // 榛樿瀛樺偍閰嶇疆
  private defaultStorageConfig: CategoryStorageConfig = {
    cacheTTL: 3600000, // 1灏忔椂
    maxCacheItems: 1000,
    persistCategories: true,
    autoSync: true,
    syncInterval: 1800000, // 30鍒嗛挓
    offlineMode: false
  };
  
  // 瀛樺偍閰嶇疆
  private storageConfig: CategoryStorageConfig = { ...this.defaultStorageConfig };
  
  // 鍒嗙被鏁版嵁瀛樺偍
  private categories: Map<string, Category> = new Map();
  private groups: Map<string, CategoryGroup> = new Map();
  private followedCategories: Set<string> = new Set();
  private customOrder: Map<string, number> = new Map();
  
  // 缁熻淇℃伅
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
  
  // 鍚屾鐘舵€?
  private lastSyncTime: number = 0;
  private isSyncing: boolean = false;
  private syncTimer: number | null = null;
  
  // 鍒濆鍖栫姸鎬?
  private initialized: boolean = false;
  
  /**
   * 绉佹湁鏋勯€犲嚱鏁?
   */
  private constructor() {
    this.logger.info('CategoryRepository initialized');
    this.setupEventListeners();
  }

  /**
   * 鑾峰彇CategoryRepository鍗曚緥瀹炰緥
   */
  public static getInstance(): CategoryRepository {
    if (!CategoryRepository.instance) {
      CategoryRepository.instance = new CategoryRepository();
    }
    return CategoryRepository.instance;
  }

  /**
   * 鍒濆鍖栧垎绫讳粨搴?  * @param config 瀛樺偍閰嶇疆
   */
  public async initialize(config?: Partial<CategoryStorageConfig>): Promise<void> {
    try {
      if (this.initialized) {
        this.logger.warn('CategoryRepository already initialized');
        return;
      }
      
      // 鏇存柊閰嶇疆
      if (config) {
        this.storageConfig = { ...this.storageConfig, ...config };
      }
      
      // 鍔犺浇鏈湴鏁版嵁
      await this.loadLocalData();
      
      // 鍚姩鑷姩鍚屾
      if (this.storageConfig.autoSync) {
        this.startAutoSync();
      }
      
      this.initialized = true;
      this.logger.info('CategoryRepository initialized successfully', {
        persistCategories: this.storageConfig.persistCategories,
        autoSync: this.storageConfig.autoSync,
        offlineMode: this.storageConfig.offlineMode
      });
      
      // 鍙戝竷鍔犺浇瀹屾垚浜嬩欢
      this.eventBus.emit(CategoryEventType.LOADED, {
        type: CategoryEventType.LOADED,
        timestamp: Date.now(),
        categories: Array.from(this.categories.values())
      });
    } catch (error) {
      this.logger.error('Failed to initialize CategoryRepository', error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
    }
  }

  /**
   * 璁剧疆浜嬩欢鐩戝惉鍣?   */
  private setupEventListeners(): void {
    // 鐩戝惉缃戠粶鐘舵€佸彉鍖?    this.eventBus.on('network:online', () => {
      this.onNetworkOnline();
    });
    
    this.eventBus.on('network:offline', () => {
      this.onNetworkOffline();
    });
    
    // 鐩戝惉搴旂敤閫€鍑轰簨浠?    this.eventBus.on('app:exit', async () => {
      await this.shutdown();
    });
  }

  /**
   * 鍔犺浇鏈湴鏁版嵁
   */
  private async loadLocalData(): Promise<void> {
    try {
      // 鍔犺浇鍒嗙被鏁版嵁
      const categoriesData = await this.storageUtil.get(LocalStorageType.CATEGORIES);
      if (categoriesData) {
        const categories = JSON.parse(categoriesData) as Category[];
        this.categories.clear();
        categories.forEach(category => {
          this.categories.set(category.id, category);
        });
      }
      
      // 鍔犺浇鍒嗙粍鏁版嵁
      const groupsData = await this.storageUtil.get(LocalStorageType.CATEGORY_GROUPS);
      if (groupsData) {
        const groups = JSON.parse(groupsData) as CategoryGroup[];
        this.groups.clear();
        groups.forEach(group => {
          this.groups.set(group.id, group);
        });
      }
      
      // 鍔犺浇鍏虫敞鍒嗙被
      const followedData = await this.storageUtil.get(LocalStorageType.FOLLOWED_CATEGORIES);
      if (followedData) {
        const followed = JSON.parse(followedData) as string[];
        this.followedCategories = new Set(followed);
      }
      
      // 鍔犺浇鑷畾涔夋帓搴?
     const orderData = await this.storageUtil.get(LocalStorageType.CATEGORY_CUSTOM_ORDER);
      if (orderData) {
        const order = JSON.parse(orderData) as Record<string, number>;
        this.customOrder.clear();
        const entries = ObjectUtils.getEntries<number>(order);
        for (let i = 0; i < entries.length; i++) {
          const [id, index] = entries[i];
          this.customOrder.set(id, index);
        }
      }
      
      // 鍔犺浇缁熻淇℃伅
      const statsData = await this.storageUtil.get(LocalStorageType.CATEGORY_STATS);
      if (statsData) {
        this.stats = JSON.parse(statsData) as CategoryStats;
      }
      
      // 鍔犺浇鏈€鍚庡悓姝ユ椂闂?     const syncTimeData = await this.storageUtil.get(LocalStorageType.LAST_SYNC_TIME);
      if (syncTimeData) {
        this.lastSyncTime = parseInt(syncTimeData);
      }
      
      // 鏇存柊缁熻淇℃伅
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
   * 淇濆瓨鏈湴鏁版嵁
   */
  private async saveLocalData(): Promise<void> {
    if (!this.storageConfig.persistCategories) {
      return;
    }
    
    try {
      // 淇濆瓨鍒嗙被鏁版嵁
      const categories = Array.from(this.categories.values());
      await this.storageUtil.set(
        LocalStorageType.CATEGORIES,
        JSON.stringify(categories)
      );
      
      // 淇濆瓨鍒嗙粍鏁版嵁
      const groups = Array.from(this.groups.values());
      await this.storageUtil.set(
        LocalStorageType.CATEGORY_GROUPS,
        JSON.stringify(groups)
      );
      
      // 淇濆瓨鍏虫敞鍒嗙被
      const followed = Array.from(this.followedCategories);
      await this.storageUtil.set(
        LocalStorageType.FOLLOWED_CATEGORIES,
        JSON.stringify(followed)
      );
      
      // 淇濆瓨鑷畾涔夋帓搴?
      const order = Object.fromEntries(this.customOrder);
      await this.storageUtil.set(
        LocalStorageType.CATEGORY_CUSTOM_ORDER,
        JSON.stringify(order)
      );
      
      // 淇濆瓨缁熻淇℃伅
      await this.storageUtil.set(
        LocalStorageType.CATEGORY_STATS,
        JSON.stringify(this.stats)
      );
      
      // 淇濆瓨鏈€鍚庡悓姝ユ椂闂?
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
   * 鍚姩鑷姩鍚屾
   */
  private startAutoSync(): void {
    if (this.syncTimer) {
      clearInterval(this.syncTimer);
    }
    
    this.syncTimer = setInterval(async () => {
      if (!this.isSyncing && this.shouldSync()) {
        await this.syncCategories();
      }
    }, this.storageConfig.syncInterval);
  }

  /**
   * 鍋滄鑷姩鍚屾
   */
  private stopAutoSync(): void {
    if (this.syncTimer) {
      clearInterval(this.syncTimer);
      this.syncTimer = null;
    }
  }

  /**
   * 妫€鏌ユ槸鍚﹂渶瑕佸悓姝?  */
  private shouldSync(): boolean {
    const now = Date.now();
    const timeSinceLastSync = now - this.lastSyncTime;
    return timeSinceLastSync >= this.storageConfig.cacheTTL;
  }

  /**
   * 缃戠粶鍦ㄧ嚎澶勭悊
   */
  private onNetworkOnline(): void {
    this.logger.info('Network online, checking for category sync');
    
    if (this.shouldSync()) {
      this.syncCategories();
    }
  }

  /**
   * 缃戠粶绂荤嚎澶勭悊
   */
  private onNetworkOffline(): void {
    this.logger.info('Network offline, category sync paused');
    this.storageConfig.offlineMode = true;
  }

  /**
   * 鍚屾鍒嗙被鏁版嵁
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
      
      // 浠嶢PI鑾峰彇鍒嗙被鏁版嵁
      const response = await this.fetchCategoriesFromAPI();
      
      if (response) {
        // 鏇存柊鍒嗙被鏁版嵁
        await this.updateCategories(response.categories);
        
        // 鏇存柊鍒嗙粍鏁版嵁
        if (response.groups) {
          await this.updateGroups(response.groups);
        }
        
        // 鏇存柊鏈€鍚庡悓姝ユ椂闂?       this.lastSyncTime = Date.now();
        
        // 淇濆瓨鏈湴鏁版嵁
        await this.saveLocalData();
        
        // 鍙戝竷鍚屾瀹屾垚浜嬩欢
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
      
      // 鍙戝竷閿欒浜嬩欢
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * 浠嶢PI鑾峰彇鍒嗙被鏁版嵁
   */
  private async fetchCategoriesFromAPI(): Promise<CategoryResponse | null> {
    try {
      // 鏋勫缓璇锋眰URL
      const url = '/api/categories';
      const cacheKey = `categories:${Date.now()}`;
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?
      const cachedResponse = await this.cacheService.getCache<CategoryResponse>(cacheKey);
      if (cachedResponse) {
        this.logger.debug('Category data loaded from cache');
        return { ...cachedResponse, cacheHit: true };
      }
      
      // 浠庣湡瀹濧PI鑾峰彇
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      const response = await httpService.get<CategoryResponse>(url, {
        timeout: 5000
      });
      
      if (response.status === 200 && response.data) {
        const categoryResponse = response.data;
        
        // 缂撳瓨鍝嶅簲鏁版嵁
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
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 鏇存柊鍒嗙被鏁版嵁
   */
  private async updateCategories(newCategories: Category[]): Promise<void> {
    const updatedCategories: Category[] = [];
    const createdCategories: Category[] = [];
    
    for (const newCategory of newCategories) {
      const existingCategory = this.categories.get(newCategory.id);
      
      if (existingCategory) {
        // 鏇存柊鐜版湁鍒嗙被
        const updatedCategory: Record<string, string | number | boolean | null> = { ... };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? string | number | boolean | null> = { ... };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(string | number | boolean | null> = { ... };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory instanceof Error ? ...newCategory };
        this.categories.set(newCategory.id, updatedCategory : new Error(String(...newCategory };
        this.categories.set(newCategory.id, updatedCategory)))))));
        updatedCategories.push(updatedCategory);
      } else {
        // 娣诲姞鏂板垎绫?       this.categories.set(newCategory.id, newCategory);
        createdCategories.push(newCategory);
      }
    }
    
    // 鍙戝竷浜嬩欢
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
    
    // 鏇存柊缁熻淇℃伅
    this.updateStats();
  }

  /**
   * 鏇存柊鍒嗙粍鏁版嵁
   */
  private async updateGroups(newGroups: CategoryGroup[]): Promise<void> {
    const updatedGroups: CategoryGroup[] = [];
    const createdGroups: CategoryGroup[] = [];
    
    for (const newGroup of newGroups) {
      const existingGroup = this.groups.get(newGroup.id);
      
      if (existingGroup) {
        // 鏇存柊鐜版湁鍒嗙粍
        const updatedGroup: Record<string, string | number | boolean | null> = { ... };
        this.groups.set(newGroup.id, updatedGroup);
        updatedGroups.push(updatedGroup);
      } else {
        // 娣诲姞鏂板垎缁?       this.groups.set(newGroup.id, newGroup);
        createdGroups.push(newGroup);
      }
    }
    
    // 鍙戝竷浜嬩欢
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
   * 鏇存柊缁熻淇℃伅
   */
  private updateStats(): void {
    const now = Date.now();
    
    // 閲嶇疆缁熻淇℃伅
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
    
    // 璁＄畻缁熻淇℃伅
    for (const category of this.categories.values()) {
      // 鎸夌被鍨嬬粺璁?     const typeCount = this.stats.byType.get(category.type) || 0;
      this.stats.byType.set(category.type, typeCount + 1);
      
      // 鎸夊彲瑙佹€х粺璁?     const visibilityCount = this.stats.byVisibility.get(category.visibility) || 0;
      this.stats.byVisibility.set(category.visibility, visibilityCount + 1);
      
      // 缁熻娲昏穬鍒嗙被
      if (category.status === 'active') {
        this.stats.activeCategories++;
      }
      
      // 缁熻绮鹃€夊垎绫?     if (category.metadata.isFeatured) {
        this.stats.featuredCategories++;
      }
      
      // 缁熻鍐呭鎬绘暟
      this.stats.totalContentCount += category.metadata.contentCount;
    }
    
    // 鍙戝竷缁熻鏇存柊浜嬩欢
    this.eventBus.emit(CategoryEventType.CONTENT_COUNT_CHANGED, {
      type: CategoryEventType.CONTENT_COUNT_CHANGED,
      timestamp: now,
      contentCount: this.stats.totalContentCount
    });
  }

  /**
   * 鑾峰彇鍒嗙被鍒楄〃
   * @param request 鍒嗙被璇锋眰
   */
  public async getCategories(request?: CategoryRequest): Promise<CategoryResponse> {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    try {
      // 妫€鏌ユ槸鍚﹂渶瑕佸悓姝?     if (this.shouldSync() && !this.isSyncing) {
        this.syncCategories();
      }
      
      // 鑾峰彇鎵€鏈夊垎绫?     let categories = Array.from(this.categories.values());
      
      // 搴旂敤杩囨护鏉′欢      if (request?.filter) {
        categories = this.filterCategories(categories, request.filter);
      }
      
      // 搴旂敤鎺掑簭
      categories = this.sortCategories(categories, request?.filter?.sortBy);
      
      // 搴旂敤鍒嗛〉
      const limit = request?.filter?.limit || 50;
      const offset = request?.filter?.offset || 0;
      const paginatedCategories = categories.slice(offset, offset + limit);
      
      // 鏋勫缓鍝嶅簲
      const response: CategoryResponse = {
        categories: paginatedCategories,
        totalCount: categories.length,
        hasMore: offset + limit < categories.length,
        timestamp: Date.now()
      };
      
      // 鍖呭惈鍒嗙粍淇℃伅
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
      this.Logger.error('Failed to get categories', error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 鏍规嵁ID鑾峰彇鍒嗙被
   * @param id 鍒嗙被ID
   */
  public getCategoryById(id: string): Category | null {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    return this.categories.get(id) || null;
  }

  /**
   * 鏍规嵁slug鑾峰彇鍒嗙被
   * @param slug 鍒嗙被slug
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
   * 鑾峰彇鍒嗙被缁勫垪琛?  */
  public getCategoryGroups(): CategoryGroup[] {
    if (!this.initialized) {
      throw new Error('CategoryRepository not initialized');
    }
    
    return Array.from(this.groups.values());
  }

  /**
   * 鑾峰彇鍒嗙被缁熻淇℃伅
   */
  public getCategoryStats(): CategoryStats {
    return { ...this.stats };
  }

  /**
   * 鍏虫敞鍒嗙被
   * @param categoryId 鍒嗙被ID
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
      
      // 娣诲姞鍏虫敞
      this.followedCategories.add(categoryId);
      
      // 鏇存柊鍒嗙被鍏冩暟鎹?     category.metadata.isFollowing = true;
      category.metadata.followerCount++;
      
      // 淇濆瓨鏈湴鏁版嵁
      await this.saveLocalData();
      
      // 鍙戝竷鍏虫敞浜嬩欢
      this.eventBus.emit(CategoryEventType.FOLLOWED, {
        type: CategoryEventType.FOLLOWED,
        timestamp: Date.now(),
        category,
        contentCount: category.metadata.contentCount
      });
      
      this.logger.info(`Category followed: ${category.name}`);
    } catch (error) {
      this.logger.error(`Failed to follow category: ${categoryId}`, error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 鍙栨秷鍏虫敞鍒嗙被
   * @param categoryId 鍒嗙被ID
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
      
      // 绉婚櫎鍏虫敞
      this.followedCategories.delete(categoryId);
      
      // 鏇存柊鍒嗙被鍏冩暟鎹?     category.metadata.isFollowing = false;
      category.metadata.followerCount = Math.max(0, category.metadata.followerCount - 1);
      
      // 淇濆瓨鏈湴鏁版嵁
      await this.saveLocalData();
      
      // 鍙戝竷鍙栨秷鍏虫敞浜嬩欢
      this.eventBus.emit(CategoryEventType.UNFOLLOWED, {
        type: CategoryEventType.UNFOLLOWED,
        timestamp: Date.now(),
        category,
        contentCount: category.metadata.contentCount
      });
      
      this.logger.info(`Category unfollowed: ${category.name}`);
    } catch (error) {
      this.Logger.error(`Failed to unfollow category: ${categoryId}`, error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 妫€鏌ユ槸鍚﹀凡鍏虫敞鍒嗙被
   * @param categoryId 鍒嗙被ID
   */
  public isCategoryFollowed(categoryId: string): boolean {
    if (!this.initialized) {
      return false;
    }
    
    return this.followedCategories.has(categoryId);
  }

  /**
   * 鑾峰彇宸插叧娉ㄧ殑鍒嗙被鍒楄〃
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
   * 璁剧疆鍒嗙被鑷畾涔夋帓搴?  * @param categoryId 鍒嗙被ID
   * @param orderIndex 鎺掑簭绱㈠紩
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
      
      // 鏇存柊鎺掑簭绱㈠紩
      this.customOrder.set(categoryId, orderIndex);
      category.orderIndex = orderIndex;
      
      // 淇濆瓨鏈湴鏁版嵁
      await this.saveLocalData();
      
      // 鍙戝竷閲嶆柊鎺掑簭浜嬩欢
      this.eventBus.emit(CategoryEventType.REORDERED, {
        type: CategoryEventType.REORDERED,
        timestamp: Date.now(),
        category,
        previousOrderIndex: category.orderIndex
      });
      
      this.logger.debug(`Category order updated: ${category.name} -> ${orderIndex}`);
    } catch (error) {
      this.Logger.error(`Failed to set category order: ${categoryId}`, error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 鎵归噺鏇存柊鍒嗙被
   * @param categories 鍒嗙被鍒楄〃
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
          // 鏇存柊鐜版湁鍒嗙被
          const updatedCategory: Record<string, string | number | boolean | null> = { ... };
          this.categories.set(category.id, updatedCategory);
          updatedCategories.push(updatedCategory);
        } else {
          // 娣诲姞鏂板垎绫?         this.categories.set(category.id, category);
          updatedCategories.push(category);
        }
      }
      
      // 淇濆瓨鏈湴鏁版嵁
      await this.saveLocalData();
      
      // 鍙戝竷鎵归噺鏇存柊浜嬩欢
      this.eventBus.emit(CategoryEventType.BATCH_UPDATED, {
        type: CategoryEventType.BATCH_UPDATED,
        timestamp: Date.now(),
        categories: updatedCategories
      });
      
      this.logger.info(`Categories batch updated: ${updatedCategories.length} categories`);
    } catch (error) {
      this.Logger.error('Failed to update categories batch', error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 杩囨护鍒嗙被
   */
  private filterCategories(categories: Category[], filter: CategoryFilter): Category[] {
    return categories.filter(category => {
      // 妫€鏌ョ被鍨?     if (filter.types && filter.types.length > 0 && !filter.types.includes(category.type)) {
        return false;
      }
      
      // 妫€鏌ュ彲瑙佹€?     if (filter.visibility && filter.visibility.length > 0 && !filter.visibility.includes(category.visibility)) {
        return false;
      }
      
      // 妫€鏌ユ悳绱㈣瘝
      if (filter.searchTerm) {
        const searchTerm = filter.searchTerm.toLowerCase();
        const nameMatch = category.name.toLowerCase().includes(searchTerm);
        const slugMatch = category.slug.toLowerCase().includes(searchTerm);
        const descMatch = category.metadata.description?.toLowerCase().includes(searchTerm);
        
        if (!nameMatch && !slugMatch && !descMatch) {
          return false;
        }
      }
      
      // 妫€鏌ョ埗鍒嗙被ID
      if (filter.parentId && category.metadata.parentCategoryId !== filter.parentId) {
        return false;
      }
      
      // 妫€鏌ュ瓙鍒嗙被
      if (filter.childOf && (!category.metadata.childCategoryIds || !category.metadata.childCategoryIds.includes(filter.childOf))) {
        return false;
      }
      
      // 妫€鏌ョ姸鎬?     if (filter.status && filter.status.length > 0 && !filter.status.includes(category.status)) {
        return false;
      }
      
      // 妫€鏌ョ簿閫夌姸鎬?     if (filter.featured !== undefined && category.metadata.isFeatured !== filter.featured) {
        return false;
      }
      
      // 妫€鏌ュ叧娉ㄧ姸鎬?     if (filter.followed !== undefined && this.followedCategories.has(category.id) !== filter.followed) {
        return false;
      }
      
      // 妫€鏌ュ唴瀹规暟閲忚寖鍥?     if (filter.contentCountMin && category.metadata.contentCount < filter.contentCountMin) {
        return false;
      }
      
      if (filter.contentCountMax && category.metadata.contentCount > filter.contentCountMax) {
        return false;
      }
      
      // 妫€鏌ユ爣绛?     if (filter.tags && filter.tags.length > 0) {
        const hasMatchingTag = filter.tags.some(tag => category.metadata.tags?.includes(tag));
        if (!hasMatchingTag) {
          return false;
        }
      }
      
      // 妫€鏌ヨ瑷€
      if (filter.lang && category.localization && !category.localization[filter.lang]) {
        return false;
      }
      
      // 妫€鏌ュ湴鍖?     if (filter.region && category.metadata.restrictedCountries?.includes(filter.region)) {
        return false;
      }
      
      return true;
    });
  }

  /**
   * 鎺掑簭鍒嗙被
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
          // 绠€鍖栧疄鐜帮細鍩轰簬鏈€鍚庢洿鏂版椂闂?         return (b.metadata.lastUpdated || 0) - (a.metadata.lastUpdated || 0);
        
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
   * 鍏抽棴鍒嗙被浠撳簱
   */
  public async shutdown(): Promise<void> {
    if (!this.initialized) {
      return;
    }
    
    try {
      // 鍋滄鑷姩鍚屾
      this.stopAutoSync();
      
      // 淇濆瓨鏈湴鏁版嵁
      await this.saveLocalData();
      
      // 娓呯┖鏁版嵁
      this.categories.clear();
      this.groups.clear();
      this.followedCategories.clear();
      this.customOrder.clear();
      
      this.initialized = false;
      this.logger.info('CategoryRepository shutdown');
    } catch (error) {
      this.Logger.error('Failed to shutdown CategoryRepository', error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
      this.eventBus.emit(CategoryEventType.ERROR, {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: CategoryEventType.ERROR,
        timestamp: Date.now( : new Error(String({
        type: CategoryEventType.ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
}





