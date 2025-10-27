// SearchHistoryRepository - 搜索历史仓库类
// 负责管理用户的搜索历史数据，包括保存、获取、删除搜索记录等

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import { LocalStorageType } from '../model/LocalModel';

/**
 * 搜索记录类型枚举
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
 * 搜索历史记录接口
 */
export interface SearchHistoryItem {
  id: string; // 唯一标识符
  query: string; // 搜索关键词
  type: SearchType; // 搜索类型
  timestamp: number; // 搜索时间戳
  resultCount?: number; // 搜索结果数量
  selected?: boolean; // 是否被选中
  isFavorite?: boolean; // 是否为收藏的搜索词
  category?: string; // 搜索分类（可选）
}

/**
 * 搜索历史配置接口
 */
export interface SearchHistoryConfig {
  maxHistoryItems: number; // 最大历史记录数量
  maxFavoriteItems: number; // 最大收藏搜索词数量
  autoClearDays?: number; // 自动清除天数（可选）
  enableAutoComplete: boolean; // 是否启用自动完成
  enableRecentSearches: boolean; // 是否启用最近搜索
  enableFavorites: boolean; // 是否启用收藏功能
}

/**
 * 搜索历史事件类型
 */
export const SearchHistoryEventType = {
  SEARCH_HISTORY_ADDED: 'searchHistory:added',
  SEARCH_HISTORY_DELETED: 'searchHistory:deleted',
  SEARCH_HISTORY_CLEARED: 'searchHistory:cleared',
  SEARCH_HISTORY_UPDATED: 'searchHistory:updated',
  SEARCH_FAVORITE_TOGGLED: 'searchHistory:favoriteToggled',
  SEARCH_HISTORY_CONFIG_CHANGED: 'searchHistory:configChanged'
} as const;

/**
 * 搜索历史事件数据
 */
export interface SearchHistoryEvent {
  type: string;
  timestamp: number;
  data?: any;
  error?: Error;
}

/**
 * 搜索历史仓库类
 */
export class SearchHistoryRepository {
  private static instance: SearchHistoryRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  
  // 存储键配置
  private storageKeys = {
    searchHistory: 'search:history',
    favoriteSearches: 'search:favorites',
    searchHistoryConfig: 'search:history:config',
    recentSearches: 'search:recent'
  };
  
  // 默认配置
  private defaultConfig: SearchHistoryConfig = {
    maxHistoryItems: 100,
    maxFavoriteItems: 20,
    autoClearDays: 30,
    enableAutoComplete: true,
    enableRecentSearches: true,
    enableFavorites: true
  };
  
  // 缓存的配置
  private cachedConfig: SearchHistoryConfig | null = null;
  
  // 缓存的历史记录
  private cachedHistory: SearchHistoryItem[] | null = null;
  
  // 缓存的收藏搜索
  private cachedFavorites: SearchHistoryItem[] | null = null;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('SearchHistoryRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取SearchHistoryRepository单例实例
   */
  public static getInstance(): SearchHistoryRepository {
    if (!SearchHistoryRepository.instance) {
      SearchHistoryRepository.instance = new SearchHistoryRepository();
    }
    return SearchHistoryRepository.instance;
  }

  /**
   * 初始化搜索历史仓库
   */
  private async initialize(): Promise<void> {
    try {
      // 加载配置
      await this.loadConfig();
      
      // 初始化缓存
      await this.loadHistory();
      await this.loadFavorites();
      
      // 检查并清理过期历史记录
      await this.cleanupExpiredHistory();
      
      this.logger.info('SearchHistoryRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize SearchHistoryRepository', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听用户登录/登出事件
    this.eventBus.on('user:logout', async () => {
      // 登出时清除用户相关的搜索历史（如果配置允许）
      if (this.cachedConfig?.enableRecentSearches) {
        await this.clearRecentSearches();
      }
    });
    
    // 监听应用退出事件
    this.eventBus.on('app:exit', async () => {
      // 应用退出时保存数据
      await this.saveData();
    });
  }

  /**
   * 保存搜索记录
   * @param query 搜索关键词
   * @param type 搜索类型
   * @param resultCount 搜索结果数量
   * @param category 搜索分类
   */
  public async saveSearch(
    query: string, 
    type: SearchType = SearchType.ALL, 
    resultCount?: number,
    category?: string
  ): Promise<SearchHistoryItem> {
    try {
      // 验证输入
      if (!query || query.trim().length === 0) {
        throw new Error('Search query cannot be empty');
      }
      
      // 去除多余空格并转小写
      const trimmedQuery = query.trim().toLowerCase();
      
      // 检查关键词长度
      if (trimmedQuery.length > 100) {
        throw new Error('Search query too long (maximum 100 characters)');
      }
      
      // 加载配置
      const config = await this.getConfig();
      
      // 检查是否启用搜索历史
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
      
      // 加载现有历史记录
      let history = await this.getHistory();
      
      // 检查是否已存在相同的搜索记录
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
        // 更新现有记录
        const existingItem = history[existingIndex];
        newItem.isFavorite = existingItem.isFavorite;
        history.splice(existingIndex, 1);
      }
      
      // 添加到历史记录开头
      history.unshift(newItem);
      
      // 限制历史记录数量
      if (history.length > config.maxHistoryItems) {
        history = history.slice(0, config.maxHistoryItems);
      }
      
      // 保存更新后的历史记录
      this.cachedHistory = history;
      await this.storageUtil.setObject(
        this.storageKeys.searchHistory,
        history,
        LocalStorageType.DEFAULT
      );
      
      // 发布搜索历史添加事件
      this.eventBus.emit(SearchHistoryEventType.SEARCH_HISTORY_ADDED, {
        type: SearchHistoryEventType.SEARCH_HISTORY_ADDED,
        timestamp: Date.now(),
        data: newItem
      } as SearchHistoryEvent);
      
      this.logger.debug(`Search history saved: "${trimmedQuery}" (type: ${type})`);
      
      return newItem;
    } catch (error) {
      this.logger.error('Failed to save search history', error as Error);
      throw error;
    }
  }

  /**
   * 获取搜索历史记录
   * @param type 可选的搜索类型过滤
   * @param limit 可选的返回数量限制
   */
  public async getHistory(type?: SearchType, limit?: number): Promise<SearchHistoryItem[]> {
    try {
      // 如果缓存为空，加载数据
      if (!this.cachedHistory) {
        await this.loadHistory();
      }
      
      let history = [...this.cachedHistory!];
      
      // 按类型过滤
      if (type && type !== SearchType.ALL) {
        history = history.filter(item => item.type === type);
      }
      
      // 限制返回数量
      if (limit && limit > 0) {
        history = history.slice(0, limit);
      }
      
      return history;
    } catch (error) {
      this.logger.error('Failed to get search history', error as Error);
      return [];
    }
  }

  /**
   * 获取最近的搜索记录
   * @param count 返回数量
   */
  public async getRecentSearches(count: number = 10): Promise<SearchHistoryItem[]> {
    try {
      return await this.getHistory(SearchType.ALL, Math.max(1, Math.min(count, 50)));
    } catch (error) {
      this.logger.warn('Failed to get recent searches', error as Error);
      return [];
    }
  }

  /**
   * 删除搜索历史记录
   * @param id 搜索记录ID
   */
  public async deleteSearchHistory(id: string): Promise<boolean> {
    try {
      // 加载历史记录
      let history = await this.getHistory();
      
      // 查找并删除记录
      const initialLength = history.length;
      history = history.filter(item => item.id !== id);
      
      // 检查是否删除了记录
      if (history.length === initialLength) {
        this.logger.debug(`Search history item with ID ${id} not found`);
        return false;
      }
      
      // 保存更新后的历史记录
      this.cachedHistory = history;
      await this.storageUtil.setObject(
        this.storageKeys.searchHistory,
        history,
        LocalStorageType.DEFAULT
      );
      
      // 发布搜索历史删除事件
      this.eventBus.emit(SearchHistoryEventType.SEARCH_HISTORY_DELETED, {
        type: SearchHistoryEventType.SEARCH_HISTORY_DELETED,
        timestamp: Date.now(),
        data: { id }
      } as SearchHistoryEvent);
      
      this.logger.debug(`Search history item deleted: ${id}`);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to delete search history item ${id}`, error as Error);
      return false;
    }
  }

  /**
   * 清除所有搜索历史
   * @param type 可选的搜索类型过滤
   */
  public async clearSearchHistory(type?: SearchType): Promise<boolean> {
    try {
      let history: SearchHistoryItem[] = [];
      
      // 如果指定了类型，只清除该类型的记录
      if (type && type !== SearchType.ALL) {
        const allHistory = await this.getHistory();
        history = allHistory.filter(item => item.type !== type && item.isFavorite);
      }
      
      // 保存更新后的历史记录
      this.cachedHistory = history;
      await this.storageUtil.setObject(
        this.storageKeys.searchHistory,
        history,
        LocalStorageType.DEFAULT
      );
      
      // 清除最近搜索缓存
      await this.clearRecentSearches();
      
      // 发布搜索历史清除事件
      this.eventBus.emit(SearchHistoryEventType.SEARCH_HISTORY_CLEARED, {
        type: SearchHistoryEventType.SEARCH_HISTORY_CLEARED,
        timestamp: Date.now(),
        data: { type }
      } as SearchHistoryEvent);
      
      this.logger.info(`Search history cleared${type ? ` for type: ${type}` : ''}`);
      
      return true;
    } catch (error) {
      this.logger.error('Failed to clear search history', error as Error);
      return false;
    }
  }

  /**
   * 清除最近搜索记录
   */
  private async clearRecentSearches(): Promise<void> {
    try {
      await this.storageUtil.remove(this.storageKeys.recentSearches, LocalStorageType.DEFAULT);
    } catch (error) {
      this.logger.warn('Failed to clear recent searches', error as Error);
    }
  }

  /**
   * 切换搜索收藏状态
   * @param id 搜索记录ID
   */
  public async toggleFavorite(id: string): Promise<SearchHistoryItem | null> {
    try {
      // 加载配置
      const config = await this.getConfig();
      
      // 检查是否启用收藏功能
      if (!config.enableFavorites) {
        throw new Error('Favorites feature is disabled');
      }
      
      // 加载历史记录和收藏
      let history = await this.getHistory();
      let favorites = await this.getFavorites();
      
      // 查找搜索记录
      const itemIndex = history.findIndex(item => item.id === id);
      if (itemIndex === -1) {
        throw new Error('Search history item not found');
      }
      
      const item = { ...history[itemIndex] };
      const isCurrentlyFavorite = item.isFavorite || false;
      
      if (isCurrentlyFavorite) {
        // 取消收藏
        item.isFavorite = false;
        favorites = favorites.filter(fav => fav.id !== id);
      } else {
        // 添加收藏
        // 检查收藏数量限制
        if (favorites.length >= config.maxFavoriteItems) {
          throw new Error(`Maximum number of favorite searches (${config.maxFavoriteItems}) reached`);
        }
        
        item.isFavorite = true;
        favorites.push(item);
      }
      
      // 更新历史记录
      history[itemIndex] = item;
      
      // 保存更新后的数据
      this.cachedHistory = history;
      this.cachedFavorites = favorites;
      
      await this.storageUtil.setObject(
        this.storageKeys.searchHistory,
        history,
        LocalStorageType.DEFAULT
      );
      
      await this.storageUtil.setObject(
        this.storageKeys.favoriteSearches,
        favorites,
        LocalStorageType.DEFAULT
      );
      
      // 发布收藏状态变更事件
      this.eventBus.emit(SearchHistoryEventType.SEARCH_FAVORITE_TOGGLED, {
        type: SearchHistoryEventType.SEARCH_FAVORITE_TOGGLED,
        timestamp: Date.now(),
        data: {
          item,
          isFavorite: item.isFavorite
        }
      } as SearchHistoryEvent);
      
      this.logger.debug(`Search favorite toggled: ${id}, favorite: ${item.isFavorite}`);
      
      return item;
    } catch (error) {
      this.logger.error(`Failed to toggle favorite for search history item ${id}`, error as Error);
      throw error;
    }
  }

  /**
   * 获取收藏的搜索记录
   */
  public async getFavorites(): Promise<SearchHistoryItem[]> {
    try {
      // 如果缓存为空，加载数据
      if (!this.cachedFavorites) {
        await this.loadFavorites();
      }
      
      return [...this.cachedFavorites!];
    } catch (error) {
      this.logger.error('Failed to get favorite searches', error as Error);
      return [];
    }
  }

  /**
   * 清除所有收藏
   */
  public async clearFavorites(): Promise<boolean> {
    try {
      // 加载历史记录
      const history = await this.getHistory();
      
      // 移除所有收藏标记
      const updatedHistory = history.map(item => ({
        ...item,
        isFavorite: false
      }));
      
      // 保存更新后的历史记录
      this.cachedHistory = updatedHistory;
      this.cachedFavorites = [];
      
      await this.storageUtil.setObject(
        this.storageKeys.searchHistory,
        updatedHistory,
        LocalStorageType.DEFAULT
      );
      
      await this.storageUtil.setObject(
        this.storageKeys.favoriteSearches,
        [],
        LocalStorageType.DEFAULT
      );
      
      this.logger.info('All favorite searches cleared');
      
      return true;
    } catch (error) {
      this.logger.error('Failed to clear favorite searches', error as Error);
      return false;
    }
  }

  /**
   * 获取搜索建议（基于历史记录）
   * @param query 搜索关键词前缀
   * @param type 可选的搜索类型过滤
   * @param limit 返回数量限制
   */
  public async getSuggestions(
    query: string,
    type?: SearchType,
    limit: number = 10
  ): Promise<string[]> {
    try {
      // 验证输入
      if (!query || query.trim().length === 0) {
        return [];
      }
      
      const trimmedQuery = query.trim().toLowerCase();
      
      // 加载配置
      const config = await this.getConfig();
      
      // 检查是否启用自动完成
      if (!config.enableAutoComplete) {
        return [];
      }
      
      // 获取历史记录
      const history = await this.getHistory(type);
      
      // 过滤匹配的搜索词
      const suggestions = history
        .filter(item => item.query.includes(trimmedQuery))
        .map(item => item.query)
        .filter((suggestion, index, self) => self.indexOf(suggestion) === index) // 去重
        .slice(0, Math.max(1, Math.min(limit, 50))); // 限制数量
      
      return suggestions;
    } catch (error) {
      this.logger.warn('Failed to get search suggestions', error as Error);
      return [];
    }
  }

  /**
   * 设置搜索历史配置
   * @param config 配置对象
   */
  public async setConfig(config: Partial<SearchHistoryConfig>): Promise<SearchHistoryConfig> {
    try {
      // 获取当前配置
      const currentConfig = await this.getConfig();
      
      // 合并新配置
      const updatedConfig: SearchHistoryConfig = {
        ...currentConfig,
        ...config
      };
      
      // 验证配置
      this.validateConfig(updatedConfig);
      
      // 保存配置
      this.cachedConfig = updatedConfig;
      await this.storageUtil.setObject(
        this.storageKeys.searchHistoryConfig,
        updatedConfig,
        LocalStorageType.DEFAULT
      );
      
      // 根据新配置清理数据
      await this.applyConfigChanges(currentConfig, updatedConfig);
      
      // 发布配置变更事件
      this.eventBus.emit(SearchHistoryEventType.SEARCH_HISTORY_CONFIG_CHANGED, {
        type: SearchHistoryEventType.SEARCH_HISTORY_CONFIG_CHANGED,
        timestamp: Date.now(),
        data: updatedConfig
      } as SearchHistoryEvent);
      
      this.logger.info('Search history configuration updated');
      
      return updatedConfig;
    } catch (error) {
      this.logger.error('Failed to set search history config', error as Error);
      throw error;
    }
  }

  /**
   * 获取搜索历史配置
   */
  public async getConfig(): Promise<SearchHistoryConfig> {
    try {
      // 如果缓存为空，加载配置
      if (!this.cachedConfig) {
        await this.loadConfig();
      }
      
      return { ...this.cachedConfig! };
    } catch (error) {
      this.logger.error('Failed to get search history config', error as Error);
      return { ...this.defaultConfig };
    }
  }

  /**
   * 重置搜索历史配置到默认值
   */
  public async resetConfig(): Promise<SearchHistoryConfig> {
    try {
      // 保存默认配置
      this.cachedConfig = { ...this.defaultConfig };
      await this.storageUtil.setObject(
        this.storageKeys.searchHistoryConfig,
        this.defaultConfig,
        LocalStorageType.DEFAULT
      );
      
      this.logger.info('Search history configuration reset to default');
      
      return { ...this.defaultConfig };
    } catch (error) {
      this.logger.error('Failed to reset search history config', error as Error);
      throw error;
    }
  }

  /**
   * 加载历史记录
   */
  private async loadHistory(): Promise<void> {
    try {
      const history = await this.storageUtil.getObject<SearchHistoryItem[]>(
        this.storageKeys.searchHistory,
        LocalStorageType.DEFAULT
      );
      
      this.cachedHistory = history || [];
      this.logger.debug(`Loaded ${this.cachedHistory.length} search history items`);
    } catch (error) {
      this.logger.error('Failed to load search history', error as Error);
      this.cachedHistory = [];
    }
  }

  /**
   * 加载收藏搜索
   */
  private async loadFavorites(): Promise<void> {
    try {
      const favorites = await this.storageUtil.getObject<SearchHistoryItem[]>(
        this.storageKeys.favoriteSearches,
        LocalStorageType.DEFAULT
      );
      
      this.cachedFavorites = favorites || [];
      this.logger.debug(`Loaded ${this.cachedFavorites.length} favorite searches`);
    } catch (error) {
      this.logger.error('Failed to load favorite searches', error as Error);
      this.cachedFavorites = [];
    }
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const config = await this.storageUtil.getObject<SearchHistoryConfig>(
        this.storageKeys.searchHistoryConfig,
        LocalStorageType.DEFAULT
      );
      
      this.cachedConfig = config ? { ...this.defaultConfig, ...config } : { ...this.defaultConfig };
      
      // 验证配置
      this.validateConfig(this.cachedConfig);
      
      this.logger.debug('Search history configuration loaded');
    } catch (error) {
      this.logger.error('Failed to load search history config', error as Error);
      this.cachedConfig = { ...this.defaultConfig };
    }
  }

  /**
   * 保存所有数据
   */
  private async saveData(): Promise<void> {
    try {
      await Promise.all([
        this.storageUtil.setObject(
          this.storageKeys.searchHistory,
          this.cachedHistory || [],
          LocalStorageType.DEFAULT
        ),
        this.storageUtil.setObject(
          this.storageKeys.favoriteSearches,
          this.cachedFavorites || [],
          LocalStorageType.DEFAULT
        ),
        this.storageUtil.setObject(
          this.storageKeys.searchHistoryConfig,
          this.cachedConfig || this.defaultConfig,
          LocalStorageType.DEFAULT
        )
      ]);
      
      this.logger.debug('Search history data saved');
    } catch (error) {
      this.logger.error('Failed to save search history data', error as Error);
    }
  }

  /**
   * 清理过期的历史记录
   */
  private async cleanupExpiredHistory(): Promise<void> {
    try {
      const config = await this.getConfig();
      
      // 检查是否启用自动清理
      if (!config.autoClearDays || config.autoClearDays <= 0) {
        return;
      }
      
      const expirationTime = Date.now() - (config.autoClearDays * 24 * 60 * 60 * 1000);
      const history = await this.getHistory();
      
      // 过滤出未过期且不是收藏的记录
      const filteredHistory = history.filter(
        item => item.timestamp > expirationTime || item.isFavorite
      );
      
      // 如果有变化，保存更新后的历史记录
      if (filteredHistory.length !== history.length) {
        this.cachedHistory = filteredHistory;
        await this.storageUtil.setObject(
          this.storageKeys.searchHistory,
          filteredHistory,
          LocalStorageType.DEFAULT
        );
        
        this.logger.info(`Cleaned up ${history.length - filteredHistory.length} expired search history items`);
      }
    } catch (error) {
      this.logger.warn('Failed to cleanup expired search history', error as Error);
    }
  }

  /**
   * 应用配置变更
   */
  private async applyConfigChanges(
    oldConfig: SearchHistoryConfig,
    newConfig: SearchHistoryConfig
  ): Promise<void> {
    try {
      // 检查历史记录数量限制是否改变
      if (oldConfig.maxHistoryItems !== newConfig.maxHistoryItems) {
        const history = await this.getHistory();
        if (history.length > newConfig.maxHistoryItems) {
          const filteredHistory = history.slice(0, newConfig.maxHistoryItems);
          this.cachedHistory = filteredHistory;
          await this.storageUtil.setObject(
            this.storageKeys.searchHistory,
            filteredHistory,
            LocalStorageType.DEFAULT
          );
        }
      }
      
      // 检查收藏数量限制是否改变
      if (oldConfig.maxFavoriteItems !== newConfig.maxFavoriteItems) {
        const favorites = await this.getFavorites();
        if (favorites.length > newConfig.maxFavoriteItems) {
          const filteredFavorites = favorites.slice(0, newConfig.maxFavoriteItems);
          this.cachedFavorites = filteredFavorites;
          
          // 更新历史记录中的收藏状态
          const history = await this.getHistory();
          const updatedHistory = history.map(item => ({
            ...item,
            isFavorite: filteredFavorites.some(fav => fav.id === item.id)
          }));
          
          this.cachedHistory = updatedHistory;
          await this.storageUtil.setObject(
            this.storageKeys.favoriteSearches,
            filteredFavorites,
            LocalStorageType.DEFAULT
          );
          await this.storageUtil.setObject(
            this.storageKeys.searchHistory,
            updatedHistory,
            LocalStorageType.DEFAULT
          );
        }
      }
    } catch (error) {
      this.logger.warn('Failed to apply config changes', error as Error);
    }
  }

  /**
   * 验证配置
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
   * 生成唯一ID
   */
  private generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * 导出搜索历史数据
   */
  public async exportData(): Promise<{
    history: SearchHistoryItem[];
    favorites: SearchHistoryItem[];
    config: SearchHistoryConfig;
    exportTime: number;
  }> {
    try {
      const data = {
        history: await this.getHistory(),
        favorites: await this.getFavorites(),
        config: await this.getConfig(),
        exportTime: Date.now()
      };
      
      this.logger.info('Search history data exported');
      
      return data;
    } catch (error) {
      this.logger.error('Failed to export search history data', error as Error);
      throw error;
    }
  }

  /**
   * 导入搜索历史数据
   * @param data 导入的数据
   * @param merge 是否合并（true）或覆盖（false）
   */
  public async importData(
    data: {
      history?: SearchHistoryItem[];
      favorites?: SearchHistoryItem[];
      config?: Partial<SearchHistoryConfig>;
    },
    merge: boolean = true
  ): Promise<void> {
    try {
      // 验证导入数据
      if (!data || (!data.history && !data.favorites && !data.config)) {
        throw new Error('No valid data to import');
      }
      
      // 获取当前配置
      const currentConfig = await this.getConfig();
      
      // 处理配置导入
      if (data.config) {
        const mergedConfig = merge ? 
          { ...currentConfig, ...data.config } : 
          { ...this.defaultConfig, ...data.config };
        
        this.validateConfig(mergedConfig);
        this.cachedConfig = mergedConfig;
        
        await this.storageUtil.setObject(
          this.storageKeys.searchHistoryConfig,
          mergedConfig,
          LocalStorageType.DEFAULT
        );
      }
      
      // 处理历史记录导入
      if (data.history && Array.isArray(data.history)) {
        const processedHistory = data.history
          .filter(item => this.isValidHistoryItem(item))
          .map(item => this.normalizeHistoryItem(item));
        
        let finalHistory: SearchHistoryItem[];
        
        if (merge) {
          // 合并历史记录
          const currentHistory = await this.getHistory();
          const historyMap = new Map<string, SearchHistoryItem>();
          
          // 添加现有记录
          currentHistory.forEach(item => {
            historyMap.set(`${item.query}-${item.type}`, item);
          });
          
          // 合并新记录（新记录优先级更高）
          processedHistory.forEach(item => {
            const key = `${item.query}-${item.type}`;
            const existingItem = historyMap.get(key);
            
            if (existingItem) {
              // 保留收藏状态
              item.isFavorite = existingItem.isFavorite;
            }
            
            historyMap.set(key, item);
          });
          
          finalHistory = Array.from(historyMap.values())
            .sort((a, b) => b.timestamp - a.timestamp);
        } else {
          // 覆盖历史记录
          finalHistory = processedHistory
            .sort((a, b) => b.timestamp - a.timestamp);
        }
        
        // 应用数量限制
        if (finalHistory.length > currentConfig.maxHistoryItems) {
          finalHistory = finalHistory.slice(0, currentConfig.maxHistoryItems);
        }
        
        this.cachedHistory = finalHistory;
        await this.storageUtil.setObject(
          this.storageKeys.searchHistory,
          finalHistory,
          LocalStorageType.DEFAULT
        );
      }
      
      // 处理收藏导入
      if (data.favorites && Array.isArray(data.favorites)) {
        const processedFavorites = data.favorites
          .filter(item => this.isValidHistoryItem(item))
          .map(item => this.normalizeHistoryItem(item))
          .map(item => ({ ...item, isFavorite: true }));
        
        let finalFavorites: SearchHistoryItem[];
        
        if (merge) {
          // 合并收藏
          const currentFavorites = await this.getFavorites();
          const favoriteMap = new Map<string, SearchHistoryItem>();
          
          // 添加现有收藏
          currentFavorites.forEach(item => {
            favoriteMap.set(`${item.query}-${item.type}`, item);
          });
          
          // 合并新收藏
          processedFavorites.forEach(item => {
            favoriteMap.set(`${item.query}-${item.type}`, item);
          });
          
          finalFavorites = Array.from(favoriteMap.values());
        } else {
          // 覆盖收藏
          finalFavorites = processedFavorites;
        }
        
        // 应用数量限制
        if (finalFavorites.length > currentConfig.maxFavoriteItems) {
          finalFavorites = finalFavorites.slice(0, currentConfig.maxFavoriteItems);
        }
        
        this.cachedFavorites = finalFavorites;
        await this.storageUtil.setObject(
          this.storageKeys.favoriteSearches,
          finalFavorites,
          LocalStorageType.DEFAULT
        );
        
        // 更新历史记录中的收藏状态
        if (this.cachedHistory) {
          const updatedHistory = this.cachedHistory.map(item => ({
            ...item,
            isFavorite: finalFavorites.some(fav => fav.id === item.id || 
              (fav.query === item.query && fav.type === item.type))
          }));
          
          this.cachedHistory = updatedHistory;
          await this.storageUtil.setObject(
            this.storageKeys.searchHistory,
            updatedHistory,
            LocalStorageType.DEFAULT
          );
        }
      }
      
      this.logger.info('Search history data imported successfully');
    } catch (error) {
      this.logger.error('Failed to import search history data', error as Error);
      throw error;
    }
  }

  /**
   * 验证历史记录项
   */
  private isValidHistoryItem(item: any): boolean {
    return item && 
           typeof item.query === 'string' && 
           item.query.trim().length > 0 &&
           typeof item.type === 'string' &&
           typeof item.timestamp === 'number';
  }

  /**
   * 规范化历史记录项
   */
  private normalizeHistoryItem(item: any): SearchHistoryItem {
    return {
      id: item.id || this.generateId(),
      query: item.query.trim().toLowerCase(),
      type: item.type as SearchType,
      timestamp: item.timestamp || Date.now(),
      resultCount: item.resultCount,
      category: item.category,
      isFavorite: !!item.isFavorite
    };
  }

  /**
   * 获取搜索统计信息
   */
  public async getSearchStatistics(): Promise<{
    totalHistoryItems: number;
    totalFavoriteItems: number;
    historyByType: Record<SearchType, number>;
    mostSearchedQuery: string | null;
    mostSearchedType: SearchType;
    lastSearchTime: number | null;
  }> {
    try {
      const history = await this.getHistory();
      const favorites = await this.getFavorites();
      
      // 按类型统计
      const historyByType: Record<SearchType, number> = {
        [SearchType.VIDEO]: 0,
        [SearchType.LIVE]: 0,
        [SearchType.USER]: 0,
        [SearchType.CATEGORY]: 0,
        [SearchType.TAG]: 0,
        [SearchType.ALL]: 0
      };
      
      // 统计查询频率
      const queryFrequency = new Map<string, number>();
      let mostSearchedQuery = '';
      let highestFrequency = 0;
      let mostSearchedType = SearchType.ALL;
      let typeCounts = new Map<SearchType, number>();
      let lastSearchTime: number | null = null;
      
      history.forEach(item => {
        // 类型统计
        historyByType[item.type]++;
        
        // 查询频率
        const frequency = (queryFrequency.get(item.query) || 0) + 1;
        queryFrequency.set(item.query, frequency);
        
        if (frequency > highestFrequency) {
          highestFrequency = frequency;
          mostSearchedQuery = item.query;
        }
        
        // 类型统计
        const typeCount = (typeCounts.get(item.type) || 0) + 1;
        typeCounts.set(item.type, typeCount);
        
        if (typeCount > typeCounts.get(mostSearchedType)!) {
          mostSearchedType = item.type;
        }
        
        // 最后搜索时间
        if (!lastSearchTime || item.timestamp > lastSearchTime) {
          lastSearchTime = item.timestamp;
        }
      });
      
      return {
        totalHistoryItems: history.length,
        totalFavoriteItems: favorites.length,
        historyByType,
        mostSearchedQuery: mostSearchedQuery || null,
        mostSearchedType,
        lastSearchTime
      };
    } catch (error) {
      this.logger.error('Failed to get search statistics', error as Error);
      
      // 返回默认统计信息
      return {
        totalHistoryItems: 0,
        totalFavoriteItems: 0,
        historyByType: {
          [SearchType.VIDEO]: 0,
          [SearchType.LIVE]: 0,
          [SearchType.USER]: 0,
          [SearchType.CATEGORY]: 0,
          [SearchType.TAG]: 0,
          [SearchType.ALL]: 0
        },
        mostSearchedQuery: null,
        mostSearchedType: SearchType.ALL,
        lastSearchTime: null
      };
    }
  }
}

// 导出默认实例
export default SearchHistoryRepository.getInstance();