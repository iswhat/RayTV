/**
 * Network Source Manager - 网络源管理服务
 * 
 * 负责网络源的CRUD操作、健康检查、内容使用配置等
 * 与ConfigSourceService协作,提供更高层次的源管理功能
 */

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import HttpService from '../HttpService';
import SourcePoolManager, { NetworkSourceConfig, ContentUsage } from '../pool/SourcePoolManager';

const STORAGE_KEY = 'network_sources_config';
const TAG = 'NetworkSourceManager';

/**
 * 默认内容使用配置
 */
const DEFAULT_CONTENT_USAGE: ContentUsage = {
  vodSites: true,
  liveChannels: true,
  wallpapers: true,
  adBlockRules: true,
  decoderConfigs: true,
  parserConfigs: true
};

/**
 * 默认网络源
 */
const DEFAULT_SOURCES: NetworkSourceConfig[] = [
  {
    id: 'source_default_a',
    name: '默认配置源A',
    url: 'https://list.eoeoo.com/base2/a.json',
    type: 'json',
    version: '1.0.0',
    isActive: true,
    contentUsage: { ...DEFAULT_CONTENT_USAGE },
    priority: 1,
    tags: ['TVBox', '推荐'],
    lastUpdated: Date.now(),
    healthStatus: 'healthy'
  },
  {
    id: 'source_default_b',
    name: '默认配置源B',
    url: 'https://q.uoouo.com/dianshi.json',
    type: 'json',
    version: '1.0.0',
    isActive: true,
    contentUsage: { ...DEFAULT_CONTENT_USAGE },
    priority: 2,
    tags: ['影视仓', 'Fongmi'],
    lastUpdated: Date.now(),
    healthStatus: 'healthy'
  }
];

/**
 * 网络源管理器
 */
export class NetworkSourceManager {
  private static instance: NetworkSourceManager | null = null;
  private logger: Logger;
  private httpService: HttpService;
  private poolManager: SourcePoolManager;
  
  private sources: NetworkSourceConfig[] = [];
  private initialized: boolean = false;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): NetworkSourceManager {
    if (!NetworkSourceManager.instance) {
      NetworkSourceManager.instance = new NetworkSourceManager();
    }
    return NetworkSourceManager.instance;
  }
  
  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger = Logger.getInstance(TAG);
    this.httpService = HttpService.getInstance();
    this.poolManager = SourcePoolManager.getInstance();
  }
  
  /**
   * 初始化管理器
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }
    
    try {
      // 加载存储的源配置
      await this.loadSources();
      
      this.initialized = true;
      this.logger.info('NetworkSourceManager initialized');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.logger.error('Failed to initialize NetworkSourceManager', err);
      throw err;
    }
  }
  
  /**
   * 加载源配置
   */
  private async loadSources(): Promise<void> {
    try {
      const stored = await StorageUtil.getItem(STORAGE_KEY);
      if (stored) {
        this.sources = JSON.parse(stored) as NetworkSourceConfig[];
      } else {
        // 使用默认源
        this.sources = DEFAULT_SOURCES.map(s => ({ ...s }));
        await this.saveSources();
      }
      
      this.logger.info(`Loaded ${this.sources.length} network sources`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.logger.error('Failed to load sources', err);
      // 使用默认源
      this.sources = DEFAULT_SOURCES.map(s => ({ ...s }));
    }
  }
  
  /**
   * 保存源配置
   */
  private async saveSources(): Promise<void> {
    try {
      await StorageUtil.setItem(STORAGE_KEY, JSON.stringify(this.sources));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.logger.error('Failed to save sources', err);
      throw err;
    }
  }
  
  // ========================================
  // 源CRUD操作
  // ========================================
  
  /**
   * 添加网络源
   */
  public async addSource(source: NetworkSourceConfig): Promise<void> {
    // 检查ID是否重复
    if (this.sources.some(s => s.id === source.id)) {
      throw new Error(`Source with ID ${source.id} already exists`);
    }
    
    // 检查URL是否重复
    if (this.sources.some(s => s.url === source.url)) {
      throw new Error(`Source with URL ${source.url} already exists`);
    }
    
    try {
      // 测试连接
      const healthStatus = await this.checkSourceHealthInternal(source.url);
      source.healthStatus = healthStatus;
      source.lastUpdated = Date.now();
      
      // 添加到列表
      this.sources.push(source);
      
      // 保存并重建池
      await this.saveSources();
      await this.rebuildPoolsIfNeeded(source.isActive);
      
      this.logger.info(`Added source: ${source.name}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.logger.error(`Failed to add source ${source.name}`, err);
      throw err;
    }
  }
  
  /**
   * 删除网络源
   */
  public async removeSource(sourceId: string): Promise<void> {
    const index = this.sources.findIndex(s => s.id === sourceId);
    if (index === -1) {
      throw new Error(`Source with ID ${sourceId} not found`);
    }
    
    const source = this.sources[index];
    this.sources.splice(index, 1);
    
    // 保存并重建池
    await this.saveSources();
    await this.poolManager.rebuildAllPools(this.sources);
    
    this.logger.info(`Removed source: ${source.name}`);
  }
  
  /**
   * 更新网络源
   */
  public async updateSource(source: NetworkSourceConfig): Promise<void> {
    const index = this.sources.findIndex(s => s.id === source.id);
    if (index === -1) {
      throw new Error(`Source with ID ${source.id} not found`);
    }
    
    // 如果URL改变了,重新检查健康状态
    const oldSource = this.sources[index];
    if (oldSource.url !== source.url) {
      const healthStatus = await this.checkSourceHealthInternal(source.url);
      source.healthStatus = healthStatus;
      source.lastUpdated = Date.now();
    }
    
    // 更新源
    this.sources[index] = source;
    
    // 保存并重建池
    await this.saveSources();
    await this.rebuildPoolsIfNeeded(source.isActive || oldSource.isActive);
    
    this.logger.info(`Updated source: ${source.name}`);
  }
  
  /**
   * 切换源启用状态
   */
  public async toggleSource(sourceId: string, isActive: boolean): Promise<void> {
    const source = this.sources.find(s => s.id === sourceId);
    if (!source) {
      throw new Error(`Source with ID ${sourceId} not found`);
    }
    
    if (source.isActive === isActive) {
      return; // 状态未改变
    }
    
    source.isActive = isActive;
    
    // 保存并重建池
    await this.saveSources();
    await this.poolManager.rebuildAllPools(this.sources);
    
    this.logger.info(`Toggled source ${source.name} to ${isActive ? 'active' : 'inactive'}`);
  }
  
  /**
   * 更新内容使用配置
   */
  public async updateContentUsage(sourceId: string, usage: ContentUsage): Promise<void> {
    const source = this.sources.find(s => s.id === sourceId);
    if (!source) {
      throw new Error(`Source with ID ${sourceId} not found`);
    }
    
    source.contentUsage = { ...usage };
    
    // 保存并重建池
    await this.saveSources();
    await this.poolManager.rebuildAllPools(this.sources);
    
    this.logger.info(`Updated content usage for source: ${source.name}`);
  }
  
  /**
   * 更新优先级
   */
  public async updatePriority(sourceId: string, priority: number): Promise<void> {
    const source = this.sources.find(s => s.id === sourceId);
    if (!source) {
      throw new Error(`Source with ID ${sourceId} not found`);
    }
    
    source.priority = Math.max(1, Math.min(10, priority)); // 限制在1-10范围内
    
    // 保存并重建池
    await this.saveSources();
    await this.poolManager.rebuildAllPools(this.sources);
    
    this.logger.info(`Updated priority for source ${source.name} to ${priority}`);
  }
  
  /**
   * 添加标签
   */
  public async addTag(sourceId: string, tag: string): Promise<void> {
    const source = this.sources.find(s => s.id === sourceId);
    if (!source) {
      throw new Error(`Source with ID ${sourceId} not found`);
    }
    
    if (!source.tags) {
      source.tags = [];
    }
    
    if (!source.tags.includes(tag)) {
      source.tags.push(tag);
      await this.saveSources();
    }
  }
  
  /**
   * 移除标签
   */
  public async removeTag(sourceId: string, tag: string): Promise<void> {
    const source = this.sources.find(s => s.id === sourceId);
    if (!source) {
      throw new Error(`Source with ID ${sourceId} not found`);
    }
    
    if (source.tags) {
      source.tags = source.tags.filter(t => t !== tag);
      await this.saveSources();
    }
  }
  
  // ========================================
  // 源查询
  // ========================================
  
  /**
   * 获取所有源
   */
  public getAllSources(): NetworkSourceConfig[] {
    return this.sources;
  }
  
  /**
   * 获取启用的源
   */
  public getActiveSources(): NetworkSourceConfig[] {
    return this.sources.filter(s => s.isActive);
  }
  
  /**
   * 按ID获取源
   */
  public getSourceById(sourceId: string): NetworkSourceConfig | null {
    return this.sources.find(s => s.id === sourceId) || null;
  }
  
  /**
   * 按标签获取源
   */
  public getSourcesByTag(tag: string): NetworkSourceConfig[] {
    return this.sources.filter(s => s.tags && s.tags.includes(tag));
  }
  
  // ========================================
  // 健康检查
  // ========================================
  
  /**
   * 检查单个源的健康状态
   */
  public async checkSourceHealth(sourceId: string): Promise<'healthy' | 'degraded' | 'unreachable'> {
    const source = this.getSourceById(sourceId);
    if (!source) {
      throw new Error(`Source with ID ${sourceId} not found`);
    }
    
    const healthStatus = await this.checkSourceHealthInternal(source.url);
    source.healthStatus = healthStatus;
    source.lastUpdated = Date.now();
    await this.saveSources();
    
    return healthStatus;
  }
  
  /**
   * 检查所有源的健康状态
   */
  public async checkAllSourcesHealth(): Promise<Map<string, 'healthy' | 'degraded' | 'unreachable'>> {
    const results = new Map<string, 'healthy' | 'degraded' | 'unreachable'>();
    
    for (const source of this.sources) {
      try {
        const healthStatus = await this.checkSourceHealthInternal(source.url);
        source.healthStatus = healthStatus;
        source.lastUpdated = Date.now();
        results.set(source.id, healthStatus);
      } catch (error) {
        source.healthStatus = 'unreachable';
        source.lastUpdated = Date.now();
        results.set(source.id, 'unreachable');
      }
    }
    
    await this.saveSources();
    return results;
  }
  
  /**
   * 内部健康检查方法
   */
  private async checkSourceHealthInternal(url: string): Promise<'healthy' | 'degraded' | 'unreachable'> {
    try {
      const startTime = Date.now();
      const response = await this.httpService.get(url, { timeout: 10000 });
      const duration = Date.now() - startTime;
      
      if (response && response.statusCode >= 200 && response.statusCode < 300) {
        // 响应时间超过5秒视为降级
        return duration > 5000 ? 'degraded' : 'healthy';
      }
      
      return 'degraded';
    } catch (error) {
      return 'unreachable';
    }
  }
  
  // ========================================
  // 池管理
  // ========================================
  
  /**
   * 重建所有池(当源配置改变时调用)
   */
  public async rebuildPools(): Promise<void> {
    await this.poolManager.rebuildAllPools(this.sources);
  }
  
  /**
   * 如果需要则重建池
   */
  private async rebuildPoolsIfNeeded(needRebuild: boolean): Promise<void> {
    if (needRebuild) {
      await this.rebuildPools();
    }
  }
  
  /**
   * 获取源统计信息
   */
  public getSourcesStats(): {
    total: number;
    active: number;
    healthy: number;
    degraded: number;
    unreachable: number;
  } {
    const stats = {
      total: this.sources.length,
      active: this.sources.filter(s => s.isActive).length,
      healthy: this.sources.filter(s => s.healthStatus === 'healthy').length,
      degraded: this.sources.filter(s => s.healthStatus === 'degraded').length,
      unreachable: this.sources.filter(s => s.healthStatus === 'unreachable').length
    };
    
    return stats;
  }
}

// 导出单例实例
export default NetworkSourceManager.getInstance();
