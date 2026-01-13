// NotificationRepository - 閫氱煡浠撳簱绫?// 璐熻矗绠＄悊搴旂敤鍐呴€氱煡銆佺郴缁熼€氱煡鍜岀敤鎴峰亸濂借缃?
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType } from '../model/CacheModel';

/**
 * 閫氱煡绫诲瀷鏋氫妇
 */
export enum NotificationType {
  // 鍐呭閫氱煡
  LIVE_START = 'live_start',
  LIVE_END = 'live_end',
  VIDEO_UPDATED = 'video_updated',
  SERIES_NEW_EPISODE = 'series_new_episode',
  RECOMMENDATION = 'recommendation',
  
  // 绀句氦閫氱煡
  FOLLOWED_CHANNEL_LIVE = 'followed_channel_live',
  COMMENT_REPLY = 'comment_reply',
  MENTIONED = 'mentioned',
  LIKE = 'like',
  SHARE = 'share',
  
  // 绯荤粺閫氱煡
  SYSTEM_ANNOUNCEMENT = 'system_announcement',
  MAINTENANCE_ALERT = 'maintenance_alert',
  FEATURE_UPDATE = 'feature_update',
  
  // 鐢ㄦ埛鐩稿叧閫氱煡
  ACCOUNT_VERIFICATION = 'account_verification',
  PASSWORD_CHANGE = 'password_change',
  LOGIN_ACTIVITY = 'login_activity',
  SUBSCRIPTION_REMINDER = 'subscription_reminder',
  SUBSCRIPTION_EXPIRY = 'subscription_expiry',
  PAYMENT_SUCCESS = 'payment_success',
  PAYMENT_FAILED = 'payment_failed',
  
  // 浜掑姩閫氱煡
  DOWNLOAD_COMPLETE = 'download_complete',
  DOWNLOAD_FAILED = 'download_failed',
  PLAYBACK_ERROR = 'playback_error',
  WATCHLIST_ADD = 'watchlist_add',
  WATCHLIST_REMOVE = 'watchlist_remove',
  
  // 瀹氬埗閫氱煡
  CUSTOM = 'custom',
  UNKNOWN = 'unknown'
}

/**
 * 閫氱煡浼樺厛绾ф灇涓? */
export enum NotificationPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  URGENT = 'urgent'
}

/**
 * 閫氱煡鐘舵€佹灇涓? */
export enum NotificationStatus {
  NEW = 'new',
  READ = 'read',
  DISMISSED = 'dismissed',
  ARCHIVED = 'archived'
}

/**
 * 閫氱煡鍐呭鎺ュ彛
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
 * 閫氱煡鍏冩暟鎹帴鍙? */
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
 * 閫氱煡鎺ュ彛
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
 * 閫氱煡閰嶇疆鎺ュ彛
 */
export interface NotificationConfig {
  // 閫氱敤璁剧疆
  enableNotifications: boolean;
  enableSound: boolean;
  enableVibration: boolean;
  enableLight: boolean;
  
  // 绫诲瀷璁剧疆
  enabledTypes: NotificationType[];
  mutedTypes: NotificationType[];
  
  // 鏃堕棿娈佃缃?  enableDoNotDisturb: boolean;
  doNotDisturbStart: string; // HH:MM
  doNotDisturbEnd: string; // HH:MM
  
  // 浼樺厛绾ц缃?  minPriority: NotificationPriority;
  
  // 楂樼骇璁剧疆
  enableBadgeCount: boolean;
  maxStoredNotifications: number;
  notificationHistoryDays: number;
  
  // 棰戦亾/鐢ㄦ埛鐗瑰畾璁剧疆
  subscribedChannels: string[];
  mutedChannels: string[];
  
  // 绯荤粺閫氱煡璁剧疆
  enableSystemNotifications: boolean;
  enableMaintenanceAlerts: boolean;
  enableFeatureUpdates: boolean;
  
  // 绀句氦閫氱煡璁剧疆
  enableSocialNotifications: boolean;
  enableCommentReplies: boolean;
  enableMentions: boolean;
  enableLikes: boolean;
  enableShares: boolean;
  
  // 鍐呭閫氱煡璁剧疆
  enableLiveNotifications: boolean;
  enableVideoUpdateNotifications: boolean;
  enableRecommendationNotifications: boolean;
  
  // 鐢ㄦ埛閫氱煡璁剧疆
  enableAccountNotifications: boolean;
  enablePaymentNotifications: boolean;
  enableSubscriptionNotifications: boolean;
  
  // 浜掑姩閫氱煡璁剧疆
  enableDownloadNotifications: boolean;
  enableErrorNotifications: boolean;
}

/**
 * 閫氱煡浜嬩欢绫诲瀷
 */
export const NotificationEventType = {
  // 閫氱煡鐢熷懡鍛ㄦ湡浜嬩欢
  RECEIVED: 'notification:received',
  READ: 'notification:read',
  DISMISSED: 'notification:dismissed',
  ARCHIVED: 'notification:archived',
  RESTORED: 'notification:restored',
  
  // 鐘舵€佸彉鏇翠簨浠?  STATUS_CHANGED: 'notification:statusChanged',
  BADGE_COUNT_CHANGED: 'notification:badgeCountChanged',
  
  // 閰嶇疆浜嬩欢
  CONFIG_CHANGED: 'notification:configChanged',
  DO_NOT_DISTURB_TOGGLED: 'notification:doNotDisturbToggled',
  
  // 缁勪簨浠?  GROUP_CREATED: 'notification:groupCreated',
  GROUP_UPDATED: 'notification:groupUpdated',
  
  // 鎵归噺浜嬩欢
  BATCH_MARKED_READ: 'notification:batchMarkedRead',
  BATCH_DISMISSED: 'notification:batchDismissed',
  BATCH_ARCHIVED: 'notification:batchArchived',
  CLEARED_ALL: 'notification:clearedAll',
  
  // 杩囨护浜嬩欢
  FILTER_APPLIED: 'notification:filterApplied',
  
  // 缁熻浜嬩欢
  STATS_UPDATED: 'notification:statsUpdated'
} as const;

/**
 * 閫氱煡浜嬩欢鏁版嵁
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
 * 閫氱煡杩囨护鍣ㄦ帴鍙? */
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
 * 閫氱煡缁熻鎺ュ彛
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
 * 閫氱煡缁勬帴鍙? */
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
 * 閫氱煡浠撳簱绫? */
export class NotificationRepository {
  private static instance: NotificationRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  
  // 瀛樺偍閿厤缃?  private storageKeys = {
    notifications: 'notification:notifications',
    config: 'notification:config',
    stats: 'notification:stats',
    groups: 'notification:groups',
    badgeCount: 'notification:badgeCount'
  };
  
  // 缂撳瓨閿厤缃?  private cacheKeys = {
    notifications: 'notification:notifications',
    config: 'notification:config',
    stats: 'notification:stats',
    groups: 'notification:groups'
  };
  
  // 榛樿閰嶇疆
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
  
  // 鍐呴儴鐘舵€?  private notifications: Map<string, Notification> = new Map();
  private groups: Map<string, NotificationGroup> = new Map();
  private config: NotificationConfig = this.defaultConfig;
  private stats: NotificationStats = this.createDefaultStats();
  private badgeCount: number = 0;
  private isInitialized: boolean = false;
  
  /**
   * 绉佹湁鏋勯€犲嚱鏁?   */
  private constructor() {
    // 鍒濆鍖栦簨浠剁洃鍚櫒
    this.setupEventListeners();
  }
  
  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  public static getInstance(): NotificationRepository {
    if (!NotificationRepository.instance) {
      NotificationRepository.instance = new NotificationRepository();
    }
    return NotificationRepository.instance;
  }
  
  /**
   * 鍒濆鍖栦粨搴?   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    
    try {
      // 鍔犺浇閰嶇疆
      await this.loadConfig();
      
      // 鍔犺浇閫氱煡鏁版嵁
      await this.loadNotifications();
      
      // 鍔犺浇缁熻淇℃伅
      await this.loadStats();
      
      // 鍔犺浇鍒嗙粍淇℃伅
      await this.loadGroups();
      
      // 鍔犺浇寰界珷璁℃暟
      await this.loadBadgeCount();
      
      this.isInitialized = true;
      this.logger.info('NotificationRepository initialized successfully');
    } catch (error) {
      this.Logger.error('Failed to initialize NotificationRepository:', error);
      throw error;
    }
  }
  
  /**
   * 璁剧疆浜嬩欢鐩戝惉鍣?   */
  private setupEventListeners(): void {
    // 鐩戝惉搴旂敤鐢熷懡鍛ㄦ湡浜嬩欢
    this.eventBus.on('app:foreground', ( instanceof Error ? ( : new Error(String(( instanceof Error ? ( instanceof Error ? ( : new Error(String(( : new Error(String(( instanceof Error ? ( : new Error(String(( instanceof Error ? ( instanceof Error ? ( : new Error(String(( instanceof Error ? ( instanceof Error ? ( : new Error(String(( : new Error(String(( instanceof Error ? ( : new Error(String(( : new Error(String(( instanceof Error ? ( : new Error(String(( instanceof Error ? ( instanceof Error ? ( : new Error(String(( : new Error(String(( instanceof Error ? ( : new Error(String(())))))) => {
      this.handleAppForeground();
    });
    
    this.eventBus.on('app:background', () => {
      this.handleAppBackground();
    });
    
    // 鐩戝惉缃戠粶鐘舵€佸彉鍖?    this.eventBus.on('network:online', () => {
      this.handleNetworkOnline();
    });
    
    this.eventBus.on('network:offline', () => {
      this.handleNetworkOffline();
    });
    
    // 鐩戝惉瀛樺偍鍙樺寲
    this.eventBus.on('storage:changed', (event) => {
      this.handleStorageChanged(event);
    });
  }
  
  /**
   * 鍒涘缓榛樿缁熻淇℃伅
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
   * 鍔犺浇閰嶇疆
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
      
      // 缂撳瓨閰嶇疆
      await this.cacheService.set(
        this.cacheKeys.config,
        this.config,
        CacheType.PERSISTENT,
        3600 // 1灏忔椂
      );
    } catch (error) {
      this.Logger.error('Failed to load notification config:', error);
      this.config = this.defaultConfig;
    }
  }
  
  /**
   * 淇濆瓨閰嶇疆
   */
  private async saveConfig(): Promise<void> {
    try {
      await this.storageUtil.set(
        this.storageKeys.config, this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.config,
        LocalStorageType.PERSISTENT
       : new Error(String(this.config,
        LocalStorageType.PERSISTENT
      )))))));
      
      // 鏇存柊缂撳瓨
      await this.cacheService.set(
        this.cacheKeys.config,
        this.config,
        CacheType.PERSISTENT,
        3600
      );
      
      // 鍙戝竷閰嶇疆鍙樻洿浜嬩欢
      this.eventBus.emit(NotificationEventType.CONFIG_CHANGED, {
        type: NotificationEventType.CONFIG_CHANGED,
        timestamp: Date.now(),
        config: this.config
      });
    } catch (error) {
      this.Logger.error('Failed to save notification config:', error);
    }
  }
  
  /**
   * 鍔犺浇閫氱煡鏁版嵁
   */
  private async loadNotifications(): Promise<void> {
    try {
      const notifications = await this.storageUtil.get<Notification[]>(
        this.storageKeys.notifications, LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
      )))))));
      
      if (notifications) {
        this.notifications.clear();
        notifications.forEach(notification => {
          this.notifications.set(notification.id, notification);
        });
      }
      
      // 缂撳瓨閫氱煡鏁版嵁
      await this.cacheService.set(
        this.cacheKeys.notifications,
        Array.from(this.notifications.values()),
        CacheType.PERSISTENT,
        300 // 5鍒嗛挓
      );
    } catch (error) {
      this.Logger.error('Failed to load notifications:', error);
      this.notifications.clear();
    }
  }
  
  /**
   * 淇濆瓨閫氱煡鏁版嵁
   */
  private async saveNotifications(): Promise<void> {
    try {
      const notifications = Array.from(this.notifications.values());
      
      await this.storageUtil.set(
        this.storageKeys.notifications, notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
       instanceof Error ? notifications,
        LocalStorageType.PERSISTENT
       : new Error(String(notifications,
        LocalStorageType.PERSISTENT
      )))))));
      
      // 鏇存柊缂撳瓨
      await this.cacheService.set(
        this.cacheKeys.notifications,
        notifications,
        CacheType.PERSISTENT,
        300
      );
    } catch (error) {
      this.Logger.error('Failed to save notifications:', error);
    }
  }
  
  /**
   * 鍔犺浇缁熻淇℃伅
   */
  private async loadStats(): Promise<void> {
    try {
      const stats = await this.storageUtil.get<NotificationStats>(
        this.storageKeys.stats, LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
      )))))));
      
      if (stats) {
        this.stats = stats;
      } else {
        this.stats = this.createDefaultStats();
        await this.saveStats();
      }
      
      // 缂撳瓨缁熻淇℃伅
      await this.cacheService.set(
        this.cacheKeys.stats,
        this.stats,
        CacheType.PERSISTENT,
        600 // 10鍒嗛挓
      );
    } catch (error) {
      this.Logger.error('Failed to load notification stats:', error);
      this.stats = this.createDefaultStats();
    }
  }
  
  /**
   * 淇濆瓨缁熻淇℃伅
   */
  private async saveStats(): Promise<void> {
    try {
      await this.storageUtil.set(
        this.storageKeys.stats, this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.stats,
        LocalStorageType.PERSISTENT
       : new Error(String(this.stats,
        LocalStorageType.PERSISTENT
      )))))));
      
      // 鏇存柊缂撳瓨
      await this.cacheService.set(
        this.cacheKeys.stats,
        this.stats,
        CacheType.PERSISTENT,
        600
      );
      
      // 鍙戝竷缁熻鏇存柊浜嬩欢
      this.eventBus.emit(NotificationEventType.STATS_UPDATED, {
        type: NotificationEventType.STATS_UPDATED,
        timestamp: Date.now(),
        stats: this.stats
      });
    } catch (error) {
      this.Logger.error('Failed to save notification stats:', error);
    }
  }
  
  /**
   * 鍔犺浇鍒嗙粍淇℃伅
   */
  private async loadGroups(): Promise<void> {
    try {
      const groups = await this.storageUtil.get<NotificationGroup[]>(
        this.storageKeys.groups, LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
      )))))));
      
      if (groups) {
        this.groups.clear();
        groups.forEach(group => {
          this.groups.set(group.id, group);
        });
      }
      
      // 缂撳瓨鍒嗙粍淇℃伅
      await this.cacheService.set(
        this.cacheKeys.groups,
        Array.from(this.groups.values()),
        CacheType.PERSISTENT,
        300
      );
    } catch (error) {
      this.Logger.error('Failed to load notification groups:', error);
      this.groups.clear();
    }
  }
  
  /**
   * 淇濆瓨鍒嗙粍淇℃伅
   */
  private async saveGroups(): Promise<void> {
    try {
      const groups = Array.from(this.groups.values());
      
      await this.storageUtil.set(
        this.storageKeys.groups, groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
       instanceof Error ? groups,
        LocalStorageType.PERSISTENT
       : new Error(String(groups,
        LocalStorageType.PERSISTENT
      )))))));
      
      // 鏇存柊缂撳瓨
      await this.cacheService.set(
        this.cacheKeys.groups,
        groups,
        CacheType.PERSISTENT,
        300
      );
    } catch (error) {
      this.Logger.error('Failed to save notification groups:', error);
    }
  }
  
  /**
   * 鍔犺浇寰界珷璁℃暟
   */
  private async loadBadgeCount(): Promise<void> {
    try {
      const badgeCount = await this.storageUtil.get<number>(
        this.storageKeys.badgeCount, LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
       instanceof Error ? LocalStorageType.PERSISTENT
       : new Error(String(LocalStorageType.PERSISTENT
      )))))));
      
      if (badgeCount !== undefined) {
        this.badgeCount = badgeCount;
      }
    } catch (error) {
      this.Logger.error('Failed to load badge count:', error);
      this.badgeCount = 0;
    }
  }
  
  /**
   * 淇濆瓨寰界珷璁℃暟
   */
  private async saveBadgeCount(): Promise<void> {
    try {
      await this.storageUtil.set(
        this.storageKeys.badgeCount, this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
       instanceof Error ? this.badgeCount,
        LocalStorageType.PERSISTENT
       : new Error(String(this.badgeCount,
        LocalStorageType.PERSISTENT
      )))))));
      
      // 鍙戝竷寰界珷璁℃暟鍙樻洿浜嬩欢
      this.eventBus.emit(NotificationEventType.BADGE_COUNT_CHANGED, {
        type: NotificationEventType.BADGE_COUNT_CHANGED,
        timestamp: Date.now(),
        badgeCount: this.badgeCount
      });
    } catch (error) {
      this.Logger.error('Failed to save badge count:', error);
    }
  }
  
  /**
   * 澶勭悊搴旂敤杩涘叆鍓嶅彴
   */
  private handleAppForeground(): void {
    this.logger.debug('NotificationRepository: App entered foreground');
    // 鍙互鍦ㄨ繖閲屾墽琛屼竴浜涘墠鍙版搷浣滐紝濡傚埛鏂伴€氱煡绛?  }
  
  /**
   * 澶勭悊搴旂敤杩涘叆鍚庡彴
   */
  private handleAppBackground(): void {
    this.logger.debug('NotificationRepository: App entered background');
    // 鍙互鍦ㄨ繖閲屾墽琛屼竴浜涘悗鍙版搷浣滐紝濡備繚瀛樻暟鎹瓑
    this.saveAllData();
  }
  
  /**
   * 澶勭悊缃戠粶鍦ㄧ嚎
   */
  private handleNetworkOnline(): void {
    this.logger.debug('NotificationRepository: Network online');
    // 鍙互鍦ㄨ繖閲屾墽琛屼竴浜涚綉缁滄仮澶嶅悗鐨勬搷浣?  }
  
  /**
   * 澶勭悊缃戠粶绂荤嚎
   */
  private handleNetworkOffline(): void {
    this.logger.debug('NotificationRepository: Network offline');
    // 鍙互鍦ㄨ繖閲屾墽琛屼竴浜涚綉缁滄柇寮€鍚庣殑鎿嶄綔
  }
  
  /**
   * 澶勭悊瀛樺偍鍙樺寲
   */
  private handleStorageChanged(event: Record<string, string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null>))): void {
    this.logger.debug('NotificationRepository: Storage changed', event instanceof Error ? event : new Error(String(event instanceof Error ? event instanceof Error ? event : new Error(String(event : new Error(String(event instanceof Error ? event : new Error(String(event)))));
    // 鍙互鍦ㄨ繖閲屽鐞嗗瓨鍌ㄥ彉鍖栦簨浠?  }
  
  /**
   * 淇濆瓨鎵€鏈夋暟鎹?   */
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
      this.Logger.error('Failed to save all notification data:', error);
    }
  }
  
  /**
   * 鑾峰彇閫氱煡閰嶇疆
   */
  public getConfig(): NotificationConfig {
    return { ...this.config };
  }
  
  /**
   * 鏇存柊閫氱煡閰嶇疆
   */
  public async updateConfig(updates: Partial<NotificationConfig>): Promise<void> {
    this.config = { ...this.config, ...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig( instanceof Error ? ...updates };
    await this.saveConfig( : new Error(String(...updates };
    await this.saveConfig()))))));
  }
  
  /**
   * 閲嶇疆閫氱煡閰嶇疆涓洪粯璁ゅ€?   */
  public async resetConfig(): Promise<void> {
    this.config = this.defaultConfig;
    await this.saveConfig();
  }
  
  /**
   * 妫€鏌ラ€氱煡绫诲瀷鏄惁鍚敤
   */
  public isTypeEnabled(type: NotificationType): boolean {
    return this.config.enabledTypes.includes(type) && 
           !this.config.mutedTypes.includes(type);
  }
  
  /**
   * 妫€鏌ユ槸鍚﹀湪鍏嶆墦鎵版椂闂存
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
   * 妫€鏌ユ槸鍚﹀彲浠ュ彂閫侀€氱煡
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
   * 鑾峰彇浼樺厛绾х骇鍒?   */
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
   * 娣诲姞閫氱煡
   */
  public async addNotification(notification: Notification): Promise<boolean> {
    if (!this.canSendNotification(notification)) {
      this.logger.debug('Notification blocked by settings:', notification.id);
      return false;
    }
    
    try {
      // 妫€鏌ラ€氱煡鏄惁宸插瓨鍦?      if (this.notifications.has(notification.id)) {
        this.logger.debug('Notification already exists:', notification.id);
        return false;
      }
      
      // 娣诲姞閫氱煡
      this.notifications.set(notification.id, notification);
      
      // 鏇存柊缁熻淇℃伅
      this.updateStatsForNewNotification(notification);
      
      // 鏇存柊寰界珷璁℃暟
      if (notification.status === NotificationStatus.NEW) {
        this.badgeCount++;
        await this.saveBadgeCount();
      }
      
      // 鏇存柊鍒嗙粍
      await this.updateGroupsForNotification(notification);
      
      // 淇濆瓨鏁版嵁
      await this.saveNotifications();
      await this.saveStats();
      
      // 鍙戝竷閫氱煡鎺ユ敹浜嬩欢
      this.eventBus.emit(NotificationEventType.RECEIVED, {
        type: NotificationEventType.RECEIVED,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification added successfully:', notification.id);
      return true;
    } catch (error) {
      this.Logger.error('Failed to add notification:', error);
      return false;
    }
  }
  
  /**
   * 鎵归噺娣诲姞閫氱煡
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
   * 鑾峰彇閫氱煡
   */
  public getNotification(id: string): Notification | undefined {
    return this.notifications.get(id);
  }
  
  /**
   * 鑾峰彇鎵€鏈夐€氱煡
   */
  public getAllNotifications(): Notification[] {
    return Array.from(this.notifications.values());
  }
  
  /**
   * 鑾峰彇杩囨护鍚庣殑閫氱煡
   */
  public getFilteredNotifications(filter: NotificationFilter): Notification[] {
    let notifications = this.getAllNotifications();
    
    // 鎸夌被鍨嬭繃婊?    if (filter.types && filter.types.length > 0) {
      notifications = notifications.filter(n => filter.types!.includes(n.type));
    }
    
    // 鎸夌姸鎬佽繃婊?    if (filter.status && filter.status.length > 0) {
      notifications = notifications.filter(n => filter.status!.includes(n.status));
    }
    
    // 鎸変紭鍏堢骇杩囨护
    if (filter.priorities && filter.priorities.length > 0) {
      notifications = notifications.filter(n => filter.priorities!.includes(n.priority));
    }
    
    // 鎸夋椂闂磋寖鍥磋繃婊?    if (filter.startDate) {
      notifications = notifications.filter(n => n.metadata.timestamp >= filter.startDate!);
    }
    
    if (filter.endDate) {
      notifications = notifications.filter(n => n.metadata.timestamp <= filter.endDate!);
    }
    
    // 鎸夋悳绱㈣瘝杩囨护
    if (filter.searchTerm) {
      const searchTerm = filter.searchTerm.toLowerCase();
      notifications = notifications.filter(n => 
        n.content.title.toLowerCase().includes(searchTerm) ||
        n.content.body.toLowerCase().includes(searchTerm)
      );
    }
    
    // 鎸夌浉鍏冲疄浣撹繃婊?    if (filter.relatedEntityId) {
      notifications = notifications.filter(n => n.metadata.relatedEntityId === filter.relatedEntityId);
    }
    
    if (filter.relatedEntityType) {
      notifications = notifications.filter(n => n.metadata.relatedEntityType === filter.relatedEntityType);
    }
    
    // 鎸夊彂閫佽€呰繃婊?    if (filter.senderId) {
      notifications = notifications.filter(n => n.metadata.senderId === filter.senderId);
    }
    
    // 鎺掑簭锛堟寜鏃堕棿鍊掑簭锛?    notifications.sort((a, b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b))))))) => b.metadata.timestamp - a.metadata.timestamp);
    
    // 鍒嗛〉
    if (filter.limit) {
      const offset = filter.offset || 0;
      notifications = notifications.slice(offset, offset + filter.limit);
    }
    
    return notifications;
  }
  
  /**
   * 鏍囪閫氱煡涓哄凡璇?   */
  public async markAsRead(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      if (notification.status === NotificationStatus.READ) {
        return true; // 宸茬粡鏄凡璇荤姸鎬?      }
      
      // 鏇存柊鐘舵€?      notification.status = NotificationStatus.READ;
      notification.readAt = Date.now();
      
      // 鏇存柊缁熻淇℃伅
      this.updateStatsForStatusChange(notification, NotificationStatus.READ);
      
      // 鏇存柊寰界珷璁℃暟
      if (this.badgeCount > 0) {
        this.badgeCount--;
        await this.saveBadgeCount();
      }
      
      // 淇濆瓨鏁版嵁
      await this.saveNotifications();
      await this.saveStats();
      
      // 鍙戝竷閫氱煡宸茶浜嬩欢
      this.eventBus.emit(NotificationEventType.READ, {
        type: NotificationEventType.READ,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification marked as read:', id);
      return true;
    } catch (error) {
      this.Logger.error('Failed to mark notification as read:', error);
      return false;
    }
  }
  
  /**
   * 鎵归噺鏍囪涓哄凡璇?   */
  public async markAsReadBatch(ids: string[]): Promise<number> {
    let successCount = 0;
    
    for (const id of ids) {
      if (await this.markAsRead(id)) {
        successCount++;
      }
    }
    
    if (successCount > 0) {
      // 鍙戝竷鎵归噺鏍囪宸茶浜嬩欢
      this.eventBus.emit(NotificationEventType.BATCH_MARKED_READ, {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_MARKED_READ,
        timestamp: Date.now())))))),
        notificationIds: ids,
        count: successCount
      });
    }
    
    this.logger.debug(`Marked ${successCount} out of ${ids.length} notifications as read`);
    return successCount;
  }
  
  /**
   * 鏍囪閫氱煡涓哄凡鍏抽棴
   */
  public async dismissNotification(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      if (notification.status === NotificationStatus.DISMISSED) {
        return true; // 宸茬粡鏄凡鍏抽棴鐘舵€?      }
      
      // 鏇存柊鐘舵€?      notification.status = NotificationStatus.DISMISSED;
      notification.dismissedAt = Date.now();
      
      // 鏇存柊缁熻淇℃伅
      this.updateStatsForStatusChange(notification, NotificationStatus.DISMISSED);
      
      // 鏇存柊寰界珷璁℃暟
      if (notification.status === NotificationStatus.NEW && this.badgeCount > 0) {
        this.badgeCount--;
        await this.saveBadgeCount();
      }
      
      // 淇濆瓨鏁版嵁
      await this.saveNotifications();
      await this.saveStats();
      
      // 鍙戝竷閫氱煡鍏抽棴浜嬩欢
      this.eventBus.emit(NotificationEventType.DISMISSED, {
        type: NotificationEventType.DISMISSED,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification dismissed:', id);
      return true;
    } catch (error) {
      this.Logger.error('Failed to dismiss notification:', error);
      return false;
    }
  }
  
  /**
   * 鎵归噺鏍囪涓哄凡鍏抽棴
   */
  public async dismissNotificationsBatch(ids: string[]): Promise<number> {
    let successCount = 0;
    
    for (const id of ids) {
      if (await this.dismissNotification(id)) {
        successCount++;
      }
    }
    
    if (successCount > 0) {
      // 鍙戝竷鎵归噺鍏抽棴浜嬩欢
      this.eventBus.emit(NotificationEventType.BATCH_DISMISSED, {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_DISMISSED,
        timestamp: Date.now())))))),
        notificationIds: ids,
        count: successCount
      });
    }
    
    this.logger.debug(`Dismissed ${successCount} out of ${ids.length} notifications`);
    return successCount;
  }
  
  /**
   * 褰掓。閫氱煡
   */
  public async archiveNotification(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      if (notification.status === NotificationStatus.ARCHIVED) {
        return true; // 宸茬粡鏄綊妗ｇ姸鎬?      }
      
      // 鏇存柊鐘舵€?      notification.status = NotificationStatus.ARCHIVED;
      notification.archivedAt = Date.now();
      
      // 鏇存柊缁熻淇℃伅
      this.updateStatsForStatusChange(notification, NotificationStatus.ARCHIVED);
      
      // 鏇存柊寰界珷璁℃暟
      if (notification.status === NotificationStatus.NEW && this.badgeCount > 0) {
        this.badgeCount--;
        await this.saveBadgeCount();
      }
      
      // 淇濆瓨鏁版嵁
      await this.saveNotifications();
      await this.saveStats();
      
      // 鍙戝竷閫氱煡褰掓。浜嬩欢
      this.eventBus.emit(NotificationEventType.ARCHIVED, {
        type: NotificationEventType.ARCHIVED,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification archived:', id);
      return true;
    } catch (error) {
      this.Logger.error('Failed to archive notification:', error);
      return false;
    }
  }
  
  /**
   * 鎵归噺褰掓。閫氱煡
   */
  public async archiveNotificationsBatch(ids: string[]): Promise<number> {
    let successCount = 0;
    
    for (const id of ids) {
      if (await this.archiveNotification(id)) {
        successCount++;
      }
    }
    
    if (successCount > 0) {
      // 鍙戝竷鎵归噺褰掓。浜嬩欢
      this.eventBus.emit(NotificationEventType.BATCH_ARCHIVED, {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.BATCH_ARCHIVED,
        timestamp: Date.now())))))),
        notificationIds: ids,
        count: successCount
      });
    }
    
    this.logger.debug(`Archived ${successCount} out of ${ids.length} notifications`);
    return successCount;
  }
  
  /**
   * 鎭㈠閫氱煡
   */
  public async restoreNotification(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      if (notification.status === NotificationStatus.NEW) {
        return true; // 宸茬粡鏄柊鐘舵€?      }
      
      // 鎭㈠鐘舵€?      const oldStatus = notification.status;
      notification.status = NotificationStatus.NEW;
      notification.readAt = undefined;
      notification.dismissedAt = undefined;
      notification.archivedAt = undefined;
      
      // 鏇存柊缁熻淇℃伅
      this.updateStatsForStatusChange(notification, oldStatus, NotificationStatus.NEW);
      
      // 鏇存柊寰界珷璁℃暟
      this.badgeCount++;
      await this.saveBadgeCount();
      
      // 淇濆瓨鏁版嵁
      await this.saveNotifications();
      await this.saveStats();
      
      // 鍙戝竷閫氱煡鎭㈠浜嬩欢
      this.eventBus.emit(NotificationEventType.RESTORED, {
        type: NotificationEventType.RESTORED,
        timestamp: Date.now(),
        notification: notification
      });
      
      this.logger.debug('Notification restored:', id);
      return true;
    } catch (error) {
      this.Logger.error('Failed to restore notification:', error);
      return false;
    }
  }
  
  /**
   * 鍒犻櫎閫氱煡
   */
  public async deleteNotification(id: string): Promise<boolean> {
    try {
      const notification = this.notifications.get(id);
      if (!notification) {
        return false;
      }
      
      // 鏇存柊缁熻淇℃伅
      this.updateStatsForDelete(notification);
      
      // 鏇存柊寰界珷璁℃暟
      if (notification.status === NotificationStatus.NEW && this.badgeCount > 0) {
        this.badgeCount--;
        await this.saveBadgeCount();
      }
      
      // 鍒犻櫎閫氱煡
      this.notifications.delete(id);
      
      // 浠庡垎缁勪腑绉婚櫎
      await this.removeNotificationFromGroups(id);
      
      // 淇濆瓨鏁版嵁
      await this.saveNotifications();
      await this.saveStats();
      
      this.logger.debug('Notification deleted:', id instanceof Error ? id : new Error(String(id instanceof Error ? id instanceof Error ? id : new Error(String(id : new Error(String(id instanceof Error ? id : new Error(String(id instanceof Error ? id instanceof Error ? id : new Error(String(id instanceof Error ? id instanceof Error ? id : new Error(String(id : new Error(String(id instanceof Error ? id : new Error(String(id : new Error(String(id instanceof Error ? id : new Error(String(id instanceof Error ? id instanceof Error ? id : new Error(String(id : new Error(String(id instanceof Error ? id : new Error(String(id)))))));
      return true;
    } catch (error) {
      this.Logger.error('Failed to delete notification:', error);
      return false;
    }
  }
  
  /**
   * 鎵归噺鍒犻櫎閫氱煡
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
   * 娓呯┖鎵€鏈夐€氱煡
   */
  public async clearAllNotifications(): Promise<boolean> {
    try {
      const notificationCount = this.notifications.size;
      
      // 娓呯┖鎵€鏈夐€氱煡
      this.notifications.clear();
      
      // 娓呯┖鍒嗙粍
      this.groups.clear();
      
      // 閲嶇疆缁熻淇℃伅
      this.stats = this.createDefaultStats();
      
      // 閲嶇疆寰界珷璁℃暟
      this.badgeCount = 0;
      
      // 淇濆瓨鏁版嵁
      await this.saveNotifications();
      await this.saveGroups();
      await this.saveStats();
      await this.saveBadgeCount();
      
      // 鍙戝竷娓呯┖浜嬩欢
      this.eventBus.emit(NotificationEventType.CLEARED_ALL, {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( instanceof Error ? {
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now( : new Error(String({
        type: NotificationEventType.CLEARED_ALL,
        timestamp: Date.now())))))),
        count: notificationCount
      });
      
      this.logger.debug('All notifications cleared');
      return true;
    } catch (error) {
      this.Logger.error('Failed to clear all notifications:', error);
      return false;
    }
  }
  
  /**
   * 鏇存柊鏂伴€氱煡鐨勭粺璁′俊鎭?   */
  private updateStatsForNewNotification(notification: Notification): void {
    this.stats.totalCount++;
    this.stats.newCount++;
    this.stats.lastReceivedTime = Math.max(this.stats.lastReceivedTime, notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp : new Error(String(notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp : new Error(String(notification.metadata.timestamp : new Error(String(notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp : new Error(String(notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp : new Error(String(notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp : new Error(String(notification.metadata.timestamp : new Error(String(notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp : new Error(String(notification.metadata.timestamp : new Error(String(notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp : new Error(String(notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp : new Error(String(notification.metadata.timestamp : new Error(String(notification.metadata.timestamp instanceof Error ? notification.metadata.timestamp : new Error(String(notification.metadata.timestamp)))))));
    
    // 鎸夌被鍨嬬粺璁?    const typeCount = this.stats.byType.get(notification.type) || 0;
    this.stats.byType.set(notification.type, typeCount + 1);
    
    // 鎸変紭鍏堢骇缁熻
    const priorityCount = this.stats.byPriority.get(notification.priority) || 0;
    this.stats.byPriority.set(notification.priority, priorityCount + 1);
    
    // 鎸夊彂閫佽€呯粺璁?    if (notification.metadata.senderId) {
      const senderCount = this.stats.bySender.get(notification.metadata.senderId) || 0;
      this.stats.bySender.set(notification.metadata.senderId, senderCount + 1);
    }
  }
  
  /**
   * 鏇存柊鐘舵€佸彉鏇寸殑缁熻淇℃伅
   */
  private updateStatsForStatusChange(notification: Notification, newStatus: NotificationStatus): void;
  private updateStatsForStatusChange(notification: Notification, oldStatus: NotificationStatus, newStatus: NotificationStatus): void;
  private updateStatsForStatusChange(notification: Notification, oldStatusOrNewStatus: NotificationStatus, newStatus?: NotificationStatus): void {
    const oldStatus = newStatus ? oldStatusOrNewStatus : notification.status;
    const actualNewStatus = newStatus || oldStatusOrNewStatus;
    
    // 鍑忓皯鏃х姸鎬佺殑璁℃暟
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
    
    // 澧炲姞鏂扮姸鎬佺殑璁℃暟
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
   * 鏇存柊鍒犻櫎閫氱煡鐨勭粺璁′俊鎭?   */
  private updateStatsForDelete(notification: Notification): void {
    this.stats.totalCount--;
    
    // 鍑忓皯鐘舵€佺殑璁℃暟
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
    
    // 鍑忓皯绫诲瀷缁熻
    const typeCount = this.stats.byType.get(notification.type) || 0;
    if (typeCount > 1) {
      this.stats.byType.set(notification.type, typeCount - 1);
    } else {
      this.stats.byType.delete(notification.type);
    }
    
    // 鍑忓皯浼樺厛绾х粺璁?    const priorityCount = this.stats.byPriority.get(notification.priority) || 0;
    if (priorityCount > 1) {
      this.stats.byPriority.set(notification.priority, priorityCount - 1);
    } else {
      this.stats.byPriority.delete(notification.priority);
    }
    
    // 鍑忓皯鍙戦€佽€呯粺璁?    if (notification.metadata.senderId) {
      const senderCount = this.stats.bySender.get(notification.metadata.senderId) || 0;
      if (senderCount > 1) {
        this.stats.bySender.set(notification.metadata.senderId, senderCount - 1);
      } else {
        this.stats.bySender.delete(notification.metadata.senderId);
      }
    }
  }
  
  /**
   * 鏇存柊閫氱煡鐨勫垎缁?   */
  private async updateGroupsForNotification(notification: Notification): Promise<void> {
    // 鏍规嵁閫氱煡绫诲瀷鍜屽彂閫佽€呭垱寤烘垨鏇存柊鍒嗙粍
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
    
    // 鏇存柊鍒嗙粍淇℃伅
    group.notificationIds.push(notification.id);
    group.count++;
    if (notification.status === NotificationStatus.NEW) {
      group.newCount++;
    }
    group.timestamp = Math.max(group.timestamp, notification.metadata.timestamp);
    
    // 淇濆瓨鍒嗙粍淇℃伅
    await this.saveGroups();
    
    // 鍙戝竷鍒嗙粍鏇存柊浜嬩欢
    this.eventBus.emit(NotificationEventType.GROUP_UPDATED, {
      type: NotificationEventType.GROUP_UPDATED,
      timestamp: Date.now(),
      group: group
    });
  }
  
  /**
   * 浠庡垎缁勪腑绉婚櫎閫氱煡
   */
  private async removeNotificationFromGroups(notificationId: string): Promise<void> {
    for (const [groupId, group] of this.groups.entries()) {
      const index = group.notificationIds.indexOf(notificationId);
      if (index !== -1) {
        group.notificationIds.splice(index, 1);
        group.count--;
        
        // 濡傛灉鍒嗙粍涓虹┖锛屽垹闄ゅ垎缁?        if (group.count === 0) {
          this.groups.delete(groupId);
        } else {
          // 鏇存柊鏂伴€氱煡璁℃暟
          const notification = this.notifications.get(notificationId);
          if (notification && notification.status === NotificationStatus.NEW) {
            group.newCount = Math.max(0, group.newCount - 1);
          }
          
          // 淇濆瓨鍒嗙粍淇℃伅
          await this.saveGroups();
          
          // 鍙戝竷鍒嗙粍鏇存柊浜嬩欢
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
   * 鐢熸垚鍒嗙粍ID
   */
  private generateGroupId(notification: Notification): string {
    return `${notification.type}:${notification.metadata.senderId || 'system'}:${notification.metadata.relatedEntityId || 'general'}`;
  }
  
  /**
   * 鑾峰彇鍒嗙粍鏍囬
   */
  private getGroupTitle(notification: Notification): string {
    switch (notification.type) {
      case NotificationType.LIVE_START:
        return '鐩存挱寮€濮嬮€氱煡';
      case NotificationType.COMMENT_REPLY:
        return '璇勮鍥炲';
      case NotificationType.MENTIONED:
        return '鎻愬強閫氱煡';
      case NotificationType.LIKE:
        return '鐐硅禐閫氱煡';
      case NotificationType.SYSTEM_ANNOUNCEMENT:
        return '绯荤粺鍏憡';
      default:
        return '鍏朵粬閫氱煡';
    }
  }
  
  /**
   * 鑾峰彇鍒嗙粍鎽樿
   */
  private getGroupSummary(notification: Notification): string {
    return `鏈?{notification.metadata.senderName ? notification.metadata.senderName + '鐨? : ''}鏂伴€氱煡`;
  }
  
  /**
   * 鑾峰彇閫氱煡缁熻淇℃伅
   */
  public getStats(): NotificationStats {
    return { ...this.stats };
  }
  
  /**
   * 鑾峰彇寰界珷璁℃暟
   */
  public getBadgeCount(): number {
    return this.badgeCount;
  }
  
  /**
   * 鑾峰彇鎵€鏈夊垎缁?   */
  public getAllGroups(): NotificationGroup[] {
    return Array.from(this.groups.values());
  }
  
  /**
   * 鑾峰彇鍒嗙粍
   */
  public getGroup(id: string): NotificationGroup | undefined {
    return this.groups.get(id);
  }
  
  /**
   * 鑾峰彇鍒嗙粍涓殑閫氱煡
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
   * 娓呯悊杩囨湡閫氱煡
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
      this.Logger.error('Failed to cleanup expired notifications:', error);
      return 0;
    }
  }
  
  /**
   * 娓呯悊鏃ч€氱煡
   */
  public async cleanupOldNotifications(): Promise<number> {
    try {
      const cutoffTime = Date.now() - (this.config.notificationHistoryDays * 24 * 60 * 60 * 1000);
      const oldNotifications: string[] = [];
      
      for (const [id, notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries( instanceof Error ? notification] of this.notifications.entries( : new Error(String(notification] of this.notifications.entries()))))))) {
        if (notification.metadata.timestamp < cutoffTime) {
          oldNotifications.push(id);
        }
      }
      
      const deletedCount = await this.deleteNotificationsBatch(oldNotifications);
      this.logger.debug(`Cleaned up ${deletedCount} old notifications`);
      return deletedCount;
    } catch (error) {
      this.Logger.error('Failed to cleanup old notifications:', error);
      return 0;
    }
  }
  
  /**
   * 妫€鏌ラ€氱煡鏄惁瀛樺湪
   */
  public hasNotification(id: string): boolean {
    return this.notifications.has(id);
  }
  
  /**
   * 鑾峰彇閫氱煡鏁伴噺
   */
  public getNotificationCount(): number {
    return this.notifications.size;
  }
  
  /**
   * 鑾峰彇鏂伴€氱煡鏁伴噺
   */
  public getNewNotificationCount(): number {
    return this.stats.newCount;
  }
  
  /**
   * 鑾峰彇鏈閫氱煡鏁伴噺
   */
  public getUnreadNotificationCount(): number {
    return this.stats.newCount + this.stats.readCount; // 鏂伴€氱煡鍜屽凡璇婚€氱煡閮界畻鏈
  }
  
  /**
   * 搴旂敤閫氱煡杩囨护鍣?   */
  public applyFilter(filter: NotificationFilter): Notification[] {
    const filteredNotifications = this.getFilteredNotifications(filter);
    
    // 鍙戝竷杩囨护搴旂敤浜嬩欢
    this.eventBus.emit(NotificationEventType.FILTER_APPLIED, {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( instanceof Error ? {
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now( : new Error(String({
      type: NotificationEventType.FILTER_APPLIED,
      timestamp: Date.now())))))),
      filter: filter,
      notifications: filteredNotifications
    });
    
    return filteredNotifications;
  }
  
  /**
   * 鍏抽棴浠撳簱
   */
  public async shutdown(): Promise<void> {
    try {
      // 淇濆瓨鎵€鏈夋暟鎹?      await this.saveAllData();
      
      // 娓呯悊缂撳瓨
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





