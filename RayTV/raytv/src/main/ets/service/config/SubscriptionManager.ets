import Logger from '../../common/util/Logger';
import { Site } from '../../data/bean/Site';
import { SiteManager } from '../spider/SiteManager';
import { ConfigLoader } from './ConfigLoader';
import { ConfigParser } from './ConfigParser';
import { SiteDao } from '../../data/db/dao/SiteDao';
import { SubscriptionDao } from '../../data/dao/SubscriptionDao';

const TAG = 'SubscriptionManager';

/**
 * 订阅项接口定�? */
export interface SubscriptionItem {
  id: string;              // 唯一标识
  name: string;            // 订阅名称
  url: string;             // 订阅URL
  description?: string;    // 订阅描述
  type?: 'all' | 'vod' | 'live'; // 订阅类型
  updateTime: number;      // 最后更新时�?  createTime: number;      // 创建时间
  siteCount: number;       // 包含站点数量
  enabled: boolean;        // 是否启用
  current: boolean;        // 是否为当前使用的订阅
}

/**
 * 订阅管理结果
 */
export interface SubscriptionResult {
  success: boolean;
  message?: string;
  data?: Record<string, string | number | boolean | null>;
}

/**
 * 订阅管理�? * 负责配置URL的订阅管理、更新和切换
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
   * 获取单例实例
   */
  public static getInstance(): SubscriptionManager {
    if (!SubscriptionManager.instance) {
      SubscriptionManager.instance = new SubscriptionManager();
    }
    return SubscriptionManager.instance;
  }

  /**
   * 构造函�?   */
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
   * 初始化订阅管理器
   * @param context 应用上下�?   */
  public async initialize(context?: Record<string, string | number | boolean | null>): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      // 保存上下文（如果提供�?      if (context) {
        this.context = context;
      }
      
      Logger.info(TAG, 'Initializing subscription manager...');
      
      // 初始化订阅表
      await this.subscriptionDao.initTable(context);
      
      // 从持久化存储加载订阅配置
      await this.loadSubscriptions();
      
      // 恢复当前订阅的站�?      const currentSubscription = this.getCurrentSubscription();
      if (currentSubscription && currentSubscription.enabled) {
        Logger.info(TAG, `Restoring sites for current subscription: ${currentSubscription.name}`);
        try {
          // 加载配置并注册站�?          const configContent = await this.configLoader.loadFromUrl(currentSubscription.url);
          const sites = this.configParser.parseSites(configContent);
          await this.siteManager.registerSites(sites);
        } catch (error) {
          Logger.error(TAG, `Failed to restore current subscription sites: ${error}`);
        }
      }
      
      this.initialized = true;
      Logger.info(TAG, `Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions` instanceof Error ? `Subscription manager initialized with ${this.subscriptions.size} subscriptions` : new Error(String(`Subscription manager initialized with ${this.subscriptions.size} subscriptions`)))))));
    } catch (error) {
      Logger.error(TAG, `Failed to initialize subscription manager: ${error}`);
      throw error;
    }
  }

  /**
   * 添加订阅
   * @param name 订阅名称
   * @param url 订阅URL
   * @param description 订阅描述
   */
  public async addSubscription(name: string, url: string, description?: string instanceof Error ? url: string, description?: string : new Error(String(url: string, description?: string instanceof Error ? url: string, description?: string instanceof Error ? url: string, description?: string : new Error(String(url: string, description?: string : new Error(String(url: string, description?: string instanceof Error ? url: string, description?: string : new Error(String(url: string, description?: string instanceof Error ? url: string, description?: string instanceof Error ? url: string, description?: string : new Error(String(url: string, description?: string instanceof Error ? url: string, description?: string instanceof Error ? url: string, description?: string : new Error(String(url: string, description?: string : new Error(String(url: string, description?: string instanceof Error ? url: string, description?: string : new Error(String(url: string, description?: string : new Error(String(url: string, description?: string instanceof Error ? url: string, description?: string : new Error(String(url: string, description?: string instanceof Error ? url: string, description?: string instanceof Error ? url: string, description?: string : new Error(String(url: string, description?: string : new Error(String(url: string, description?: string instanceof Error ? url: string, description?: string : new Error(String(url: string, description?: string))))))): Promise<SubscriptionResult> {
    try {
      // 验证URL格式
      if (!this.isValidUrl(url)) {
        return {
          success: false,
          message: '无效的URL格式'
        };
      }

      // 生成订阅ID
      const id = this.generateSubscriptionId(url);
      
      // 检查是否已存在相同URL的订�?      if (this.subscriptions.has(id)) {
        return {
          success: false,
          message: '订阅URL已存�?
        };
      }

      // 测试订阅URL是否可访�?      const testResult = await this.testSubscriptionUrl(url);
      if (!testResult.success) {
        return testResult;
      }

      // 创建订阅�?      const subscription: SubscriptionItem = {
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

      // 添加到订阅列�?      this.subscriptions.set(id, subscription);
      
      // 保存到持久化存储
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
        success: false, message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `添加订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `添加订阅失败: ${error instanceof Error ? error.message : String(error)))))))}`
      };
    }
  }

  /**
   * 删除订阅
   * @param subscriptionId 订阅ID
   */
  public async deleteSubscription(subscriptionId: string): Promise<SubscriptionResult> {
    try {
      const subscription = this.subscriptions.get(subscriptionId);
      if (!subscription) {
        return {
          success: false,
          message: '订阅不存�?
        };
      }

      // 如果是当前使用的订阅，先停用
      if (subscription.current) {
        await this.disableCurrentSubscription();
      }

      // 从订阅列表中移除
      this.subscriptions.delete(subscriptionId);
      
      // 保存到持久化存储
      await this.saveSubscriptions();

      Logger.info(TAG, `Deleted subscription: ${subscription.name}`);
      return {
        success: true,
        message: '订阅删除成功'
      };
    } catch (error) {
      Logger.error(TAG, `Failed to delete subscription: ${error}`);
      return {
        success: false, message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `删除订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `删除订阅失败: ${error instanceof Error ? error.message : String(error)))))))}`
      };
    }
  }

  /**
   * 更新订阅
   * @param subscriptionId 订阅ID
   * @param data 更新数据
   */
  public async updateSubscription(subscriptionId: string, data: Partial<SubscriptionItem>): Promise<SubscriptionResult> {
    try {
      const subscription = this.subscriptions.get(subscriptionId);
      if (!subscription) {
        return {
          success: false,
          message: '订阅不存�?
        };
      }

      // 更新订阅信息
      const updatedSubscription: Record<string, string | number | boolean | null> = { ... };

      // 如果更新了URL，需要重新生成ID
      if (data.url && data.url !== subscription.url) {
        // 验证新URL
        if (!this.isValidUrl(data.url)) {
          return {
            success: false,
            message: '无效的URL格式'
          };
        }

        // 检查新URL是否已存�?        const newId = this.generateSubscriptionId(data.url);
        if (this.subscriptions.has(newId) && newId !== subscriptionId) {
          return {
            success: false,
            message: '新URL已存在订�?
          };
        }

        // 从旧ID移除
        this.subscriptions.delete(subscriptionId);
        
        // 用新ID添加
        updatedSubscription.id = newId;
        this.subscriptions.set(newId, updatedSubscription);
      } else {
        this.subscriptions.set(subscriptionId, updatedSubscription);
      }

      // 保存到持久化存储
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
        success: false, message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `更新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `更新订阅失败: ${error instanceof Error ? error.message : String(error)))))))}`
      };
    }
  }

  /**
   * 刷新订阅
   * @param subscriptionId 订阅ID
   */
  public async refreshSubscription(subscriptionId: string): Promise<SubscriptionResult> {
    try {
      const subscription = this.subscriptions.get(subscriptionId);
      if (!subscription) {
        return {
          success: false,
          message: '订阅不存�?
        };
      }

      // 加载最新配�?      const configContent = await this.configLoader.loadFromUrl(subscription.url);
      
      // 解析站点配置
      const sites = this.configParser.parseSites(configContent);
      
      // 更新订阅信息
      subscription.siteCount = sites.length;
      subscription.updateTime = Date.now();
      
      // 如果是当前订阅，更新站点
      if (subscription.current) {
        // 先禁用所有当前站�?        await this.disableCurrentSites();
        
        // 注册新站�?        await this.siteManager.registerSites(sites);
      }

      // 保存到持久化存储
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
        success: false, message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `刷新订阅失败: ${error instanceof Error ? error.message : String(error)))))))}`
      };
    }
  }

  /**
   * 切换到指定订�?   * @param subscriptionId 订阅ID
   */
  public async switchToSubscription(subscriptionId: string): Promise<SubscriptionResult> {
    try {
      const subscription = this.subscriptions.get(subscriptionId);
      if (!subscription) {
        return {
          success: false,
          message: '订阅不存�?
        };
      }

      if (!subscription.enabled) {
        return {
          success: false,
          message: '订阅已禁�?
        };
      }

      // 停用当前订阅
      await this.disableCurrentSubscription();

      // 设置新的当前订阅
      subscription.current = true;
      
      // 加载订阅配置
      const configContent = await this.configLoader.loadFromUrl(subscription.url);
      const sites = this.configParser.parseSites(configContent);
      
      // 注册站点
      await this.siteManager.registerSites(sites);
      
      // 保存到持久化存储
      await this.saveSubscriptions();

      Logger.info(TAG, `Switched to subscription: ${subscription.name}, loaded ${sites.length} sites`);
      return {
        success: true,
        message: `成功切换到订�?${subscription.name}"`,
        data: sites
      };
    } catch (error) {
      Logger.error(TAG, `Failed to switch subscription: ${error}`);
      return {
        success: false, message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `切换订阅失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `切换订阅失败: ${error instanceof Error ? error.message : String(error)))))))}`
      };
    }
  }

  /**
   * 禁用当前订阅
   */
  private async disableCurrentSubscription(): Promise<void> {
    // 禁用所有站�?    await this.disableCurrentSites();
    
    // 重置所有订阅的current状�?    for (const subscription of this.subscriptions.values()) {
      subscription.current = false;
    }
  }

  /**
   * 禁用当前所有站�?   */
  private async disableCurrentSites(): Promise<void> {
    const sites = this.siteManager.getAllSites();
    for (const site of sites) {
      await this.siteManager.setSiteEnabled(site.key, false);
    }
  }

  /**
   * 测试订阅URL
   * @param url 订阅URL
   */
  public async testSubscriptionUrl(url: string): Promise<SubscriptionResult> {
    try {
      Logger.info(TAG, `Testing subscription URL: ${url}`);
      
      // 加载配置
      const configContent = await this.configLoader.loadFromUrl(url);
      
      // 解析站点
      const sites = this.configParser.parseSites(configContent);
      
      // 验证站点数量
      if (sites.length === 0) {
        return {
          success: false,
          message: '配置文件中未找到有效站点'
        };
      }
      
      return {
        success: true,
        message: `URL访问成功，发�?{sites.length}个站点`,
        data: { sites }
      };
    } catch (error) {
      Logger.error(TAG, `Failed to test subscription URL: ${error}`);
      return {
        success: false, message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error instanceof Error ? message: `URL测试失败: ${error instanceof Error ? error.message : String(error : new Error(String(message: `URL测试失败: ${error instanceof Error ? error.message : String(error)))))))}`
      };
    }
  }

  /**
   * 获取所有订�?   */
  public getAllSubscriptions(): SubscriptionItem[] {
    return Array.from(this.subscriptions.values());
  }

  /**
   * 获取订阅详情
   * @param subscriptionId 订阅ID
   */
  public getSubscription(subscriptionId: string): SubscriptionItem | undefined {
    return this.subscriptions.get(subscriptionId);
  }

  /**
   * 获取当前使用的订�?   */
  public getCurrentSubscription(): SubscriptionItem | undefined {
    return Array.from(this.subscriptions.values()).find(sub => sub.current);
  }

  /**
   * 生成订阅ID
   * @param url 订阅URL
   */
  private generateSubscriptionId(url: string): string {
    // 简单的URL哈希作为订阅ID
    let hash = 0;
    for (let i = 0; i < url.length; i++) {
      const char = url.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return `sub_${Math.abs(hash).toString(36)}`;
  }

  /**
   * 验证URL格式
   * @param url URL字符�?   */
  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      // 简单的URL格式检查作为备�?      return /^https?:\/\/.+/.test(url);
    }
  }

  /**
   * 保存订阅列表到持久化存储
   */
  private async saveSubscriptions(): Promise<void> {
    try {
      const subscriptions = Array.from(this.subscriptions.values());
      Logger.info(TAG, `Saving ${subscriptions.length} subscriptions`);
      
      // 批量保存订阅
      await this.subscriptionDao.saveAll(subscriptions);
    } catch (error) {
      Logger.error(TAG, `Failed to save subscriptions: ${error}`);
      // 保存失败不影响主要功�?    }
  }

  /**
   * 从持久化存储加载订阅列表
   */
  private async loadSubscriptions(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage' instanceof Error ? 'Loading subscriptions from storage' : new Error(String('Loading subscriptions from storage')))))));
      
      // 从数据库加载订阅
      const subscriptions = await this.subscriptionDao.getAll();
      
      // 清空现有订阅
      this.subscriptions.clear();
      
      // 添加到内�?      subscriptions.forEach(subscription => {
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



