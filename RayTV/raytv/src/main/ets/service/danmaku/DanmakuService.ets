// 弹幕服务 | Danmaku service
// 提供弹幕的显示、发送、过滤和历史管理功能 | Provides danmaku display, sending, filtering and history management functionality

import { StorageUtil } from '../../common/util/StorageUtil';
import { HttpService } from '../HttpService';

export class DanmakuService {
  static instance: DanmakuService;
  storageUtil: StorageUtil;
  httpService: HttpService;
  danmakuConfig: DanmakuConfig;
  danmakuHistory: DanmakuHistoryItem[] = [];
  customDanmakus: DanmakuItem[] = [];
  listeners: DanmakuListener[] = [];

  constructor() {
    this.storageUtil = StorageUtil.getInstance();
    this.httpService = HttpService.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例 | Get singleton instance
   */
  static getInstance(): DanmakuService {
    if (!DanmakuService.instance) {
      DanmakuService.instance = new DanmakuService();
    }
    return DanmakuService.instance;
  }

  /**
   * 初始化弹幕服务 | Initialize danmaku service
   */
  async initialize(): Promise<void> {
    // 加载配置 | Load configuration
    this.danmakuConfig = await this.storageUtil.get<DanmakuConfig>('danmakuConfig', {
      enabled: true,
      opacity: 0.8,
      fontSize: 16,
      speed: 100,
      showTop: true,
      showBottom: true,
      showScroll: true,
      filterKeywords: [],
      maxDisplayCount: 50
    });

    // 加载自定义弹幕 | Load custom danmakus
    this.customDanmakus = await this.storageUtil.get<DanmakuItem[]>('customDanmakus', []);
  }

  /**
   * 设置弹幕配置 | Set danmaku configuration
   * @param config 弹幕配置 | Danmaku configuration
   */
  async setConfig(config: Partial<DanmakuConfig>): Promise<void> {
    this.danmakuConfig = { ...this.danmakuConfig, ...config };
    await this.storageUtil.save('danmakuConfig', this.danmakuConfig);
    this.notifyConfigChanged();
  }

  /**
   * 获取弹幕配置 | Get danmaku configuration
   */
  getConfig(): DanmakuConfig {
    return { ...this.danmakuConfig };
  }

  /**
   * 加载视频弹幕 | Load video danmakus
   * @param videoId 视频ID | Video ID
   * @param siteKey 站点键 | Site key
   * @param episodeIndex 剧集索引 | Episode index
   */
  async loadDanmakus(videoId: string, siteKey: string, episodeIndex?: number): Promise<DanmakuItem[]> {
    try {
      // 首先从本地缓存加载 | First load from local cache
      const cacheKey = this.getCacheKey(videoId, siteKey, episodeIndex);
      const cachedDanmakus = await this.storageUtil.get<DanmakuItem[]>(cacheKey, []);
      
      // 这里可以添加从远程服务器加载弹幕的逻辑 | Can add logic to load danmakus from remote server here
      // const remoteDanmakus = await this.fetchRemoteDanmakus(videoId, siteKey, episodeIndex);
      
      // 合并本地和远程弹幕 | Merge local and remote danmakus
      const allDanmakus = [...cachedDanmakus];
      
      // 应用过滤规则 | Apply filter rules
      const filteredDanmakus = this.applyFilters(allDanmakus);
      
      // 按时间排序 | Sort by time
      filteredDanmakus.sort((a, b) => a.time - b.time);
      
      return filteredDanmakus;
    } catch (error) {
      console.error('Failed to load danmakus:', error);
      return [];
    }
  }

  /**
   * 发送弹幕 | Send danmaku
   * @param danmaku 弹幕内容 | Danmaku content
   */
  async sendDanmaku(danmaku: Omit<DanmakuItem, 'id' | 'timestamp'>): Promise<boolean> {
    try {
      const newDanmaku: DanmakuItem = {
        ...danmaku,
        id: this.generateId(),
        timestamp: Date.now()
      };

      // 保存到自定义弹幕列表 | Save to custom danmaku list
      this.customDanmakus.push(newDanmaku);
      await this.storageUtil.save('customDanmakus', this.customDanmakus);

      // 这里可以添加发送到远程服务器的逻辑 | Can add logic to send to remote server here
      // await this.sendToRemoteServer(newDanmaku);

      // 通知监听器 | Notify listeners
      this.notifyDanmakuAdded(newDanmaku);

      return true;
    } catch (error) {
      console.error('Failed to send danmaku:', error);
      return false;
    }
  }

  /**
   * 保存弹幕到缓存/历史 | Save danmakus to cache/history
   * @param videoId 视频ID | Video ID
   * @param siteKey 站点键 | Site key
   * @param danmakus 弹幕列表 | Danmaku list
   * @param episodeIndex 剧集索引 | Episode index
   */
  async saveDanmakusToHistory(videoId: string, siteKey: string, danmakus: DanmakuItem[], episodeIndex?: number): Promise<void> {
    try {
      const cacheKey = this.getCacheKey(videoId, siteKey, episodeIndex);
      
      // 合并并去重 | Merge and deduplicate
      const existingDanmakus = await this.storageUtil.get<DanmakuItem[]>(cacheKey, []);
      const mergedDanmakus = this.mergeDanmakus(existingDanmakus, danmakus);
      
      await this.storageUtil.save(cacheKey, mergedDanmakus);
      
      // 更新历史记录 | Update history record
      const historyItem: DanmakuHistoryItem = {
        videoId,
        siteKey,
        episodeIndex,
        danmakuCount: mergedDanmakus.length,
        lastUpdated: Date.now()
      };
      
      this.updateHistoryItem(historyItem);
    } catch (error) {
      console.error('Failed to save danmakus to history:', error);
    }
  }

  /**
   * 添加弹幕过滤关键词 | Add danmaku filter keyword
   * @param keyword 关键词 | Keyword
   */
  async addFilterKeyword(keyword: string): Promise<void> {
    if (!this.danmakuConfig.filterKeywords.includes(keyword)) {
      this.danmakuConfig.filterKeywords.push(keyword);
      await this.setConfig(this.danmakuConfig);
    }
  }

  /**
   * 删除弹幕过滤关键词 | Remove danmaku filter keyword
   * @param keyword 关键词 | Keyword
   */
  async removeFilterKeyword(keyword: string): Promise<void> {
    this.danmakuConfig.filterKeywords = this.danmakuConfig.filterKeywords.filter(k => k !== keyword);
    await this.setConfig(this.danmakuConfig);
  }

  /**
   * 添加弹幕监听器 | Add danmaku listener
   * @param listener 监听器 | Listener
   */
  addListener(listener: DanmakuListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  /**
   * 删除弹幕监听器 | Remove danmaku listener
   * @param listener 监听器 | Listener
   */
  removeListener(listener: DanmakuListener): void {
    this.listeners = this.listeners.filter(l => l !== listener);
  }

  /**
   * 获取弹幕历史记录 | Get danmaku history
   */
  public async getDanmakuHistory(): Promise<DanmakuHistoryItem[]> {
    await this.loadHistory();
    return [...this.danmakuHistory];
  }

  /**
   * 清空弹幕历史 | Clear danmaku history
   */
  public async clearDanmakuHistory(): Promise<void> {
    this.danmakuHistory = [];
    await this.storageUtil.save('danmakuHistory', this.danmakuHistory);
  }

  /**
   * 应用弹幕过滤规则 | Apply danmaku filter rules
   * @param danmakus 弹幕列表 | Danmaku list
   */
  private applyFilters(danmakus: DanmakuItem[]): DanmakuItem[] {
    return danmakus.filter(danmaku => {
      // 检查类型过滤 | Check type filter
      switch (danmaku.type) {
        case DanmakuType.TOP:
          if (!this.danmakuConfig.showTop) return false;
          break;
        case DanmakuType.BOTTOM:
          if (!this.danmakuConfig.showBottom) return false;
          break;
        case DanmakuType.SCROLL:
          if (!this.danmakuConfig.showScroll) return false;
          break;
      }

      // 检查关键词过滤 | Check keyword filter
      const content = danmaku.content.toLowerCase();
      return !this.danmakuConfig.filterKeywords.some(keyword => 
        content.includes(keyword.toLowerCase())
      );
    });
  }

  /**
   * 合并弹幕列表并去重 | Merge danmaku lists and deduplicate
   * @param existingDanmakus 已存在的弹幕 | Existing danmakus
   * @param newDanmakus 新弹幕 | New danmakus
   */
  private mergeDanmakus(existingDanmakus: DanmakuItem[], newDanmakus: DanmakuItem[]): DanmakuItem[] {
    const idSet = new Set(existingDanmakus.map(d => d.id));
    const merged = [...existingDanmakus];
    
    for (const danmaku of newDanmakus) {
      if (!idSet.has(danmaku.id)) {
        merged.push(danmaku);
        idSet.add(danmaku.id);
      }
    }
    
    return merged;
  }

  /**
   * 更新历史记录项 | Update history record item
   * @param item 历史记录项 | History record item
   */
  private updateHistoryItem(item: DanmakuHistoryItem): void {
    const index = this.danmakuHistory.findIndex(
      h => h.videoId === item.videoId && h.siteKey === item.siteKey && h.episodeIndex === item.episodeIndex
    );
    
    if (index >= 0) {
      this.danmakuHistory[index] = item;
    } else {
      this.danmakuHistory.push(item);
    }
    
    // 限制历史记录数量 | Limit history record count
    if (this.danmakuHistory.length > 100) {
      this.danmakuHistory = this.danmakuHistory.slice(-100);
    }
    
    this.saveHistory();
  }

  /**
   * 加载历史记录 | Load history
   */
  private async loadHistory(): Promise<void> {
    try {
      const history = await this.storageUtil.get<DanmakuHistoryItem[]>('danmakuHistory', []);
      this.danmakuHistory = history || [];
    } catch (error) {
      console.error('Failed to load danmaku history:', error);
      this.danmakuHistory = [];
    }
  }

  /**
   * 保存历史记录 | Save history
   */
  private async saveHistory(): Promise<void> {
    try {
      await this.storageUtil.save('danmakuHistory', this.danmakuHistory);
    } catch (error) {
      console.error('Failed to save danmaku history:', error);
    }
  }

  /**
   * 生成缓存键 | Generate cache key
   */
  private getCacheKey(videoId: string, siteKey: string, episodeIndex?: number): string {
    return `danmaku_${siteKey}_${videoId}${episodeIndex !== undefined ? `_${episodeIndex}` : ''}`;
  }

  /**
   * 生成唯一ID | Generate unique ID
   */
  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  /**
   * 通知弹幕添加 | Notify danmaku added
   */
  private notifyDanmakuAdded(danmaku: DanmakuItem): void {
    for (const listener of this.listeners) {
      listener.onDanmakuAdded?.(danmaku);
    }
  }

  /**
   * 通知配置变更 | Notify config changed
   */
  private notifyConfigChanged(): void {
    for (const listener of this.listeners) {
      listener.onConfigChanged?.(this.danmakuConfig);
    }
  }
}

/**
 * 弹幕类型枚举 | Danmaku type enum
 */
export enum DanmakuType {
  SCROLL = 0, // 滚动弹幕 | Scroll danmaku
  TOP = 1,    // 顶部弹幕 | Top danmaku
  BOTTOM = 4  // 底部弹幕 | Bottom danmaku
}

/**
 * 弹幕配置 | Danmaku config
 */
export interface DanmakuConfig {
  enabled: boolean;
  opacity: number;
  fontSize: number;
  speed: number;
  showTop: boolean;
  showBottom: boolean;
  showScroll: boolean;
  filterKeywords: string[];
  maxDisplayCount: number;
}

/**
 * 弹幕项 | Danmaku item
 */
export interface DanmakuItem {
  id: string;
  content: string;
  time: number; // 时间（秒） | Time (seconds)
  type: DanmakuType;
  color?: string;
  fontSize?: number;
  timestamp: number; // 创建时间戳 | Create timestamp
  user?: string;
}

/**
 * 弹幕历史记录项 | Danmaku history item
 */
export interface DanmakuHistoryItem {
  videoId: string;
  siteKey: string;
  episodeIndex?: number;
  danmakuCount: number;
  lastUpdated: number;
}

/**
 * 弹幕监听器 | Danmaku listener
 */
export interface DanmakuListener {
  onDanmakuAdded?: (danmaku: DanmakuItem) => void;
  onConfigChanged?: (config: DanmakuConfig) => void;
}
