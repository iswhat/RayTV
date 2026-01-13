import Logger from '../../common/util/Logger';
import { Site } from '../../data/bean/Site';
import { SiteManager } from '../spider/SiteManager';
import { ConfigLoader } from './ConfigLoader';
import { ConfigParser } from './ConfigParser';
import { SiteDao } from '../../data/db/dao/SiteDao';
import { SubscriptionDao } from '../../data/db/dao/SubscriptionDao';

const TAG = 'SubscriptionManager';

/**
 * 订阅项目接口 | Subscription item interface
 */
export interface SubscriptionItem {
  id: string;              // 唯一标识 | Unique identifier
  name: string;            // 订阅名称 | Subscription name
  url: string;             // 订阅URL | Subscription URL
  description?: string;    // 订阅描述 | Subscription description
  type?: 'all' | 'vod' | 'live'; // 订阅类型 | Subscription type
  updateTime: number;      // 最后更新时间 | Last update time
  createTime: number;      // 创建时间 | Create time
  siteCount: number;       // 包含站点数量 | Number of sites
  enabled: boolean;        // 是否启用 | Whether enabled
  current: boolean;        // 是否为当前使用的订阅 | Whether it is the currently used subscription
}

/**
 * 订阅管理结果 | Subscription management result
 */
export interface SubscriptionResult {
  success: boolean;
  message?: string;
  data?: Record<string, string | number | boolean | null>;
}

/**
 * 订阅管理器 | Subscription manager
 * 负责配置URL的订阅管理、更新和切换 | Responsible for subscription management, update and switching of configuration URLs
 */
export class SubscriptionManager {
  private static instance: SubscriptionManager | null = null;
  private subscriptions: Map<string, SubscriptionItem> = new Map();
  private siteManager: SiteManager;
  private configLoader: ConfigLoader;
  private configParser: ConfigParser;
  private siteDao: SiteDao;
  private subscriptionDao: SubscriptionDao;
  private initialized: boolean = false;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): SubscriptionManager {
    if (!SubscriptionManager.instance) {
      SubscriptionManager.instance = new SubscriptionManager();
    }
    return SubscriptionManager.instance;
  }

  /**
   * 构造函数 | Constructor
   */
  private constructor() {
    this.siteManager = SiteManager.getInstance();
    this.configLoader = ConfigLoader.getInstance();
    this.configParser = ConfigParser.getInstance();
    this.siteDao = new SiteDao();
    this.subscriptionDao = new SubscriptionDao();
    Logger.info(TAG, 'SubscriptionManager initialized');
  }

  private context?: Record<string, string | number | boolean | null>;

  /**
   * 初始化订阅管理器 | Initialize subscription manager
   * @param context 应用上下文 | Application context
   */
  public async initialize(context?: Record<string, string | number | boolean | null>): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      // 保存上下文（如果提供） | Save context (if provided)
      if (context) {
        this.context = context;
      }
      
      Logger.info(TAG, 'Initializing subscription manager...');
      
      // 初始化订阅表 | Initialize subscription table
      await this.subscriptionDao.initTable(context);
      
      // 从持久化存储加载订阅配置 | Load subscription config from persistent storage
      await this.loadSubscriptions();
      
      // 恢复当前订阅的站点 | Restore sites for current subscription
      const currentSubscription = this.getCurrentSubscription();
      if (currentSubscription && currentSubscription.enabled) {
        Logger.info(TAG, `Restoring sites for current subscription: ${currentSubscription.name}`);
        try {
          // 加载配置并注册站点 | Load config and register sites
          const configContent = await this.configLoader.loadFromUrl(currentSubscription.url);
          const sites = this.configParser.parseSites(configContent);
          await this.siteManager.registerSites(sites);
        } catch (error) {
          Logger.error(TAG, `Failed to restore current subscription sites: ${error}`);
        }
      }
      
      this.initialized = true;
      Logger.info(TAG, `Subscription manager initialized with ${this.subscriptions.size} subscriptions`);
    } catch (error) {
      Logger.error(TAG, `Failed to initialize subscription manager: ${error}`);
      throw error;
    }
  }

  /**
   * 添加订阅 | Add subscription
   * @param name 订阅名称 | Subscription name
   * @param url 订阅URL | Subscription URL
   * @param description 订阅描述 | Subscription description
   */
  public async addSubscription(name: string, url: string, description?: string): Promise<SubscriptionResult> {
    try {
      // 验证URL格式 | Validate URL format
      if (!this.isValidUrl(url)) {
        return {
          success: false,
          message: '无效的URL格式'
        };
      }

      // 生成订阅ID | Generate subscription ID
      const id = this.generateSubscriptionId(url);
      
      // 检查是否已存在相同URL的订阅 | Check if subscription with same URL already exists
      if (this.subscriptions.has(id)) {
        return {
          success: false,
          message: '订阅URL已存在'
        };
      }

      // 测试订阅URL是否可访问 | Test if subscription URL is accessible
      const testResult = await this.testSubscriptionUrl(url);
      if (!testResult.success) {
        return testResult;
      }

      // 创建订阅 | Create subscription
      const subscription: SubscriptionItem = {
        id,
        name,
        url,
        description,
        updateTime: Date.now(),
        createTime: Date.now(),
        siteCount: (testResult.data?.sites?.length || 0),
        enabled: true,
        current: false
      };

      // 添加到订阅列表 | Add to subscription list
      this.subscriptions.set(id, subscription);
      
      // 保存到持久化存储 | Save to persistent storage
      await this.saveSubscriptions();

      Logger.info(TAG, `Added subscription: ${name} (${url})`);
      return {
        success: true,
        message: '订阅添加成功',
        data: subscription
      };
    } catch (error) {
      Logger.error(TAG, `Failed to add subscription: ${error}`);
      return {
        success: false, 
        message: `添加订阅失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 删除订阅 | Delete subscription
   * @param subscriptionId 订阅ID | Subscription ID
   */
  public async deleteSubscription(subscriptionId: string): Promise<SubscriptionResult> {
    try {
      const subscription = this.subscriptions.get(subscriptionId);
      if (!subscription) {
        return {
          success: false,
          message: '订阅不存在'
        };
      }

      // 如果是当前使用的订阅，先禁用 | If it is the current subscription, disable first
      if (subscription.current) {
        await this.disableCurrentSubscription();
      }

      // 从订阅列表中删除 | Remove from subscription list
      this.subscriptions.delete(subscriptionId);
      
      // 保存到持久化存储 | Save to persistent storage
      await this.saveSubscriptions();

      Logger.info(TAG, `Deleted subscription: ${subscription.name}`);
      return {
        success: true,
        message: '订阅删除成功'
      };
    } catch (error) {
      Logger.error(TAG, `Failed to delete subscription: ${error}`);
      return {
        success: false, 
        message: `删除订阅失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 更新订阅 | Update subscription
   * @param subscriptionId 订阅ID | Subscription ID
   * @param data 更新数据 | Update data
   */
  public async updateSubscription(subscriptionId: string, data: Partial<SubscriptionItem>): Promise<SubscriptionResult> {
    try {
      const subscription = this.subscriptions.get(subscriptionId);
      if (!subscription) {
        return {
          success: false,
          message: '订阅不存在'
        };
      }

      // 更新订阅信息 | Update subscription information
      const updatedSubscription = { ...subscription, ...data };

      // 如果更新了URL，需要重新生成ID | If URL is updated, need to regenerate ID
      if (data.url && data.url !== subscription.url) {
        // 验证新URL | Validate new URL
        if (!this.isValidUrl(data.url)) {
          return {
            success: false,
            message: '无效的URL格式'
          };
        }

        // 检查新URL是否已存在 | Check if new URL already exists
        const newId = this.generateSubscriptionId(data.url);
        if (this.subscriptions.has(newId) && newId !== subscriptionId) {
          return {
            success: false,
            message: '新URL已存在订阅'
          };
        }

        // 从旧ID删除 | Remove from old ID
        this.subscriptions.delete(subscriptionId);
        
        // 用新ID添加 | Add with new ID
        updatedSubscription.id = newId;
        this.subscriptions.set(newId, updatedSubscription as SubscriptionItem);
      } else {
        this.subscriptions.set(subscriptionId, updatedSubscription as SubscriptionItem);
      }

      // 保存到持久化存储 | Save to persistent storage
      await this.saveSubscriptions();

      Logger.info(TAG, `Updated subscription: ${updatedSubscription.name}`);
      return {
        success: true,
        message: '订阅更新成功',
        data: updatedSubscription
      };
    } catch (error) {
      Logger.error(TAG, `Failed to update subscription: ${error}`);
      return {
        success: false, 
        message: `更新订阅失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 刷新订阅 | Refresh subscription
   * @param subscriptionId 订阅ID | Subscription ID
   */
  public async refreshSubscription(subscriptionId: string): Promise<SubscriptionResult> {
    try {
      const subscription = this.subscriptions.get(subscriptionId);
      if (!subscription) {
        return {
          success: false,
          message: '订阅不存在'
        };
      }

      // 加载最新配置 | Load latest config
      const configContent = await this.configLoader.loadFromUrl(subscription.url);
      
      // 解析站点配置 | Parse site config
      const sites = this.configParser.parseSites(configContent);
      
      // 更新订阅信息 | Update subscription information
      subscription.siteCount = sites.length;
      subscription.updateTime = Date.now();
      
      // 如果是当前订阅，更新站点 | If it is current subscription, update sites
      if (subscription.current) {
        // 先禁用所有当前站点 | First disable all current sites
        await this.disableCurrentSites();
        
        // 注册新站点 | Register new sites
        await this.siteManager.registerSites(sites);
      }

      // 保存到持久化存储 | Save to persistent storage
      await this.saveSubscriptions();

      Logger.info(TAG, `Refreshed subscription: ${subscription.name}, loaded ${sites.length} sites`);
      return {
        success: true,
        message: `订阅刷新成功，共${sites.length}个站点`,
        data: {
          subscription,
          sites
        }
      };
    } catch (error) {
      Logger.error(TAG, `Failed to refresh subscription: ${error}`);
      return {
        success: false, 
        message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 切换到指定订阅 | Switch to specified subscription
   * @param subscriptionId 订阅ID | Subscription ID
   */
  public async switchToSubscription(subscriptionId: string): Promise<SubscriptionResult> {
    try {
      const subscription = this.subscriptions.get(subscriptionId);
      if (!subscription) {
        return {
          success: false,
          message: '订阅不存在'
        };
      }

      if (!subscription.enabled) {
        return {
          success: false,
          message: '订阅已禁用'
        };
      }

      // 禁用当前订阅 | Disable current subscription
      await this.disableCurrentSubscription();

      // 设置新的当前订阅 | Set new current subscription
      subscription.current = true;
      
      // 加载订阅配置 | Load subscription config
      const configContent = await this.configLoader.loadFromUrl(subscription.url);
      const sites = this.configParser.parseSites(configContent);
      
      // 注册站点 | Register sites
      await this.siteManager.registerSites(sites);
      
      // 保存到持久化存储 | Save to persistent storage
      await this.saveSubscriptions();

      Logger.info(TAG, `Switched to subscription: ${subscription.name}, loaded ${sites.length} sites`);
      return {
        success: true,
        message: `成功切换到订阅"${subscription.name}"`,
        data: sites
      };
    } catch (error) {
      Logger.error(TAG, `Failed to switch subscription: ${error}`);
      return {
        success: false, 
        message: `切换订阅失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 禁用当前订阅 | Disable current subscription
   */
  private async disableCurrentSubscription(): Promise<void> {
    // 禁用所有站点 | Disable all sites
    await this.disableCurrentSites();
    
    // 重置所有订阅的current状态 | Reset current status of all subscriptions
    for (const subscription of this.subscriptions.values()) {
      subscription.current = false;
    }
  }

  /**
   * 禁用当前所有站点 | Disable all current sites
   */
  private async disableCurrentSites(): Promise<void> {
    const sites = this.siteManager.getAllSites();
    for (const site of sites) {
      await this.siteManager.setSiteEnabled(site.key, false);
    }
  }

  /**
   * 测试订阅URL | Test subscription URL
   * @param url 订阅URL | Subscription URL
   */
  public async testSubscriptionUrl(url: string): Promise<SubscriptionResult> {
    try {
      Logger.info(TAG, `Testing subscription URL: ${url}`);
      
      // 加载配置 | Load config
      const configContent = await this.configLoader.loadFromUrl(url);
      
      // 解析站点 | Parse sites
      const sites = this.configParser.parseSites(configContent);
      
      // 验证站点数量 | Validate site count
      if (sites.length === 0) {
        return {
          success: false,
          message: '配置文件中未找到有效站点'
        };
      }
      
      return {
        success: true,
        message: `URL访问成功，发现${sites.length}个站点`,
        data: { sites }
      };
    } catch (error) {
      Logger.error(TAG, `Failed to test subscription URL: ${error}`);
      return {
        success: false, 
        message: `URL测试失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 获取所有订阅项 | Get all subscriptions
   */
  public getAllSubscriptions(): SubscriptionItem[] {
    return Array.from(this.subscriptions.values());
  }

  /**
   * 获取订阅详情 | Get subscription details
   * @param subscriptionId 订阅ID | Subscription ID
   */
  public getSubscription(subscriptionId: string): SubscriptionItem | undefined {
    return this.subscriptions.get(subscriptionId);
  }

  /**
   * 获取当前使用的订阅项 | Get current subscription
   */
  public getCurrentSubscription(): SubscriptionItem | undefined {
    return Array.from(this.subscriptions.values()).find(sub => sub.current);
  }

  /**
   * 生成订阅ID | Generate subscription ID
   * @param url 订阅URL | Subscription URL
   */
  private generateSubscriptionId(url: string): string {
    // 简单的URL哈希作为订阅ID | Simple URL hash as subscription ID
    let hash = 0;
    for (let i = 0; i < url.length; i++) {
      const char = url.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return `sub_${Math.abs(hash).toString(36)}`;
  }

  /**
   * 验证URL格式 | Validate URL format
   * @param url URL字符串 | URL string
   * @returns 是否为有效URL | Whether it is a valid URL
   */
  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      // 简单的URL格式检查作为备用 | Simple URL format check as fallback
      return /^https?:\/\/.+/.test(url);
    }
  }

  /**
   * 保存订阅列表到持久化存储 | Save subscription list to persistent storage
   */
  private async saveSubscriptions(): Promise<void> {
    try {
      const subscriptions = Array.from(this.subscriptions.values());
      Logger.info(TAG, `Saving ${subscriptions.length} subscriptions`);
      
      // 批量保存订阅 | Batch save subscriptions
      await this.subscriptionDao.saveAll(subscriptions);
    } catch (error) {
      Logger.error(TAG, `Failed to save subscriptions: ${error}`);
      // 保存失败不影响主要功能 | Save failure does not affect main functionality
    }
  }

  /**
   * 从持久化存储加载订阅列表 | Load subscription list from persistent storage
   */
  private async loadSubscriptions(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading subscriptions from storage');
      
      // 从数据库加载订阅 | Load subscriptions from database
      const subscriptions = await this.subscriptionDao.getAll();
      
      // 清空现有订阅 | Clear existing subscriptions
      this.subscriptions.clear();
      
      // 添加到内存 | Add to memory
      subscriptions.forEach(subscription => {
        this.subscriptions.set(subscription.id, subscription);
      });
      
      Logger.info(TAG, `Loaded ${subscriptions.length} subscriptions from storage`);
    } catch (error) {
      Logger.error(TAG, `Failed to load subscriptions: ${error}`);
    }
  }
}

export function getSubscriptionManager(): SubscriptionManager {
  return SubscriptionManager.getInstance();
}
