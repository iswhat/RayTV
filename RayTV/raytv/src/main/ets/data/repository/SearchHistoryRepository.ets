// SearchHistoryRepository - 搜索历史仓库 | Search history repository
// 负责管理用户的搜索历史数据，包括保存、获取、删除搜索记录等 | Manages user search history data, including saving, retrieving, deleting search records, etc.

import StorageUtil, { StorageType } from '../../common/util/StorageUtil';
import EventBusUtil from '../../common/util/EventBusUtil';

/**
 * 搜索记录类型枚举 | Search record type enumeration
 */
export enum SearchType {
  VIDEO = 'video',
  LIVE = 'live',
  USER = 'user',
  CATEGORY = 'category',
  TAG = 'tag',
  ALL = 'all'
}

/**
 * 搜索历史记录接口 | Search history record interface
 */
export interface SearchHistoryItem {
  id: string; // 唯一标识符 | Unique identifier
  query: string; // 搜索关键词 | Search keyword
  type: SearchType; // 搜索类型 | Search type
  timestamp: number; // 搜索时间戳 | Search timestamp
  resultCount?: number; // 搜索结果数量 | Search result count
  selected?: boolean; // 是否已被选中 | Whether selected
  isFavorite?: boolean; // 是否为收藏的搜索词 | Whether it is a favorite search term
  category?: string; // 搜索分类（可选） | Search category (optional)
}

/**
 * 搜索历史配置接口 | Search history configuration interface
 */
export interface SearchHistoryConfig {
  maxHistoryItems: number; // 最大历史记录数量 | Maximum history items count
  maxFavoriteItems: number; // 最大收藏搜索词数量 | Maximum favorite searches count
  autoClearDays?: number; // 自动清除天数（可选） | Auto clear days (optional)
  enableAutoComplete: boolean; // 是否启用自动完成 | Whether to enable auto complete
  enableRecentSearches: boolean; // 是否启用最近搜索 | Whether to enable recent searches
  enableFavorites: boolean; // 是否启用收藏功能 | Whether to enable favorites feature
}

/**
 * 搜索历史事件类型接口 | Search history event type interface
 */
export interface SearchHistoryEventTypeInterface {
  readonly SEARCH_HISTORY_ADDED: string;
  readonly SEARCH_HISTORY_DELETED: string;
  readonly SEARCH_HISTORY_CLEARED: string;
  readonly SEARCH_HISTORY_UPDATED: string;
  readonly SEARCH_FAVORITE_TOGGLED: string;
  readonly SEARCH_HISTORY_CONFIG_CHANGED: string;
}

/**
 * 搜索历史事件类型 | Search history event type
 */
export const SearchHistoryEventType: SearchHistoryEventTypeInterface = {
  SEARCH_HISTORY_ADDED: 'searchHistory:added',
  SEARCH_HISTORY_DELETED: 'searchHistory:deleted',
  SEARCH_HISTORY_CLEARED: 'searchHistory:cleared',
  SEARCH_HISTORY_UPDATED: 'searchHistory:updated',
  SEARCH_FAVORITE_TOGGLED: 'searchHistory:favoriteToggled',
  SEARCH_HISTORY_CONFIG_CHANGED: 'searchHistory:configChanged'
};

/**
 * 搜索历史事件数据 | Search history event data
 */
export interface SearchHistoryEvent {
  type: string;
  timestamp: number;
  data?: SearchHistoryItem | DeleteEventData | ClearEventData | FavoriteToggleEventData | SearchHistoryConfig;
  error?: Error;
}

/**
 * 搜索历史导出数据接口 | Search history export data interface
 */
export interface SearchHistoryExportData {
  history: SearchHistoryItem[];
  favorites: SearchHistoryItem[];
  config: SearchHistoryConfig;
  exportTime: number;
}

/**
 * 删除事件数据接口 | Delete event data interface
 */
export interface DeleteEventData {
  id: string;
}

/**
 * 清除事件数据接口 | Clear event data interface
 */
export interface ClearEventData {
  type: string;
}

/**
 * 收藏切换事件数据接口 | Favorite toggle event data interface
 */
export interface FavoriteToggleEventData {
  item: SearchHistoryItem;
  isFavorite: boolean;
}

/**
 * 搜索历史导入数据接口 | Search history import data interface
 */
export interface SearchHistoryImportData {
  history?: SearchHistoryItem[];
  favorites?: SearchHistoryItem[];
  config?: { maxHistoryItems?: number; maxFavoriteItems?: number; autoClearDays?: number; enableAutoComplete?: boolean; enableRecentSearches?: boolean; enableFavorites?: boolean };
}

/**
 * 存储键值映射 | Storage keys mapping
 */
interface StorageKeys {
  searchHistory: string;
  favoriteSearches: string;
  searchHistoryConfig: string;
  recentSearches: string;
}

/**
 * 搜索历史仓库 | Search history repository
 */
export class SearchHistoryRepository {
  private static instance: SearchHistoryRepository;
  
  // 存储键值映射 | Storage keys mapping
  private storageKeys: StorageKeys = {
    searchHistory: 'search:history',
    favoriteSearches: 'search:favorites',
    searchHistoryConfig: 'search:history:config',
    recentSearches: 'search:recent'
  };
  
  // 默认配置 | Default configuration
  private defaultConfig: SearchHistoryConfig = {
    maxHistoryItems: 100,
    maxFavoriteItems: 20,
    autoClearDays: 30,
    enableAutoComplete: true,
    enableRecentSearches: true,
    enableFavorites: true
  };
  
  // 缓存的配置 | Cached configuration
  private cachedConfig: SearchHistoryConfig = this.defaultConfig;
  
  // 缓存的历史记录 | Cached history records
  private cachedHistory: SearchHistoryItem[] = [];
  
  // 缓存的收藏搜索 | Cached favorite searches
  private cachedFavorites: SearchHistoryItem[] = [];

  // 事件总线实例 | Event bus instance
  private eventBus = EventBusUtil;

  /**
   * 构造函数 | Constructor
   */
  constructor() {
    console.info('SearchHistoryRepository: 搜索历史仓库已初始化 | SearchHistoryRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取SearchHistoryRepository单例实例 | Get SearchHistoryRepository singleton instance
   */
  public static getInstance(): SearchHistoryRepository {
    if (!SearchHistoryRepository.instance) {
      SearchHistoryRepository.instance = new SearchHistoryRepository();
    }
    return SearchHistoryRepository.instance;
  }

  /**
   * 初始化搜索历史仓库 | Initialize search history repository
   */
  public async initialize(): Promise<void> {
    try {
      // 加载配置 | Load configuration
      await this.loadConfig();
      
      // 初始化缓存 | Initialize cache
      await this.loadHistory();
      await this.loadFavorites();
      
      // 检查并清理过期历史记录 | Check and cleanup expired history records
      await this.cleanupExpiredHistory();
      
      console.info('SearchHistoryRepository: 搜索历史仓库初始化完成 | SearchHistoryRepository initialization completed');
    } catch (error) {
      console.error('SearchHistoryRepository: 搜索历史仓库初始化失败 | Failed to initialize SearchHistoryRepository', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 设置事件监听器 | Set up event listeners
   */
  private setupEventListeners(): void {
    // 监听用户登录/登出事件 | Listen for user login/logout events
    this.eventBus.on('user:logout', async () => {
      // 登出时清除用户相关的搜索历史（如果配置允许） | Clear user-related search history on logout (if config allows)
      if (this.cachedConfig?.enableRecentSearches) {
        await this.clearRecentSearches();
      }
    });
    
    // 监听应用退出事件 | Listen for app exit events
    this.eventBus.on('app:exit', async () => {
      // 应用退出时保存数据 | Save data when app exits
      await this.saveData();
    });
  }

  /**
   * 保存搜索记录 | Save search record
   * @param query 搜索关键词 | Search keyword
   * @param type 搜索类型 | Search type
   * @param resultCount 搜索结果数量 | Search result count
   * @param category 搜索分类 | Search category
   */
  public async saveSearch(
    query: string, 
    type: SearchType = SearchType.ALL, 
    resultCount?: number,
    category?: string
  ): Promise<SearchHistoryItem> {
    try {
      // 验证输入 | Validate input
      if (!query || query.trim().length === 0) {
        throw new Error('Search query cannot be empty');
      }
      
      // 移除多余空格并转为小写 | Remove extra spaces and convert to lowercase
      const trimmedQuery = query.trim().toLowerCase();
      
      // 检查关键词长度 | Check keyword length
      if (trimmedQuery.length > 100) {
        throw new Error('Search query too long (maximum 100 characters)');
      }
      
      // 加载配置 | Load configuration
      const config = await this.getConfig();
      
      // 检查是否启用搜索历史 | Check if search history is enabled
      if (!config.enableRecentSearches) {
        return {
          id: this.generateId(),
          query: trimmedQuery,
          type,
          timestamp: Date.now(),
          resultCount,
          category
        };
      }
      
      // 加载现有历史记录 | Load existing history records
      let history = await this.getHistory();
      
      // 检查是否已存在相同的搜索记录 | Check if same search record already exists
      const existingIndex = history.findIndex(
        item => item.query === trimmedQuery && item.type === type
      );
      
      const newItem: SearchHistoryItem = {
        id: this.generateId(),
        query: trimmedQuery,
        type,
        timestamp: Date.now(),
        resultCount,
        category,
        isFavorite: false
      };
      
      if (existingIndex >= 0) {
        // 更新现有记录 | Update existing record
        const existingItem = history[existingIndex];
        newItem.isFavorite = existingItem.isFavorite;
        history.splice(existingIndex, 1);
      }
      
      // 添加到历史记录开头 | Add to the beginning of history records
      history.unshift(newItem);
      
      // 限制历史记录数量 | Limit history records count
      if (history.length > config.maxHistoryItems) {
        history = history.slice(0, config.maxHistoryItems);
      }
      
      // 保存更新后的历史记录 | Save updated history records
      this.cachedHistory = history;
      await StorageUtil.setObject(
        this.storageKeys.searchHistory,
        history,
        StorageType.PREFERENCES
      );
      
      // 发布搜索历史添加事件 | Publish search history added event
      this.eventBus.emit(SearchHistoryEventType.SEARCH_HISTORY_ADDED);
      
      console.debug(`SearchHistoryRepository: 搜索历史已保存: "${trimmedQuery}" (类型: ${type}) | Search history saved: "${trimmedQuery}" (type: ${type})`);
      
      return newItem;
    } catch (error) {
      console.error('SearchHistoryRepository: 保存搜索历史失败 | Failed to save search history', error instanceof Error ? error : new Error(String(error)));
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取搜索历史记录 | Get search history records
   * @param type 可选的搜索类型过滤 | Optional search type filter
   * @param limit 可选的返回数量限制 | Optional return count limit
   */
  public async getHistory(type?: SearchType, limit?: number): Promise<SearchHistoryItem[]> {
    try {
      // 如果缓存为空，加载数据 | If cache is empty, load data
      if (!this.cachedHistory) {
        await this.loadHistory();
      }
      
      let history = [...this.cachedHistory];
      
      // 按类型过滤 | Filter by type
      if (type && type !== SearchType.ALL) {
        history = history.filter(item => item.type === type);
      }
      
      // 限制返回数量 | Limit return count
      if (limit && limit > 0) {
        history = history.slice(0, limit);
      }
      
      return history;
    } catch (error) {
      console.error('SearchHistoryRepository: 获取搜索历史失败 | Failed to get search history', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * 获取最近的搜索记录 | Get recent search records
   * @param count 返回数量 | Return count
   */
  public async getRecentSearches(count: number = 10): Promise<SearchHistoryItem[]> {
    try {
      return await this.getHistory(SearchType.ALL, Math.max(1, Math.min(count, 50)));
    } catch (error) {
      console.warn('SearchHistoryRepository: 获取最近搜索失败 | Failed to get recent searches', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * 删除搜索历史记录 | Delete search history record
   * @param id 搜索记录ID | Search record ID
   */
  public async deleteSearchHistory(id: string): Promise<boolean> {
    try {
      // 加载历史记录 | Load history records
      let history = await this.getHistory();
      
      // 查找并删除记录 | Find and delete record
      const initialLength = history.length;
      history = history.filter(item => item.id !== id);
      
      // 检查是否删除了记录 | Check if record was deleted
      if (history.length === initialLength) {
        console.debug(`SearchHistoryRepository: 未找到ID为 ${id} 的搜索历史项 | Search history item with ID ${id} not found`);
        return false;
      }
      
      // 保存更新后的历史记录 | Save updated history records
      this.cachedHistory = history;
      await StorageUtil.setObject(
        this.storageKeys.searchHistory,
        history,
        StorageType.PREFERENCES
      );
      
      // 发布搜索历史删除事件 | Publish search history deleted event
      this.eventBus.emit(SearchHistoryEventType.SEARCH_HISTORY_DELETED);
      
      console.debug(`SearchHistoryRepository: 已删除搜索历史项: ${id} | Search history item deleted: ${id}`);
      
      return true;
    } catch (error) {
      console.error(`SearchHistoryRepository: 删除搜索历史项 ${id} 失败 | Failed to delete search history item ${id}`, error instanceof Error ? error : new Error(String(error)));
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 清除所有搜索历史 | Clear all search history
   * @param type 可选的搜索类型过滤 | Optional search type filter
   */
  public async clearSearchHistory(type?: SearchType): Promise<boolean> {
    try {
      let history: SearchHistoryItem[] = [];
      
      // 如果指定了类型，只清除该类型的记录 | If type is specified, only clear records of that type
      if (type && type !== SearchType.ALL) {
        const allHistory = await this.getHistory();
        history = allHistory.filter(item => item.type !== type && item.isFavorite);
      }
      
      // 保存更新后的历史记录 | Save updated history records
      this.cachedHistory = history;
      await StorageUtil.setObject(
        this.storageKeys.searchHistory, 
        history,
        StorageType.PREFERENCES
      );
      
      // 清除最近搜索缓存 | Clear recent searches cache
      await this.clearRecentSearches();
      
      // 发布搜索历史清除事件 | Publish search history cleared event
      this.eventBus.emit(SearchHistoryEventType.SEARCH_HISTORY_CLEARED);
      
      console.info(`SearchHistoryRepository: 搜索历史已清除${type ? `，类型: ${type}` : ''} | Search history cleared${type ? ` for type: ${type}` : ''}`);
      
      return true;
    } catch (error) {
      console.error('SearchHistoryRepository: 清除搜索历史失败 | Failed to clear search history', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  /**
   * 清除最近搜索记录 | Clear recent search records
   */
  private async clearRecentSearches(): Promise<void> {
    try {
      await StorageUtil.remove(this.storageKeys.recentSearches, StorageType.PREFERENCES);
    } catch (error) {
      console.warn('SearchHistoryRepository: 清除最近搜索失败 | Failed to clear recent searches', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 切换搜索收藏状态 | Toggle search favorite status
   * @param id 搜索记录ID | Search record ID
   */
  public async toggleFavorite(id: string): Promise<SearchHistoryItem | null> {
    try {
      // 加载配置 | Load configuration
      const config = await this.getConfig();
      
      // 检查是否启用收藏功能 | Check if favorites feature is enabled
      if (!config.enableFavorites) {
        throw new Error('Favorites feature is disabled');
      }
      
      // 加载历史记录和收藏 | Load history records and favorites
      let history = await this.getHistory();
      let favorites = await this.getFavorites();
      
      // 查找搜索记录 | Find search record
      const itemIndex = history.findIndex(item => item.id === id);
      if (itemIndex === -1) {
        throw new Error('Search history item not found');
      }
      
      const item = history[itemIndex];
      const isCurrentlyFavorite = item.isFavorite || false;
      
      if (isCurrentlyFavorite) {
        // 取消收藏 | Remove from favorites
        item.isFavorite = false;
        favorites = favorites.filter(fav => fav.id !== id);
      } else {
        // 添加收藏 | Add to favorites
        // 检查收藏数量限制 | Check favorites count limit
        if (favorites.length >= config.maxFavoriteItems) {
          throw new Error(`Maximum number of favorite searches (${config.maxFavoriteItems}) reached`);
        }
        
        item.isFavorite = true;
        favorites.push(item);
      }
      
      // 更新历史记录 | Update history record
      history[itemIndex] = item;
      
      // 保存更新后的数据 | Save updated data
      this.cachedHistory = history;
      this.cachedFavorites = favorites;
      
      await StorageUtil.setObject(
        this.storageKeys.searchHistory,
        history,
        StorageType.PREFERENCES
      );
      
      await StorageUtil.setObject(
        this.storageKeys.favoriteSearches,
        favorites,
        StorageType.PREFERENCES
      );
      
      // 发布收藏状态变更事件 | Publish favorite status changed event
      this.eventBus.emit(SearchHistoryEventType.SEARCH_FAVORITE_TOGGLED);
      
      console.debug(`SearchHistoryRepository: 搜索收藏状态已切换: ${id}, 收藏: ${item.isFavorite} | Search favorite toggled: ${id}, favorite: ${item.isFavorite}`);
      
      return item;
    } catch (error) {
      console.error(`SearchHistoryRepository: 切换搜索历史项 ${id} 的收藏状态失败 | Failed to toggle favorite for search history item ${id}`, error instanceof Error ? error : new Error(String(error)));
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取收藏的搜索记录 | Get favorite search records
   */
  public async getFavorites(): Promise<SearchHistoryItem[]> {
    try {
      // 如果缓存为空，加载数据 | If cache is empty, load data
      if (!this.cachedFavorites) {
        await this.loadFavorites();
      }
      
      return Array.from(this.cachedFavorites);
    } catch (error) {
      console.error('SearchHistoryRepository: 获取收藏搜索失败 | Failed to get favorite searches', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * 清除所有收藏 | Clear all favorites
   */
  public async clearFavorites(): Promise<boolean> {
    try {
      // 加载历史记录 | Load history records
      const history = await this.getHistory();
      
      // 移除所有收藏标记 | Remove all favorite markers
      const updatedHistory = history.map(item => {
        const updatedItem: SearchHistoryItem = {
          id: item.id,
          query: item.query,
          type: item.type,
          timestamp: item.timestamp,
          resultCount: item.resultCount,
          category: item.category,
          isFavorite: false,
          selected: item.selected
        };
        return updatedItem;
      });
      
      // 保存更新后的历史记录 | Save updated history records
      this.cachedHistory = updatedHistory;
      this.cachedFavorites = [];
      
      await StorageUtil.setObject(
        this.storageKeys.searchHistory,
        updatedHistory,
        StorageType.PREFERENCES
      );
      
      await StorageUtil.setObject(
        this.storageKeys.favoriteSearches,
        [],
        StorageType.PREFERENCES
      );
      
      console.info('SearchHistoryRepository: 所有收藏搜索已清除 | All favorite searches cleared');
      
      return true;
    } catch (error) {
      console.error('SearchHistoryRepository: 清除收藏搜索失败 | Failed to clear favorite searches', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  /**
   * 获取搜索建议（基于历史记录） | Get search suggestions (based on history)
   * @param query 搜索关键词前缀 | Search keyword prefix
   * @param type 可选的搜索类型过滤 | Optional search type filter
   * @param limit 返回数量限制 | Return count limit
   */
  public async getSuggestions(
    query: string, 
    type?: SearchType,
    limit: number = 10
  ): Promise<string[]> {
    try {
      // 验证输入 | Validate input
      if (!query || query.trim().length === 0) {
        return [];
      }
      
      const trimmedQuery = query.trim().toLowerCase();
      
      // 加载配置 | Load configuration
      const config = await this.getConfig();
      
      // 检查是否启用自动完成 | Check if auto complete is enabled
      if (!config.enableAutoComplete) {
        return [];
      }
      
      // 获取历史记录 | Get history records
      const history = await this.getHistory(type);
      
      // 处理匹配的搜索词 | Process matching search terms
      const suggestions = history
        .filter(item => item.query.includes(trimmedQuery))
        .map(item => item.query)
        .filter((suggestion, index, self) => self.indexOf(suggestion) === index) // 去重 | Remove duplicates
        .slice(0, Math.max(1, Math.min(limit, 50))); // 限制数量 | Limit count
      
      return suggestions;
    } catch (error) {
      console.warn('SearchHistoryRepository: 获取搜索建议失败 | Failed to get search suggestions', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * 设置搜索历史配置 | Set search history configuration
   * @param config 配置对象 | Configuration object
   */
  public async setConfig(config: Partial<SearchHistoryConfig>): Promise<SearchHistoryConfig> {
    try {
      // 获取当前配置 | Get current configuration
      const currentConfig = await this.getConfig();
      
      // 合并新配置 | Merge new configuration
      const updatedConfig: SearchHistoryConfig = {
        maxHistoryItems: config.maxHistoryItems ?? currentConfig.maxHistoryItems,
        maxFavoriteItems: config.maxFavoriteItems ?? currentConfig.maxFavoriteItems,
        autoClearDays: config.autoClearDays ?? currentConfig.autoClearDays,
        enableAutoComplete: config.enableAutoComplete ?? currentConfig.enableAutoComplete,
        enableRecentSearches: config.enableRecentSearches ?? currentConfig.enableRecentSearches,
        enableFavorites: config.enableFavorites ?? currentConfig.enableFavorites
      };
      
      // 验证配置 | Validate configuration
      this.validateConfig(updatedConfig);
      
      // 保存配置 | Save configuration
      this.cachedConfig = updatedConfig;
      await StorageUtil.setObject(
        this.storageKeys.searchHistoryConfig,
        updatedConfig,
        StorageType.PREFERENCES
      );
      
      // 根据新配置清理数据 | Clean up data based on new configuration
      await this.applyConfigChanges(currentConfig, updatedConfig);
      
      // 发布配置变更事件 | Publish configuration changed event
      this.eventBus.emit(SearchHistoryEventType.SEARCH_HISTORY_CONFIG_CHANGED);
      
      console.info('SearchHistoryRepository: 搜索历史配置已更新 | Search history configuration updated');
      
      return updatedConfig;
    } catch (error) {
      console.error('SearchHistoryRepository: 设置搜索历史配置失败 | Failed to set search history config', error instanceof Error ? error : new Error(String(error)));
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取搜索历史配置 | Get search history configuration
   */
  public async getConfig(): Promise<SearchHistoryConfig> {
    try {
      // 如果缓存为空，加载配置 | If cache is empty, load configuration
      if (!this.cachedConfig) {
        await this.loadConfig();
      }
      
      // 使用手动属性复制替代Object.assign | Use manual property copy instead of Object.assign
      return {
        maxHistoryItems: this.cachedConfig!.maxHistoryItems,
        maxFavoriteItems: this.cachedConfig!.maxFavoriteItems,
        autoClearDays: this.cachedConfig!.autoClearDays,
        enableAutoComplete: this.cachedConfig!.enableAutoComplete,
        enableRecentSearches: this.cachedConfig!.enableRecentSearches,
        enableFavorites: this.cachedConfig!.enableFavorites
      };
    } catch (error) {
      console.error('SearchHistoryRepository: 获取搜索历史配置失败 | Failed to get search history config', error instanceof Error ? error : new Error(String(error)));
      // 使用手动属性复制替代Object.assign | Use manual property copy instead of Object.assign
      return {
        maxHistoryItems: this.defaultConfig.maxHistoryItems,
        maxFavoriteItems: this.defaultConfig.maxFavoriteItems,
        autoClearDays: this.defaultConfig.autoClearDays,
        enableAutoComplete: this.defaultConfig.enableAutoComplete,
        enableRecentSearches: this.defaultConfig.enableRecentSearches,
        enableFavorites: this.defaultConfig.enableFavorites
      };
    }
  }

  /**
   * 重置搜索历史配置到默认值 | Reset search history configuration to default value
   */
  public async resetConfig(): Promise<SearchHistoryConfig> {
    try {
      // 保存默认配置 | Save default configuration
      this.cachedConfig = {
        maxHistoryItems: this.defaultConfig.maxHistoryItems,
        maxFavoriteItems: this.defaultConfig.maxFavoriteItems,
        autoClearDays: this.defaultConfig.autoClearDays,
        enableAutoComplete: this.defaultConfig.enableAutoComplete,
        enableRecentSearches: this.defaultConfig.enableRecentSearches,
        enableFavorites: this.defaultConfig.enableFavorites
      };
      await StorageUtil.setObject(
        this.storageKeys.searchHistoryConfig,
        this.defaultConfig,
        StorageType.PREFERENCES
      );
      
      console.info('SearchHistoryRepository: 搜索历史配置已重置为默认值 | Search history configuration reset to default');
    
      return {
        maxHistoryItems: this.defaultConfig.maxHistoryItems,
        maxFavoriteItems: this.defaultConfig.maxFavoriteItems,
        autoClearDays: this.defaultConfig.autoClearDays,
        enableAutoComplete: this.defaultConfig.enableAutoComplete,
        enableRecentSearches: this.defaultConfig.enableRecentSearches,
        enableFavorites: this.defaultConfig.enableFavorites
      };
    } catch (error) {
      console.error('SearchHistoryRepository: 重置搜索历史配置失败 | Failed to reset search history config', error instanceof Error ? error : new Error(String(error)));
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 加载历史记录 | Load history records
   */
  private async loadHistory(): Promise<void> {
    try {
      const historyResult: SearchHistoryItem[] | null = await StorageUtil.getObject<SearchHistoryItem[]>(
        this.storageKeys.searchHistory, 
        StorageType.PREFERENCES
      );
      
      this.cachedHistory = historyResult || [];
      console.debug(`SearchHistoryRepository: 已加载 ${this.cachedHistory.length} 个搜索历史项 | Loaded ${this.cachedHistory.length} search history items`);
    } catch (error) {
      console.error('SearchHistoryRepository: 加载搜索历史失败 | Failed to load search history', error instanceof Error ? error : new Error(String(error)));
      this.cachedHistory = [];
    }
  }

  /**
   * 加载收藏搜索 | Load favorite searches
   */
  private async loadFavorites(): Promise<void> {
    try {
      const favoritesResult: SearchHistoryItem[] | null = await StorageUtil.getObject<SearchHistoryItem[]>(
        this.storageKeys.favoriteSearches, 
        StorageType.PREFERENCES
      );
      
      this.cachedFavorites = favoritesResult || [];
      console.debug(`SearchHistoryRepository: 已加载 ${this.cachedFavorites.length} 个收藏搜索项 | Loaded ${this.cachedFavorites.length} favorite searches`);
    } catch (error) {
      console.error('SearchHistoryRepository: 加载收藏搜索失败 | Failed to load favorite searches', error instanceof Error ? error : new Error(String(error)));
      this.cachedFavorites = [];
    }
  }

  /**
   * 加载配置 | Load configuration
   */
  private async loadConfig(): Promise<void> {
    try {
      const configResult: SearchHistoryConfig | null = await StorageUtil.getObject<SearchHistoryConfig>(
        this.storageKeys.searchHistoryConfig, 
        StorageType.PREFERENCES
      );
      
      // 使用手动属性复制替代Object.assign | Use manual property copy instead of Object.assign
      if (configResult) {
        this.cachedConfig = {
          maxHistoryItems: configResult.maxHistoryItems ?? this.defaultConfig.maxHistoryItems,
          maxFavoriteItems: configResult.maxFavoriteItems ?? this.defaultConfig.maxFavoriteItems,
          autoClearDays: configResult.autoClearDays ?? this.defaultConfig.autoClearDays,
          enableAutoComplete: configResult.enableAutoComplete ?? this.defaultConfig.enableAutoComplete,
          enableRecentSearches: configResult.enableRecentSearches ?? this.defaultConfig.enableRecentSearches,
          enableFavorites: configResult.enableFavorites ?? this.defaultConfig.enableFavorites
        };
      } else {
        // 使用手动属性复制替代Object.assign和扩展运算符 | Use manual property copy instead of Object.assign and spread operator
        this.cachedConfig = {
          maxHistoryItems: this.defaultConfig.maxHistoryItems,
          maxFavoriteItems: this.defaultConfig.maxFavoriteItems,
          autoClearDays: this.defaultConfig.autoClearDays,
          enableAutoComplete: this.defaultConfig.enableAutoComplete,
          enableRecentSearches: this.defaultConfig.enableRecentSearches,
          enableFavorites: this.defaultConfig.enableFavorites
        };
      }
      
      // 验证配置 | Validate configuration
      this.validateConfig(this.cachedConfig);
      
      console.debug('SearchHistoryRepository: 搜索历史配置已加载 | Search history configuration loaded');
    } catch (error) {
      console.error('SearchHistoryRepository: 加载搜索历史配置失败 | Failed to load search history config', error instanceof Error ? error : new Error(String(error)));
      // 使用手动属性复制替代扩展运算符 | Use manual property copy instead of spread operator
      this.cachedConfig = {
        maxHistoryItems: this.defaultConfig.maxHistoryItems,
        maxFavoriteItems: this.defaultConfig.maxFavoriteItems,
        autoClearDays: this.defaultConfig.autoClearDays,
        enableAutoComplete: this.defaultConfig.enableAutoComplete,
        enableRecentSearches: this.defaultConfig.enableRecentSearches,
        enableFavorites: this.defaultConfig.enableFavorites
      };
    }
  }

  /**
   * 保存所有数据 | Save all data
   */
  private async saveData(): Promise<void> {
    try {
      await Promise.all([
        StorageUtil.setObject(
          this.storageKeys.searchHistory, 
          this.cachedHistory || [],
          StorageType.PREFERENCES
        ),
        StorageUtil.setObject(
          this.storageKeys.favoriteSearches,
          this.cachedFavorites || [],
          StorageType.PREFERENCES
        ),
        StorageUtil.setObject(
          this.storageKeys.searchHistoryConfig,
          this.cachedConfig || this.defaultConfig,
          StorageType.PREFERENCES
        )
      ]);
      
      console.debug('SearchHistoryRepository: 搜索历史数据已保存 | Search history data saved');
    } catch (error) {
      console.error('SearchHistoryRepository: 保存搜索历史数据失败 | Failed to save search history data', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 清理过期的历史记录 | Cleanup expired history records
   */
  private async cleanupExpiredHistory(): Promise<void> {
    try {
      const config = await this.getConfig();
      
      // 检查是否启用自动清理 | Check if auto cleanup is enabled
      if (!config.autoClearDays || config.autoClearDays <= 0) {
        return;
      }
      
      const expirationTime = Date.now() - (config.autoClearDays * 24 * 60 * 60 * 1000);
      const history = await this.getHistory();
      
      // 过滤出未过期且不是收藏的记录 | Filter out expired and non-favorite records
      const filteredHistory = history.filter(
        item => item.timestamp > expirationTime || item.isFavorite
      );
      
      // 如果有变化，保存更新后的历史记录 | If there are changes, save updated history records
      if (filteredHistory.length !== history.length) {
        this.cachedHistory = filteredHistory;
        await StorageUtil.setObject(
          this.storageKeys.searchHistory,
          filteredHistory,
          StorageType.PREFERENCES
        );
        
        console.info(`SearchHistoryRepository: 已清理 ${history.length - filteredHistory.length} 个过期搜索历史项 | Cleaned up ${history.length - filteredHistory.length} expired search history items`);
      }
    } catch (error) {
      console.warn('SearchHistoryRepository: 清理过期搜索历史失败 | Failed to cleanup expired search history', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 应用配置变更 | Apply configuration changes
   */
  private async applyConfigChanges(
    oldConfig: SearchHistoryConfig,
    newConfig: SearchHistoryConfig
  ): Promise<void> {
    try {
      // 检查历史记录数量限制是否改变 | Check if history items count limit changed
      if (oldConfig.maxHistoryItems !== newConfig.maxHistoryItems) {
        const history = await this.getHistory();
        if (history.length > newConfig.maxHistoryItems) {
          const filteredHistory = history.slice(0, newConfig.maxHistoryItems);
          this.cachedHistory = filteredHistory;
          await StorageUtil.setObject(
            this.storageKeys.searchHistory,
            filteredHistory,
            StorageType.PREFERENCES
          );
        }
      }
      
      // 检查收藏数量限制是否改变 | Check if favorite items count limit changed
      if (oldConfig.maxFavoriteItems !== newConfig.maxFavoriteItems) {
        const favorites = await this.getFavorites();
        if (favorites.length > newConfig.maxFavoriteItems) {
          const filteredFavorites = favorites.slice(0, newConfig.maxFavoriteItems);
          this.cachedFavorites = filteredFavorites;
          
          // 更新历史记录中的收藏状态 | Update favorite status in history records
          const history = await this.getHistory();
          const updatedHistory = history.map(item => {
            const updatedItem: SearchHistoryItem = {
              id: item.id,
              query: item.query,
              type: item.type,
              timestamp: item.timestamp,
              resultCount: item.resultCount,
              category: item.category,
              isFavorite: filteredFavorites.some(fav => fav.id === item.id),
              selected: item.selected
            };
            return updatedItem;
          });
          
          this.cachedHistory = updatedHistory;
          await StorageUtil.setObject(
            this.storageKeys.favoriteSearches,
            filteredFavorites,
            StorageType.PREFERENCES
          );
          await StorageUtil.setObject(
            this.storageKeys.searchHistory,
            updatedHistory,
            StorageType.PREFERENCES
          );
        }
      }
    } catch (error) {
      console.warn('SearchHistoryRepository: 应用配置变更失败 | Failed to apply config changes', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 验证配置 | Validate configuration
   */
  private validateConfig(config: SearchHistoryConfig): void {
    const errors: string[] = [];
    
    if (config.maxHistoryItems < 1 || config.maxHistoryItems > 1000) {
      errors.push('maxHistoryItems must be between 1 and 1000');
    }
    
    if (config.maxFavoriteItems < 1 || config.maxFavoriteItems > 100) {
      errors.push('maxFavoriteItems must be between 1 and 100');
    }
    
    if (config.autoClearDays !== undefined && (config.autoClearDays < 1 || config.autoClearDays > 365)) {
      errors.push('autoClearDays must be between 1 and 365');
    }
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 生成唯一ID | Generate unique ID
   */
  private generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * 导出搜索历史数据 | Export search history data
   */
  public async exportData(): Promise<SearchHistoryExportData> {
    try {
      const data: SearchHistoryExportData = {
        history: await this.getHistory(),
        favorites: await this.getFavorites(),
        config: await this.getConfig(),
        exportTime: Date.now()
      };
      
      console.info('SearchHistoryRepository: 搜索历史数据已导出 | Search history data exported');
      
      return data;
    } catch (error) {
      console.error('SearchHistoryRepository: 导出搜索历史数据失败 | Failed to export search history data', error instanceof Error ? error : new Error(String(error)));
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 导入搜索历史数据 | Import search history data
   * @param data 导入的数据 | Data to import
   * @param merge 是否合并（true）或覆盖（false） | Whether to merge (true) or overwrite (false)
   */
  public async importData(
    data: SearchHistoryImportData, 
    merge: boolean = true
  ): Promise<void> {
    try {
      // 验证导入数据 | Validate import data
      if (!data || (!data.history && !data.favorites && !data.config)) {
        throw new Error('No valid data to import');
      }
      
      // 获取当前配置 | Get current configuration
      const currentConfig = await this.getConfig();
      
      // 处理配置导入 | Process configuration import
      if (data.config) {
        // 使用手动合并替代扩展运算符 | Use manual merge instead of spread operator
        const baseConfig = merge ? currentConfig : this.defaultConfig;
        const mergedConfig: SearchHistoryConfig = {
          maxHistoryItems: data.config.maxHistoryItems ?? baseConfig.maxHistoryItems,
          maxFavoriteItems: data.config.maxFavoriteItems ?? baseConfig.maxFavoriteItems,
          autoClearDays: data.config.autoClearDays ?? baseConfig.autoClearDays,
          enableAutoComplete: data.config.enableAutoComplete ?? baseConfig.enableAutoComplete,
          enableRecentSearches: data.config.enableRecentSearches ?? baseConfig.enableRecentSearches,
          enableFavorites: data.config.enableFavorites ?? baseConfig.enableFavorites
        };
        
        this.validateConfig(mergedConfig);
        this.cachedConfig = mergedConfig;
        
        await StorageUtil.setObject(
          this.storageKeys.searchHistoryConfig,
          mergedConfig,
          StorageType.PREFERENCES
        );
      }
      
      // 处理历史记录导入 | Process history records import
      if (data.history && Array.isArray(data.history)) {
        const processedHistory = data.history
          .filter(item => this.isValidHistoryItem(item))
          .map(item => this.normalizeHistoryItem(item));
        
        let finalHistory: SearchHistoryItem[];
        
        if (merge) {
          // 合并历史记录 | Merge history records
          const currentHistory = await this.getHistory();
          const historyMap = new Map<string, SearchHistoryItem>();
          
          // 添加现有记录 | Add existing records
          currentHistory.forEach(item => {
            historyMap.set(`${item.query}-${item.type}`, item);
          });
          
          // 合并新记录（新记录优先级高） | Merge new records (new records have higher priority)
          processedHistory.forEach(item => {
            const key = `${item.query}-${item.type}`;
            const existingItem = historyMap.get(key);
            
            if (existingItem) {
              // 保留收藏状态 | Preserve favorite status
              item.isFavorite = existingItem.isFavorite;
            }
            
            historyMap.set(key, item);
          });
          
          finalHistory = Array.from(historyMap.values())
            .sort((a, b) => b.timestamp - a.timestamp);
        } else {
          // 覆盖历史记录 | Overwrite history records
          finalHistory = processedHistory
            .sort((a, b) => b.timestamp - a.timestamp);
        }
        
        // 应用数量限制 | Apply count limit
        if (finalHistory.length > currentConfig.maxHistoryItems) {
          finalHistory = finalHistory.slice(0, currentConfig.maxHistoryItems);
        }
        
        this.cachedHistory = finalHistory;
        await StorageUtil.setObject(
          this.storageKeys.searchHistory,
          finalHistory,
          StorageType.PREFERENCES
        );
      }
      
      // 处理收藏导入 | Process favorites import
      if (data.favorites && Array.isArray(data.favorites)) {
        const processedFavorites = data.favorites
          .filter(item => this.isValidHistoryItem(item))
          .map(item => this.normalizeHistoryItem(item))
          .map(item => {
            const favoriteItem: SearchHistoryItem = {
              id: item.id,
              query: item.query,
              type: item.type,
              timestamp: item.timestamp,
              resultCount: item.resultCount,
              category: item.category,
              isFavorite: true,
              selected: item.selected
            };
            return favoriteItem;
          });
        
        let finalFavorites: SearchHistoryItem[];
        
        if (merge) {
          // 合并收藏 | Merge favorites
          const currentFavorites = await this.getFavorites();
          const favoriteMap = new Map<string, SearchHistoryItem>();
          
          // 添加现有收藏 | Add existing favorites
          currentFavorites.forEach(item => {
            favoriteMap.set(`${item.query}-${item.type}`, item);
          });
          
          // 合并新收藏 | Merge new favorites
          processedFavorites.forEach(item => {
            favoriteMap.set(`${item.query}-${item.type}`, item);
          });
          
          finalFavorites = Array.from(favoriteMap.values());
        } else {
          // 覆盖收藏 | Overwrite favorites
          finalFavorites = processedFavorites;
        }
        
        // 应用数量限制 | Apply count limit
        if (finalFavorites.length > currentConfig.maxFavoriteItems) {
          finalFavorites = finalFavorites.slice(0, currentConfig.maxFavoriteItems);
        }
        
        this.cachedFavorites = finalFavorites;
        await StorageUtil.setObject(
          this.storageKeys.favoriteSearches,
          finalFavorites,
          StorageType.PREFERENCES
        );
      }
      
      // 更新历史记录中的收藏状态 | Update favorite status in history records
      if (data.favorites) {
        const history = await this.getHistory();
        const favorites = await this.getFavorites();
        const updatedHistory = history.map(item => {
          const updatedItem: SearchHistoryItem = {
            id: item.id,
            query: item.query,
            type: item.type,
            timestamp: item.timestamp,
            resultCount: item.resultCount,
            category: item.category,
            isFavorite: favorites.some(fav => fav.id === item.id) || false,
            selected: item.selected
          };
          return updatedItem;
        });
        
        this.cachedHistory = updatedHistory;
        await StorageUtil.setObject(
          this.storageKeys.searchHistory,
          updatedHistory,
          StorageType.PREFERENCES
        );
      }
      
      console.info('SearchHistoryRepository: 搜索历史数据导入成功 | Search history data imported successfully');
    } catch (error) {
      console.error('SearchHistoryRepository: 导入搜索历史数据失败 | Failed to import search history data', error instanceof Error ? error : new Error(String(error)));
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 验证历史记录项目 | Validate history record item
   */
  private isValidHistoryItem(item: SearchHistoryItem): boolean {
    return !!item && 
           typeof item.id === 'string' && 
           typeof item.query === 'string' && 
           typeof item.timestamp === 'number' &&
           item.timestamp > 0 &&
           typeof item.type === 'string' &&
           (item.type === SearchType.ALL || item.type === SearchType.VIDEO || item.type === SearchType.LIVE || item.type === SearchType.USER || item.type === SearchType.CATEGORY || item.type === SearchType.TAG);
  }

  /**
   * 规范化历史记录项目 | Normalize history record item
   */
  private normalizeHistoryItem(item: SearchHistoryItem): SearchHistoryItem {
    const normalizedType: SearchType = 
      (item.type === SearchType.ALL || item.type === SearchType.VIDEO || item.type === SearchType.LIVE || item.type === SearchType.USER || item.type === SearchType.CATEGORY || item.type === SearchType.TAG) ? 
      item.type : 
      SearchType.ALL;
    
    return {
      id: item.id || this.generateId(),
      query: item.query || '',
      type: normalizedType,
      timestamp: item.timestamp || Date.now(),
      resultCount: item.resultCount || 0,
      category: item.category || '',
      isFavorite: item.isFavorite || false
    };
  }
}




