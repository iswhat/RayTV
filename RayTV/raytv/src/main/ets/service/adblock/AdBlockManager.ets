import Logger from '../../common/util/Logger';
import { AdBlockConfig } from '../../data/bean/Config';
import { configService } from '../config/ConfigService';

/**
 * 广告规则模型
 */
export class AdRule {
  pattern: string;       // 匹配模式
  type: 'domain' | 'regex' | 'keyword'; // 规则类型
  description?: string;  // 规则描述
  source?: string;       // 规则来源

  constructor(pattern: string, type: 'domain' | 'regex' | 'keyword', description?: string, source?: string) {
    this.pattern = pattern;
    this.type = type;
    this.description = description;
    this.source = source;
  }

  /**
   * 测试URL是否匹配此规则
   */
  matches(url: string): boolean {
    switch (this.type) {
      case 'domain':
        return this.matchesDomain(url);
      case 'regex':
        return this.matchesRegex(url);
      case 'keyword':
        return this.matchesKeyword(url);
      default:
        return false;
    }
  }

  private matchesDomain(url: string): boolean {
    try {
      const domain = new URL(url).hostname;
      return domain === this.pattern || domain.endsWith(`.${this.pattern}`);
    } catch {
      return false;
    }
  }

  private matchesRegex(url: string): boolean {
    try {
      const regex = new RegExp(this.pattern);
      return regex.test(url);
    } catch {
      return false;
    }
  }

  private matchesKeyword(url: string): boolean {
    return url.toLowerCase().includes(this.pattern.toLowerCase());
  }
}

/**
 * URL过滤器
 */
export class UrlFilter {
  private rules: AdRule[] = [];

  /**
   * 添加规则
   */
  addRule(rule: AdRule): void {
    this.rules.push(rule);
  }

  /**
   * 批量添加规则
   */
  addRules(rules: AdRule[]): void {
    this.rules.push(...rules);
  }

  /**
   * 清除所有规则
   */
  clearRules(): void {
    this.rules = [];
  }

  /**
   * 检查URL是否应该被过滤
   */
  shouldBlock(url: string): boolean {
    if (!url || typeof url !== 'string') {
      return false;
    }

    return this.rules.some(rule => rule.matches(url));
  }

  /**
   * 获取匹配的规则
   */
  getMatchingRule(url: string): AdRule | null {
    return this.rules.find(rule => rule.matches(url)) || null;
  }

  /**
   * 获取规则数量
   */
  getRuleCount(): number {
    return this.rules.length;
  }
}

/**
 * 广告屏蔽管理器
 */
export class AdBlockManager {
  private static readonly TAG: string = 'AdBlockManager';
  private static instance: AdBlockManager;
  
  private config: AdBlockConfig | null = null;
  private urlFilter: UrlFilter = new UrlFilter();
  private isInitialized: boolean = false;
  private whitelist: Set<string> = new Set();

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): AdBlockManager {
    if (!AdBlockManager.instance) {
      AdBlockManager.instance = new AdBlockManager();
    }
    return AdBlockManager.instance;
  }

  /**
   * 初始化广告屏蔽管理器
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(AdBlockManager.TAG, 'Initializing AdBlockManager...');
      
      // 加载配置
      this.config = await configService.getAdBlockConfig();
      
      // 加载默认规则
      await this.loadDefaultRules();
      
      // 加载白名单
      await this.loadWhitelist();
      
      this.isInitialized = true;
      Logger.info(AdBlockManager.TAG, `AdBlockManager initialized with ${this.urlFilter.getRuleCount()} rules`);
    } catch (error) {
      Logger.error(AdBlockManager.TAG, `Failed to initialize AdBlockManager: ${error}`);
      throw error;
    }
  }

  /**
   * 加载默认广告规则
   */
  private async loadDefaultRules(): Promise<void> {
    // 默认广告规则列表
    const defaultRules: AdRule[] = [
      // 常见广告域名
      new AdRule('example.com', 'domain', 'AdService'),
      new AdRule('example-doubleclick.net', 'domain', 'Ad Network'),
        new AdRule('example-syndication.com', 'domain', 'Ad Network'),
      
      // 广告关键词
      new AdRule('banner', 'keyword', 'Banner ads'),
      new AdRule('adspot', 'keyword', 'Ad spot'),
      new AdRule('advertisement', 'keyword', 'Advertisement'),
      
      // 视频广告正则表达式
      new AdRule(/ad\.(mp4|m3u8|ts)/i, 'regex', 'Video ads'),
      new AdRule(/advertisement\d*\./i, 'regex', 'Advertisement domains'),
    ];
    
    // 如果有自定义规则，加载它们
    if (this.config?.rules && this.config.rules.length > 0) {
      this.config.rules.forEach(ruleStr => {
        try {
          // 简单的规则解析逻辑
          if (ruleStr.startsWith('regex:')) {
            const pattern = ruleStr.replace('regex:', '');
            this.urlFilter.addRule(new AdRule(pattern, 'regex', 'Custom regex rule'));
          } else if (ruleStr.includes('.')) {
            this.urlFilter.addRule(new AdRule(ruleStr, 'domain', 'Custom domain rule'));
          } else {
            this.urlFilter.addRule(new AdRule(ruleStr, 'keyword', 'Custom keyword rule'));
          }
        } catch (e) {
          Logger.error(AdBlockManager.TAG, `Invalid custom rule: ${ruleStr}`, e);
        }
      });
    }
    
    // 添加默认规则
    this.urlFilter.addRules(defaultRules);
  }

  /**
   * 加载白名单
   */
  private async loadWhitelist(): Promise<void> {
    if (this.config?.whitelist && this.config.whitelist.length > 0) {
      this.config.whitelist.forEach(item => this.whitelist.add(item));
    }
  }

  /**
   * 更新广告规则
   */
  public async updateRules(): Promise<void> {
    try {
      Logger.info(AdBlockManager.TAG, 'Updating ad block rules...');
      
      // 清除现有规则
      this.urlFilter.clearRules();
      
      // 重新加载配置
      this.config = await configService.getAdBlockConfig();
      
      // 重新加载规则
      await this.loadDefaultRules();
      await this.loadWhitelist();
      
      // 更新最后更新时间
      if (this.config) {
        this.config.lastUpdateTime = Date.now();
        await configService.saveAdBlockConfig(this.config);
      }
      
      Logger.info(AdBlockManager.TAG, `Rules updated. Now have ${this.urlFilter.getRuleCount()} rules.`);
    } catch (error) {
      Logger.error(AdBlockManager.TAG, `Failed to update rules: ${error}`);
      throw error;
    }
  }

  /**
   * 检查URL是否应该被屏蔽
   */
  public shouldBlock(url: string): boolean {
    if (!this.isInitialized || !this.config?.enabled) {
      return false;
    }

    // 检查白名单
    for (const item of this.whitelist) {
      if (url.includes(item)) {
        return false;
      }
    }

    return this.urlFilter.shouldBlock(url);
  }

  /**
   * 处理网络请求，拦截广告
   */
  public interceptRequest(url: string, requestType: string): boolean {
    if (!this.isInitialized || !this.config?.enabled) {
      return false;
    }

    // 根据请求类型和配置决定是否拦截
    if (requestType === 'video' && !this.config.blockVideoAds) {
      return false;
    }

    if (requestType === 'popup' && !this.config.blockPopupAds) {
      return false;
    }

    return this.shouldBlock(url);
  }

  /**
   * 获取规则统计信息
   */
  public getStats(): { ruleCount: number; lastUpdate?: number; enabled: boolean } {
    return {
      ruleCount: this.urlFilter.getRuleCount(),
      lastUpdate: this.config?.lastUpdateTime,
      enabled: this.config?.enabled || false
    };
  }

  /**
   * 添加自定义过滤规则
   */
  public async addCustomFilter(filter: string): Promise<void> {
    try {
      if (!this.config) {
        this.config = await configService.getAdBlockConfig();
      }
      
      if (!this.config.customFilters) {
        this.config.customFilters = [];
      }
      
      if (!this.config.customFilters.includes(filter)) {
        this.config.customFilters.push(filter);
        await configService.saveAdBlockConfig(this.config);
        await this.updateRules();
      }
    } catch (error) {
      Logger.error(AdBlockManager.TAG, `Failed to add custom filter: ${error}`);
      throw error;
    }
  }

  /**
   * 启用/禁用广告屏蔽
   */
  public async setEnabled(enabled: boolean): Promise<void> {
    try {
      if (!this.config) {
        this.config = await configService.getAdBlockConfig();
      }
      
      this.config.enabled = enabled;
      await configService.saveAdBlockConfig(this.config);
      
      Logger.info(AdBlockManager.TAG, `Ad blocking ${enabled ? 'enabled' : 'disabled'}`);
    } catch (error) {
      Logger.error(AdBlockManager.TAG, `Failed to set ad block enabled state: ${error}`);
      throw error;
    }
  }
}

// 导出单例实例
export const adBlockManager = AdBlockManager.getInstance();