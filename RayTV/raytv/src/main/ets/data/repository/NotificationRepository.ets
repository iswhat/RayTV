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
  actionData?: Record<string, unknown>;
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
    badgeCount: 'notification:badgeCount'
  };
  
  // 缓存键配置
  private cacheKeys = {
    notifications: 'notification:notifications',
    config: 'notification:config',
    stats: 'notification:stats',
    groups: 'notification:groups'
  };
  
  // 默认配置
  private defaultConfig: NotificationConfig = {
    enableNotifications: true,
    enableSound: true,
    enableVibration: true,
    enableLight: true,
    enabledTypes: Object.values(NotificationType),
    mutedTypes: [],
    enableDoNotDisturb: false,
    doNotDisturbStart: '22:00',
    doNotDisturbEnd: '08:00',
    minPriority: NotificationPriority.LOW,
    enableBadgeCount: true,
    maxStoredNotifications: 1000,
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
  
  // 内部状态
  private notifications: Map<string, Notification> = new Map();
  private groups: Map<string, NotificationGroup> = new Map();
  private config: NotificationConfig = this.defaultConfig;
  private stats: NotificationStats = this.createDefaultStats();
  private badgeCount: number = 0;
  private isInitialized: boolean = false;
  
  /**
   * 私有构造函数
   */
  private constructor() {
    // 初始化事件监听器
    this.setupEventListeners();
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): NotificationRepository {
    if (!NotificationRepository.instance) {
      NotificationRepository.instance = new NotificationRepository();
    }
    return NotificationRepository.instance;
  }
  
  /**
   * 初始化仓库
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    
    try {
      // 加载配置
      await this.loadConfig();
      
      // 加载通知数据
      await this.loadNotifications();
      
      // 加载统计信息
      await this.loadStats();
      
      // 加载分组信息
      await this.loadGroups();
      
      // 加载徽章计数
      await this.loadBadgeCount();
      
      this.isInitialized = true;
      this.logger.info('NotificationRepository initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize NotificationRepository:', error);
      throw error;
    }
  }
  
  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听应用生命周期事件
    this.eventBus.on('app:foreground', () => {
      this.handleAppForeground();
    });
    
    this.eventBus.on('app:background', () => {
      this.handleAppBackground();
    });
    
    // 监听网络状态变化
    this.eventBus.on('network:online', () => {
      this.handleNetworkOnline();
    });
    
    this.eventBus.on('network:offline', () => {
      this.handleNetworkOffline();
    });
    
    // 监听存储变化
    this.eventBus.on('storage:changed', (event) => {
      this.handleStorageChanged(event);
    });
  }
  
  /**
   * 创建默认统计信息
   */
  private createDefaultStats(): NotificationStats {
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
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const config = await this.storageUtil.get<NotificationConfig>(
        this.storageKeys.config,
        LocalStorageType.PERSISTENT
      );
      
      if (config) {
        this.config = { ...this.defaultConfig, ...config };
      } else {
        this.config = this.defaultConfig;
        await this.saveConfig();
      }
      
      // 缓存配置
      await this.cacheService.set(
        this.cacheKeys.config,
        this.config,
        CacheType.PERSISTENT,
        3600 // 1小时
      );
    } catch (error) {
      this.logger.error('Failed to load notification config:', error);
      this.config = this.defaultConfig;
    }
  }
  
  /**
   * 保存配置
   */
  private async saveConfig(): Promise<void> {
    try {
      await this.storageUtil.set(
        this.storageKeys.config,
        this.config,
        LocalStorageType.PERSISTENT
      );
      
      // 更新缓存
      await this.cacheService.set(
        this.cacheKeys.config,
        this.config,
        CacheType.PERSISTENT,
        3600
      );
      
      // 发布配置变更事件
      this.eventBus.emit(NotificationEventType.CONFIG_CHANGED, {
        type: NotificationEventType.CONFIG_CHANGED,
        timestamp: Date.now(),
        config: this.config
      });
    } catch (error) {
      this.logger.error('Failed to save notification config:', error);
    }
  }
  
  /**
   * 加载通知数据
   */
  private async loadNotifications(): Promise<void> {
    try {
      const notifications = await this.storageUtil.get<Notification[]>(
        this.storageKeys.notifications,
        LocalStorageType.PERSISTENT
      );
      
      if (notifications) {
        this.notifications.clear();
        notifications.forEach(notification => {
          this.notifications.set(notification.id, notification);
        });
      }
      
      // 缓存通知数据
      await this.cacheService.set(
        this.cacheKeys.notifications,
        Array.from(this.notifications.values()),
        CacheType.PERSISTENT,
        300 // 5分钟
      );
    } catch (error) {
      this.logger.error('Failed to load notifications:', error);
      this.notifications.clear();
    }
  }
  
  /**
   * 保存通知数据
   */
  private async saveNotifications(): Promise<void> {
    try {
      const notifications = Array.from(this.notifications.values());
      
      await this.storageUtil.set(
        this.storageKeys.notifications,
        notifications,
        LocalStorageType.PERSISTENT
      );
      
      // 更新缓存
      await this.cacheService.set(
        this.cacheKeys.notifications,
        notifications,
        CacheType.PERSISTENT,
        300
      );
    } catch (error) {
      this.logger.error('Failed to save notifications:', error);
    }
  }
  
  /**
   * 加载统计信息
   */
  private async loadStats(): Promise<void> {
    try {
      const stats = await this.storageUtil.get<NotificationStats>(
        this.storageKeys.stats,
        LocalStorageType.PERSISTENT
      );
      
      if (stats) {
        this.stats = stats;
      } else {
        this.stats = this.createDefaultStats();
        await this.saveStats();
      }
      
      // 缓存统计信息
      await this.cacheService.set(
        this.cacheKeys.stats,
        this.stats,
        CacheType.PERSISTENT,
        600 // 10分钟
      );
    } catch (error) {
      this.logger.error('Failed to load notification stats:', error);
      this.stats = this.createDefaultStats();
    }
  }
  
  /**
   * 保存统计信息
   */
  private async saveStats(): Promise<void> {
    try {
      await this.storageUtil.set(
        this.storageKeys.stats,
        this.stats,
        LocalStorageType.PERSISTENT
      );
      
      // 更新缓存
      await this.cacheService.set(
        this.cacheKeys.stats,
        this.stats,
        CacheType.PERSISTENT,
        600
      );
      
      // 发布统计更新事件
      this.eventBus.emit(NotificationEventType.STATS_UPDATED, {
        type: NotificationEventType.STATS_UPDATED,
        timestamp: Date.now(),
        stats: this.stats
      });
    } catch (error) {
      this.logger.error('Failed to save notification stats:', error);
    }
  }
  
  /**
   * 加载分组信息
   */
  private async loadGroups(): Promise<void> {
    try {
      const groups = await this.storageUtil.get<NotificationGroup[]>(
        this.storageKeys.groups,
        LocalStorageType.PERSISTENT
      );
      
      if (groups) {
        this.groups.clear();
        groups.forEach(group => {
          this.groups.set(group.id, group);
        });
      }
      
      // 缓存分组信息
      await this.cacheService.set(
        this.cacheKeys.groups,
        Array.from(this.groups.values()),
        CacheType.PERSISTENT,
        300
      );
    } catch (error) {
      this.logger.error('Failed to load notification groups:', error);
      this.groups.clear();
    }
  }
  
  /**
   * 保存分组信息
   */
  private async saveGroups(): Promise<void> {
    try {
      const groups = Array.from(this.groups.values());
      
      await this.storageUtil.set(
        this.storageKeys.groups,
        groups,
        LocalStorageType.PERSISTENT
      );
      
      // 更新缓存
      await this.cacheService.set(
        this.cacheKeys.groups,
        groups,
        CacheType.PERSISTENT,
        300
      );
    } catch (error) {
      this.logger.error('Failed to save notification groups:', error);
    }
  }
  
  /**
   * 加载徽章计数
   */
  private async loadBadgeCount(): Promise<void> {
    try {
      const badgeCount = await this.storageUtil.get<number>(
        this.storageKeys.badgeCount,
        LocalStorageType.PERSISTENT
      );
      
      if (badgeCount !== undefined) {
        this.badgeCount = badgeCount;
      }
    } catch (error) {
      this.logger.error('Failed to load badge count:', error);
      this.badgeCount = 0;
    }
  }
  
  /**
   * 保存徽章计数
   */
  private async saveBadgeCount(): Promise<void> {
    try {
      await this.storageUtil.set(
        this.storageKeys.badgeCount,
        this.badgeCount,
        LocalStorageType.PERSISTENT
      );
      
      // 发布徽章计数变更事件
      this.eventBus.emit(NotificationEventType.BADGE_COUNT_CHANGED, {
        type: NotificationEventType.BADGE_COUNT_CHANGED,
        timestamp: Date.now(),
        badgeCount: this.badgeCount
      });
    } catch (error) {
      this.logger.error('Failed to save badge count:', error);
    }
  }
  
  /**
   * 处理应用进入前台
   */
  private handleAppForeground(): void {
    this.logger.debug('NotificationRepository: App entered foreground');
    // 可以在这里执行一些前台操作，如刷新通知等
  }
  
  /**
   * 处理应用进入后台
   */
  private handleAppBackground(): void {
    this.logger.debug('NotificationRepository: App entered background');
    // 可以在这里执行一些后台操作，如保存数据等
    this.saveAllData();
  }
  
  /**
   * 处理网络在线
   */
  private handleNetworkOnline(): void {
    this.logger.debug('NotificationRepository: Network online');
    // 可以在这里执行一些网络恢复后的操作
  }
  
  /**
   * 处理网络离线
   */
  private handleNetworkOffline(): void {
    this.logger.debug('NotificationRepository: Network offline');
    // 可以在这里执行一些网络断开后的操作
  }
  
  /**
   * 处理存储变化
   */
  private handleStorageChanged(event: any): void {
    this.logger.debug('NotificationRepository: Storage changed', event);
    // 可以在这里处理存储变化事件
  }
  
  /**
   * 保存所有数据
   */
  private async saveAllData(): Promise<void> {
    try {
      await Promise.all([
        this.saveNotifications(),
        this.saveConfig(),
        this.saveStats(),
        this.saveGroups(),
        this.saveBadgeCount()
      ]);
      this.logger.debug('NotificationRepository: All data saved successfully');
    } catch (error) {
      this.logger.error('Failed to save all notification data:', error);
    }
  }
  
  /**
   * 获取通知配置
   */
  public getConfig(): NotificationConfig {
    return { ...this.config };
  }
  
  /**
   * 更新通知配置
   */
  public async updateConfig(updates: Partial<NotificationConfig>): Promise<void> {
    this.config = { ...this.config, ...updates };
    await this.saveConfig();
  }
  
  /**
   * 重置通知配置为默认值
   */
  public async resetConfig(): Promise<void> {
    this.config = this.defaultConfig;
    await this.saveConfig();
  }
  
  /**
   * 检查通知类型是否启用
   */
  public isTypeEnabled(type: NotificationType): boolean {
    return this.config.enabledTypes.includes(type) && 
           !this.config.mutedTypes.includes(type);
  }
  
  /**
   * 检查是否在免打扰时间段
   */
  public isInDoNotDisturb(): boolean {
    if (!this.config.enableDoNotDisturb) {
      return false;
    }
    
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    
    const [startHour, startMinute] = this.config.doNotDisturbStart.split(':').map(Number);
    const [endHour, endMinute] = this.config.doNotDisturbEnd.split(':').map(Number);
    
    const startTime = startHour * 60 + startMinute;
    const endTime = endHour * 60 + endMinute;
    
    if (startTime < endTime) {
      return currentTime >= startTime && currentTime < endTime;
    } else {
      return currentTime >= startTime || currentTime < endTime;
    }
  }
  
  /**
   * 检查是否可以发送通知
   */
  public canSendNotification(notification: Notification): boolean {
    if (!this.config.enableNotifications) {
      return false;
    }
    
    if (!this.isTypeEnabled(notification.type)) {
      return false;
    }
    
    if (this.isInDoNotDisturb() && notification.priority !== NotificationPriority.URGENT) {
      return false;
    }
    
    if (this.getPriorityLevel(notification.priority) < this.getPriorityLevel(this.config.minPriority)) {
      return false;
    }
    
    return true;
  }
  
  /**
   * 获取优先级级别
   */
  private getPriorityLevel(priority: NotificationPriority): number {
    switch (priority) {
      case NotificationPriority.URGENT: return 4;
      case NotificationPriority.HIGH: return 3;
      case NotificationPriority.MEDIUM: return 2;
      case NotificationPriority.LOW: return 1;
      default: return 0;
    }
  }
  
  /**
   * 添加通知
   */
  public async addNotification(notification: Notification): Promise<boolean> {
    if (!this.canSendNotification(notification)) {
      this.logger.debug('Notification blocked by settings:', notification.id);
      return false;
    }
    
    try {
      // 检查通知是否已存在
      if (this.notifications.has(notification.id)) {
        this.logger.debug('Notification already exists:', notification.id);
        return false;
      }
      
      // 添加通知
      this.notifications.set(notification.id, notification);
      
      // 更新统计信息
      this.updateStatsForNewNotification(notification);
      
      // 更新徽章计数
      if (notification.status === NotificationStatus.NEW) {
        this.badgeCount++;
        await this.saveBadgeCount();
      }
      
      // 更新分组
      await this.updateGroupsForNotification(notification);
      
      // 保存数据
      await this.saveNotifications();
      await this.saveStats();
      
      // 发布通知接收事件
      this.eventBus.emit(NotificationEventType.RECEIVED, {
        type: NotificationEventType.RECEIVED,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification added successfully:', notification.id);
      return true;
    } catch (error) {
      this.logger.error('Failed to add notification:', error);
      return false;
    }
  }
  
  /**
   * 批量添加通知
   */
  public async addNotifications(notifications: Notification[]): Promise<number> {
    let successCount = 0;
    
    for (const notification of notifications) {
      if (await this.addNotification(notification)) {
        successCount++;
      }
    }
    
    this.logger.debug(`Added ${successCount} out of ${notifications.length} notifications`);
    return successCount;
  }
  
  /**
   * 获取通知
   */
  public getNotification(id: string): Notification | undefined {
    return this.notifications.get(id);
  }
  
  /**
   * 获取所有通知
   */
  public getAllNotifications(): Notification[] {
    return Array.from(this.notifications.values());
  }
  
  /**
   * 获取过滤后的通知
   */
  public getFilteredNotifications(filter: NotificationFilter): Notification[] {
    let notifications = this.getAllNotifications();
    
    // 按类型过滤
    if (filter.types && filter.types.length > 0) {
      notifications = notifications.filter(n => filter.types!.includes(n.type));
    }
    
    // 按状态过滤
    if (filter.status && filter.status.length > 0) {
      notifications = notifications.filter(n => filter.status!.includes(n.status));
    }
    
    // 按优先级过滤
    if (filter.priorities && filter.priorities.length > 0) {
      notifications = notifications.filter(n => filter.priorities!.includes(n.priority));
    }
    
    // 按时间范围过滤
    if (filter.startDate) {
      notifications = notifications.filter(n => n.metadata.timestamp >= filter.startDate!);
    }
    
    if (filter.endDate) {
      notifications = notifications.filter(n => n.metadata.timestamp <= filter.endDate!);
    }
    
    // 按搜索词过滤
    if (filter.searchTerm) {
      const searchTerm = filter.searchTerm.toLowerCase();
      notifications = notifications.filter(n => 
        n.content.title.toLowerCase().includes(searchTerm) ||
        n.content.body.toLowerCase().includes(searchTerm)
      );
    }
    
    // 按相关实体过滤
    if (filter.relatedEntityId) {
      notifications = notifications.filter(n => n.metadata.relatedEntityId === filter.relatedEntityId);
    }
    
    if (filter.relatedEntityType) {
      notifications = notifications.filter(n => n.metadata.relatedEntityType === filter.relatedEntityType);
    }
    
    // 按发送者过滤
    if (filter.senderId) {
      notifications = notifications.filter(n => n.metadata.senderId === filter.senderId);
    }
    
    // 排序（按时间倒序）
    notifications.sort((a, b) => b.metadata.timestamp - a.metadata.timestamp);
    
    // 分页
    if (filter.limit) {
      const offset = filter.offset || 0;
      notifications = notifications.slice(offset, offset + filter.limit);
    }
    
    return notifications;
  }
  
  /**
   * 标记通知为已读
   */
  public async markAsRead(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      if (notification.status === NotificationStatus.READ) {
        return true; // 已经是已读状态
      }
      
      // 更新状态
      notification.status = NotificationStatus.READ;
      notification.readAt = Date.now();
      
      // 更新统计信息
      this.updateStatsForStatusChange(notification, NotificationStatus.READ);
      
      // 更新徽章计数
      if (this.badgeCount > 0) {
        this.badgeCount--;
        await this.saveBadgeCount();
      }
      
      // 保存数据
      await this.saveNotifications();
      await this.saveStats();
      
      // 发布通知已读事件
      this.eventBus.emit(NotificationEventType.READ, {
        type: NotificationEventType.READ,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification marked as read:', id);
      return true;
    } catch (error) {
      this.logger.error('Failed to mark notification as read:', error);
      return false;
    }
  }
  
  /**
   * 批量标记为已读
   */
  public async markAsReadBatch(ids: string[]): Promise<number> {
    let successCount = 0;
    
    for (const id of ids) {
      if (await this.markAsRead(id)) {
        successCount++;
      }
    }
    
    if (successCount > 0) {
      // 发布批量标记已读事件
      this.eventBus.emit(NotificationEventType.BATCH_MARKED_READ, {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now(),
        notificationIds: ids,
        count: successCount
      });
    }
    
    this.logger.debug(`Marked ${successCount} out of ${ids.length} notifications as read`);
    return successCount;
  }
  
  /**
   * 标记通知为已关闭
   */
  public async dismissNotification(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      if (notification.status === NotificationStatus.DISMISSED) {
        return true; // 已经是已关闭状态
      }
      
      // 更新状态
      notification.status = NotificationStatus.DISMISSED;
      notification.dismissedAt = Date.now();
      
      // 更新统计信息
      this.updateStatsForStatusChange(notification, NotificationStatus.DISMISSED);
      
      // 更新徽章计数
      if (notification.status === NotificationStatus.NEW && this.badgeCount > 0) {
        this.badgeCount--;
        await this.saveBadgeCount();
      }
      
      // 保存数据
      await this.saveNotifications();
      await this.saveStats();
      
      // 发布通知关闭事件
      this.eventBus.emit(NotificationEventType.DISMISSED, {
        type: NotificationEventType.DISMISSED,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification dismissed:', id);
      return true;
    } catch (error) {
      this.logger.error('Failed to dismiss notification:', error);
      return false;
    }
  }
  
  /**
   * 批量标记为已关闭
   */
  public async dismissNotificationsBatch(ids: string[]): Promise<number> {
    let successCount = 0;
    
    for (const id of ids) {
      if (await this.dismissNotification(id)) {
        successCount++;
      }
    }
    
    if (successCount > 0) {
      // 发布批量关闭事件
      this.eventBus.emit(NotificationEventType.BATCH_DISMISSED, {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now(),
        notificationIds: ids,
        count: successCount
      });
    }
    
    this.logger.debug(`Dismissed ${successCount} out of ${ids.length} notifications`);
    return successCount;
  }
  
  /**
   * 归档通知
   */
  public async archiveNotification(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      if (notification.status === NotificationStatus.ARCHIVED) {
        return true; // 已经是归档状态
      }
      
      // 更新状态
      notification.status = NotificationStatus.ARCHIVED;
      notification.archivedAt = Date.now();
      
      // 更新统计信息
      this.updateStatsForStatusChange(notification, NotificationStatus.ARCHIVED);
      
      // 更新徽章计数
      if (notification.status === NotificationStatus.NEW && this.badgeCount > 0) {
        this.badgeCount--;
        await this.saveBadgeCount();
      }
      
      // 保存数据
      await this.saveNotifications();
      await this.saveStats();
      
      // 发布通知归档事件
      this.eventBus.emit(NotificationEventType.ARCHIVED, {
        type: NotificationEventType.ARCHIVED,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification archived:', id);
      return true;
    } catch (error) {
      this.logger.error('Failed to archive notification:', error);
      return false;
    }
  }
  
  /**
   * 批量归档通知
   */
  public async archiveNotificationsBatch(ids: string[]): Promise<number> {
    let successCount = 0;
    
    for (const id of ids) {
      if (await this.archiveNotification(id)) {
        successCount++;
      }
    }
    
    if (successCount > 0) {
      // 发布批量归档事件
      this.eventBus.emit(NotificationEventType.BATCH_ARCHIVED, {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now(),
        notificationIds: ids,
        count: successCount
      });
    }
    
    this.logger.debug(`Archived ${successCount} out of ${ids.length} notifications`);
    return successCount;
  }
  
  /**
   * 恢复通知
   */
  public async restoreNotification(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      if (notification.status === NotificationStatus.NEW) {
        return true; // 已经是新状态
      }
      
      // 恢复状态
      const oldStatus = notification.status;
      notification.status = NotificationStatus.NEW;
      notification.readAt = undefined;
      notification.dismissedAt = undefined;
      notification.archivedAt = undefined;
      
      // 更新统计信息
      this.updateStatsForStatusChange(notification, oldStatus, NotificationStatus.NEW);
      
      // 更新徽章计数
      this.badgeCount++;
      await this.saveBadgeCount();
      
      // 保存数据
      await this.saveNotifications();
      await this.saveStats();
      
      // 发布通知恢复事件
      this.eventBus.emit(NotificationEventType.RESTORED, {
        type: NotificationEventType.RESTORED,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification restored:', id);
      return true;
    } catch (error) {
      this.logger.error('Failed to restore notification:', error);
      return false;
    }
  }
  
  /**
   * 删除通知
   */
  public async deleteNotification(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      // 更新统计信息
      this.updateStatsForDelete(notification);
      
      // 更新徽章计数
      if (notification.status === NotificationStatus.NEW && this.badgeCount > 0) {
        this.badgeCount--;
        await this.saveBadgeCount();
      }
      
      // 删除通知
      this.notifications.delete(id);
      
      // 从分组中移除
      await this.removeNotificationFromGroups(id);
      
      // 保存数据
      await this.saveNotifications();
      await this.saveStats();
      
      this.logger.debug('Notification deleted:', id);
      return true;
    } catch (error) {
      this.logger.error('Failed to delete notification:', error);
      return false;
    }
  }
  
  /**
   * 批量删除通知
   */
  public async deleteNotificationsBatch(ids: string[]): Promise<number> {
    let successCount = 0;
    
    for (const id of ids) {
      if (await this.deleteNotification(id)) {
        successCount++;
      }
    }
    
    this.logger.debug(`Deleted ${successCount} out of ${ids.length} notifications`);
    return successCount;
  }
  
  /**
   * 清空所有通知
   */
  public async clearAllNotifications(): Promise<boolean> {
    try {
      const notificationCount = this.notifications.size;
      
      // 清空所有通知
      this.notifications.clear();
      
      // 清空分组
      this.groups.clear();
      
      // 重置统计信息
      this.stats = this.createDefaultStats();
      
      // 重置徽章计数
      this.badgeCount = 0;
      
      // 保存数据
      await this.saveNotifications();
      await this.saveGroups();
      await this.saveStats();
      await this.saveBadgeCount();
      
      // 发布清空事件
      this.eventBus.emit(NotificationEventType.CLEARED_ALL, {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now(),
        count: notificationCount
      });
      
      this.logger.debug('All notifications cleared');
      return true;
    } catch (error) {
      this.logger.error('Failed to clear all notifications:', error);
      return false;
    }
  }
  
  /**
   * 更新新通知的统计信息
   */
  private updateStatsForNewNotification(notification: Notification): void {
    this.stats.totalCount++;
    this.stats.newCount++;
    this.stats.lastReceivedTime = Math.max(this.stats.lastReceivedTime, notification.metadata.timestamp);
    
    // 按类型统计
    const typeCount = this.stats.byType.get(notification.type) || 0;
    this.stats.byType.set(notification.type, typeCount + 1);
    
    // 按优先级统计
    const priorityCount = this.stats.byPriority.get(notification.priority) || 0;
    this.stats.byPriority.set(notification.priority, priorityCount + 1);
    
    // 按发送者统计
    if (notification.metadata.senderId) {
      const senderCount = this.stats.bySender.get(notification.metadata.senderId) || 0;
      this.stats.bySender.set(notification.metadata.senderId, senderCount + 1);
    }
  }
  
  /**
   * 更新状态变更的统计信息
   */
  private updateStatsForStatusChange(notification: Notification, newStatus: NotificationStatus): void;
  private updateStatsForStatusChange(notification: Notification, oldStatus: NotificationStatus, newStatus: NotificationStatus): void;
  private updateStatsForStatusChange(notification: Notification, oldStatusOrNewStatus: NotificationStatus, newStatus?: NotificationStatus): void {
    const oldStatus = newStatus ? oldStatusOrNewStatus : notification.status;
    const actualNewStatus = newStatus || oldStatusOrNewStatus;
    
    // 减少旧状态的计数
    switch (oldStatus) {
      case NotificationStatus.NEW:
        this.stats.newCount--;
        break;
      case NotificationStatus.READ:
        this.stats.readCount--;
        break;
      case NotificationStatus.DISMISSED:
        this.stats.dismissedCount--;
        break;
      case NotificationStatus.ARCHIVED:
        this.stats.archivedCount--;
        break;
    }
    
    // 增加新状态的计数
    switch (actualNewStatus) {
      case NotificationStatus.NEW:
        this.stats.newCount++;
        break;
      case NotificationStatus.READ:
        this.stats.readCount++;
        this.stats.lastReadTime = Date.now();
        break;
      case NotificationStatus.DISMISSED:
        this.stats.dismissedCount++;
        break;
      case NotificationStatus.ARCHIVED:
        this.stats.archivedCount++;
        break;
    }
  }
  
  /**
   * 更新删除通知的统计信息
   */
  private updateStatsForDelete(notification: Notification): void {
    this.stats.totalCount--;
    
    // 减少状态的计数
    switch (notification.status) {
      case NotificationStatus.NEW:
        this.stats.newCount--;
        break;
      case NotificationStatus.READ:
        this.stats.readCount--;
        break;
      case NotificationStatus.DISMISSED:
        this.stats.dismissedCount--;
        break;
      case NotificationStatus.ARCHIVED:
        this.stats.archivedCount--;
        break;
    }
    
    // 减少类型统计
    const typeCount = this.stats.byType.get(notification.type) || 0;
    if (typeCount > 1) {
      this.stats.byType.set(notification.type, typeCount - 1);
    } else {
      this.stats.byType.delete(notification.type);
    }
    
    // 减少优先级统计
    const priorityCount = this.stats.byPriority.get(notification.priority) || 0;
    if (priorityCount > 1) {
      this.stats.byPriority.set(notification.priority, priorityCount - 1);
    } else {
      this.stats.byPriority.delete(notification.priority);
    }
    
    // 减少发送者统计
    if (notification.metadata.senderId) {
      const senderCount = this.stats.bySender.get(notification.metadata.senderId) || 0;
      if (senderCount > 1) {
        this.stats.bySender.set(notification.metadata.senderId, senderCount - 1);
      } else {
        this.stats.bySender.delete(notification.metadata.senderId);
      }
    }
  }
  
  /**
   * 更新通知的分组
   */
  private async updateGroupsForNotification(notification: Notification): Promise<void> {
    // 根据通知类型和发送者创建或更新分组
    const groupId = this.generateGroupId(notification);
    
    let group = this.groups.get(groupId);
    if (!group) {
      group = {
        id: groupId,
        title: this.getGroupTitle(notification),
        summary: this.getGroupSummary(notification),
        notificationIds: [],
        count: 0,
        newCount: 0,
        timestamp: notification.metadata.timestamp,
        type: notification.type,
        priority: notification.priority,
        senderId: notification.metadata.senderId,
        relatedEntityId: notification.metadata.relatedEntityId
      };
      this.groups.set(groupId, group);
    }
    
    // 更新分组信息
    group.notificationIds.push(notification.id);
    group.count++;
    if (notification.status === NotificationStatus.NEW) {
      group.newCount++;
    }
    group.timestamp = Math.max(group.timestamp, notification.metadata.timestamp);
    
    // 保存分组信息
    await this.saveGroups();
    
    // 发布分组更新事件
    this.eventBus.emit(NotificationEventType.GROUP_UPDATED, {
      type: NotificationEventType.GROUP_UPDATED,
      timestamp: Date.now(),
      group: group
    });
  }
  
  /**
   * 从分组中移除通知
   */
  private async removeNotificationFromGroups(notificationId: string): Promise<void> {
    for (const [groupId, group] of this.groups.entries()) {
      const index = group.notificationIds.indexOf(notificationId);
      if (index !== -1) {
        group.notificationIds.splice(index, 1);
        group.count--;
        
        // 如果分组为空，删除分组
        if (group.count === 0) {
          this.groups.delete(groupId);
        } else {
          // 更新新通知计数
          const notification = this.notifications.get(notificationId);
          if (notification && notification.status === NotificationStatus.NEW) {
            group.newCount = Math.max(0, group.newCount - 1);
          }
          
          // 保存分组信息
          await this.saveGroups();
          
          // 发布分组更新事件
          this.eventBus.emit(NotificationEventType.GROUP_UPDATED, {
            type: NotificationEventType.GROUP_UPDATED,
            timestamp: Date.now(),
            group: group
          });
        }
        break;
      }
    }
  }
  
  /**
   * 生成分组ID
   */
  private generateGroupId(notification: Notification): string {
    return `${notification.type}:${notification.metadata.senderId || 'system'}:${notification.metadata.relatedEntityId || 'general'}`;
  }
  
  /**
   * 获取分组标题
   */
  private getGroupTitle(notification: Notification): string {
    switch (notification.type) {
      case NotificationType.LIVE_START:
        return '直播开始通知';
      case NotificationType.COMMENT_REPLY:
        return '评论回复';
      case NotificationType.MENTIONED:
        return '提及通知';
      case NotificationType.LIKE:
        return '点赞通知';
      case NotificationType.SYSTEM_ANNOUNCEMENT:
        return '系统公告';
      default:
        return '其他通知';
    }
  }
  
  /**
   * 获取分组摘要
   */
  private getGroupSummary(notification: Notification): string {
    return `有${notification.metadata.senderName ? notification.metadata.senderName + '的' : ''}新通知`;
  }
  
  /**
   * 获取通知统计信息
   */
  public getStats(): NotificationStats {
    return { ...this.stats };
  }
  
  /**
   * 获取徽章计数
   */
  public getBadgeCount(): number {
    return this.badgeCount;
  }
  
  /**
   * 获取所有分组
   */
  public getAllGroups(): NotificationGroup[] {
    return Array.from(this.groups.values());
  }
  
  /**
   * 获取分组
   */
  public getGroup(id: string): NotificationGroup | undefined {
    return this.groups.get(id);
  }
  
  /**
   * 获取分组中的通知
   */
  public getNotificationsInGroup(groupId: string): Notification[] {
    const group = this.groups.get(groupId);
    if (!group) {
      return [];
    }
    
    return group.notificationIds
      .map(id => this.notifications.get(id))
      .filter((notification): notification is Notification => notification !== undefined);
  }
  
  /**
   * 清理过期通知
   */
  public async cleanupExpiredNotifications(): Promise<number> {
    try {
      const now = Date.now();
      const expiredNotifications: string[] = [];
      
      for (const [id, notification] of this.notifications.entries()) {
        if (notification.metadata.expiresAt && notification.metadata.expiresAt < now) {
          expiredNotifications.push(id);
        }
      }
      
      const deletedCount = await this.deleteNotificationsBatch(expiredNotifications);
      this.logger.debug(`Cleaned up ${deletedCount} expired notifications`);
      return deletedCount;
    } catch (error) {
      this.logger.error('Failed to cleanup expired notifications:', error);
      return 0;
    }
  }
  
  /**
   * 清理旧通知
   */
  public async cleanupOldNotifications(): Promise<number> {
    try {
      const cutoffTime = Date.now() - (this.config.notificationHistoryDays * 24 * 60 * 60 * 1000);
      const oldNotifications: string[] = [];
      
      for (const [id, notification] of this.notifications.entries()) {
        if (notification.metadata.timestamp < cutoffTime) {
          oldNotifications.push(id);
        }
      }
      
      const deletedCount = await this.deleteNotificationsBatch(oldNotifications);
      this.logger.debug(`Cleaned up ${deletedCount} old notifications`);
      return deletedCount;
    } catch (error) {
      this.logger.error('Failed to cleanup old notifications:', error);
      return 0;
    }
  }
  
  /**
   * 检查通知是否存在
   */
  public hasNotification(id: string): boolean {
    return this.notifications.has(id);
  }
  
  /**
   * 获取通知数量
   */
  public getNotificationCount(): number {
    return this.notifications.size;
  }
  
  /**
   * 获取新通知数量
   */
  public getNewNotificationCount(): number {
    return this.stats.newCount;
  }
  
  /**
   * 获取未读通知数量
   */
  public getUnreadNotificationCount(): number {
    return this.stats.newCount + this.stats.readCount; // 新通知和已读通知都算未读
  }
  
  /**
   * 应用通知过滤器
   */
  public applyFilter(filter: NotificationFilter): Notification[] {
    const filteredNotifications = this.getFilteredNotifications(filter);
    
    // 发布过滤应用事件
    this.eventBus.emit(NotificationEventType.FILTER_APPLIED, {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now(),
      filter: filter,
      notifications: filteredNotifications
    });
    
    return filteredNotifications;
  }
  
  /**
   * 关闭仓库
   */
  public async shutdown(): Promise<void> {
    try {
      // 保存所有数据
      await this.saveAllData();
      
      // 清理缓存
      await this.cacheService.delete(this.cacheKeys.notifications);
      await this.cacheService.delete(this.cacheKeys.config);
      await this.cacheService.delete(this.cacheKeys.stats);
      await this.cacheService.delete(this.cacheKeys.groups);
      
      this.isInitialized = false;
      this.logger.info('NotificationRepository shutdown successfully');
    } catch (error) {
      this.logger.error('Failed to shutdown NotificationRepository:', error);
    }
  }
}