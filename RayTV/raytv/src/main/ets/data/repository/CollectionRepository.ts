// CollectionRepository - 收藏仓库类
// 负责管理用户的视频、直播和内容收藏

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType, CachePolicy } from '../model/CacheModel';
import { UserRepository } from './UserRepository';
import { VideoRepository } from './VideoRepository';
import { LiveStreamRepository } from './LiveStreamRepository';

/**
 * 收藏内容类型枚举
 */
export enum CollectionItemType {
  VIDEO = 'video',
  LIVE_STREAM = 'live_stream',
  CHANNEL = 'channel',
  PLAYLIST = 'playlist',
  TAG = 'tag',
  CATEGORY = 'category',
  USER = 'user',
  COMMENT = 'comment',
  EVENT = 'event',
  POST = 'post',
  ARTICLE = 'article',
  UNKNOWN = 'unknown'
}

/**
 * 收藏集合可见性枚举
 */
export enum CollectionVisibility {
  PRIVATE = 'private', // 仅自己可见
  PUBLIC = 'public',   // 公开可见
  FRIENDS = 'friends', // 仅好友可见
  SHARED = 'shared'    // 分享给特定用户
}

/**
 * 收藏排序类型枚举
 */
export enum CollectionSortType {
  ADDED_DATE_ASC = 'added_date_asc',      // 添加日期升序
  ADDED_DATE_DESC = 'added_date_desc',    // 添加日期降序
  NAME_ASC = 'name_asc',                  // 名称升序
  NAME_DESC = 'name_desc',                // 名称降序
  RELEASE_DATE_ASC = 'release_date_asc',  // 发布日期升序
  RELEASE_DATE_DESC = 'release_date_desc',// 发布日期降序
  VIEWS_ASC = 'views_asc',                // 观看次数升序
  VIEWS_DESC = 'views_desc',              // 观看次数降序
  DURATION_ASC = 'duration_asc',          // 时长升序
  DURATION_DESC = 'duration_desc',        // 时长降序
  CUSTOM = 'custom'                       // 自定义排序
}

/**
 * 收藏项目元数据接口
 */
export interface CollectionItemMetadata {
  addedDate: number;            // 添加日期
  lastViewedDate?: number;      // 最后观看日期
  viewCount: number;            // 观看次数
  rating?: number;              // 用户评分
  notes?: string;               // 笔记
  position?: number;            // 播放位置（毫秒）
  completed?: boolean;          // 是否已完成
  favorite?: boolean;           // 是否标记为收藏中的收藏
  tags?: string[];              // 自定义标签
  customFields?: Record<string, any>; // 自定义字段
  sortOrder?: number;           // 排序顺序
  source?: string;              // 添加来源
  referrerId?: string;          // 引荐ID
}

/**
 * 收藏项目接口
 */
export interface CollectionItem {
  id: string;                   // 项目唯一标识
  type: CollectionItemType;     // 项目类型
  contentId: string;            // 原始内容ID
  userId: string;               // 所属用户ID
  collectionId: string;         // 所属集合ID
  metadata: CollectionItemMetadata; // 元数据
  title: string;                // 项目标题
  thumbnailUrl?: string;        // 缩略图URL
  duration?: number;            // 时长（毫秒）
  publishDate?: number;         // 发布日期
  viewCount?: number;           // 总观看次数
  channelId?: string;           // 频道/创建者ID
  channelName?: string;         // 频道/创建者名称
  tags?: string[];              // 项目标签
  status: 'active' | 'removed' | 'hidden'; // 状态
}

/**
 * 收藏集合元数据接口
 */
export interface CollectionMetadata {
  itemCount: number;            // 项目数量
  viewCount: number;            // 查看次数
  followerCount: number;        // 关注者数量
  lastUpdated: number;          // 最后更新时间
  createdAt: number;            // 创建时间
  coverImageUrl?: string;       // 封面图片URL
  description?: string;         // 详细描述
  isPublic?: boolean;           // 是否公开
  isCollaborative?: boolean;    // 是否协作
  contributors?: string[];      // 协作者ID列表
  featuredItems?: string[];     // 精选项目ID列表
  tags?: string[];              // 集合标签
  categoryId?: string;          // 分类ID
  source?: string;              // 创建来源
}

/**
 * 收藏集合接口
 */
export interface Collection {
  id: string;                   // 集合ID
  userId: string;               // 创建者用户ID
  name: string;                 // 集合名称
  description?: string;         // 集合描述
  visibility: CollectionVisibility; // 可见性
  metadata: CollectionMetadata; // 元数据
  status: 'active' | 'archived' | 'deleted'; // 状态
  defaultSortType?: CollectionSortType; // 默认排序类型
  isDefault?: boolean;          // 是否默认集合
  isLocked?: boolean;           // 是否锁定
  coverImageUrl?: string;       // 封面图片URL
  iconUrl?: string;             // 图标URL
  createdAt: number;            // 创建时间
  updatedAt: number;            // 更新时间
  expiresAt?: number;           // 过期时间
  allowedUserIds?: string[];    // 允许访问的用户ID列表（共享集合）
  autoAddNewItems?: boolean;    // 是否自动添加新项目
}

/**
 * 收藏事件类型
 */
export const CollectionEventType = {
  // 集合事件
  COLLECTION_CREATED: 'collection:created',
  COLLECTION_UPDATED: 'collection:updated',
  COLLECTION_DELETED: 'collection:deleted',
  COLLECTION_ARCHIVED: 'collection:archived',
  COLLECTION_ACTIVATED: 'collection:activated',
  
  // 项目事件
  ITEM_ADDED: 'collection:itemAdded',
  ITEM_REMOVED: 'collection:itemRemoved',
  ITEM_UPDATED: 'collection:itemUpdated',
  ITEM_REORDERED: 'collection:itemReordered',
  ITEM_MOVED: 'collection:itemMoved',
  
  // 批量事件
  ITEMS_ADDED: 'collection:itemsAdded',
  ITEMS_REMOVED: 'collection:itemsRemoved',
  BATCH_UPDATED: 'collection:batchUpdated',
  
  // 交互事件
  COLLECTION_VIEWED: 'collection:viewed',
  COLLECTION_FOLLOWED: 'collection:followed',
  COLLECTION_UNFOLLOWED: 'collection:unfollowed',
  
  // 同步事件
  SYNCED: 'collection:synced',
  SYNC_FAILED: 'collection:syncFailed',
  
  // 错误事件
  ERROR: 'collection:error'
} as const;

/**
 * 收藏事件数据
 */
export interface CollectionEvent {
  type: string;
  timestamp: number;
  collection?: Collection;
  collections?: Collection[];
  item?: CollectionItem;
  items?: CollectionItem[];
  itemIds?: string[];
  collectionId?: string;
  fromCollectionId?: string;
  toCollectionId?: string;
  userId?: string;
  error?: Error;
}

/**
 * 收藏过滤条件接口
 */
export interface CollectionFilter {
  userId?: string;              // 用户ID
  itemTypes?: CollectionItemType[]; // 项目类型
  searchTerm?: string;          // 搜索词
  tags?: string[];              // 标签筛选
  isDefault?: boolean;          // 是否默认集合
  status?: string[];            // 状态筛选
  visibility?: CollectionVisibility[]; // 可见性筛选
  sortBy?: CollectionSortType;  // 排序方式
  limit?: number;               // 数量限制
  offset?: number;              // 偏移量
  favoriteOnly?: boolean;       // 仅显示收藏中的收藏
  completedOnly?: boolean;      // 仅显示已完成
  dateFrom?: number;            // 开始日期
  dateTo?: number;              // 结束日期
  includeArchived?: boolean;    // 包含归档
  ownedOnly?: boolean;          // 仅自己拥有
}

/**
 * 收藏请求接口
 */
export interface CollectionRequest {
  filter?: CollectionFilter;
  includeItems?: boolean;       // 是否包含项目
  includeMetadata?: boolean;    // 是否包含元数据
  cachePolicy?: CachePolicy;    // 缓存策略
}

/**
 * 收藏响应接口
 */
export interface CollectionResponse {
  collections: Collection[];
  items?: CollectionItem[];
  totalCount: number;
  hasMore: boolean;
  timestamp: number;
  cacheHit?: boolean;
}

/**
 * 收藏统计接口
 */
export interface CollectionStats {
  totalCollections: number;     // 总集合数
  totalItems: number;           // 总项目数
  byType: Map<CollectionItemType, number>; // 按类型统计
  byVisibility: Map<CollectionVisibility, number>; // 按可见性统计
  publicCollections: number;    // 公开集合数
  privateCollections: number;   // 私有集合数
  favoriteItems: number;        // 收藏中的收藏数
  completedItems: number;       // 已完成项目数
  lastUpdated: number;          // 最后更新时间
}

/**
 * 收藏存储配置接口
 */
export interface CollectionStorageConfig {
  cacheTTL: number;             // 缓存过期时间（毫秒）
  maxCacheItems: number;        // 最大缓存项数
  persistCollections: boolean;  // 是否持久化集合
  autoSync: boolean;            // 是否自动同步
  syncInterval: number;         // 同步间隔（毫秒）
  offlineMode: boolean;         // 离线模式
  enableBackup: boolean;        // 启用备份
  backupInterval: number;       // 备份间隔（毫秒）
}

/**
 * 收藏仓库类
 */
export class CollectionRepository {
  private static instance: CollectionRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  private userRepository = UserRepository.getInstance();
  private videoRepository = VideoRepository.getInstance();
  private liveStreamRepository = LiveStreamRepository.getInstance();
  
  // 存储键配置
  private storageKeys = {
    collections: 'collection:collections',
    items: 'collection:items',
    stats: 'collection:stats',
    config: 'collection:config',
    lastSyncTime: 'collection:lastSyncTime',
    defaultCollection: 'collection:default',
    itemPositions: 'collection:itemPositions'
  };
  
  // 默认存储配置
  private defaultStorageConfig: CollectionStorageConfig = {
    cacheTTL: 3600000, // 1小时
    maxCacheItems: 5000,
    persistCollections: true,
    autoSync: true,
    syncInterval: 3600000, // 1小时
    offlineMode: false,
    enableBackup: true,
    backupInterval: 86400000 // 24小时
  };
  
  // 存储配置
  private storageConfig: CollectionStorageConfig = { ...this.defaultStorageConfig };
  
  // 集合数据
  private collections: Map<string, Collection> = new Map();
  
  // 项目数据
  private items: Map<string, CollectionItem> = new Map();
  
  // 按集合ID索引的项目
  private itemsByCollection: Map<string, Set<string>> = new Map();
  
  // 按内容ID索引的项目
  private itemsByContentId: Map<string, Set<string>> = new Map();
  
  // 默认集合ID
  private defaultCollectionId: string | null = null;
  
  // 收藏统计
  private collectionStats: CollectionStats = this.getEmptyStats();
  
  // 上次同步时间
  private lastSyncTime: number = 0;
  
  // 同步定时器
  private syncTimer: number | null = null;
  
  // 备份定时器
  private backupTimer: number | null = null;
  
  // 是否正在同步
  private isSyncing: boolean = false;
  
  // 过滤器缓存
  private filterCache: Map<string, CollectionResponse> = new Map();
  
  // 最大过滤器缓存项
  private maxFilterCacheItems: number = 10;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('CollectionRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取CollectionRepository单例实例
   */
  public static getInstance(): CollectionRepository {
    if (!CollectionRepository.instance) {
      CollectionRepository.instance = new CollectionRepository();
    }
    return CollectionRepository.instance;
  }

  /**
   * 初始化收藏仓库
   */
  private async initialize(): Promise<void> {
    try {
      // 加载存储配置
      await this.loadStorageConfig();
      
      // 加载集合数据
      await this.loadCollections();
      
      // 加载项目数据
      await this.loadItems();
      
      // 加载默认集合
      await this.loadDefaultCollection();
      
      // 加载统计
      await this.loadStats();
      
      // 启动自动同步
      if (this.storageConfig.autoSync && !this.storageConfig.offlineMode) {
        this.startAutoSync();
      }
      
      // 启动自动备份
      if (this.storageConfig.enableBackup) {
        this.startAutoBackup();
      }
      
      // 检查缓存是否过期
      if (!this.isCacheValid() && !this.storageConfig.offlineMode) {
        this.syncCollections().catch(err => {
          this.logger.warn('Failed to sync collections on initialization', err);
        });
      }
      
      this.logger.info(`CollectionRepository initialization completed with ${this.collections.size} collections and ${this.items.size} items`);
    } catch (error) {
        this.logger.error(`Failed to update item metadata: ${itemId}`, error as Error);
        
        // 发布错误事件
        this.eventBus.emit(CollectionEventType.ERROR, {
          type: CollectionEventType.ERROR,
          timestamp: Date.now(),
          error: error as Error
        } as CollectionEvent);
        
        return null;
      }
    }

    /**
     * 重新排序项目
     */
    public async reorderItems(
      collectionId: string,
      itemIds: string[]
    ): Promise<boolean> {
      try {
        const collection = this.collections.get(collectionId);
        
        if (!collection) {
          return false;
        }
        
        // 检查权限
        const currentUser = await this.userRepository.getCurrentUser();
        if (!currentUser || currentUser.id !== collection.userId) {
          this.logger.warn('User does not have permission to reorder items');
          return false;
        }
        
        // 验证所有项目都属于该集合
        const validItems = itemIds.filter(id => {
          const item = this.items.get(id);
          return item && item.collectionId === collectionId;
        });
        
        if (validItems.length !== itemIds.length) {
          this.logger.warn('Invalid item IDs in reorder request');
          return false;
        }
        
        // 更新排序
        for (let i = 0; i < validItems.length; i++) {
          const item = this.items.get(validItems[i]);
          if (item) {
            item.metadata.sortOrder = i;
          }
        }
        
        // 更新集合的最后更新时间
        collection.metadata.lastUpdated = Date.now();
        collection.updatedAt = Date.now();
        
        // 保存数据
        await this.saveCollections();
        await this.saveItems();
        
        // 清除过滤器缓存
        this.clearFilterCache();
        
        // 发布重新排序事件
        this.eventBus.emit(CollectionEventType.ITEM_REORDERED, {
          type: CollectionEventType.ITEM_REORDERED,
          timestamp: Date.now(),
          collection,
          itemIds: validItems
        } as CollectionEvent);
        
        this.logger.info(`Items reordered in collection: ${collection.name} (${collectionId})`);
        
        return true;
      } catch (error) {
        this.logger.error(`Failed to reorder items in collection: ${collectionId}`, error as Error);
        
        // 发布错误事件
        this.eventBus.emit(CollectionEventType.ERROR, {
          type: CollectionEventType.ERROR,
          timestamp: Date.now(),
          error: error as Error
        } as CollectionEvent);
        
        return false;
      }
    }

    /**
     * 移动项目到另一个集合
     */
    public async moveItemToCollection(
      itemId: string,
      toCollectionId: string
    ): Promise<boolean> {
      try {
        const item = this.items.get(itemId);
        
        if (!item) {
          return false;
        }
        
        const fromCollection = this.collections.get(item.collectionId);
        const toCollection = this.collections.get(toCollectionId);
        
        if (!fromCollection || !toCollection || toCollection.status !== 'active') {
          return false;
        }
        
        // 检查权限
        const currentUser = await this.userRepository.getCurrentUser();
        if (!currentUser || 
            currentUser.id !== fromCollection.userId || 
            currentUser.id !== toCollection.userId) {
          this.logger.warn('User does not have permission to move item');
          return false;
        }
        
        // 更新项目集合ID
        const oldCollectionId = item.collectionId;
        item.collectionId = toCollectionId;
        
        // 更新索引
        // 从旧集合中移除
        if (this.itemsByCollection.has(oldCollectionId)) {
          this.itemsByCollection.get(oldCollectionId)!.delete(itemId);
          if (this.itemsByCollection.get(oldCollectionId)!.size === 0) {
            this.itemsByCollection.delete(oldCollectionId);
          }
        }
        
        // 添加到新集合
        if (!this.itemsByCollection.has(toCollectionId)) {
          this.itemsByCollection.set(toCollectionId, new Set());
        }
        this.itemsByCollection.get(toCollectionId)!.add(itemId);
        
        // 更新集合统计
        if (fromCollection.metadata.itemCount > 0) {
          fromCollection.metadata.itemCount--;
        }
        fromCollection.metadata.lastUpdated = Date.now();
        fromCollection.updatedAt = Date.now();
        
        toCollection.metadata.itemCount++;
        toCollection.metadata.lastUpdated = Date.now();
        toCollection.updatedAt = Date.now();
        
        // 保存数据
        await this.saveCollections();
        await this.saveItems();
        
        // 更新统计
        await this.updateStats();
        
        // 清除过滤器缓存
        this.clearFilterCache();
        
        // 发布移动事件
        this.eventBus.emit(CollectionEventType.ITEM_MOVED, {
          type: CollectionEventType.ITEM_MOVED,
          timestamp: Date.now(),
          item,
          fromCollectionId: oldCollectionId,
          toCollectionId,
          collection: toCollection
        } as CollectionEvent);
        
        this.logger.info(`Item moved from collection ${oldCollectionId} to ${toCollectionId}: ${item.title} (${itemId})`);
        
        return true;
      } catch (error) {
        this.logger.error(`Failed to move item from ${itemId} to collection ${toCollectionId}`, error as Error);
        
        // 发布错误事件
        this.eventBus.emit(CollectionEventType.ERROR, {
          type: CollectionEventType.ERROR,
          timestamp: Date.now(),
          error: error as Error
        } as CollectionEvent);
        
        return false;
      }
    }

    /**
     * 批量添加项目到集合
     */
    public async addItemsToCollection(
      collectionId: string,
      itemsData: Array<{
        type: CollectionItemType;
        contentId: string;
        title: string;
        thumbnailUrl?: string;
        duration?: number;
        publishDate?: number;
        viewCount?: number;
        channelId?: string;
        channelName?: string;
        tags?: string[];
        metadata?: Partial<CollectionItemMetadata>;
      }>
    ): Promise<CollectionItem[]> {
      try {
        const collection = this.collections.get(collectionId);
        
        if (!collection || collection.status !== 'active') {
          return [];
        }
        
        // 检查权限
        const currentUser = await this.userRepository.getCurrentUser();
        if (!currentUser || currentUser.id !== collection.userId) {
          this.logger.warn('User does not have permission to add items to collection');
          return [];
        }
        
        const addedItems: CollectionItem[] = [];
        
        for (const itemData of itemsData) {
          // 检查是否已存在
          const isInCollection = await this.isContentInCollection(
            itemData.contentId,
            itemData.type,
            collectionId
          );
          
          if (!isInCollection) {
            const newItem = await this.addItemToCollection(collectionId, itemData);
            if (newItem) {
              addedItems.push(newItem);
            }
          }
        }
        
        if (addedItems.length > 0) {
          // 更新集合统计
          collection.metadata.itemCount += addedItems.length;
          collection.metadata.lastUpdated = Date.now();
          collection.updatedAt = Date.now();
          
          // 保存集合
          await this.saveCollections();
          
          // 更新统计
          await this.updateStats();
          
          // 清除过滤器缓存
          this.clearFilterCache();
          
          // 发布批量添加事件
          this.eventBus.emit(CollectionEventType.ITEMS_ADDED, {
            type: CollectionEventType.ITEMS_ADDED,
            timestamp: Date.now(),
            collection,
            items: addedItems
          } as CollectionEvent);
        }
        
        this.logger.info(`Added ${addedItems.length} items to collection: ${collection.name} (${collectionId})`);
        
        return addedItems;
      } catch (error) {
        this.logger.error(`Failed to add items to collection: ${collectionId}`, error as Error);
        
        // 发布错误事件
        this.eventBus.emit(CollectionEventType.ERROR, {
          type: CollectionEventType.ERROR,
          timestamp: Date.now(),
          error: error as Error
        } as CollectionEvent);
        
        return [];
      }
    }

    /**
     * 批量从集合中移除项目
     */
    public async removeItemsFromCollection(itemIds: string[]): Promise<boolean> {
      try {
        if (!itemIds || itemIds.length === 0) {
          return false;
        }
        
        // 获取第一个项目以验证权限
        const firstItem = this.items.get(itemIds[0]);
        if (!firstItem) {
          return false;
        }
        
        const collection = this.collections.get(firstItem.collectionId);
        if (!collection) {
          return false;
        }
        
        // 检查权限
        const currentUser = await this.userRepository.getCurrentUser();
        if (!currentUser || currentUser.id !== collection.userId) {
          this.logger.warn('User does not have permission to remove items from collection');
          return false;
        }
        
        const removedItems: CollectionItem[] = [];
        
        for (const itemId of itemIds) {
          const item = this.items.get(itemId);
          if (item && item.collectionId === collection.id) {
            // 从索引中移除
            if (this.itemsByCollection.has(collection.id)) {
              this.itemsByCollection.get(collection.id)!.delete(itemId);
            }
            
            if (this.itemsByContentId.has(item.contentId)) {
              this.itemsByContentId.get(item.contentId)!.delete(itemId);
            }
            
            // 从项目列表中移除
            this.items.delete(itemId);
            removedItems.push(item);
          }
        }
        
        if (removedItems.length > 0) {
          // 更新集合统计
          collection.metadata.itemCount = Math.max(0, collection.metadata.itemCount - removedItems.length);
          collection.metadata.lastUpdated = Date.now();
          collection.updatedAt = Date.now();
          
          // 保存数据
          await this.saveCollections();
          await this.saveItems();
          
          // 更新统计
          await this.updateStats();
          
          // 清除过滤器缓存
          this.clearFilterCache();
          
          // 发布批量移除事件
          this.eventBus.emit(CollectionEventType.ITEMS_REMOVED, {
            type: CollectionEventType.ITEMS_REMOVED,
            timestamp: Date.now(),
            collection,
            items: removedItems
          } as CollectionEvent);
        }
        
        this.logger.info(`Removed ${removedItems.length} items from collection: ${collection.name} (${collection.id})`);
        
        return removedItems.length > 0;
      } catch (error) {
        this.logger.error('Failed to remove items from collection', error as Error);
        
        // 发布错误事件
        this.eventBus.emit(CollectionEventType.ERROR, {
          type: CollectionEventType.ERROR,
          timestamp: Date.now(),
          error: error as Error
        } as CollectionEvent);
        
        return false;
      }
    }

    /**
     * 批量更新项目元数据
     */
    public async batchUpdateItemsMetadata(
      itemIds: string[],
      metadata: Partial<CollectionItemMetadata>
    ): Promise<boolean> {
      try {
        if (!itemIds || itemIds.length === 0) {
          return false;
        }
        
        // 获取第一个项目以验证权限
        const firstItem = this.items.get(itemIds[0]);
        if (!firstItem) {
          return false;
        }
        
        const collection = this.collections.get(firstItem.collectionId);
        if (!collection) {
          return false;
        }
        
        // 检查权限
        const currentUser = await this.userRepository.getCurrentUser();
        if (!currentUser || currentUser.id !== collection.userId) {
          this.logger.warn('User does not have permission to batch update items');
          return false;
        }
        
        let hasUpdates = false;
        const updatedItems: CollectionItem[] = [];
        
        for (const itemId of itemIds) {
          const item = this.items.get(itemId);
          if (item && item.collectionId === collection.id) {
            // 更新元数据
            item.metadata = {
              ...item.metadata,
              ...metadata
            };
            updatedItems.push(item);
            hasUpdates = true;
          }
        }
        
        if (hasUpdates) {
          // 更新集合的最后更新时间
          collection.metadata.lastUpdated = Date.now();
          collection.updatedAt = Date.now();
          
          // 保存数据
          await this.saveCollections();
          await this.saveItems();
          
          // 更新统计
          await this.updateStats();
          
          // 清除过滤器缓存
          this.clearFilterCache();
          
          // 发布批量更新事件
          this.eventBus.emit(CollectionEventType.BATCH_UPDATED, {
            type: CollectionEventType.BATCH_UPDATED,
            timestamp: Date.now(),
            collection,
            items: updatedItems,
            itemIds
          } as CollectionEvent);
        }
        
        this.logger.info(`Batch updated ${updatedItems.length} items in collection: ${collection.name} (${collection.id})`);
        
        return updatedItems.length > 0;
      } catch (error) {
        this.logger.error('Failed to batch update items metadata', error as Error);
        
        // 发布错误事件
        this.eventBus.emit(CollectionEventType.ERROR, {
          type: CollectionEventType.ERROR,
          timestamp: Date.now(),
          error: error as Error
        } as CollectionEvent);
        
        return false;
      }
    }

    /**
     * 关注集合
     */
    public async followCollection(collectionId: string): Promise<boolean> {
      try {
        const collection = this.collections.get(collectionId);
        
        if (!collection || collection.visibility !== CollectionVisibility.PUBLIC) {
          return false;
        }
        
        const currentUser = await this.userRepository.getCurrentUser();
        if (!currentUser) {
          this.logger.warn('User must be logged in to follow collections');
          return false;
        }
        
        // 在实际应用中，这里应该调用API来关注集合
        // 这里简化处理，仅更新本地数据
        
        // 增加关注者数量
        collection.metadata.followerCount++;
        
        // 保存集合
        await this.saveCollections();
        
        // 发布关注事件
        this.eventBus.emit(CollectionEventType.COLLECTION_FOLLOWED, {
          type: CollectionEventType.COLLECTION_FOLLOWED,
          timestamp: Date.now(),
          collection,
          userId: currentUser.id
        } as CollectionEvent);
        
        this.logger.info(`Collection followed: ${collection.name} (${collectionId}) by user: ${currentUser.id}`);
        
        return true;
      } catch (error) {
        this.logger.error(`Failed to follow collection: ${collectionId}`, error as Error);
        
        // 发布错误事件
        this.eventBus.emit(CollectionEventType.ERROR, {
          type: CollectionEventType.ERROR,
          timestamp: Date.now(),
          error: error as Error
        } as CollectionEvent);
        
        return false;
      }
    }

    /**
     * 取消关注集合
     */
    public async unfollowCollection(collectionId: string): Promise<boolean> {
      try {
        const collection = this.collections.get(collectionId);
        
        if (!collection || collection.visibility !== CollectionVisibility.PUBLIC) {
          return false;
        }
        
        const currentUser = await this.userRepository.getCurrentUser();
        if (!currentUser) {
          return false;
        }
        
        // 在实际应用中，这里应该调用API来取消关注集合
        // 这里简化处理，仅更新本地数据
        
        // 减少关注者数量
        if (collection.metadata.followerCount > 0) {
          collection.metadata.followerCount--;
        }
        
        // 保存集合
        await this.saveCollections();
        
        // 发布取消关注事件
        this.eventBus.emit(CollectionEventType.COLLECTION_UNFOLLOWED, {
          type: CollectionEventType.COLLECTION_UNFOLLOWED,
          timestamp: Date.now(),
          collection,
          userId: currentUser.id
        } as CollectionEvent);
        
        this.logger.info(`Collection unfollowed: ${collection.name} (${collectionId}) by user: ${currentUser.id}`);
        
        return true;
      } catch (error) {
        this.logger.error(`Failed to unfollow collection: ${collectionId}`, error as Error);
        
        // 发布错误事件
        this.eventBus.emit(CollectionEventType.ERROR, {
          type: CollectionEventType.ERROR,
          timestamp: Date.now(),
          error: error as Error
        } as CollectionEvent);
        
        return false;
      }
    }

    /**
     * 获取收藏统计
     */
    public async getStats(): Promise<CollectionStats> {
      try {
        // 更新统计
        await this.updateStats();
        
        // 返回深拷贝
        return JSON.parse(JSON.stringify(this.collectionStats));
      } catch (error) {
        this.logger.error('Failed to get collection stats', error as Error);
        return this.getEmptyStats();
      }
    }

    /**
     * 更新统计
     */
    private async updateStats(): Promise<void> {
      try {
        const byType = new Map<CollectionItemType, number>();
        const byVisibility = new Map<CollectionVisibility, number>();
        
        let favoriteItems = 0;
        let completedItems = 0;
        
        // 初始化类型统计
        Object.values(CollectionItemType).forEach(type => {
          byType.set(type, 0);
        });
        
        // 初始化可见性统计
        Object.values(CollectionVisibility).forEach(visibility => {
          byVisibility.set(visibility, 0);
        });
        
        // 统计项目
        this.items.forEach(item => {
          if (item.status === 'active') {
            // 按类型统计
            const currentCount = byType.get(item.type) || 0;
            byType.set(item.type, currentCount + 1);
            
            // 统计收藏中的收藏和已完成项目
            if (item.metadata.favorite) {
              favoriteItems++;
            }
            
            if (item.metadata.completed) {
              completedItems++;
            }
          }
        });
        
        // 统计集合可见性
        let publicCollections = 0;
        let privateCollections = 0;
        
        this.collections.forEach(collection => {
          if (collection.status === 'active') {
            const currentCount = byVisibility.get(collection.visibility) || 0;
            byVisibility.set(collection.visibility, currentCount + 1);
            
            if (collection.visibility === CollectionVisibility.PUBLIC) {
              publicCollections++;
            } else if (collection.visibility === CollectionVisibility.PRIVATE) {
              privateCollections++;
            }
          }
        });
        
        // 更新统计数据
        this.collectionStats = {
          totalCollections: this.collections.size,
          totalItems: this.items.size,
          byType,
          byVisibility,
          publicCollections,
          privateCollections,
          favoriteItems,
          completedItems,
          lastUpdated: Date.now()
        };
        
        // 保存统计
        await this.saveStats();
      } catch (error) {
        this.logger.error('Failed to update collection stats', error as Error);
        this.resetStats();
      }
    }

    /**
     * 保存统计
     */
    private async saveStats(): Promise<void> {
      try {
        // 转换Map为数组以便存储
        const statsToSave = {
          totalCollections: this.collectionStats.totalCollections,
          totalItems: this.collectionStats.totalItems,
          byType: Array.from(this.collectionStats.byType.entries()),
          byVisibility: Array.from(this.collectionStats.byVisibility.entries()),
          publicCollections: this.collectionStats.publicCollections,
          privateCollections: this.collectionStats.privateCollections,
          favoriteItems: this.collectionStats.favoriteItems,
          completedItems: this.collectionStats.completedItems,
          lastUpdated: this.collectionStats.lastUpdated
        };
        
        await this.storageUtil.setObject(
          this.storageKeys.stats,
          statsToSave,
          LocalStorageType.DEFAULT
        );
      } catch (error) {
        this.logger.error('Failed to save collection stats', error as Error);
      }
    }

    /**
     * 获取空的统计数据
     */
    private getEmptyStats(): CollectionStats {
      const byType = new Map<CollectionItemType, number>();
      const byVisibility = new Map<CollectionVisibility, number>();
      
      // 初始化类型统计
      Object.values(CollectionItemType).forEach(type => {
        byType.set(type, 0);
      });
      
      // 初始化可见性统计
      Object.values(CollectionVisibility).forEach(visibility => {
        byVisibility.set(visibility, 0);
      });
      
      return {
        totalCollections: 0,
        totalItems: 0,
        byType,
        byVisibility,
        publicCollections: 0,
        privateCollections: 0,
        favoriteItems: 0,
        completedItems: 0,
        lastUpdated: Date.now()
      };
    }

    /**
     * 重置统计
     */
    private resetStats(): void {
      this.collectionStats = this.getEmptyStats();
    }

    /**
     * 搜索集合
     */
    public async searchCollections(
      searchTerm: string,
      options?: {
        includeArchived?: boolean;
        includePublic?: boolean;
        includePrivate?: boolean;
        sortBy?: CollectionSortType;
        limit?: number;
      }
    ): Promise<Collection[]> {
      try {
        const { 
          includeArchived = false,
          includePublic = true,
          includePrivate = true,
          sortBy = CollectionSortType.NAME_ASC,
          limit = 50
        } = options || {};
        
        const currentUser = await this.userRepository.getCurrentUser();
        const userId = currentUser?.id || 'anonymous';
        
        const searchLower = searchTerm.toLowerCase();
        
        // 搜索集合
        let collections = Array.from(this.collections.values()).filter(col => {
          // 状态过滤
          if (!includeArchived && col.status !== 'active') {
            return false;
          }
          
          // 可见性过滤
          if (!includePublic && col.visibility === CollectionVisibility.PUBLIC) {
            return false;
          }
          
          if (!includePrivate && 
              col.visibility === CollectionVisibility.PRIVATE && 
              col.userId === userId) {
            return false;
          }
          
          // 内容过滤
          const matchesName = col.name.toLowerCase().includes(searchLower);
          const matchesDescription = col.description ? 
            col.description.toLowerCase().includes(searchLower) : false;
          const matchesTags = col.metadata.tags ? 
            col.metadata.tags.some(tag => tag.toLowerCase().includes(searchLower)) : false;
          
          return matchesName || matchesDescription || matchesTags;
        });
        
        // 排序
        collections = this.sortCollections(collections, sortBy);
        
        // 限制数量
        return collections.slice(0, limit);
      } catch (error) {
        this.logger.error('Failed to search collections', error as Error);
        return [];
      }
    }

    /**
     * 搜索项目
     */
    public async searchItems(
      searchTerm: string,
      options?: {
        collectionId?: string;
        itemTypes?: CollectionItemType[];
        includeRemoved?: boolean;
        sortBy?: CollectionSortType;
        limit?: number;
      }
    ): Promise<CollectionItem[]> {
      try {
        const { 
          collectionId,
          itemTypes,
          includeRemoved = false,
          sortBy = CollectionSortType.NAME_ASC,
          limit = 50
        } = options || {};
        
        const searchLower = searchTerm.toLowerCase();
        
        // 获取要搜索的项目
        let items: CollectionItem[] = [];
        
        if (collectionId) {
          // 仅搜索特定集合
          items = await this.getCollectionItems(collectionId, { includeRemoved });
        } else {
          // 搜索所有可访问的项目
          const currentUser = await this.userRepository.getCurrentUser();
          const userId = currentUser?.id || 'anonymous';
          
          items = Array.from(this.items.values()).filter(item => {
            // 状态过滤
            if (!includeRemoved && item.status !== 'active') {
              return false;
            }
            
            // 检查集合权限
            const collection = this.collections.get(item.collectionId);
            if (!collection) {
              return false;
            }
            
            // 检查可见性
            if (collection.visibility === CollectionVisibility.PRIVATE && 
                collection.userId !== userId) {
              return false;
            }
            
            if (collection.visibility === CollectionVisibility.SHARED && 
                collection.userId !== userId && 
                (!collection.allowedUserIds || !collection.allowedUserIds.includes(userId))) {
              return false;
            }
            
            return true;
          });
        }
        
        // 过滤项目
        items = items.filter(item => {
          // 类型过滤
          if (itemTypes && itemTypes.length > 0 && !itemTypes.includes(item.type)) {
            return false;
          }
          
          // 内容过滤
          const matchesTitle = item.title.toLowerCase().includes(searchLower);
          const matchesTags = item.tags ? 
            item.tags.some(tag => tag.toLowerCase().includes(searchLower)) : false;
          const matchesChannel = item.channelName ? 
            item.channelName.toLowerCase().includes(searchLower) : false;
          
          return matchesTitle || matchesTags || matchesChannel;
        });
        
        // 排序
        items = this.sortItems(items, sortBy);
        
        // 限制数量
        return items.slice(0, limit);
      } catch (error) {
        this.logger.error('Failed to search items', error as Error);
        return [];
      }
    }

    /**
     * 导出收藏数据
     */
    public async exportCollections(): Promise<Record<string, any>> {
      try {
        // 准备导出数据
        const exportData = {
          version: '1.0.0',
          exportedAt: Date.now(),
          collections: Array.from(this.collections.values()),
          items: Array.from(this.items.values()),
          stats: this.collectionStats,
          defaultCollectionId: this.defaultCollectionId
        };
        
        this.logger.info(`Exported ${this.collections.size} collections and ${this.items.size} items`);
        
        return exportData;
      } catch (error) {
        this.logger.error('Failed to export collections', error as Error);
        throw error;
      }
    }

    /**
     * 导入收藏数据
     */
    public async importCollections(
      data: Record<string, any>,
      options?: {
        overwrite?: boolean;
        mergeCollections?: boolean;
        mergeItems?: boolean;
        skipDefaultCollection?: boolean;
      }
    ): Promise<{ 
      importedCollections: number;
      importedItems: number;
      errors: string[];
    }> {
      try {
        const { 
          overwrite = false,
          mergeCollections = true,
          mergeItems = true,
          skipDefaultCollection = false
        } = options || {};
        
        const errors: string[] = [];
        let importedCollections = 0;
        let importedItems = 0;
        
        const collections = data.collections || [];
        const items = data.items || [];
        const defaultCollectionId = data.defaultCollectionId;
        
        // 清空现有数据（如果需要）
        if (overwrite) {
          this.collections.clear();
          this.items.clear();
          this.itemsByCollection.clear();
          this.itemsByContentId.clear();
          this.defaultCollectionId = null;
        }
        
        // 导入集合
        for (const collectionData of collections) {
          try {
            // 检查是否跳过默认集合
            if (skipDefaultCollection && collectionData.isDefault) {
              continue;
            }
            
            // 检查是否已存在
            if (this.collections.has(collectionData.id)) {
              if (mergeCollections) {
                // 更新现有集合
                const existing = this.collections.get(collectionData.id)!;
                const updated = {
                  ...existing,
                  ...collectionData,
                  metadata: {
                    ...existing.metadata,
                    ...collectionData.metadata,
                    lastUpdated: Date.now()
                  },
                  updatedAt: Date.now()
                };
                this.collections.set(collectionData.id, updated);
                importedCollections++;
              }
            } else {
              // 添加新集合
              this.collections.set(collectionData.id, collectionData);
              importedCollections++;
            }
          } catch (err) {
            errors.push(`Failed to import collection: ${err.message}`);
          }
        }
        
        // 导入项目
        for (const itemData of items) {
          try {
            // 检查集合是否存在
            if (!this.collections.has(itemData.collectionId)) {
              errors.push(`Failed to import item: Collection ${itemData.collectionId} not found`);
              continue;
            }
            
            // 检查是否已存在
            if (this.items.has(itemData.id)) {
              if (mergeItems) {
                // 更新现有项目
                const existing = this.items.get(itemData.id)!;
                this.items.set(itemData.id, {
                  ...existing,
                  ...itemData,
                  metadata: {
                    ...existing.metadata,
                    ...itemData.metadata
                  }
                });
                importedItems++;
              }
            } else {
              // 添加新项目
              this.items.set(itemData.id, itemData);
              importedItems++;
            }
          } catch (err) {
            errors.push(`Failed to import item: ${err.message}`);
          }
        }
        
        // 设置默认集合
        if (defaultCollectionId && 
            this.collections.has(defaultCollectionId) && 
            (!skipDefaultCollection || !this.defaultCollectionId)) {
          this.defaultCollectionId = defaultCollectionId;
          
          // 更新默认标记
          for (const [id, collection] of this.collections.entries()) {
            collection.isDefault = id === defaultCollectionId;
          }
        }
        
        // 重建索引
        this.rebuildIndexes();
        
        // 保存数据
        await this.saveCollections();
        await this.saveItems();
        await this.saveDefaultCollection();
        
        // 更新统计
        await this.updateStats();
        
        // 清除过滤器缓存
        this.clearFilterCache();
        
        this.logger.info(`Imported ${importedCollections} collections and ${importedItems} items`);
        
        return { importedCollections, importedItems, errors };
      } catch (error) {
        this.logger.error('Failed to import collections', error as Error);
        throw error;
      }
    }

    /**
     * 清空所有数据
     */
    public async clearAllData(): Promise<boolean> {
      try {
        const currentUser = await this.userRepository.getCurrentUser();
        if (!currentUser) {
          this.logger.warn('User must be logged in to clear all data');
          return false;
        }
        
        // 清空所有数据
        this.collections.clear();
        this.items.clear();
        this.itemsByCollection.clear();
        this.itemsByContentId.clear();
        this.defaultCollectionId = null;
        
        // 重置统计
        this.resetStats();
        
        // 清除存储
        await this.storageUtil.remove(this.storageKeys.collections, LocalStorageType.DEFAULT);
        await this.storageUtil.remove(this.storageKeys.items, LocalStorageType.DEFAULT);
        await this.storageUtil.remove(this.storageKeys.stats, LocalStorageType.DEFAULT);
        await this.storageUtil.remove(this.storageKeys.defaultCollection, LocalStorageType.DEFAULT);
        
        // 清除过滤器缓存
        this.clearFilterCache();
        
        // 创建新的默认集合
        await this.createDefaultCollection();
        
        this.logger.info('All collection data cleared');
        
        return true;
      } catch (error) {
        this.logger.error('Failed to clear collection data', error as Error);
        return false;
      }
    }

    /**
     * 销毁收藏仓库
     */
    public async destroy(): Promise<void> {
      try {
        // 停止自动同步和备份
        this.stopAutoSync();
        this.stopAutoBackup();
        
        // 清除缓存
        this.filterCache.clear();
        
        // 移除事件监听器
        // 注意：在实际应用中，需要移除所有添加的事件监听器
        
        this.logger.info('CollectionRepository destroyed');
      } catch (error) {
        this.logger.error('Failed to destroy CollectionRepository', error as Error);
      }
    }
  }

// 导出CollectionEventType常量
export { CollectionEventType };
      this.logger.error('Failed to initialize CollectionRepository', error as Error);
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
        this.syncCollections().catch(err => {
          this.logger.warn('Failed to sync collections when network connected', err);
        });
      }
    });
    
    // 监听用户登录/登出事件
    this.eventBus.on('auth:loggedIn', async () => {
      // 用户登录后，同步收藏数据
      this.syncCollections().catch(err => {
        this.logger.warn('Failed to sync collections after login', err);
      });
    });
    
    this.eventBus.on('auth:loggedOut', async () => {
      // 用户登出后，清空数据（如果需要）
      // 注意：这里可能需要根据应用策略决定是否清空
      // 为了保持示例简单，这里不清空，但在实际应用中可能需要
      this.logger.info('User logged out, collection data preserved locally');
    });
    
    // 监听视频删除事件
    this.eventBus.on('video:deleted', async (event: { videoId: string }) => {
      // 标记相关收藏项目为已删除
      const itemIds = this.getItemsByContentId(event.videoId);
      for (const itemId of itemIds) {
        await this.markItemAsRemoved(itemId, 'content_deleted');
      }
    });
    
    // 监听直播删除事件
    this.eventBus.on('live:deleted', async (event: { streamId: string }) => {
      // 标记相关收藏项目为已删除
      const itemIds = this.getItemsByContentId(event.streamId);
      for (const itemId of itemIds) {
        await this.markItemAsRemoved(itemId, 'content_deleted');
      }
    });
  }

  /**
   * 加载存储配置
   */
  private async loadStorageConfig(): Promise<void> {
    try {
      const config = await this.storageUtil.getObject<CollectionStorageConfig>(
        this.storageKeys.config,
        LocalStorageType.DEFAULT
      );
      
      if (config) {
        this.storageConfig = { ...this.defaultStorageConfig, ...config };
      }
      
      this.logger.debug('Collection storage configuration loaded');
    } catch (error) {
      this.logger.error('Failed to load collection storage config', error as Error);
    }
  }

  /**
   * 设置存储配置
   */
  public async setStorageConfig(config: Partial<CollectionStorageConfig>): Promise<CollectionStorageConfig> {
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
      
      // 更新自动备份状态
      if (this.storageConfig.enableBackup) {
        this.startAutoBackup();
      } else {
        this.stopAutoBackup();
      }
      
      this.logger.info('Collection storage configuration updated');
      
      return { ...this.storageConfig };
    } catch (error) {
      this.logger.error('Failed to set collection storage config', error as Error);
      throw error;
    }
  }

  /**
   * 加载集合数据
   */
  private async loadCollections(): Promise<void> {
    try {
      if (this.storageConfig.persistCollections) {
        const collectionsData = await this.storageUtil.getObject<Record<string, Collection>>(
          this.storageKeys.collections,
          LocalStorageType.DEFAULT
        );
        
        if (collectionsData) {
          this.collections = new Map(Object.entries(collectionsData));
          this.logger.debug(`Loaded ${this.collections.size} collections from storage`);
        }
      }
      
      // 如果没有集合数据，创建默认集合
      if (this.collections.size === 0) {
        await this.createDefaultCollection();
      }
    } catch (error) {
      this.logger.error('Failed to load collections', error as Error);
      // 尝试创建默认集合
      await this.createDefaultCollection();
    }
  }

  /**
   * 创建默认集合
   */
  private async createDefaultCollection(): Promise<void> {
    try {
      const currentUser = await this.userRepository.getCurrentUser();
      const userId = currentUser?.id || 'anonymous';
      
      const defaultCollection: Collection = {
        id: `default_collection_${userId}`,
        userId,
        name: '我的收藏',
        description: '默认收藏集合',
        visibility: CollectionVisibility.PRIVATE,
        metadata: {
          itemCount: 0,
          viewCount: 0,
          followerCount: 0,
          lastUpdated: Date.now(),
          createdAt: Date.now(),
          description: '存储您收藏的所有内容',
          isPublic: false,
          isCollaborative: false
        },
        status: 'active',
        isDefault: true,
        coverImageUrl: undefined,
        iconUrl: undefined,
        createdAt: Date.now(),
        updatedAt: Date.now(),
        autoAddNewItems: true
      };
      
      // 添加默认集合
      this.collections.set(defaultCollection.id, defaultCollection);
      this.defaultCollectionId = defaultCollection.id;
      
      // 保存集合
      await this.saveCollections();
      await this.saveDefaultCollection();
      
      this.logger.info('Created default collection');
    } catch (error) {
      this.logger.error('Failed to create default collection', error as Error);
    }
  }

  /**
   * 保存集合数据
   */
  private async saveCollections(): Promise<void> {
    try {
      if (this.storageConfig.persistCollections) {
        // 转换Map为对象以便存储
        const collectionsObject: Record<string, Collection> = {};
        this.collections.forEach((collection, id) => {
          collectionsObject[id] = collection;
        });
        
        await this.storageUtil.setObject(
          this.storageKeys.collections,
          collectionsObject,
          LocalStorageType.DEFAULT
        );
        
        this.logger.debug(`Saved ${this.collections.size} collections to storage`);
      }
    } catch (error) {
      this.logger.error('Failed to save collections', error as Error);
    }
  }

  /**
   * 加载项目数据
   */
  private async loadItems(): Promise<void> {
    try {
      if (this.storageConfig.persistCollections) {
        const itemsData = await this.storageUtil.getObject<Record<string, CollectionItem>>(
          this.storageKeys.items,
          LocalStorageType.DEFAULT
        );
        
        if (itemsData) {
          this.items = new Map(Object.entries(itemsData));
          
          // 重建索引
          this.rebuildIndexes();
          
          this.logger.debug(`Loaded ${this.items.size} collection items from storage`);
        }
      }
    } catch (error) {
      this.logger.error('Failed to load collection items', error as Error);
      // 清空索引
      this.itemsByCollection.clear();
      this.itemsByContentId.clear();
    }
  }

  /**
   * 重建项目索引
   */
  private rebuildIndexes(): void {
    // 清空现有索引
    this.itemsByCollection.clear();
    this.itemsByContentId.clear();
    
    // 重建索引
    this.items.forEach(item => {
      // 按集合ID索引
      if (!this.itemsByCollection.has(item.collectionId)) {
        this.itemsByCollection.set(item.collectionId, new Set());
      }
      this.itemsByCollection.get(item.collectionId)!.add(item.id);
      
      // 按内容ID索引
      if (!this.itemsByContentId.has(item.contentId)) {
        this.itemsByContentId.set(item.contentId, new Set());
      }
      this.itemsByContentId.get(item.contentId)!.add(item.id);
    });
  }

  /**
   * 保存项目数据
   */
  private async saveItems(): Promise<void> {
    try {
      if (this.storageConfig.persistCollections) {
        // 转换Map为对象以便存储
        const itemsObject: Record<string, CollectionItem> = {};
        this.items.forEach((item, id) => {
          itemsObject[id] = item;
        });
        
        await this.storageUtil.setObject(
          this.storageKeys.items,
          itemsObject,
          LocalStorageType.DEFAULT
        );
        
        this.logger.debug(`Saved ${this.items.size} collection items to storage`);
      }
    } catch (error) {
      this.logger.error('Failed to save collection items', error as Error);
    }
  }

  /**
   * 加载默认集合ID
   */
  private async loadDefaultCollection(): Promise<void> {
    try {
      const defaultId = await this.storageUtil.getString(
        this.storageKeys.defaultCollection,
        LocalStorageType.DEFAULT
      );
      
      if (defaultId && this.collections.has(defaultId)) {
        this.defaultCollectionId = defaultId;
      } else {
        // 如果没有有效的默认集合，查找第一个标记为默认的集合
        for (const [id, collection] of this.collections.entries()) {
          if (collection.isDefault) {
            this.defaultCollectionId = id;
            break;
          }
        }
      }
      
      this.logger.debug(`Default collection ID: ${this.defaultCollectionId}`);
    } catch (error) {
      this.logger.error('Failed to load default collection', error as Error);
    }
  }

  /**
   * 保存默认集合ID
   */
  private async saveDefaultCollection(): Promise<void> {
    try {
      if (this.defaultCollectionId) {
        await this.storageUtil.setString(
          this.storageKeys.defaultCollection,
          this.defaultCollectionId,
          LocalStorageType.DEFAULT
        );
      }
    } catch (error) {
      this.logger.error('Failed to save default collection', error as Error);
    }
  }

  /**
   * 加载统计
   */
  private async loadStats(): Promise<void> {
    try {
      const statsData = await this.storageUtil.getObject<{
        totalCollections: number;
        totalItems: number;
        byType: [CollectionItemType, number][];
        byVisibility: [CollectionVisibility, number][];
        publicCollections: number;
        privateCollections: number;
        favoriteItems: number;
        completedItems: number;
        lastUpdated: number;
      }>(
        this.storageKeys.stats,
        LocalStorageType.DEFAULT
      );
      
      if (statsData) {
        this.collectionStats = {
          ...statsData,
          byType: new Map(statsData.byType),
          byVisibility: new Map(statsData.byVisibility)
        };
      } else {
        // 计算统计数据
        await this.updateStats();
      }
    } catch (error) {
      this.logger.warn('Failed to load collection stats', error as Error);
      this.resetStats();
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
      this.syncCollections().catch(err => {
        this.logger.warn('Failed to sync collections in auto-sync timer', err);
      });
    }, this.storageConfig.syncInterval);
    
    this.logger.debug('Auto-sync for collections started');
  }

  /**
   * 停止自动同步
   */
  private stopAutoSync(): void {
    if (this.syncTimer !== null) {
      clearInterval(this.syncTimer);
      this.syncTimer = null;
      this.logger.debug('Auto-sync for collections stopped');
    }
  }

  /**
   * 启动自动备份
   */
  private startAutoBackup(): void {
    // 停止现有的备份
    this.stopAutoBackup();
    
    // 设置定期备份
    this.backupTimer = setInterval(() => {
      this.backupCollections().catch(err => {
        this.logger.warn('Failed to backup collections in auto-backup timer', err);
      });
    }, this.storageConfig.backupInterval);
    
    this.logger.debug('Auto-backup for collections started');
  }

  /**
   * 停止自动备份
   */
  private stopAutoBackup(): void {
    if (this.backupTimer !== null) {
      clearInterval(this.backupTimer);
      this.backupTimer = null;
      this.logger.debug('Auto-backup for collections stopped');
    }
  }

  /**
   * 同步收藏数据
   */
  public async syncCollections(): Promise<boolean> {
    try {
      // 防止并发同步
      if (this.isSyncing || this.storageConfig.offlineMode) {
        return false;
      }
      
      const currentUser = await this.userRepository.getCurrentUser();
      if (!currentUser) {
        // 未登录用户不进行同步
        return false;
      }
      
      this.isSyncing = true;
      
      // 在实际应用中，这里应该调用服务器API同步收藏数据
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
      this.eventBus.emit(CollectionEventType.SYNCED, {
        type: CollectionEventType.SYNCED,
        timestamp: Date.now()
      } as CollectionEvent);
      
      this.logger.info('Collections synced successfully');
      
      return true;
    } catch (error) {
      this.logger.error('Failed to sync collections', error as Error);
      
      // 发布同步失败事件
      this.eventBus.emit(CollectionEventType.SYNC_FAILED, {
        type: CollectionEventType.SYNC_FAILED,
        timestamp: Date.now(),
        error: error as Error
      } as CollectionEvent);
      
      // 发布错误事件
      this.eventBus.emit(CollectionEventType.ERROR, {
        type: CollectionEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CollectionEvent);
      
      return false;
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * 备份收藏数据
   */
  public async backupCollections(): Promise<boolean> {
    try {
      if (!this.storageConfig.enableBackup) {
        return false;
      }
      
      // 在实际应用中，这里应该执行备份操作
      // 例如，将数据导出到文件系统或远程存储
      
      // 这里简化处理，仅记录日志
      this.logger.info('Collections backed up successfully');
      
      return true;
    } catch (error) {
      this.logger.error('Failed to backup collections', error as Error);
      return false;
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
   * 获取所有集合
   */
  public async getAllCollections(request?: CollectionRequest): Promise<CollectionResponse> {
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
      
      // 获取当前用户
      const currentUser = await this.userRepository.getCurrentUser();
      const userId = currentUser?.id || 'anonymous';
      
      // 转换为数组进行过滤
      let collections = Array.from(this.collections.values());
      
      // 应用过滤条件
      if (filter.userId) {
        collections = collections.filter(col => col.userId === filter.userId);
      }
      
      if (filter.status && filter.status.length > 0) {
        collections = collections.filter(col => filter.status!.includes(col.status));
      } else if (!filter.includeArchived) {
        // 默认不包含归档集合
        collections = collections.filter(col => col.status === 'active');
      }
      
      if (filter.visibility && filter.visibility.length > 0) {
        collections = collections.filter(col => filter.visibility!.includes(col.visibility));
      }
      
      if (filter.searchTerm) {
        const searchLower = filter.searchTerm.toLowerCase();
        collections = collections.filter(col => 
          col.name.toLowerCase().includes(searchLower) ||
          (col.description && col.description.toLowerCase().includes(searchLower)) ||
          (col.metadata.tags && col.metadata.tags.some(tag => tag.toLowerCase().includes(searchLower)))
        );
      }
      
      if (filter.tags && filter.tags.length > 0) {
        collections = collections.filter(col => 
          col.metadata.tags && filter.tags!.some(tag => col.metadata.tags!.includes(tag))
        );
      }
      
      if (filter.isDefault !== undefined) {
        collections = collections.filter(col => col.isDefault === filter.isDefault);
      }
      
      if (filter.ownedOnly) {
        collections = collections.filter(col => col.userId === userId);
      }
      
      // 根据可见性过滤（考虑共享集合）
      collections = collections.filter(col => {
        if (col.visibility === CollectionVisibility.PUBLIC) {
          return true;
        } else if (col.visibility === CollectionVisibility.PRIVATE) {
          return col.userId === userId;
        } else if (col.visibility === CollectionVisibility.SHARED) {
          return col.userId === userId || 
                 (col.allowedUserIds && col.allowedUserIds.includes(userId));
        }
        return false;
      });
      
      // 应用排序
      collections = this.sortCollections(collections, filter.sortBy);
      
      // 应用分页
      const totalCount = collections.length;
      let offset = filter.offset || 0;
      let limit = filter.limit || totalCount;
      
      const pagedCollections = collections.slice(offset, offset + limit);
      
      // 创建响应
      const response: CollectionResponse = {
        collections: pagedCollections,
        totalCount,
        hasMore: offset + limit < totalCount,
        timestamp: Date.now()
      };
      
      // 如果需要，加载集合中的项目
      if (request?.includeItems) {
        const allItems: CollectionItem[] = [];
        for (const collection of pagedCollections) {
          const items = await this.getCollectionItems(collection.id, {
            includeRemoved: filter.includeArchived || false
          });
          allItems.push(...items);
        }
        response.items = allItems;
      }
      
      // 更新缓存
      if (request?.cachePolicy !== CachePolicy.NETWORK_ONLY) {
        this.updateFilterCache(cacheKey, response);
      }
      
      return response;
    } catch (error) {
      this.logger.error('Failed to get collections', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CollectionEventType.ERROR, {
        type: CollectionEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CollectionEvent);
      
      return {
        collections: [],
        totalCount: 0,
        hasMore: false,
        timestamp: Date.now()
      };
    }
  }

  /**
   * 对集合进行排序
   */
  private sortCollections(collections: Collection[], sortBy?: CollectionSortType): Collection[] {
    const sorted = [...collections];
    
    if (!sortBy) {
      // 默认排序：默认集合在前，然后按更新时间降序
      return sorted.sort((a, b) => {
        if (a.isDefault !== b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        return b.updatedAt - a.updatedAt;
      });
    }
    
    switch (sortBy) {
      case CollectionSortType.NAME_ASC:
        return sorted.sort((a, b) => a.name.localeCompare(b.name));
        
      case CollectionSortType.NAME_DESC:
        return sorted.sort((a, b) => b.name.localeCompare(a.name));
        
      case CollectionSortType.ADDED_DATE_ASC:
        return sorted.sort((a, b) => a.createdAt - b.createdAt);
        
      case CollectionSortType.ADDED_DATE_DESC:
        return sorted.sort((a, b) => b.createdAt - a.createdAt);
        
      case CollectionSortType.CUSTOM:
      default:
        // 默认排序
        return sorted.sort((a, b) => {
          if (a.isDefault !== b.isDefault) {
            return a.isDefault ? -1 : 1;
          }
          return b.updatedAt - a.updatedAt;
        });
    }
  }

  /**
   * 更新过滤器缓存
   */
  private updateFilterCache(key: string, response: CollectionResponse): void {
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
   * 获取集合详情
   */
  public async getCollectionById(id: string): Promise<Collection | null> {
    try {
      const collection = this.collections.get(id);
      
      if (collection) {
        // 更新查看次数
        collection.metadata.viewCount++;
        await this.saveCollections();
        
        // 发布查看事件
        this.eventBus.emit(CollectionEventType.COLLECTION_VIEWED, {
          type: CollectionEventType.COLLECTION_VIEWED,
          timestamp: Date.now(),
          collection
        } as CollectionEvent);
        
        // 返回深拷贝
        return JSON.parse(JSON.stringify(collection));
      }
      
      return null;
    } catch (error) {
      this.logger.error(`Failed to get collection by id: ${id}`, error as Error);
      return null;
    }
  }

  /**
   * 获取默认集合
   */
  public async getDefaultCollection(): Promise<Collection | null> {
    try {
      if (!this.defaultCollectionId) {
        await this.loadDefaultCollection();
      }
      
      return this.defaultCollectionId ? 
        await this.getCollectionById(this.defaultCollectionId) : 
        null;
    } catch (error) {
      this.logger.error('Failed to get default collection', error as Error);
      return null;
    }
  }

  /**
   * 设置默认集合
   */
  public async setDefaultCollection(collectionId: string): Promise<boolean> {
    try {
      const collection = this.collections.get(collectionId);
      
      if (!collection) {
        return false;
      }
      
      // 检查权限
      const currentUser = await this.userRepository.getCurrentUser();
      if (!currentUser || currentUser.id !== collection.userId) {
        this.logger.warn('User does not have permission to set default collection');
        return false;
      }
      
      // 移除之前的默认标记
      for (const [id, col] of this.collections.entries()) {
        if (col.isDefault) {
          col.isDefault = false;
        }
      }
      
      // 设置新的默认集合
      collection.isDefault = true;
      this.defaultCollectionId = collectionId;
      
      // 保存更改
      await this.saveCollections();
      await this.saveDefaultCollection();
      
      this.logger.info(`Default collection set to: ${collection.name} (${collectionId})`);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to set default collection: ${collectionId}`, error as Error);
      return false;
    }
  }

  /**
   * 获取集合中的项目
   */
  public async getCollectionItems(
    collectionId: string,
    options?: {
      includeRemoved?: boolean;
      filter?: CollectionFilter;
      sortBy?: CollectionSortType;
    }
  ): Promise<CollectionItem[]> {
    try {
      const { includeRemoved = false, filter = {}, sortBy } = options || {};
      
      // 获取集合中的所有项目ID
      const itemIds = this.itemsByCollection.get(collectionId) || new Set();
      
      // 获取项目对象
      let items = Array.from(itemIds)
        .map(id => this.items.get(id))
        .filter((item): item is CollectionItem => !!item);
      
      // 是否包含已移除的项目
      if (!includeRemoved) {
        items = items.filter(item => item.status === 'active');
      }
      
      // 应用过滤条件
      if (filter.itemTypes && filter.itemTypes.length > 0) {
        items = items.filter(item => filter.itemTypes!.includes(item.type));
      }
      
      if (filter.searchTerm) {
        const searchLower = filter.searchTerm.toLowerCase();
        items = items.filter(item => 
          item.title.toLowerCase().includes(searchLower) ||
          (item.tags && item.tags.some(tag => tag.toLowerCase().includes(searchLower)))
        );
      }
      
      if (filter.tags && filter.tags.length > 0) {
        items = items.filter(item => 
          item.tags && filter.tags!.some(tag => item.tags!.includes(tag))
        );
      }
      
      if (filter.favoriteOnly) {
        items = items.filter(item => item.metadata.favorite);
      }
      
      if (filter.completedOnly !== undefined) {
        items = items.filter(item => item.metadata.completed === filter.completedOnly);
      }
      
      if (filter.dateFrom) {
        items = items.filter(item => item.metadata.addedDate >= filter.dateFrom!);
      }
      
      if (filter.dateTo) {
        items = items.filter(item => item.metadata.addedDate <= filter.dateTo!);
      }
      
      // 应用排序
      items = this.sortItems(items, sortBy);
      
      return items;
    } catch (error) {
      this.logger.error(`Failed to get items for collection: ${collectionId}`, error as Error);
      return [];
    }
  }

  /**
   * 对项目进行排序
   */
  private sortItems(items: CollectionItem[], sortBy?: CollectionSortType): CollectionItem[] {
    const sorted = [...items];
    
    if (!sortBy) {
      // 默认按添加日期降序
      return sorted.sort((a, b) => b.metadata.addedDate - a.metadata.addedDate);
    }
    
    switch (sortBy) {
      case CollectionSortType.ADDED_DATE_ASC:
        return sorted.sort((a, b) => a.metadata.addedDate - b.metadata.addedDate);
        
      case CollectionSortType.ADDED_DATE_DESC:
        return sorted.sort((a, b) => b.metadata.addedDate - a.metadata.addedDate);
        
      case CollectionSortType.NAME_ASC:
        return sorted.sort((a, b) => a.title.localeCompare(b.title));
        
      case CollectionSortType.NAME_DESC:
        return sorted.sort((a, b) => b.title.localeCompare(a.title));
        
      case CollectionSortType.RELEASE_DATE_ASC:
        return sorted.sort((a, b) => {
          const aDate = a.publishDate || 0;
          const bDate = b.publishDate || 0;
          return aDate - bDate;
        });
        
      case CollectionSortType.RELEASE_DATE_DESC:
        return sorted.sort((a, b) => {
          const aDate = a.publishDate || 0;
          const bDate = b.publishDate || 0;
          return bDate - aDate;
        });
        
      case CollectionSortType.VIEWS_ASC:
        return sorted.sort((a, b) => {
          const aViews = a.viewCount || 0;
          const bViews = b.viewCount || 0;
          return aViews - bViews;
        });
        
      case CollectionSortType.VIEWS_DESC:
        return sorted.sort((a, b) => {
          const aViews = a.viewCount || 0;
          const bViews = b.viewCount || 0;
          return bViews - aViews;
        });
        
      case CollectionSortType.DURATION_ASC:
        return sorted.sort((a, b) => {
          const aDuration = a.duration || 0;
          const bDuration = b.duration || 0;
          return aDuration - bDuration;
        });
        
      case CollectionSortType.DURATION_DESC:
        return sorted.sort((a, b) => {
          const aDuration = a.duration || 0;
          const bDuration = b.duration || 0;
          return bDuration - aDuration;
        });
        
      case CollectionSortType.CUSTOM:
        return sorted.sort((a, b) => {
          const aOrder = a.metadata.sortOrder !== undefined ? a.metadata.sortOrder : 9999;
          const bOrder = b.metadata.sortOrder !== undefined ? b.metadata.sortOrder : 9999;
          return aOrder - bOrder;
        });
        
      default:
        return sorted.sort((a, b) => b.metadata.addedDate - a.metadata.addedDate);
    }
  }

  /**
   * 获取项目详情
   */
  public async getItemById(id: string): Promise<CollectionItem | null> {
    try {
      const item = this.items.get(id);
      
      if (item) {
        // 更新查看次数
        item.metadata.viewCount++;
        item.metadata.lastViewedDate = Date.now();
        await this.saveItems();
        
        // 返回深拷贝
        return JSON.parse(JSON.stringify(item));
      }
      
      return null;
    } catch (error) {
      this.logger.error(`Failed to get item by id: ${id}`, error as Error);
      return null;
    }
  }

  /**
   * 检查内容是否已收藏
   */
  public async isContentInCollection(
    contentId: string,
    type: CollectionItemType,
    collectionId?: string
  ): Promise<boolean> {
    try {
      const itemIds = this.itemsByContentId.get(contentId) || new Set();
      
      for (const itemId of itemIds) {
        const item = this.items.get(itemId);
        if (item && item.type === type) {
          if (!collectionId || item.collectionId === collectionId) {
            return true;
          }
        }
      }
      
      return false;
    } catch (error) {
      this.logger.error(`Failed to check if content is in collection: ${contentId}`, error as Error);
      return false;
    }
  }

  /**
   * 获取内容的所有收藏项
   */
  private getItemsByContentId(contentId: string): string[] {
    return Array.from(this.itemsByContentId.get(contentId) || new Set());
  }

  /**
   * 创建新集合
   */
  public async createCollection(
    collection: Omit<Collection, 'id' | 'metadata' | 'createdAt' | 'updatedAt'>
  ): Promise<Collection> {
    try {
      const currentUser = await this.userRepository.getCurrentUser();
      const userId = currentUser?.id || 'anonymous';
      
      const newCollection: Collection = {
        ...collection,
        id: `collection_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        userId,
        metadata: {
          itemCount: 0,
          viewCount: 0,
          followerCount: 0,
          lastUpdated: Date.now(),
          createdAt: Date.now(),
          description: collection.description || '',
          isPublic: collection.visibility === CollectionVisibility.PUBLIC,
          isCollaborative: collection.metadata?.isCollaborative || false,
          tags: collection.metadata?.tags || [],
          contributors: collection.metadata?.contributors || [],
          categoryId: collection.metadata?.categoryId
        },
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      
      // 添加到集合列表
      this.collections.set(newCollection.id, newCollection);
      
      // 如果是第一个集合或标记为默认，则设置为默认集合
      if (this.collections.size === 1 || newCollection.isDefault) {
        await this.setDefaultCollection(newCollection.id);
      }
      
      // 保存集合
      await this.saveCollections();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布创建事件
      this.eventBus.emit(CollectionEventType.COLLECTION_CREATED, {
        type: CollectionEventType.COLLECTION_CREATED,
        timestamp: Date.now(),
        collection: newCollection
      } as CollectionEvent);
      
      this.logger.info(`Collection created: ${newCollection.name} (${newCollection.id})`);
      
      return newCollection;
    } catch (error) {
      this.logger.error('Failed to create collection', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CollectionEventType.ERROR, {
        type: CollectionEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CollectionEvent);
      
      throw error;
    }
  }

  /**
   * 更新集合
   */
  public async updateCollection(
    id: string,
    updates: Partial<Collection>
  ): Promise<Collection | null> {
    try {
      const collection = this.collections.get(id);
      
      if (!collection) {
        return null;
      }
      
      // 检查权限
      const currentUser = await this.userRepository.getCurrentUser();
      if (!currentUser || currentUser.id !== collection.userId) {
        this.logger.warn('User does not have permission to update collection');
        return null;
      }
      
      const oldCollection = { ...collection };
      
      // 更新集合属性
      const updatedCollection: Collection = {
        ...collection,
        ...updates,
        metadata: {
          ...collection.metadata,
          ...updates.metadata,
          lastUpdated: Date.now()
        },
        updatedAt: Date.now()
      };
      
      // 处理状态变更
      if (updates.status === 'archived' && oldCollection.status === 'active') {
        this.eventBus.emit(CollectionEventType.COLLECTION_ARCHIVED, {
          type: CollectionEventType.COLLECTION_ARCHIVED,
          timestamp: Date.now(),
          collection: updatedCollection
        } as CollectionEvent);
      } else if (updates.status === 'active' && oldCollection.status === 'archived') {
        this.eventBus.emit(CollectionEventType.COLLECTION_ACTIVATED, {
          type: CollectionEventType.COLLECTION_ACTIVATED,
          timestamp: Date.now(),
          collection: updatedCollection
        } as CollectionEvent);
      }
      
      // 更新集合
      this.collections.set(id, updatedCollection);
      
      // 保存集合
      await this.saveCollections();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布更新事件
      this.eventBus.emit(CollectionEventType.COLLECTION_UPDATED, {
        type: CollectionEventType.COLLECTION_UPDATED,
        timestamp: Date.now(),
        collection: updatedCollection
      } as CollectionEvent);
      
      this.logger.info(`Collection updated: ${updatedCollection.name} (${id})`);
      
      return updatedCollection;
    } catch (error) {
      this.logger.error(`Failed to update collection: ${id}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CollectionEventType.ERROR, {
        type: CollectionEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CollectionEvent);
      
      return null;
    }
  }

  /**
   * 删除集合
   */
  public async deleteCollection(id: string): Promise<boolean> {
    try {
      const collection = this.collections.get(id);
      
      if (!collection) {
        return false;
      }
      
      // 检查权限
      const currentUser = await this.userRepository.getCurrentUser();
      if (!currentUser || currentUser.id !== collection.userId) {
        this.logger.warn('User does not have permission to delete collection');
        return false;
      }
      
      // 检查是否为默认集合
      if (collection.isDefault) {
        // 找到另一个集合作为默认集合
        let newDefaultId: string | null = null;
        for (const [colId, col] of this.collections.entries()) {
          if (colId !== id && col.status === 'active' && col.userId === currentUser.id) {
            newDefaultId = colId;
            break;
          }
        }
        
        if (newDefaultId) {
          await this.setDefaultCollection(newDefaultId);
        }
      }
      
      // 获取集合中的所有项目
      const itemIds = this.itemsByCollection.get(id) || new Set();
      
      // 删除所有项目
      for (const itemId of itemIds) {
        this.items.delete(itemId);
        
        // 更新内容ID索引
        const item = this.items.get(itemId);
        if (item && this.itemsByContentId.has(item.contentId)) {
          this.itemsByContentId.get(item.contentId)!.delete(itemId);
          if (this.itemsByContentId.get(item.contentId)!.size === 0) {
            this.itemsByContentId.delete(item.contentId);
          }
        }
      }
      
      // 移除集合
      const removed = this.collections.delete(id);
      
      // 移除集合索引
      this.itemsByCollection.delete(id);
      
      // 保存数据
      await this.saveCollections();
      await this.saveItems();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布删除事件
      this.eventBus.emit(CollectionEventType.COLLECTION_DELETED, {
        type: CollectionEventType.COLLECTION_DELETED,
        timestamp: Date.now(),
        collection
      } as CollectionEvent);
      
      this.logger.info(`Collection deleted: ${collection.name} (${id})`);
      
      return removed;
    } catch (error) {
      this.logger.error(`Failed to delete collection: ${id}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CollectionEventType.ERROR, {
        type: CollectionEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CollectionEvent);
      
      return false;
    }
  }

  /**
   * 归档集合
   */
  public async archiveCollection(id: string): Promise<boolean> {
    try {
      const updated = await this.updateCollection(id, { status: 'archived' });
      return updated !== null;
    } catch (error) {
      this.logger.error(`Failed to archive collection: ${id}`, error as Error);
      return false;
    }
  }

  /**
   * 激活集合
   */
  public async activateCollection(id: string): Promise<boolean> {
    try {
      const updated = await this.updateCollection(id, { status: 'active' });
      return updated !== null;
    } catch (error) {
      this.logger.error(`Failed to activate collection: ${id}`, error as Error);
      return false;
    }
  }

  /**
   * 添加项目到集合
   */
  public async addItemToCollection(
    collectionId: string,
    itemData: {
      type: CollectionItemType;
      contentId: string;
      title: string;
      thumbnailUrl?: string;
      duration?: number;
      publishDate?: number;
      viewCount?: number;
      channelId?: string;
      channelName?: string;
      tags?: string[];
      metadata?: Partial<CollectionItemMetadata>;
    }
  ): Promise<CollectionItem | null> {
    try {
      const collection = this.collections.get(collectionId);
      
      if (!collection || collection.status !== 'active') {
        return null;
      }
      
      // 检查权限
      const currentUser = await this.userRepository.getCurrentUser();
      if (!currentUser || currentUser.id !== collection.userId) {
        this.logger.warn('User does not have permission to add item to collection');
        return null;
      }
      
      // 检查是否已存在相同的项目
      if (await this.isContentInCollection(itemData.contentId, itemData.type, collectionId)) {
        this.logger.warn(`Content already in collection: ${itemData.contentId}`);
        return null;
      }
      
      // 创建新项目
      const newItem: CollectionItem = {
        id: `collection_item_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        type: itemData.type,
        contentId: itemData.contentId,
        userId: currentUser.id,
        collectionId,
        metadata: {
          addedDate: Date.now(),
          viewCount: 0,
          completed: false,
          favorite: false,
          tags: [],
          ...itemData.metadata
        },
        title: itemData.title,
        thumbnailUrl: itemData.thumbnailUrl,
        duration: itemData.duration,
        publishDate: itemData.publishDate,
        viewCount: itemData.viewCount,
        channelId: itemData.channelId,
        channelName: itemData.channelName,
        tags: itemData.tags,
        status: 'active'
      };
      
      // 添加项目
      this.items.set(newItem.id, newItem);
      
      // 更新索引
      if (!this.itemsByCollection.has(collectionId)) {
        this.itemsByCollection.set(collectionId, new Set());
      }
      this.itemsByCollection.get(collectionId)!.add(newItem.id);
      
      if (!this.itemsByContentId.has(newItem.contentId)) {
        this.itemsByContentId.set(newItem.contentId, new Set());
      }
      this.itemsByContentId.get(newItem.contentId)!.add(newItem.id);
      
      // 更新集合的项目计数
      collection.metadata.itemCount++;
      collection.metadata.lastUpdated = Date.now();
      collection.updatedAt = Date.now();
      
      // 保存数据
      await this.saveCollections();
      await this.saveItems();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布添加事件
      this.eventBus.emit(CollectionEventType.ITEM_ADDED, {
        type: CollectionEventType.ITEM_ADDED,
        timestamp: Date.now(),
        collection,
        item: newItem
      } as CollectionEvent);
      
      this.logger.info(`Item added to collection: ${newItem.title} (${newItem.id}) -> ${collection.name} (${collectionId})`);
      
      return newItem;
    } catch (error) {
      this.logger.error(`Failed to add item to collection: ${collectionId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CollectionEventType.ERROR, {
        type: CollectionEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CollectionEvent);
      
      return null;
    }
  }

  /**
   * 从集合中移除项目
   */
  public async removeItemFromCollection(itemId: string): Promise<boolean> {
    try {
      const item = this.items.get(itemId);
      
      if (!item) {
        return false;
      }
      
      const collection = this.collections.get(item.collectionId);
      
      if (!collection) {
        return false;
      }
      
      // 检查权限
      const currentUser = await this.userRepository.getCurrentUser();
      if (!currentUser || currentUser.id !== collection.userId) {
        this.logger.warn('User does not have permission to remove item from collection');
        return false;
      }
      
      // 从索引中移除
      if (this.itemsByCollection.has(item.collectionId)) {
        this.itemsByCollection.get(item.collectionId)!.delete(itemId);
        if (this.itemsByCollection.get(item.collectionId)!.size === 0) {
          this.itemsByCollection.delete(item.collectionId);
        }
      }
      
      if (this.itemsByContentId.has(item.contentId)) {
        this.itemsByContentId.get(item.contentId)!.delete(itemId);
        if (this.itemsByContentId.get(item.contentId)!.size === 0) {
          this.itemsByContentId.delete(item.contentId);
        }
      }
      
      // 从项目列表中移除
      const removed = this.items.delete(itemId);
      
      // 更新集合的项目计数
      if (collection.metadata.itemCount > 0) {
        collection.metadata.itemCount--;
      }
      collection.metadata.lastUpdated = Date.now();
      collection.updatedAt = Date.now();
      
      // 保存数据
      await this.saveCollections();
      await this.saveItems();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布移除事件
      this.eventBus.emit(CollectionEventType.ITEM_REMOVED, {
        type: CollectionEventType.ITEM_REMOVED,
        timestamp: Date.now(),
        collection,
        item
      } as CollectionEvent);
      
      this.logger.info(`Item removed from collection: ${item.title} (${itemId}) -> ${collection.name} (${item.collectionId})`);
      
      return removed;
    } catch (error) {
      this.logger.error(`Failed to remove item from collection: ${itemId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(CollectionEventType.ERROR, {
        type: CollectionEventType.ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as CollectionEvent);
      
      return false;
    }
  }

  /**
   * 标记项目为已移除
   */
  private async markItemAsRemoved(itemId: string, reason: string): Promise<void> {
    try {
      const item = this.items.get(itemId);
      
      if (!item) {
        return;
      }
      
      // 更新项目状态
      item.status = 'removed';
      
      // 保存项目
      await this.saveItems();
      
      this.logger.info(`Item marked as removed: ${item.title} (${itemId}) - Reason: ${reason}`);
    } catch (error) {
      this.logger.error(`Failed to mark item as removed: ${itemId}`, error as Error);
    }
  }

  /**
   * 更新项目元数据
   */
  public async updateItemMetadata(
    itemId: string,
    metadata: Partial<CollectionItemMetadata>
  ): Promise<CollectionItem | null> {
    try {
      const item = this.items.get(itemId);
      
      if (!item) {
        return null;
      }
      
      const collection = this.collections.get(item.collectionId);
      
      if (!collection) {
        return null;
      }
      
      // 检查权限
      const currentUser = await this.userRepository.getCurrentUser();
      if (!currentUser || currentUser.id !== collection.userId) {
        this.logger.warn('User does not have permission to update item metadata');
        return null;
      }
      
      // 更新元数据
      item.metadata = {
        ...item.metadata,
        ...metadata
      };
      
      // 更新集合的最后更新时间
      collection.metadata.lastUpdated = Date.now();
      collection.updatedAt = Date.now();
      
      // 保存数据
      await this.saveCollections();
      await this.saveItems();
      
      // 更新统计
      await this.updateStats();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布更新事件
      this.eventBus.emit(CollectionEventType.ITEM_UPDATED, {
        type: CollectionEventType.ITEM_UPDATED,
        timestamp: Date.now(),
        collection,
        item
      } as CollectionEvent);
      
      this.logger.info(`Item metadata updated: ${item.title} (${itemId})`);
      
      return item;
    } catch (error) {
     