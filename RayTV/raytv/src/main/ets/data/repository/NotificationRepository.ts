// NotificationRepository - 通知仓库类
// 负责管理应用内通知、系统通知和用户偏好设置

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType } from '../model/CacheModel';

/**
 * 通知类型枚举
 */
export enum NotificationType {
  // 内容通知
  LIVE_START = 'live_start',
  LIVE_END = 'live_end',
  VIDEO_UPDATED = 'video_updated',
  SERIES_NEW_EPISODE = 'series_new_episode',
  RECOMMENDATION = 'recommendation',
  
  // 社交通知
  FOLLOWED_CHANNEL_LIVE = 'followed_channel_live',
  COMMENT_REPLY = 'comment_reply',
  MENTIONED = 'mentioned',
  LIKE = 'like',
  SHARE = 'share',
  
  // 系统通知
  SYSTEM_ANNOUNCEMENT = 'system_announcement',
  MAINTENANCE_ALERT = 'maintenance_alert',
  FEATURE_UPDATE = 'feature_update',
  
  // 用户相关通知
  ACCOUNT_VERIFICATION = 'account_verification',
  PASSWORD_CHANGE = 'password_change',
  LOGIN_ACTIVITY = 'login_activity',
  SUBSCRIPTION_REMINDER = 'subscription_reminder',
  SUBSCRIPTION_EXPIRY = 'subscription_expiry',
  PAYMENT_SUCCESS = 'payment_success',
  PAYMENT_FAILED = 'payment_failed',
  
  // 互动通知
  DOWNLOAD_COMPLETE = 'download_complete',
  DOWNLOAD_FAILED = 'download_failed',
  PLAYBACK_ERROR = 'playback_error',
  WATCHLIST_ADD = 'watchlist_add',
  WATCHLIST_REMOVE = 'watchlist_remove',
  
  // 定制通知
  CUSTOM = 'custom',
  UNKNOWN = 'unknown'
}

/**
 * 通知优先级枚举
 */
export enum NotificationPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  URGENT = 'urgent'
}

/**
 * 通知状态枚举
 */
export enum NotificationStatus {
  NEW = 'new',
  READ = 'read',
  DISMISSED = 'dismissed',
  ARCHIVED = 'archived'
}

/**
 * 通知内容接口
 */
export interface NotificationContent {
  title: string;
  body: string;
  imageUrl?: string;
  videoUrl?: string;
  thumbnailUrl?: string;
  deepLink?: string;
  actionText?: string;
  actionUrl?: string;
  actionData?: Record<string, any>;
}

/**
 * 通知元数据接口
 */
export interface NotificationMetadata {
  relatedEntityId?: string;
  relatedEntityType?: 'video' | 'live' | 'user' | 'channel' | 'comment';
  senderId?: string;
  senderName?: string;
  senderAvatar?: string;
  timestamp: number;
  expiresAt?: number;
  isSilent: boolean;
  requiresInteraction: boolean;
  notificationGroup?: string;
  badgeCount?: number;
  customSound?: string;
  vibrationPattern?: number[];
}

/**
 * 通知接口
 */
export interface Notification {
  id: string;
  type: NotificationType;
  status: NotificationStatus;
  priority: NotificationPriority;
  content: NotificationContent;
  metadata: NotificationMetadata;
  readAt?: number;
  dismissedAt?: number;
  archivedAt?: number;
}

/**
 * 通知配置接口
 */
export interface NotificationConfig {
  // 通用设置
  enableNotifications: boolean;
  enableSound: boolean;
  enableVibration: boolean;
  enableLight: boolean;
  
  // 类型设置
  enabledTypes: NotificationType[];
  mutedTypes: NotificationType[];
  
  // 时间段设置
  enableDoNotDisturb: boolean;
  doNotDisturbStart: string; // HH:MM
  doNotDisturbEnd: string; // HH:MM
  
  // 优先级设置
  minPriority: NotificationPriority;
  
  // 高级设置
  enableBadgeCount: boolean;
  maxStoredNotifications: number;
  notificationHistoryDays: number;
  
  // 频道/用户特定设置
  subscribedChannels: string[];
  mutedChannels: string[];
  
  // 系统通知设置
  enableSystemNotifications: boolean;
  enableMaintenanceAlerts: boolean;
  enableFeatureUpdates: boolean;
  
  // 社交通知设置
  enableSocialNotifications: boolean;
  enableCommentReplies: boolean;
  enableMentions: boolean;
  enableLikes: boolean;
  enableShares: boolean;
  
  // 内容通知设置
  enableLiveNotifications: boolean;
  enableVideoUpdateNotifications: boolean;
  enableRecommendationNotifications: boolean;
  
  // 用户通知设置
  enableAccountNotifications: boolean;
  enablePaymentNotifications: boolean;
  enableSubscriptionNotifications: boolean;
  
  // 互动通知设置
  enableDownloadNotifications: boolean;
  enableErrorNotifications: boolean;
}

/**
 * 通知事件类型
 */
export const NotificationEventType = {
  // 通知生命周期事件
  RECEIVED: 'notification:received',
  READ: 'notification:read',
  DISMISSED: 'notification:dismissed',
  ARCHIVED: 'notification:archived',
  RESTORED: 'notification:restored',
  
  // 状态变更事件
  STATUS_CHANGED: 'notification:statusChanged',
  BADGE_COUNT_CHANGED: 'notification:badgeCountChanged',
  
  // 配置事件
  CONFIG_CHANGED: 'notification:configChanged',
  DO_NOT_DISTURB_TOGGLED: 'notification:doNotDisturbToggled',
  
  // 组事件
  GROUP_CREATED: 'notification:groupCreated',
  GROUP_UPDATED: 'notification:groupUpdated',
  
  // 批量事件
  BATCH_MARKED_READ: 'notification:batchMarkedRead',
  BATCH_DISMISSED: 'notification:batchDismissed',
  BATCH_ARCHIVED: 'notification:batchArchived',
  CLEARED_ALL: 'notification:clearedAll',
  
  // 过滤事件
  FILTER_APPLIED: 'notification:filterApplied',
  
  // 统计事件
  STATS_UPDATED: 'notification:statsUpdated'
} as const;

/**
 * 通知事件数据
 */
export interface NotificationEvent {
  type: string;
  timestamp: number;
  notification?: Notification;
  notifications?: Notification[];
  notificationIds?: string[];
  status?: NotificationStatus;
  config?: NotificationConfig;
  badgeCount?: number;
  filter?: NotificationFilter;
  stats?: NotificationStats;
  error?: Error;
}

/**
 * 通知过滤器接口
 */
export interface NotificationFilter {
  types?: NotificationType[];
  status?: NotificationStatus[];
  priorities?: NotificationPriority[];
  startDate?: number;
  endDate?: number;
  searchTerm?: string;
  relatedEntityId?: string;
  relatedEntityType?: string;
  senderId?: string;
  limit?: number;
  offset?: number;
}

/**
 * 通知统计接口
 */
export interface NotificationStats {
  totalCount: number;
  newCount: number;
  readCount: number;
  dismissedCount: number;
  archivedCount: number;
  byType: Map<NotificationType, number>;
  byPriority: Map<NotificationPriority, number>;
  bySender: Map<string, number>;
  lastReceivedTime: number;
  lastReadTime: number;
}

/**
 * 通知组接口
 */
export interface NotificationGroup {
  id: string;
  title: string;
  summary: string;
  notificationIds: string[];
  count: number;
  newCount: number;
  timestamp: number;
  type: NotificationType;
  priority: NotificationPriority;
  senderId?: string;
  relatedEntityId?: string;
}

/**
 * 通知仓库类
 */
export class NotificationRepository {
  private static instance: NotificationRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  
  // 存储键配置
  private storageKeys = {
    notifications: 'notification:notifications',
    config: 'notification:config',
    stats: 'notification:stats',
    groups: 'notification:groups',
    settings: 'notification:settings',
    badgeCount: 'notification:badgeCount',
    lastSyncTime: 'notification:lastSyncTime'
  };
  
  // 获取所有有效的通知类型值
  private getNotificationTypeValues(): NotificationType[] {
    return [
      NotificationType.LIVE_START,
      NotificationType.LIVE_END,
      NotificationType.VIDEO_UPDATED,
      NotificationType.SERIES_NEW_EPISODE,
      NotificationType.RECOMMENDATION,
      NotificationType.FOLLOWED_CHANNEL_LIVE,
      NotificationType.COMMENT_REPLY,
      NotificationType.MENTIONED,
      NotificationType.LIKE,
      NotificationType.SHARE,
      NotificationType.SYSTEM_ANNOUNCEMENT,
      NotificationType.MAINTENANCE_ALERT,
      NotificationType.FEATURE_UPDATE,
      NotificationType.ACCOUNT_VERIFICATION,
      NotificationType.PASSWORD_CHANGE,
      NotificationType.LOGIN_ACTIVITY,
      NotificationType.SUBSCRIPTION_REMINDER,
      NotificationType.SUBSCRIPTION_EXPIRY,
      NotificationType.PAYMENT_SUCCESS,
      NotificationType.PAYMENT_FAILED,
      NotificationType.DOWNLOAD_COMPLETE,
      NotificationType.DOWNLOAD_FAILED,
      NotificationType.PLAYBACK_ERROR,
      NotificationType.WATCHLIST_ADD,
      NotificationType.WATCHLIST_REMOVE,
      NotificationType.CUSTOM
    ];
  }

  // 默认配置
  private defaultConfig: NotificationConfig = {
    enableNotifications: true,
    enableSound: true,
    enableVibration: true,
    enableLight: true,
    enabledTypes: this.getNotificationTypeValues(),
    mutedTypes: [],
    enableDoNotDisturb: false,
    doNotDisturbStart: '22:00',
    doNotDisturbEnd: '07:00',
    minPriority: NotificationPriority.LOW,
    enableBadgeCount: true,
    maxStoredNotifications: 500,
    notificationHistoryDays: 30,
    subscribedChannels: [],
    mutedChannels: [],
    enableSystemNotifications: true,
    enableMaintenanceAlerts: true,
    enableFeatureUpdates: true,
    enableSocialNotifications: true,
    enableCommentReplies: true,
    enableMentions: true,
    enableLikes: true,
    enableShares: true,
    enableLiveNotifications: true,
    enableVideoUpdateNotifications: true,
    enableRecommendationNotifications: true,
    enableAccountNotifications: true,
    enablePaymentNotifications: true,
    enableSubscriptionNotifications: true,
    enableDownloadNotifications: true,
    enableErrorNotifications: true
  };
  
  // 缓存的配置
  private cachedConfig: NotificationConfig | null = null;
  
  // 通知列表
  private notifications: Notification[] = [];
  
  // 通知组
  private notificationGroups: Map<string, NotificationGroup> = new Map();
  
  // 当前徽章计数
  private badgeCount: number = 0;
  
  // 通知统计
  private notificationStats: NotificationStats = {
    totalCount: 0,
    newCount: 0,
    readCount: 0,
    dismissedCount: 0,
    archivedCount: 0,
    byType: new Map(),
    byPriority: new Map(),
    bySender: new Map(),
    lastReceivedTime: 0,
    lastReadTime: 0
  };
  
  // 上次同步时间
  private lastSyncTime: number = 0;
  
  // 同步间隔（毫秒）
  private syncInterval: number = 300000; // 5分钟
  
  // 同步定时器
  private syncTimer: number | null = null;
  
  // 是否正在同步
  private isSyncing: boolean = false;
  
  // 过滤器缓存
  private filterCache: Map<string, Notification[]> = new Map();
  
  // 最大过滤器缓存项
  private maxFilterCacheItems: number = 10;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('NotificationRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取NotificationRepository单例实例
   */
  public static getInstance(): NotificationRepository {
    if (!NotificationRepository.instance) {
      NotificationRepository.instance = new NotificationRepository();
    }
    return NotificationRepository.instance;
  }

  /**
   * 初始化通知仓库
   */
  private async initialize(): Promise<void> {
    try {
      // 加载配置
      await this.loadConfig();
      
      // 加载通知
      await this.loadNotifications();
      
      // 加载统计
      await this.loadStats();
      
      // 加载组
      await this.loadGroups();
      
      // 开始定期同步
      if (this.cachedConfig?.enableNotifications) {
        this.startPeriodicSync();
      }
      
      // 清理过期通知
      this.cleanupExpiredNotifications().catch(err => {
        this.logger.warn('Failed to cleanup expired notifications', err);
      });
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      this.logger.info('NotificationRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize NotificationRepository', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听应用状态变化
    this.eventBus.on('app:stateChanged', async (state: { isActive: boolean }) => {
      if (state.isActive) {
        // 应用切换到前台时，同步通知
        this.syncNotifications().catch(err => {
          this.logger.warn('Failed to sync notifications when app becomes active', err);
        });
      }
    });
    
    // 监听用户登录/登出事件
    this.eventBus.on('auth:loggedIn', async () => {
      // 用户登录后，同步通知
      this.syncNotifications().catch(err => {
        this.logger.warn('Failed to sync notifications after login', err);
      });
    });
    
    this.eventBus.on('auth:loggedOut', async () => {
      // 用户登出后，清除通知
      await this.clearAllNotifications();
    });
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const config = await this.storageUtil.getObject<NotificationConfig>(
        this.storageKeys.config,
        LocalStorageType.DEFAULT
      );
      
      this.cachedConfig = config ? {
        ...this.defaultConfig,
        ...config,
        enabledTypes: config.enabledTypes || this.defaultConfig.enabledTypes,
        mutedTypes: config.mutedTypes || this.defaultConfig.mutedTypes,
        subscribedChannels: config.subscribedChannels || this.defaultConfig.subscribedChannels,
        mutedChannels: config.mutedChannels || this.defaultConfig.mutedChannels
      } : { ...this.defaultConfig };
      
      this.logger.debug('Notification configuration loaded');
    } catch (error) {
      this.logger.error('Failed to load notification config', error as Error);
      this.cachedConfig = { ...this.defaultConfig };
    }
  }

  /**
   * 设置配置
   */
  public async setConfig(config: Partial<NotificationConfig>): Promise<NotificationConfig> {
    try {
      // 获取当前配置
      const currentConfig = await this.getConfig();
      
      // 合并新配置
      const updatedConfig: NotificationConfig = {
        ...currentConfig,
        ...config,
        enabledTypes: config.enabledTypes || currentConfig.enabledTypes,
        mutedTypes: config.mutedTypes || currentConfig.mutedTypes,
        subscribedChannels: config.subscribedChannels || currentConfig.subscribedChannels,
        mutedChannels: config.mutedChannels || currentConfig.mutedChannels
      };
      
      // 验证配置
      this.validateConfig(updatedConfig);
      
      // 保存配置
      this.cachedConfig = updatedConfig;
      await this.storageUtil.setObject(
        this.storageKeys.config,
        updatedConfig,
        LocalStorageType.DEFAULT
      );
      
      // 更新同步状态
      if (updatedConfig.enableNotifications !== currentConfig.enableNotifications) {
        if (updatedConfig.enableNotifications) {
          this.startPeriodicSync();
        } else {
          this.stopPeriodicSync();
        }
      }
      
      // 发布配置变更事件
      this.eventBus.emit(NotificationEventType.CONFIG_CHANGED, {
        type: NotificationEventType.CONFIG_CHANGED,
        timestamp: Date.now(),
        config: updatedConfig
      } as NotificationEvent);
      
      // 特殊处理勿扰模式切换
      if (updatedConfig.enableDoNotDisturb !== currentConfig.enableDoNotDisturb) {
        this.eventBus.emit(NotificationEventType.DO_NOT_DISTURB_TOGGLED, {
          type: NotificationEventType.DO_NOT_DISTURB_TOGGLED,
          timestamp: Date.now(),
          config: updatedConfig
        } as NotificationEvent);
      }
      
      this.logger.info('Notification configuration updated');
      
      return updatedConfig;
    } catch (error) {
      this.logger.error('Failed to set notification config', error as Error);
      throw error;
    }
  }

  /**
   * 获取配置
   */
  public async getConfig(): Promise<NotificationConfig> {
    try {
      // 如果缓存为空，加载配置
      if (!this.cachedConfig) {
        await this.loadConfig();
      }
      
      return { ...this.cachedConfig! };
    } catch (error) {
      this.logger.error('Failed to get notification config', error as Error);
      return { ...this.defaultConfig };
    }
  }

  /**
   * 验证配置
   */
  private validateConfig(config: NotificationConfig): void {
    const errors: string[] = [];
    
    // 验证静默通知和需要交互的通知不能同时设置
    if (config.mutedTypes.some(type => config.enabledTypes.includes(type))) {
      errors.push('Muted types cannot be included in enabled types');
    }
    
    // 验证最大存储通知数
    if (config.maxStoredNotifications < 10 || config.maxStoredNotifications > 1000) {
      errors.push('Max stored notifications must be between 10 and 1000');
    }
    
    // 验证历史保留天数
    if (config.notificationHistoryDays < 1 || config.notificationHistoryDays > 365) {
      errors.push('Notification history days must be between 1 and 365');
    }
    
    // 验证时间段格式
    const timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/;
    if (!timeRegex.test(config.doNotDisturbStart)) {
      errors.push('Invalid do not disturb start time format. Use HH:MM');
    }
    if (!timeRegex.test(config.doNotDisturbEnd)) {
      errors.push('Invalid do not disturb end time format. Use HH:MM');
    }
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 加载通知
   */
  private async loadNotifications(): Promise<void> {
    try {
      const notifications = await this.storageUtil.getObject<Notification[]>(
        this.storageKeys.notifications,
        LocalStorageType.DEFAULT
      );
      
      if (notifications) {
        this.notifications = notifications.sort((a, b) => b.metadata.timestamp - a.metadata.timestamp);
      }
      
      this.logger.debug(`Loaded ${this.notifications.length} notifications`);
    } catch (error) {
      this.logger.error('Failed to load notifications', error as Error);
      this.notifications = [];
    }
  }

  /**
   * 保存通知
   */
  private async saveNotifications(): Promise<void> {
    try {
      // 限制通知数量
      if (this.notifications.length > this.cachedConfig!.maxStoredNotifications) {
        this.notifications = this.notifications.slice(0, this.cachedConfig!.maxStoredNotifications);
      }
      
      await this.storageUtil.setObject(
        this.storageKeys.notifications,
        this.notifications,
        LocalStorageType.DEFAULT
      );
      
      // 更新统计
      await this.updateStats();
    } catch (error) {
      this.logger.error('Failed to save notifications', error as Error);
    }
  }

  /**
   * 添加通知
   */
  public async addNotification(
    type: NotificationType,
    content: NotificationContent,
    metadata: Partial<NotificationMetadata> = {},
    priority: NotificationPriority = NotificationPriority.MEDIUM
  ): Promise<Notification> {
    try {
      // 检查是否应该接收此通知
      if (!await this.shouldReceiveNotification(type, priority, metadata)) {
        this.logger.debug(`Notification of type ${type} skipped due to settings`);
        return null!;
      }
      
      const now = Date.now();
      
      // 创建通知对象
      const notification: Notification = {
        id: `notification_${now}_${Math.random().toString(36).substr(2, 9)}`,
        type,
        status: NotificationStatus.NEW,
        priority,
        content,
        metadata: {
          timestamp: now,
          isSilent: false,
          requiresInteraction: true,
          ...metadata
        }
      };
      
      // 添加到通知列表的顶部（最新的在前面）
      this.notifications.unshift(notification);
      
      // 保存通知
      await this.saveNotifications();
      
      // 处理通知组
      await this.processNotificationGroup(notification);
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      // 发布收到通知事件
      this.eventBus.emit(NotificationEventType.RECEIVED, {
        type: NotificationEventType.RECEIVED,
        timestamp: now,
        notification
      } as NotificationEvent);
      
      // 显示通知
      this.displayNotification(notification);
      
      this.logger.info(`Notification added: ${notification.id} (${type})`);
      
      return notification;
    } catch (error) {
      this.logger.error('Failed to add notification', error as Error);
      throw error;
    }
  }

  /**
   * 检查是否应该接收通知
   */
  private async shouldReceiveNotification(
    type: NotificationType,
    priority: NotificationPriority,
    metadata: Partial<NotificationMetadata>
  ): Promise<boolean> {
    // 获取配置
    const config = await this.getConfig();
    
    // 检查是否启用通知
    if (!config.enableNotifications) {
      return false;
    }
    
    // 检查是否在勿扰模式
    if (config.enableDoNotDisturb && this.isInDoNotDisturbTime()) {
      // 紧急通知仍然可以接收
      if (priority !== NotificationPriority.URGENT) {
        return false;
      }
    }
    
    // 检查通知类型是否启用
    if (!config.enabledTypes.includes(type)) {
      return false;
    }
    
    // 检查通知类型是否被静音
    if (config.mutedTypes.includes(type)) {
      return false;
    }
    
    // 检查优先级
    if (this.getPriorityValue(priority) < this.getPriorityValue(config.minPriority)) {
      return false;
    }
    
    // 检查频道是否被静音
    if (metadata.senderId && config.mutedChannels.includes(metadata.senderId)) {
      return false;
    }
    
    // 根据类型检查特定设置
    switch (type) {
      case NotificationType.SYSTEM_ANNOUNCEMENT:
      case NotificationType.FEATURE_UPDATE:
        return config.enableSystemNotifications && 
               (type !== NotificationType.FEATURE_UPDATE || config.enableFeatureUpdates);
      
      case NotificationType.MAINTENANCE_ALERT:
        return config.enableMaintenanceAlerts;
      
      case NotificationType.COMMENT_REPLY:
      case NotificationType.MENTIONED:
      case NotificationType.LIKE:
      case NotificationType.SHARE:
        return config.enableSocialNotifications && 
               (type === NotificationType.COMMENT_REPLY ? config.enableCommentReplies :
                type === NotificationType.MENTIONED ? config.enableMentions :
                type === NotificationType.LIKE ? config.enableLikes :
                type === NotificationType.SHARE ? config.enableShares : true);
      
      case NotificationType.LIVE_START:
      case NotificationType.LIVE_END:
      case NotificationType.FOLLOWED_CHANNEL_LIVE:
        return config.enableLiveNotifications;
      
      case NotificationType.VIDEO_UPDATED:
      case NotificationType.SERIES_NEW_EPISODE:
        return config.enableVideoUpdateNotifications;
      
      case NotificationType.RECOMMENDATION:
        return config.enableRecommendationNotifications;
      
      case NotificationType.ACCOUNT_VERIFICATION:
      case NotificationType.PASSWORD_CHANGE:
      case NotificationType.LOGIN_ACTIVITY:
        return config.enableAccountNotifications;
      
      case NotificationType.PAYMENT_SUCCESS:
      case NotificationType.PAYMENT_FAILED:
        return config.enablePaymentNotifications;
      
      case NotificationType.SUBSCRIPTION_REMINDER:
      case NotificationType.SUBSCRIPTION_EXPIRY:
        return config.enableSubscriptionNotifications;
      
      case NotificationType.DOWNLOAD_COMPLETE:
      case NotificationType.DOWNLOAD_FAILED:
        return config.enableDownloadNotifications;
      
      case NotificationType.PLAYBACK_ERROR:
        return config.enableErrorNotifications;
      
      default:
        return true;
    }
  }

  /**
   * 检查当前时间是否在勿扰模式时间内
   */
  private isInDoNotDisturbTime(): boolean {
    const config = this.cachedConfig!;
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    
    // 解析开始时间
    const [startHour, startMinute] = config.doNotDisturbStart.split(':').map(Number);
    // 解析结束时间
    const [endHour, endMinute] = config.doNotDisturbEnd.split(':').map(Number);
    
    const currentTime = currentHour * 60 + currentMinute;
    const startTime = startHour * 60 + startMinute;
    const endTime = endHour * 60 + endMinute;
    
    // 处理跨天的情况
    if (startTime <= endTime) {
      // 同一天内
      return currentTime >= startTime && currentTime <= endTime;
    } else {
      // 跨天
      return currentTime >= startTime || currentTime <= endTime;
    }
  }

  /**
   * 获取优先级值（用于比较）
   */
  private getPriorityValue(priority: NotificationPriority): number {
    switch (priority) {
      case NotificationPriority.LOW:
        return 1;
      case NotificationPriority.MEDIUM:
        return 2;
      case NotificationPriority.HIGH:
        return 3;
      case NotificationPriority.URGENT:
        return 4;
      default:
        return 2; // 默认中等
    }
  }

  /**
   * 处理通知组
   */
  private async processNotificationGroup(notification: Notification): Promise<void> {
    try {
      // 根据通知类型和发送者创建或更新组
      let groupId: string;
      
      // 对于来自同一发送者的类似通知，使用发送者ID作为组ID
      if (notification.metadata.senderId) {
        groupId = `${notification.type}_${notification.metadata.senderId}`;
      } else {
        // 对于系统通知，使用类型作为组ID
        groupId = `${notification.type}`;
      }
      
      let group = this.notificationGroups.get(groupId);
      
      if (!group) {
        // 创建新组
        group = {
          id: groupId,
          title: notification.content.title,
          summary: notification.content.body,
          notificationIds: [notification.id],
          count: 1,
          newCount: 1,
          timestamp: notification.metadata.timestamp,
          type: notification.type,
          priority: notification.priority,
          senderId: notification.metadata.senderId,
          relatedEntityId: notification.metadata.relatedEntityId
        };
        
        this.notificationGroups.set(groupId, group);
        
        // 发布组创建事件
        this.eventBus.emit(NotificationEventType.GROUP_CREATED, {
          type: NotificationEventType.GROUP_CREATED,
          timestamp: Date.now(),
          group
        } as NotificationEvent);
      } else {
        // 更新现有组
        group.notificationIds.unshift(notification.id);
        group.count++;
        group.newCount++;
        group.timestamp = notification.metadata.timestamp;
        
        // 更新组标题和摘要（使用最新通知的内容）
        if (group.notificationIds.length === 1) {
          group.title = notification.content.title;
          group.summary = notification.content.body;
        } else {
          // 对于有多条通知的组，更新摘要以显示数量
          group.summary = `${group.count} ${notification.type === NotificationType.LIKE ? 'likes' : 
                         notification.type === NotificationType.COMMENT_REPLY ? 'replies' : 'notifications'}`;
        }
        
        // 发布组更新事件
        this.eventBus.emit(NotificationEventType.GROUP_UPDATED, {
          type: NotificationEventType.GROUP_UPDATED,
          timestamp: Date.now(),
          group
        } as NotificationEvent);
      }
      
      // 保存组
      await this.saveGroups();
    } catch (error) {
      this.logger.warn('Failed to process notification group', error as Error);
    }
  }

  /**
   * 显示通知
   */
  private displayNotification(notification: Notification): void {
    try {
      // 在实际应用中，这里应该调用系统API显示通知
      // 例如在Android中使用NotificationManager，在iOS中使用UNUserNotificationCenter
      // 这里简化处理，仅记录日志
      
      const isSilent = notification.metadata.isSilent || 
                      (this.cachedConfig?.enableDoNotDisturb && 
                       this.isInDoNotDisturbTime() && 
                       notification.priority !== NotificationPriority.URGENT);
      
      if (!isSilent) {
        this.logger.info(`Displaying notification: ${notification.id}`);
        
        // 实际应用中，这里应该调用系统通知API
      } else {
        this.logger.debug(`Silent notification received: ${notification.id}`);
      }
    } catch (error) {
      this.logger.error('Failed to display notification', error as Error);
    }
  }

  /**
   * 获取所有通知
   */
  public async getAllNotifications(filter?: NotificationFilter): Promise<Notification[]> {
    try {
      // 生成过滤缓存键
      const cacheKey = filter ? JSON.stringify(filter) : 'all';
      
      // 检查缓存
      if (this.filterCache.has(cacheKey)) {
        return [...this.filterCache.get(cacheKey)!];
      }
      
      // 应用过滤
      let filtered = [...this.notifications];
      
      if (filter) {
        // 按类型过滤
        if (filter.types && filter.types.length > 0) {
          filtered = filtered.filter(n => filter.types!.includes(n.type));
        }
        
        // 按状态过滤
        if (filter.status && filter.status.length > 0) {
          filtered = filtered.filter(n => filter.status!.includes(n.status));
        }
        
        // 按优先级过滤
        if (filter.priorities && filter.priorities.length > 0) {
          filtered = filtered.filter(n => filter.priorities!.includes(n.priority));
        }
        
        // 按时间范围过滤
        if (filter.startDate) {
          filtered = filtered.filter(n => n.metadata.timestamp >= filter.startDate!);
        }
        
        if (filter.endDate) {
          filtered = filtered.filter(n => n.metadata.timestamp <= filter.endDate!);
        }
        
        // 按搜索词过滤
        if (filter.searchTerm) {
          const searchLower = filter.searchTerm.toLowerCase();
          filtered = filtered.filter(n => 
            n.content.title.toLowerCase().includes(searchLower) ||
            n.content.body.toLowerCase().includes(searchLower) ||
            (n.metadata.senderName && n.metadata.senderName.toLowerCase().includes(searchLower))
          );
        }
        
        // 按相关实体ID过滤
        if (filter.relatedEntityId) {
          filtered = filtered.filter(n => n.metadata.relatedEntityId === filter.relatedEntityId);
        }
        
        // 按相关实体类型过滤
        if (filter.relatedEntityType) {
          filtered = filtered.filter(n => n.metadata.relatedEntityType === filter.relatedEntityType);
        }
        
        // 按发送者ID过滤
        if (filter.senderId) {
          filtered = filtered.filter(n => n.metadata.senderId === filter.senderId);
        }
      }
      
      // 应用分页
      if (filter && (filter.limit !== undefined || filter.offset !== undefined)) {
        const offset = filter.offset || 0;
        const limit = filter.limit || filtered.length;
        filtered = filtered.slice(offset, offset + limit);
      }
      
      // 更新过滤器缓存
      this.updateFilterCache(cacheKey, filtered);
      
      return filtered;
    } catch (error) {
      this.logger.error('Failed to get notifications', error as Error);
      return [];
    }
  }

  /**
   * 更新过滤器缓存
   */
  private updateFilterCache(key: string, notifications: Notification[]): void {
    // 限制缓存大小
    if (this.filterCache.size >= this.maxFilterCacheItems && !this.filterCache.has(key)) {
      // 移除最早的缓存项
      const firstKey = this.filterCache.keys().next().value;
      this.filterCache.delete(firstKey);
    }
    
    this.filterCache.set(key, notifications);
  }

  /**
   * 获取未读通知数量
   */
  public async getUnreadCount(): Promise<number> {
    return this.notifications.filter(n => n.status === NotificationStatus.NEW).length;
  }

  /**
   * 获取通知详情
   */
  public async getNotificationById(id: string): Promise<Notification | null> {
    try {
      const notification = this.notifications.find(n => n.id === id);
      
      if (notification) {
        return { ...notification };
      }
      
      return null;
    } catch (error) {
      this.logger.error(`Failed to get notification by id: ${id}`, error as Error);
      return null;
    }
  }

  /**
   * 标记通知为已读
   */
  public async markAsRead(notificationId: string): Promise<boolean> {
    try {
      const notification = this.notifications.find(n => n.id === notificationId);
      
      if (!notification || notification.status === NotificationStatus.READ) {
        return false;
      }
      
      // 更新状态
      const oldStatus = notification.status;
      notification.status = NotificationStatus.READ;
      notification.readAt = Date.now();
      
      // 更新组
      await this.updateNotificationGroup(notificationId, false);
      
      // 保存通知
      await this.saveNotifications();
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      // 发布事件
      this.eventBus.emit(NotificationEventType.READ, {
        type: NotificationEventType.READ,
        timestamp: Date.now(),
        notification
      } as NotificationEvent);
      
      this.eventBus.emit(NotificationEventType.STATUS_CHANGED, {
        type: NotificationEventType.STATUS_CHANGED,
        timestamp: Date.now(),
        notification,
        status: NotificationStatus.READ,
        previousStatus: oldStatus
      } as NotificationEvent);
      
      this.logger.info(`Notification marked as read: ${notificationId}`);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to mark notification as read: ${notificationId}`, error as Error);
      return false;
    }
  }

  /**
   * 标记所有通知为已读
   */
  public async markAllAsRead(): Promise<boolean> {
    try {
      const unreadNotifications = this.notifications.filter(n => n.status === NotificationStatus.NEW);
      
      if (unreadNotifications.length === 0) {
        return false;
      }
      
      const now = Date.now();
      
      // 更新所有未读通知的状态
      unreadNotifications.forEach(notification => {
        notification.status = NotificationStatus.READ;
        notification.readAt = now;
      });
      
      // 更新所有组
      await Promise.all(unreadNotifications.map(n => this.updateNotificationGroup(n.id, false)));
      
      // 保存通知
      await this.saveNotifications();
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      // 发布事件
      this.eventBus.emit(NotificationEventType.BATCH_MARKED_READ, {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: now,
        notifications: unreadNotifications,
        notificationIds: unreadNotifications.map(n => n.id)
      } as NotificationEvent);
      
      this.logger.info(`All ${unreadNotifications.length} notifications marked as read`);
      
      return true;
    } catch (error) {
      this.logger.error('Failed to mark all notifications as read', error as Error);
      return false;
    }
  }

  /**
   * 标记一组通知为已读
   */
  public async markMultipleAsRead(notificationIds: string[]): Promise<boolean> {
    try {
      const notificationsToUpdate = this.notifications.filter(
        n => notificationIds.includes(n.id) && n.status === NotificationStatus.NEW
      );
      
      if (notificationsToUpdate.length === 0) {
        return false;
      }
      
      const now = Date.now();
      
      // 更新状态
      notificationsToUpdate.forEach(notification => {
        notification.status = NotificationStatus.READ;
        notification.readAt = now;
      });
      
      // 更新组
      await Promise.all(notificationsToUpdate.map(n => this.updateNotificationGroup(n.id, false)));
      
      // 保存通知
      await this.saveNotifications();
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      // 发布事件
      this.eventBus.emit(NotificationEventType.BATCH_MARKED_READ, {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: now,
        notifications: notificationsToUpdate,
        notificationIds: notificationsToUpdate.map(n => n.id)
      } as NotificationEvent);
      
      this.logger.info(`${notificationsToUpdate.length} notifications marked as read`);
      
      return true;
    } catch (error) {
      this.logger.error('Failed to mark multiple notifications as read', error as Error);
      return false;
    }
  }

  /**
   * 标记通知为已关闭
   */
  public async dismissNotification(notificationId: string): Promise<boolean> {
    try {
      const notification = this.notifications.find(n => n.id === notificationId);
      
      if (!notification || notification.status === NotificationStatus.DISMISSED) {
        return false;
      }
      
      // 更新状态
      const oldStatus = notification.status;
      notification.status = NotificationStatus.DISMISSED;
      notification.dismissedAt = Date.now();
      
      // 更新组
      await this.updateNotificationGroup(notificationId, false);
      
      // 保存通知
      await this.saveNotifications();
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      // 发布事件
      this.eventBus.emit(NotificationEventType.DISMISSED, {
        type: NotificationEventType.DISMISSED,
        timestamp: Date.now(),
        notification
      } as NotificationEvent);
      
      this.eventBus.emit(NotificationEventType.STATUS_CHANGED, {
        type: NotificationEventType.STATUS_CHANGED,
        timestamp: Date.now(),
        notification,
        status: NotificationStatus.DISMISSED,
        previousStatus: oldStatus
      } as NotificationEvent);
      
      this.logger.info(`Notification dismissed: ${notificationId}`);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to dismiss notification: ${notificationId}`, error as Error);
      return false;
    }
  }

  /**
   * 关闭所有通知
   */
  public async dismissAllNotifications(): Promise<boolean> {
    try {
      const notificationsToDismiss = this.notifications.filter(
        n => n.status !== NotificationStatus.DISMISSED && n.status !== NotificationStatus.ARCHIVED
      );
      
      if (notificationsToDismiss.length === 0) {
        return false;
      }
      
      const now = Date.now();
      
      // 更新状态
      notificationsToDismiss.forEach(notification => {
        notification.status = NotificationStatus.DISMISSED;
        notification.dismissedAt = now;
      });
      
      // 更新所有组
      await Promise.all(notificationsToDismiss.map(n => this.updateNotificationGroup(n.id, false)));
      
      // 保存通知
      await this.saveNotifications();
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      // 发布事件
      this.eventBus.emit(NotificationEventType.BATCH_DISMISSED, {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: now,
        notifications: notificationsToDismiss,
        notificationIds: notificationsToDismiss.map(n => n.id)
      } as NotificationEvent);
      
      this.logger.info(`All ${notificationsToDismiss.length} notifications dismissed`);
      
      return true;
    } catch (error) {
      this.logger.error('Failed to dismiss all notifications', error as Error);
      return false;
    }
  }

  /**
   * 归档通知
   */
  public async archiveNotification(notificationId: string): Promise<boolean> {
    try {
      const notification = this.notifications.find(n => n.id === notificationId);
      
      if (!notification || notification.status === NotificationStatus.ARCHIVED) {
        return false;
      }
      
      // 更新状态
      const oldStatus = notification.status;
      notification.status = NotificationStatus.ARCHIVED;
      notification.archivedAt = Date.now();
      
      // 更新组
      await this.updateNotificationGroup(notificationId, false);
      
      // 保存通知
      await this.saveNotifications();
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      // 发布事件
      this.eventBus.emit(NotificationEventType.ARCHIVED, {
        type: NotificationEventType.ARCHIVED,
        timestamp: Date.now(),
        notification
      } as NotificationEvent);
      
      this.eventBus.emit(NotificationEventType.STATUS_CHANGED, {
        type: NotificationEventType.STATUS_CHANGED,
        timestamp: Date.now(),
        notification,
        status: NotificationStatus.ARCHIVED,
        previousStatus: oldStatus
      } as NotificationEvent);
      
      this.logger.info(`Notification archived: ${notificationId}`);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to archive notification: ${notificationId}`, error as Error);
      return false;
    }
  }

  /**
   * 恢复通知
   */
  public async restoreNotification(notificationId: string): Promise<boolean> {
    try {
      const notification = this.notifications.find(n => n.id === notificationId);
      
      if (!notification || notification.status !== NotificationStatus.ARCHIVED) {
        return false;
      }
      
      // 更新状态
      const oldStatus = notification.status;
      notification.status = NotificationStatus.READ; // 恢复为已读状态
      delete notification.archivedAt;
      
      // 更新组
      await this.updateNotificationGroup(notificationId, true);
      
      // 保存通知
      await this.saveNotifications();
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      // 发布事件
      this.eventBus.emit(NotificationEventType.RESTORED, {
        type: NotificationEventType.RESTORED,
        timestamp: Date.now(),
        notification
      } as NotificationEvent);
      
      this.eventBus.emit(NotificationEventType.STATUS_CHANGED, {
        type: NotificationEventType.STATUS_CHANGED,
        timestamp: Date.now(),
        notification,
        status: NotificationStatus.READ,
        previousStatus: oldStatus
      } as NotificationEvent);
      
      this.logger.info(`Notification restored: ${notificationId}`);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to restore notification: ${notificationId}`, error as Error);
      return false;
    }
  }

  /**
   * 删除通知
   */
  public async deleteNotification(notificationId: string): Promise<boolean> {
    try {
      const initialLength = this.notifications.length;
      
      // 从列表中删除
      this.notifications = this.notifications.filter(n => n.id !== notificationId);
      
      const removed = initialLength !== this.notifications.length;
      
      if (removed) {
        // 更新组
        await this.removeNotificationFromGroups(notificationId);
        
        // 保存通知
        await this.saveNotifications();
        
        // 更新徽章计数
        this.updateBadgeCount();
        
        // 清除过滤器缓存
        this.clearFilterCache();
        
        this.logger.info(`Notification deleted: ${notificationId}`);
      }
      
      return removed;
    } catch (error) {
      this.logger.error(`Failed to delete notification: ${notificationId}`, error as Error);
      return false;
    }
  }

  /**
   * 清除所有通知
   */
  public async clearAllNotifications(): Promise<boolean> {
    try {
      const notificationCount = this.notifications.length;
      
      if (notificationCount === 0) {
        return false;
      }
      
      // 清空通知列表
      this.notifications = [];
      
      // 清空通知组
      this.notificationGroups.clear();
      
      // 保存状态
      await this.storageUtil.setObject(
        this.storageKeys.notifications,
        [],
        LocalStorageType.DEFAULT
      );
      
      await this.storageUtil.setObject(
        this.storageKeys.groups,
        {},
        LocalStorageType.DEFAULT
      );
      
      // 更新徽章计数
      this.updateBadgeCount(0);
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      // 发布事件
      this.eventBus.emit(NotificationEventType.CLEARED_ALL, {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now(),
        count: notificationCount
      } as NotificationEvent);
      
      this.logger.info(`All ${notificationCount} notifications cleared`);
      
      return true;
    } catch (error) {
      this.logger.error('Failed to clear all notifications', error as Error);
      return false;
    }
  }

  /**
   * 更新通知组
   */
  private async updateNotificationGroup(notificationId: string, isNew: boolean): Promise<void> {
    try {
      // 查找包含此通知的组
      for (const [groupId, group] of this.notificationGroups.entries()) {
        if (group.notificationIds.includes(notificationId)) {
          // 更新组的未读计数
          if (isNew) {
            group.newCount++;
          } else {
            // 尝试获取通知以确定是否为新通知
            const notification = this.notifications.find(n => n.id === notificationId);
            if (notification && notification.status === NotificationStatus.NEW) {
              group.newCount = Math.max(0, group.newCount - 1);
            }
          }
          
          // 如果组没有通知了，删除组
          if (group.count === 0) {
            this.notificationGroups.delete(groupId);
          } else {
            // 发布组更新事件
            this.eventBus.emit(NotificationEventType.GROUP_UPDATED, {
              type: NotificationEventType.GROUP_UPDATED,
              timestamp: Date.now(),
              group: { ...group }
            } as NotificationEvent);
          }
          
          break;
        }
      }
      
      // 保存组
      await this.saveGroups();
    } catch (error) {
      this.logger.warn('Failed to update notification group', error as Error);
    }
  }

  /**
   * 从组中移除通知
   */
  private async removeNotificationFromGroups(notificationId: string): Promise<void> {
    try {
      for (const [groupId, group] of this.notificationGroups.entries()) {
        const index = group.notificationIds.indexOf(notificationId);
        
        if (index !== -1) {
          // 从通知ID列表中移除
          group.notificationIds.splice(index, 1);
          group.count--;
          
          // 检查被删除的通知是否为新通知
          const notification = this.notifications.find(n => n.id === notificationId);
          if (notification && notification.status === NotificationStatus.NEW) {
            group.newCount = Math.max(0, group.newCount - 1);
          }
          
          // 如果组没有通知了，删除组
          if (group.count === 0) {
            this.notificationGroups.delete(groupId);
          } else {
            // 更新组的时间戳为最新通知的时间戳
            const latestNotificationId = group.notificationIds[0];
            const latestNotification = this.notifications.find(n => n.id === latestNotificationId);
            if (latestNotification) {
              group.timestamp = latestNotification.metadata.timestamp;
            }
            
            // 发布组更新事件
            this.eventBus.emit(NotificationEventType.GROUP_UPDATED, {
              type: NotificationEventType.GROUP_UPDATED,
              timestamp: Date.now(),
              group: { ...group }
            } as NotificationEvent);
          }
          
          break;
        }
      }
      
      // 保存组
      await this.saveGroups();
    } catch (error) {
      this.logger.warn('Failed to remove notification from groups', error as Error);
    }
  }

  /**
   * 加载组
   */
  private async loadGroups(): Promise<void> {
    try {
      const groupsData = await this.storageUtil.getObject<Record<string, NotificationGroup>>(
        this.storageKeys.groups,
        LocalStorageType.DEFAULT
      );
      
      if (groupsData) {
        this.notificationGroups = new Map(Object.entries(groupsData));
      }
      
      this.logger.debug(`Loaded ${this.notificationGroups.size} notification groups`);
    } catch (error) {
      this.logger.error('Failed to load notification groups', error as Error);
      this.notificationGroups = new Map();
    }
  }

  /**
   * 保存组
   */
  private async saveGroups(): Promise<void> {
    try {
      // 转换Map为对象以便存储
      const groupsObject: Record<string, NotificationGroup> = {};
      this.notificationGroups.forEach((group, id) => {
        groupsObject[id] = group;
      });
      
      await this.storageUtil.setObject(
        this.storageKeys.groups,
        groupsObject,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save notification groups', error as Error);
    }
  }

  /**
   * 获取所有通知组
   */
  public async getAllGroups(): Promise<NotificationGroup[]> {
    try {
      return Array.from(this.notificationGroups.values())
        .sort((a, b) => b.timestamp - a.timestamp);
    } catch (error) {
      this.logger.error('Failed to get notification groups', error as Error);
      return [];
    }
  }

  /**
   * 更新徽章计数
   */
  private async updateBadgeCount(count?: number): Promise<void> {
    try {
      const config = await this.getConfig();
      
      if (!config.enableBadgeCount) {
        return;
      }
      
      // 计算新的徽章计数
      const newBadgeCount = count !== undefined ? count : 
                           this.notifications.filter(n => n.status === NotificationStatus.NEW).length;
      
      // 如果徽章计数发生变化，更新并保存
      if (newBadgeCount !== this.badgeCount) {
        this.badgeCount = newBadgeCount;
        
        // 保存到存储
        await this.storageUtil.setNumber(
          this.storageKeys.badgeCount,
          newBadgeCount,
          LocalStorageType.DEFAULT
        );
        
        // 更新应用图标徽章
        this.updateAppBadge(newBadgeCount);
        
        // 发布徽章计数变化事件
        this.eventBus.emit(NotificationEventType.BADGE_COUNT_CHANGED, {
          type: NotificationEventType.BADGE_COUNT_CHANGED,
          timestamp: Date.now(),
          badgeCount: newBadgeCount
        } as NotificationEvent);
      }
    } catch (error) {
      this.logger.warn('Failed to update badge count', error as Error);
    }
  }

  /**
   * 更新应用图标徽章
   */
  private updateAppBadge(count: number): void {
    try {
      // 在实际应用中，这里应该调用系统API更新应用图标徽章
      // 例如在iOS中使用UIApplication.setBadgeCount，在Android中使用通知徽章API
      // 这里简化处理，仅记录日志
      
      this.logger.debug(`App badge count updated to ${count}`);
    } catch (error) {
      this.logger.error('Failed to update app badge', error as Error);
    }
  }

  /**
   * 获取徽章计数
   */
  public async getBadgeCount(): Promise<number> {
    try {
      const config = await this.getConfig();
      
      if (!config.enableBadgeCount) {
        return 0;
      }
      
      // 重新计算以确保准确性
      const count = this.notifications.filter(n => n.status === NotificationStatus.NEW).length;
      
      if (count !== this.badgeCount) {
        await this.updateBadgeCount(count);
      }
      
      return this.badgeCount;
    } catch (error) {
      this.logger.error('Failed to get badge count', error as Error);
      return 0;
    }
  }

  /**
   * 清除徽章计数
   */
  public async clearBadgeCount(): Promise<void> {
    try {
      await this.updateBadgeCount(0);
      
      this.logger.info('Badge count cleared');
    } catch (error) {
      this.logger.error('Failed to clear badge count', error as Error);
    }
  }

  /**
   * 开始定期同步
   */
  private startPeriodicSync(): void {
    // 停止现有的同步
    this.stopPeriodicSync();
    
    // 设置定期同步
    this.syncTimer = setInterval(() => {
      this.syncNotifications().catch(err => {
        this.logger.warn('Failed to sync notifications in periodic timer', err);
      });
    }, this.syncInterval);
    
    this.logger.debug('Periodic notification sync started');
  }

  /**
   * 停止定期同步
   */
  private stopPeriodicSync(): void {
    if (this.syncTimer !== null) {
      clearInterval(this.syncTimer);
      this.syncTimer = null;
      this.logger.debug('Periodic notification sync stopped');
    }
  }

  /**
   * 同步通知
   */
  public async syncNotifications(): Promise<boolean> {
    try {
      // 防止并发同步
      if (this.isSyncing) {
        return false;
      }
      
      this.isSyncing = true;
      
      // 检查是否启用通知
      const config = await this.getConfig();
      if (!config.enableNotifications) {
        return false;
      }
      
      // 在实际应用中，这里应该：
      // 1. 调用服务器API获取新通知
      // 2. 合并本地通知和服务器通知
      // 3. 处理已删除的通知
      
      // 模拟同步
      // 这里简单地记录日志，实际应用中应该有真实的同步逻辑
      
      this.logger.debug('Notifications synced with server');
      
      // 更新同步时间
      this.lastSyncTime = Date.now();
      await this.storageUtil.setNumber(
        this.storageKeys.lastSyncTime,
        this.lastSyncTime,
        LocalStorageType.DEFAULT
      );
      
      return true;
    } catch (error) {
      this.logger.error('Failed to sync notifications', error as Error);
      return false;
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * 加载统计
   */
  private async loadStats(): Promise<void> {
    try {
      const statsData = await this.storageUtil.getObject<{
        totalCount: number;
        newCount: number;
        readCount: number;
        dismissedCount: number;
        archivedCount: number;
        byType: [NotificationType, number][];
        byPriority: [NotificationPriority, number][];
        bySender: [string, number][];
        lastReceivedTime: number;
        lastReadTime: number;
      }>(
        this.storageKeys.stats,
        LocalStorageType.DEFAULT
      );
      
      if (statsData) {
        this.notificationStats = {
          ...statsData,
          byType: new Map(statsData.byType),
          byPriority: new Map(statsData.byPriority),
          bySender: new Map(statsData.bySender)
        };
      }
    } catch (error) {
      this.logger.warn('Failed to load notification stats', error as Error);
      this.resetStats();
    }
  }

  /**
   * 更新统计
   */
  private async updateStats(): Promise<void> {
    try {
      const stats: NotificationStats = {
        totalCount: this.notifications.length,
        newCount: this.notifications.filter(n => n.status === NotificationStatus.NEW).length,
        readCount: this.notifications.filter(n => n.status === NotificationStatus.READ).length,
        dismissedCount: this.notifications.filter(n => n.status === NotificationStatus.DISMISSED).length,
        archivedCount: this.notifications.filter(n => n.status === NotificationStatus.ARCHIVED).length,
        byType: new Map(),
        byPriority: new Map(),
        bySender: new Map(),
        lastReceivedTime: 0,
        lastReadTime: 0
      };
      
      // 计算按类型、优先级和发送者的统计
      this.notifications.forEach(notification => {
        // 按类型统计
        stats.byType.set(
          notification.type,
          (stats.byType.get(notification.type) || 0) + 1
        );
        
        // 按优先级统计
        stats.byPriority.set(
          notification.priority,
          (stats.byPriority.get(notification.priority) || 0) + 1
        );
        
        // 按发送者统计
        if (notification.metadata.senderId) {
          stats.bySender.set(
            notification.metadata.senderId,
            (stats.bySender.get(notification.metadata.senderId) || 0) + 1
          );
        }
        
        // 更新最后接收时间
        if (notification.metadata.timestamp > stats.lastReceivedTime) {
          stats.lastReceivedTime = notification.metadata.timestamp;
        }
        
        // 更新最后阅读时间
        if (notification.readAt && notification.readAt > stats.lastReadTime) {
          stats.lastReadTime = notification.readAt;
        }
      });
      
      this.notificationStats = stats;
      
      // 保存统计
      await this.saveStats();
      
      // 发布统计更新事件
      this.eventBus.emit(NotificationEventType.STATS_UPDATED, {
        type: NotificationEventType.STATS_UPDATED,
        timestamp: Date.now(),
        stats: { ...stats }
      } as NotificationEvent);
    } catch (error) {
      this.logger.warn('Failed to update notification stats', error as Error);
    }
  }

  /**
   * 保存统计
   */
  private async saveStats(): Promise<void> {
    try {
      // 转换Map为数组以便存储
      const statsToSave = {
        ...this.notificationStats,
        byType: Array.from(this.notificationStats.byType.entries()),
        byPriority: Array.from(this.notificationStats.byPriority.entries()),
        bySender: Array.from(this.notificationStats.bySender.entries())
      };
      
      await this.storageUtil.setObject(
        this.storageKeys.stats,
        statsToSave,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.warn('Failed to save notification stats', error as Error);
    }
  }

  /**
   * 获取统计
   */
  public async getStats(): Promise<NotificationStats> {
    try {
      // 确保统计是最新的
      await this.updateStats();
      
      return {
        ...this.notificationStats,
        byType: new Map(this.notificationStats.byType),
        byPriority: new Map(this.notificationStats.byPriority),
        bySender: new Map(this.notificationStats.bySender)
      };
    } catch (error) {
      this.logger.error('Failed to get notification stats', error as Error);
      return this.getEmptyStats();
    }
  }

  /**
   * 重置统计
   */
  private resetStats(): void {
    this.notificationStats = this.getEmptyStats();
  }

  /**
   * 获取空统计
   */
  private getEmptyStats(): NotificationStats {
    return {
      totalCount: 0,
      newCount: 0,
      readCount: 0,
      dismissedCount: 0,
      archivedCount: 0,
      byType: new Map(),
      byPriority: new Map(),
      bySender: new Map(),
      lastReceivedTime: 0,
      lastReadTime: 0
    };
  }

  /**
   * 清理过期通知
   */
  private async cleanupExpiredNotifications(): Promise<void> {
    try {
      const config = await this.getConfig();
      const expiryDays = config.notificationHistoryDays;
      const cutoffTime = Date.now() - (expiryDays * 24 * 60 * 60 * 1000);
      
      const initialLength = this.notifications.length;
      
      // 过滤掉过期的通知
      this.notifications = this.notifications.filter(notification => {
        // 检查是否有过期时间，或者是否超过历史保留天数
        return !notification.metadata.expiresAt ||
               notification.metadata.expiresAt > Date.now() ||
               notification.metadata.timestamp > cutoffTime;
      });
      
      const removedCount = initialLength - this.notifications.length;
      
      if (removedCount > 0) {
        // 更新组
        await this.rebuildGroups();
        
        // 保存通知
        await this.saveNotifications();
        
        // 清除过滤器缓存
        this.clearFilterCache();
        
        this.logger.info(`Cleaned up ${removedCount} expired notifications`);
      }
    } catch (error) {
      this.logger.error('Failed to cleanup expired notifications', error as Error);
    }
  }

  /**
   * 重建通知组
   */
  private async rebuildGroups(): Promise<void> {
    try {
      // 清空现有组
      this.notificationGroups.clear();
      
      // 按时间倒序处理通知，确保最新的通知在组的顶部
      const sortedNotifications = [...this.notifications].sort((a, b) => b.metadata.timestamp - a.metadata.timestamp);
      
      // 重新构建组
      for (const notification of sortedNotifications) {
        await this.processNotificationGroup(notification);
      }
      
      // 保存组
      await this.saveGroups();
      
      this.logger.debug('Notification groups rebuilt');
    } catch (error) {
      this.logger.error('Failed to rebuild notification groups', error as Error);
    }
  }

  /**
   * 清除过滤器缓存
   */
  private clearFilterCache(): void {
    this.filterCache.clear();
  }

  /**
   * 获取通知设置
   */
  public async getNotificationSettings(): Promise<{
    isEnabled: boolean;
    soundEnabled: boolean;
    vibrationEnabled: boolean;
    doNotDisturbEnabled: boolean;
    badgeCountEnabled: boolean;
    notificationTypes: {
      type: NotificationType;
      enabled: boolean;
      muted: boolean;
      description: string;
    }[];
  }> {
    try {
      const config = await this.getConfig();
      
      // 获取所有通知类型及其设置
      const notificationTypes = this.getNotificationTypeValues()
        .map(type => ({
          type,
          enabled: config.enabledTypes.includes(type),
          muted: config.mutedTypes.includes(type),
          description: this.getNotificationTypeDescription(type)
        }));
      
      return {
        isEnabled: config.enableNotifications,
        soundEnabled: config.enableSound,
        vibrationEnabled: config.enableVibration,
        doNotDisturbEnabled: config.enableDoNotDisturb,
        badgeCountEnabled: config.enableBadgeCount,
        notificationTypes
      };
    } catch (error) {
      this.logger.error('Failed to get notification settings', error as Error);
      throw error;
    }
  }

  /**
   * 获取通知类型描述
   */
  private getNotificationTypeDescription(type: NotificationType): string {
    const descriptions: Record<NotificationType, string> = {
      [NotificationType.LIVE_START]: 'Live stream started',
      [NotificationType.LIVE_END]: 'Live stream ended',
      [NotificationType.VIDEO_UPDATED]: 'Video updated',
      [NotificationType.SERIES_NEW_EPISODE]: 'New episode available',
      [NotificationType.RECOMMENDATION]: 'Content recommendation',
      [NotificationType.FOLLOWED_CHANNEL_LIVE]: 'Followed channel live',
      [NotificationType.COMMENT_REPLY]: 'Comment reply',
      [NotificationType.MENTIONED]: 'Mentioned in comment',
      [NotificationType.LIKE]: 'Content liked',
      [NotificationType.SHARE]: 'Content shared',
      [NotificationType.SYSTEM_ANNOUNCEMENT]: 'System announcement',
      [NotificationType.MAINTENANCE_ALERT]: 'Maintenance alert',
      [NotificationType.FEATURE_UPDATE]: 'Feature update',
      [NotificationType.ACCOUNT_VERIFICATION]: 'Account verification',
      [NotificationType.PASSWORD_CHANGE]: 'Password change',
      [NotificationType.LOGIN_ACTIVITY]: 'Login activity',
      [NotificationType.SUBSCRIPTION_REMINDER]: 'Subscription reminder',
      [NotificationType.SUBSCRIPTION_EXPIRY]: 'Subscription expiry',
      [NotificationType.PAYMENT_SUCCESS]: 'Payment success',
      [NotificationType.PAYMENT_FAILED]: 'Payment failed',
      [NotificationType.DOWNLOAD_COMPLETE]: 'Download complete',
      [NotificationType.DOWNLOAD_FAILED]: 'Download failed',
      [NotificationType.PLAYBACK_ERROR]: 'Playback error',
      [NotificationType.WATCHLIST_ADD]: 'Added to watchlist',
      [NotificationType.WATCHLIST_REMOVE]: 'Removed from watchlist',
      [NotificationType.CUSTOM]: 'Custom notification',
      [NotificationType.UNKNOWN]: 'Unknown notification'
    };
    
    return descriptions[type] || 'Unknown notification';
  }

  /**
   * 设置通知类型的启用状态
   */
  public async setNotificationTypeEnabled(type: NotificationType, enabled: boolean): Promise<void> {
    try {
      const config = await this.getConfig();
      
      // 获取启用和禁用的类型列表
      let enabledTypes = [...config.enabledTypes];
      let mutedTypes = [...config.mutedTypes];
      
      if (enabled) {
        // 启用通知类型
        if (!enabledTypes.includes(type)) {
          enabledTypes.push(type);
        }
        // 从静音列表中移除
        mutedTypes = mutedTypes.filter(t => t !== type);
      } else {
        // 禁用通知类型
        enabledTypes = enabledTypes.filter(t => t !== type);
      }
      
      // 更新配置
      await this.setConfig({
        enabledTypes,
        mutedTypes
      });
      
      this.logger.info(`Notification type ${type} enabled: ${enabled}`);
    } catch (error) {
      this.logger.error(`Failed to set notification type ${type} enabled: ${enabled}`, error as Error);
      throw error;
    }
  }

  /**
   * 设置通知类型的静音状态
   */
  public async setNotificationTypeMuted(type: NotificationType, muted: boolean): Promise<void> {
    try {
      const config = await this.getConfig();
      
      // 获取启用和禁用的类型列表
      let enabledTypes = [...config.enabledTypes];
      let mutedTypes = [...config.mutedTypes];
      
      if (muted) {
        // 静音通知类型
        if (!mutedTypes.includes(type)) {
          mutedTypes.push(type);
        }
        // 确保类型仍在启用列表中（只是静音）
        if (!enabledTypes.includes(type)) {
          enabledTypes.push(type);
        }
      } else {
        // 取消静音
        mutedTypes = mutedTypes.filter(t => t !== type);
      }
      
      // 更新配置
      await this.setConfig({
        enabledTypes,
        mutedTypes
      });
      
      this.logger.info(`Notification type ${type} muted: ${muted}`);
    } catch (error) {
      this.logger.error(`Failed to set notification type ${type} muted: ${muted}`, error as Error);
      throw error;
    }
  }

  /**
   * 设置频道的通知状态
   */
  public async setChannelNotificationEnabled(channelId: string, enabled: boolean): Promise<void> {
    try {
      const config = await this.getConfig();
      
      let subscribedChannels = [...config.subscribedChannels];
      let mutedChannels = [...config.mutedChannels];
      
      if (enabled) {
        // 启用频道通知
        if (!subscribedChannels.includes(channelId)) {
          subscribedChannels.push(channelId);
        }
        // 从静音列表中移除
        mutedChannels = mutedChannels.filter(id => id !== channelId);
      } else {
        // 禁用频道通知
        subscribedChannels = subscribedChannels.filter(id => id !== channelId);
      }
      
      // 更新配置
      await this.setConfig({
        subscribedChannels,
        mutedChannels
      });
      
      this.logger.info(`Channel ${channelId} notifications enabled: ${enabled}`);
    } catch (error) {
      this.logger.error(`Failed to set channel ${channelId} notifications enabled: ${enabled}`, error as Error);
      throw error;
    }
  }

  /**
   * 设置频道的静音状态
   */
  public async setChannelMuted(channelId: string, muted: boolean): Promise<void> {
    try {
      const config = await this.getConfig();
      
      let subscribedChannels = [...config.subscribedChannels];
      let mutedChannels = [...config.mutedChannels];
      
      if (muted) {
        // 静音频道
        if (!mutedChannels.includes(channelId)) {
          mutedChannels.push(channelId);
        }
        // 确保频道仍在订阅列表中（只是静音）
        if (!subscribedChannels.includes(channelId)) {
          subscribedChannels.push(channelId);
        }
      } else {
        // 取消静音
        mutedChannels = mutedChannels.filter(id => id !== channelId);
      }
      
      // 更新配置
      await this.setConfig({
        subscribedChannels,
        mutedChannels
      });
      
      this.logger.info(`Channel ${channelId} muted: ${muted}`);
    } catch (error) {
      this.logger.error(`Failed to set channel ${channelId} muted: ${muted}`, error as Error);
      throw error;
    }
  }

  /**
   * 设置勿扰模式
   */
  public async setDoNotDisturb(enabled: boolean, startTime?: string, endTime?: string): Promise<void> {
    try {
      const config = await this.getConfig();
      
      // 更新配置
      await this.setConfig({
        enableDoNotDisturb: enabled,
        doNotDisturbStart: startTime || config.doNotDisturbStart,
        doNotDisturbEnd: endTime || config.doNotDisturbEnd
      });
      
      this.logger.info(`Do not disturb mode ${enabled ? 'enabled' : 'disabled'} ${startTime ? `from ${startTime} to ${endTime}` : ''}`);
    } catch (error) {
      this.logger.error(`Failed to set do not disturb mode: ${enabled}`, error as Error);
      throw error;
    }
  }

  /**
   * 获取勿扰模式状态
   */
  public async getDoNotDisturbStatus(): Promise<{
    enabled: boolean;
    active: boolean;
    startTime: string;
    endTime: string;
  }> {
    try {
      const config = await this.getConfig();
      
      return {
        enabled: config.enableDoNotDisturb,
        active: config.enableDoNotDisturb && this.isInDoNotDisturbTime(),
        startTime: config.doNotDisturbStart,
        endTime: config.doNotDisturbEnd
      };
    } catch (error) {
      this.logger.error('Failed to get do not disturb status', error as Error);
      throw error;
    }
  }

  /**
   * 生成测试通知
   */
  public async generateTestNotification(type: NotificationType = NotificationType.CUSTOM): Promise<Notification> {
    try {
      // 创建测试通知内容
      const testContent: NotificationContent = {
        title: 'Test Notification',
        body: 'This is a test notification to verify notification functionality',
        imageUrl: 'https://example.com/test-image.jpg',
        deepLink: 'app://test',
        actionText: 'View'
      };
      
      // 创建测试元数据
      const testMetadata: Partial<NotificationMetadata> = {
        senderId: 'system',
        senderName: 'System',
        senderAvatar: 'https://example.com/system-avatar.jpg',
        isSilent: false,
        requiresInteraction: true
      };
      
      // 添加通知
      return await this.addNotification(
        type,
        testContent,
        testMetadata,
        NotificationPriority.HIGH
      );
    } catch (error) {
      this.logger.error('Failed to generate test notification', error as Error);
      throw error;
    }
  }

  /**
   * 导出通知数据
   */
  public async exportNotifications(): Promise<{
    notifications: Notification[];
    config: NotificationConfig;
    stats: NotificationStats;
    exportDate: string;
  }> {
    try {
      return {
        notifications: [...this.notifications],
        config: await this.getConfig(),
        stats: await this.getStats(),
        exportDate: new Date().toISOString()
      };
    } catch (error) {
      this.logger.error('Failed to export notifications', error as Error);
      throw error;
    }
  }

  /**
   * 导入通知数据
   */
  public async importNotifications(data: {
    notifications: Notification[];
    config?: NotificationConfig;
    overwrite?: boolean;
  }): Promise<boolean> {
    try {
      const { notifications, config, overwrite = false } = data;
      
      if (!Array.isArray(notifications)) {
        throw new Error('Invalid notifications data format');
      }
      
      // 验证通知数据格式
      for (const notification of notifications) {
        if (!notification.id || !notification.type || !notification.content || !notification.metadata) {
          throw new Error('Invalid notification format');
        }
      }
      
      // 应用导入策略
      if (overwrite) {
        // 完全覆盖现有通知
        this.notifications = notifications;
      } else {
        // 合并新通知，避免重复
        const existingIds = new Set(this.notifications.map(n => n.id));
        const newNotifications = notifications.filter(n => !existingIds.has(n.id));
        
        this.notifications = [...newNotifications, ...this.notifications];
      }
      
      // 应用配置（如果提供）
      if (config) {
        await this.setConfig(config);
      }
      
      // 保存通知
      await this.saveNotifications();
      
      // 重建组
      await this.rebuildGroups();
      
      // 更新统计
      await this.updateStats();
      
      // 更新徽章计数
      this.updateBadgeCount();
      
      // 清除过滤器缓存
      this.clearFilterCache();
      
      this.logger.info(`Imported ${notifications.length} notifications${overwrite ? ' (overwrite mode)' : ' (merge mode)'}`);
      
      return true;
    } catch (error) {
      this.logger.error('Failed to import notifications', error as Error);
      throw error;
    }
  }

  /**
   * 销毁通知仓库
   */
  public destroy(): void {
    try {
      // 停止定期同步
      this.stopPeriodicSync();
      
      // 清除事件监听器
      // 注意：在实际应用中，应该更精确地移除注册的事件监听器
      
      // 清空缓存
      this.clearFilterCache();
      
      this.logger.info('NotificationRepository destroyed');
    } catch (error) {
      this.logger.error('Error during NotificationRepository destruction', error as Error);
    }
  }
}

// 导出事件类型常量
export { NotificationEventType };

