// 弹幕服务
// 提供弹幕的显示、发送、过滤和历史管理功能

import { StorageUtil } from '../../common/util/StorageUtil';
import { HttpService } from '../HttpService';

export class DanmakuService {
  private static instance: DanmakuService;
  private storageUtil: StorageUtil;
  private httpService: HttpService;
  private danmakuConfig: DanmakuConfig;
  private danmakuHistory: DanmakuHistoryItem[] = [];
  private customDanmakus: DanmakuItem[] = [];
  private listeners: DanmakuListener[] = [];

  private constructor() {
    this.storageUtil = StorageUtil.getInstance();
    this.httpService = HttpService.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): DanmakuService {
    if (!DanmakuService.instance) {
      DanmakuService.instance = new DanmakuService();
    }
    return DanmakuService.instance;
  }

  /**
   * 初始化弹幕服务
   */
  private async initialize(): Promise<void> {
    // 加载配置
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

    // 加载自定义弹幕
    this.customDanmakus = await this.storageUtil.get<DanmakuItem[]>('customDanmakus', []);
  }

  /**
   * 设置弹幕配置
   * @param config 弹幕配置
   */
  public async setConfig(config: Partial<DanmakuConfig>): Promise<void> {
    this.danmakuConfig = { ...this.danmakuConfig, ...config };
    await this.storageUtil.save('danmakuConfig', this.danmakuConfig);
    this.notifyConfigChanged();
  }

  /**
   * 获取弹幕配置
   */
  public getConfig(): DanmakuConfig {
    return { ...this.danmakuConfig };
  }

  /**
   * 加载视频弹幕
   * @param videoId 视频ID
   * @param siteKey 站点键
   * @param episodeIndex 剧集索引
   */
  public async loadDanmakus(videoId: string, siteKey: string, episodeIndex?: number): Promise<DanmakuItem[]> {
    try {
      // 首先从本地历史加载
      const cacheKey = this.getCacheKey(videoId, siteKey, episodeIndex);
      const cachedDanmakus = await this.storageUtil.get<DanmakuItem[]>(cacheKey, []);
      
      // 这里可以添加从远程服务器加载弹幕的逻辑
      // const remoteDanmakus = await this.fetchRemoteDanmakus(videoId, siteKey, episodeIndex);
      
      // 合并本地和远程弹幕
      const allDanmakus = [...cachedDanmakus];
      
      // 应用过滤规则
      const filteredDanmakus = this.applyFilters(allDanmakus);
      
      // 按时间排序
      filteredDanmakus.sort((a, b) => a.time - b.time);
      
      return filteredDanmakus;
    } catch (error) {
      console.error('Failed to load danmakus:', error);
      return [];
    }
  }

  /**
   * 发送弹幕
   * @param danmaku 弹幕内容
   */
  public async sendDanmaku(danmaku: Omit<DanmakuItem, 'id' | 'timestamp'>): Promise<boolean> {
    try {
      const newDanmaku: DanmakuItem = {
        ...danmaku,
        id: this.generateId(),
        timestamp: Date.now()
      };

      // 保存到自定义弹幕列表
      this.customDanmakus.push(newDanmaku);
      await this.storageUtil.save('customDanmakus', this.customDanmakus);

      // 这里可以添加发送到远程服务器的逻辑
      // await this.sendToRemoteServer(newDanmaku);

      // 通知监听器
      this.notifyDanmakuAdded(newDanmaku);

      return true;
    } catch (error) {
      console.error('Failed to send danmaku:', error);
      return false;
    }
  }

  /**
   * 保存弹幕到历史记录
   * @param videoId 视频ID
   * @param siteKey 站点键
   * @param danmakus 弹幕列表
   * @param episodeIndex 剧集索引
   */
  public async saveDanmakusToHistory(videoId: string, siteKey: string, danmakus: DanmakuItem[], episodeIndex?: number): Promise<void> {
    try {
      const cacheKey = this.getCacheKey(videoId, siteKey, episodeIndex);
      
      // 合并并去重
      const existingDanmakus = await this.storageUtil.get<DanmakuItem[]>(cacheKey, []);
      const mergedDanmakus = this.mergeDanmakus(existingDanmakus, danmakus);
      
      await this.storageUtil.save(cacheKey, mergedDanmakus);
      
      // 更新历史记录
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
   * 添加弹幕过滤关键词
   * @param keyword 关键词
   */
  public async addFilterKeyword(keyword: string): Promise<void> {
    if (!this.danmakuConfig.filterKeywords.includes(keyword)) {
      this.danmakuConfig.filterKeywords.push(keyword);
      await this.setConfig(this.danmakuConfig);
    }
  }

  /**
   * 移除弹幕过滤关键词
   * @param keyword 关键词
   */
  public async removeFilterKeyword(keyword: string): Promise<void> {
    this.danmakuConfig.filterKeywords = this.danmakuConfig.filterKeywords.filter(k => k !== keyword);
    await this.setConfig(this.danmakuConfig);
  }

  /**
   * 添加弹幕监听器
   * @param listener 监听器
   */
  public addListener(listener: DanmakuListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  /**
   * 移除弹幕监听器
   * @param listener 监听器
   */
  public removeListener(listener: DanmakuListener): void {
    this.listeners = this.listeners.filter(l => l !== listener);
  }

  /**
   * 获取弹幕历史记录
   */
  public async getDanmakuHistory(): Promise<DanmakuHistoryItem[]> {
    await this.loadHistory();
    return [...this.danmakuHistory];
  }

  /**
   * 清空弹幕历史
   */
  public async clearDanmakuHistory(): Promise<void> {
    this.danmakuHistory = [];
    await this.storageUtil.save('danmakuHistory', this.danmakuHistory);
  }

  /**
   * 应用弹幕过滤规则
   * @param danmakus 弹幕列表
   */
  private applyFilters(danmakus: DanmakuItem[]): DanmakuItem[] {
    return danmakus.filter(danmaku => {
      // 检查类型过滤
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

      // 检查关键词过滤
      const content = danmaku.content.toLowerCase();
      return !this.danmakuConfig.filterKeywords.some(keyword => 
        content.includes(keyword.toLowerCase())
      );
    });
  }

  /**
   * 合并弹幕列表并去重
   * @param existingDanmakus 已存在的弹幕
   * @param newDanmakus 新弹幕
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
   * 更新历史记录项
   * @param item 历史记录项
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
    
    // 限制历史记录数量
    if (this.danmakuHistory.length > 100) {
      this.danmakuHistory = this.danmakuHistory.slice(-100);
    }
    
    this.saveHistory();
  }

  /**
   * 加载历史记录
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
   * 保存历史记录
   */
  private async saveHistory(): Promise<void> {
    try {
      await this.storageUtil.save('danmakuHistory', this.danmakuHistory);
    } catch (error) {
      console.error('Failed to save danmaku history:', error);
    }
  }

  /**
   * 生成缓存键
   */
  private getCacheKey(videoId: string, siteKey: string, episodeIndex?: number): string {
    return `danmaku_${siteKey}_${videoId}${episodeIndex !== undefined ? `_${episodeIndex}` : ''}`;
  }

  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  /**
   * 通知弹幕添加
   */
  private notifyDanmakuAdded(danmaku: DanmakuItem): void {
    for (const listener of this.listeners) {
      listener.onDanmakuAdded?.(danmaku);
    }
  }

  /**
   * 通知配置变更
   */
  private notifyConfigChanged(): void {
    for (const listener of this.listeners) {
      listener.onConfigChanged?.(this.danmakuConfig);
    }
  }
}

/**
 * 弹幕类型枚举
 */
export enum DanmakuType {
  SCROLL = 0, // 滚动弹幕
  TOP = 1,    // 顶部弹幕
  BOTTOM = 4  // 底部弹幕
}

/**
 * 弹幕配置
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
 * 弹幕项
 */
export interface DanmakuItem {
  id: string;
  content: string;
  time: number; // 时间（秒）
  type: DanmakuType;
  color?: string;
  fontSize?: number;
  timestamp: number; // 创建时间戳
  user?: string;
}

/**
 * 弹幕历史记录项
 */
export interface DanmakuHistoryItem {
  videoId: string;
  siteKey: string;
  episodeIndex?: number;
  danmakuCount: number;
  lastUpdated: number;
}

/**
 * 弹幕监听器
 */
export interface DanmakuListener {
  onDanmakuAdded?: (danmaku: DanmakuItem) => void;
  onConfigChanged?: (config: DanmakuConfig) => void;
}