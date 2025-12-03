// NotificationService.ets - 通知服务
// 基于HarmonyOS通知API实现应用通知管理

import Logger from '../../common/util/Logger';
import ConfigService from '../config/ConfigService';
import media from '@ohos.multimedia.media';
import notificationManager from '@ohos.notificationManager';
import BusinessError from '@ohos.base';

// 常量定义
const TAG = 'NotificationService';
const NOTIFICATION_CHANNEL_ID = 'raytv_default_channel';
const NOTIFICATION_CHANNEL_NAME = 'RayTV通知';
const NOTIFICATION_BUNDLE_NAME = 'com.raytv';

// 通知类型枚举
export enum NotificationType {
  GENERAL = 'general',
  UPDATE = 'update',
  DOWNLOAD = 'download',
  PLAYBACK = 'playback',
  REMINDER = 'reminder',
  ERROR = 'error',
  SYSTEM = 'system',
  CUSTOM = 'custom'
}

// 通知优先级枚�?export enum NotificationPriority {
  LOW = 0,
  DEFAULT = 1,
  HIGH = 2,
  MAXIMUM = 3
}

// 通知级别枚举
export enum NotificationLevel {
  MIN = notificationManager.SupportLevel.MIN,
  LOW = notificationManager.SupportLevel.LOW,
  DEFAULT = notificationManager.SupportLevel.DEFAULT,
  HIGH = notificationManager.SupportLevel.HIGH
}

// 通知操作按钮接口
export interface NotificationAction {
  id: string;              // 操作ID
  title: string;           // 按钮标题
  icon?: number;           // 按钮图标
  actionData?: Record<string, string | number | boolean | null>;        // 操作数据
}

// 通知内容接口
export interface NotificationContent {
  title: string;           // 通知标题
  body: string;            // 通知内容
  subtitle?: string;       // 通知副标�?  icon?: number | string;  // 通知图标
  largeIcon?: number | string; // 大图�?  image?: string;          // 通知图片
  sound?: boolean;         // 是否播放声音
  vibrate?: boolean;       // 是否振动
  badge?: number;          // 角标数字
  actions?: NotificationAction[]; // 操作按钮
  data?: Record<string, string | number | boolean | null>;              // 附加数据
  type?: NotificationType; // 通知类型
  priority?: NotificationPriority; // 优先�?  level?: NotificationLevel; // 通知级别
  autoCancel?: boolean;    // 点击后自动取�?  ongoing?: boolean;       // 是否为持续通知
  timeoutMs?: number;      // 超时时间（毫秒）
  category?: string;       // 通知分类
  visibility?: number;     // 可见�?}

// 进度通知配置接口
export interface ProgressNotificationConfig extends NotificationContent {
  progress: number;        // 进度�?-100�?  maxProgress: number;     // 最大进�?  indeterminate?: boolean; // 是否为不确定进度
  titleFormat?: string;    // 标题格式
  bodyFormat?: string;     // 内容格式
}

// 下载通知配置接口
export interface DownloadNotificationConfig extends ProgressNotificationConfig {
  fileName: string;        // 文件�?  downloadSpeed?: number;  // 下载速度（字�?秒）
  totalSize?: number;      // 总大小（字节�?  remainingTime?: number;  // 剩余时间（秒�?  status?: 'downloading' | 'paused' | 'completed' | 'failed'; // 下载状�?}

// 通知服务配置接口
export interface NotificationServiceConfig {
  enabled: boolean;        // 是否启用通知
  soundEnabled: boolean;   // 是否启用声音
  vibrationEnabled: boolean; // 是否启用振动
  badgeEnabled: boolean;   // 是否启用角标
  headsUpEnabled: boolean; // 是否启用悬浮通知
  reminderEnabled: boolean; // 是否启用提醒
  notificationLevels: Record<NotificationType, NotificationLevel>; // 各类型通知级别
  channelSettings: Record<string, unknown>; // 通知渠道设置
}

// 默认通知服务配置
export const DEFAULT_NOTIFICATION_SERVICE_CONFIG: NotificationServiceConfig = {
  enabled: true,
  soundEnabled: true,
  vibrationEnabled: true,
  badgeEnabled: true,
  headsUpEnabled: true,
  reminderEnabled: true,
  notificationLevels: {
    [NotificationType.GENERAL]: NotificationLevel.DEFAULT,
    [NotificationType.UPDATE]: NotificationLevel.HIGH,
    [NotificationType.DOWNLOAD]: NotificationLevel.DEFAULT,
    [NotificationType.PLAYBACK]: NotificationLevel.DEFAULT,
    [NotificationType.REMINDER]: NotificationLevel.HIGH,
    [NotificationType.ERROR]: NotificationLevel.HIGH,
    [NotificationType.SYSTEM]: NotificationLevel.HIGH,
    [NotificationType.CUSTOM]: NotificationLevel.DEFAULT
  },
  channelSettings: {}
};

// 通知点击回调类型
type NotificationClickCallback = (notificationId: string, actionId?: string, data?: Record<string, string | number | boolean | null>) => void;
  type NotificationActionCallback = (actionId: string, data?: Record<string, string | number | boolean | null>) => void;

export default class NotificationService {
  private static instance: NotificationService;
  private configService: ConfigService;
  private config: NotificationServiceConfig = DEFAULT_NOTIFICATION_SERVICE_CONFIG;
  private notificationIdCounter: number = 0;
  private activeNotifications: Map<string, notificationManager.NotificationRequest> = new Map();
  private clickCallbacks: Map<string, NotificationClickCallback> = new Map();
  private actionCallbacks: Map<string, NotificationActionCallback> = new Map();
  private isInitialized: boolean = false;
  private hasPermission: boolean = false;

  /**
   * 获取单例实例
   */
  public static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  /**
   * 构造函�?   */
  private constructor() {
    this.configService = ConfigService.getInstance();
  }

  /**
   * 初始化通知服务
   * @param context 应用上下�?   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Notification service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing notification service...');

      // 检查通知权限
      await this.checkPermission();
      
      if (!this.hasPermission) {
        Logger.warn(TAG, 'Notification permission not granted');
        return;
      }

      // 加载配置
      await this.loadConfig();
      
      // 创建通知渠道
      await this.createNotificationChannel();
      
      // 注册通知响应回调
      await this.registerNotificationCallback();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Notification service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize notification service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 检查通知权限
   */
  private async checkPermission(): Promise<void> {
    try {
      const hasPerm = await notificationManager.checkPermission();
      this.hasPermission = hasPerm === 0; // 0表示有权�?      
      if (!this.hasPermission) {
        Logger.warn(TAG, 'Notification permission not granted' instanceof Error ? 'Notification permission not granted' : new Error(String('Notification permission not granted' instanceof Error ? 'Notification permission not granted' instanceof Error ? 'Notification permission not granted' : new Error(String('Notification permission not granted' : new Error(String('Notification permission not granted' instanceof Error ? 'Notification permission not granted' : new Error(String('Notification permission not granted' instanceof Error ? 'Notification permission not granted' instanceof Error ? 'Notification permission not granted' : new Error(String('Notification permission not granted' instanceof Error ? 'Notification permission not granted' instanceof Error ? 'Notification permission not granted' : new Error(String('Notification permission not granted' : new Error(String('Notification permission not granted' instanceof Error ? 'Notification permission not granted' : new Error(String('Notification permission not granted' : new Error(String('Notification permission not granted' instanceof Error ? 'Notification permission not granted' : new Error(String('Notification permission not granted' instanceof Error ? 'Notification permission not granted' instanceof Error ? 'Notification permission not granted' : new Error(String('Notification permission not granted' : new Error(String('Notification permission not granted' instanceof Error ? 'Notification permission not granted' : new Error(String('Notification permission not granted')))))));
      }
    } catch (error) {
      Logger.error(TAG, `Failed to check notification permission: ${error}`);
      this.hasPermission = false;
    }
  }

  /**
   * 请求通知权限
   */
  public async requestPermission(): Promise<boolean> {
    try {
      // 请求通知权限
      const result = await notificationManager.requestPermission();
      this.hasPermission = result === 0;
      
      if (this.hasPermission) {
        Logger.info(TAG, 'Notification permission granted' instanceof Error ? 'Notification permission granted' : new Error(String('Notification permission granted' instanceof Error ? 'Notification permission granted' instanceof Error ? 'Notification permission granted' : new Error(String('Notification permission granted' : new Error(String('Notification permission granted' instanceof Error ? 'Notification permission granted' : new Error(String('Notification permission granted' instanceof Error ? 'Notification permission granted' instanceof Error ? 'Notification permission granted' : new Error(String('Notification permission granted' instanceof Error ? 'Notification permission granted' instanceof Error ? 'Notification permission granted' : new Error(String('Notification permission granted' : new Error(String('Notification permission granted' instanceof Error ? 'Notification permission granted' : new Error(String('Notification permission granted' : new Error(String('Notification permission granted' instanceof Error ? 'Notification permission granted' : new Error(String('Notification permission granted' instanceof Error ? 'Notification permission granted' instanceof Error ? 'Notification permission granted' : new Error(String('Notification permission granted' : new Error(String('Notification permission granted' instanceof Error ? 'Notification permission granted' : new Error(String('Notification permission granted')))))));
        if (!this.isInitialized) {
          // 如果初始化失败是因为权限问题，现在重新初始化
          await this.createNotificationChannel();
          await this.registerNotificationCallback();
          this.isInitialized = true;
        }
      }
      
      return this.hasPermission;
    } catch (error) {
      Logger.error(TAG, `Failed to request notification permission: ${error}`);
      return false;
    }
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('notificationServiceConfig', DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG instanceof Error ? DEFAULT_NOTIFICATION_SERVICE_CONFIG : new Error(String(DEFAULT_NOTIFICATION_SERVICE_CONFIG)))))));
      if (savedConfig) {
        this.config = { ...DEFAULT_NOTIFICATION_SERVICE_CONFIG, ...savedConfig };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load notification service config: ${error}`);
    }
  }

  /**
   * 保存配置
   */
  public async saveConfig(config: Partial<NotificationServiceConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('notificationServiceConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('notificationServiceConfig', this.config)))))));
      
      // 如果禁用了通知，取消所有活跃通知
      if (!this.config.enabled) {
        await this.cancelAll();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save notification service config: ${error}`);
      throw error;
    }
  }

  /**
   * 获取配置
   */
  public getConfig(): NotificationServiceConfig {
    return { ...this.config };
  }

  /**
   * 创建通知渠道
   */
  private async createNotificationChannel(): Promise<void> {
    try {
      const channel: Record<string, string | number | boolean | null> = { ... };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? string | number | boolean | null> = { ... };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(string | number | boolean | null> = { ... };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel instanceof Error ? name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel : new Error(String(name: NOTIFICATION_CHANNEL_NAME,
        description: 'RayTV应用通知渠道',
        importance: notificationManager.Importance.HIGH,
        enableLights: true,
        enableVibration: this.config.vibrationEnabled,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: 0xFF0000,
        bypassDnd: true,
        enableSound: this.config.soundEnabled
      };
      
      await notificationManager.createNotificationChannel(channel)))))));
      Logger.info(TAG, 'Notification channel created');
    } catch (error) {
      Logger.error(TAG, `Failed to create notification channel: ${error}`);
    }
  }

  /**
   * 注册通知响应回调
   */
  private async registerNotificationCallback(): Promise<void> {
    try {
      await notificationManager.on('notificationResponse', (response instanceof Error ? (response : new Error(String((response instanceof Error ? (response instanceof Error ? (response : new Error(String((response : new Error(String((response instanceof Error ? (response : new Error(String((response instanceof Error ? (response instanceof Error ? (response : new Error(String((response instanceof Error ? (response instanceof Error ? (response : new Error(String((response : new Error(String((response instanceof Error ? (response : new Error(String((response : new Error(String((response instanceof Error ? (response : new Error(String((response instanceof Error ? (response instanceof Error ? (response : new Error(String((response : new Error(String((response instanceof Error ? (response : new Error(String((response))))))) => {
        const notificationId = String(response.requestId);
        const actionId = response.actionType === notificationManager.ActionType.BUTTON ? response.actionData?.data?.actionId : undefined;
        
        Logger.debug(TAG, `Notification response: ${notificationId}, action: ${actionId}`);
        
        // 触发点击回调
        const callback = this.clickCallbacks.get(notificationId);
        if (callback) {
          try {
            callback(notificationId, actionId, response.actionData?.data);
          } catch (error) {
            Logger.error(TAG, `Error in notification click callback: ${error}`);
          }
          
          // 如果是自动取消，移除回调
          const notification = this.activeNotifications.get(notificationId);
          if (notification?.autoCancel) {
            this.clickCallbacks.delete(notificationId);
          }
        }
      });
    } catch (error) {
      Logger.error(TAG, `Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}` instanceof Error ? `Failed to register notification callback: ${error}` : new Error(String(`Failed to register notification callback: ${error}`)))))));
    }
  }

  /**
   * 发送普通通知
   */
  public async sendNotification(content: NotificationContent): Promise<string> {
    if (!this.canSendNotification()) {
      Logger.warn(TAG, 'Cannot send notification: service not initialized or disabled');
      return '';
    }

    try {
      // 生成通知ID
      const notificationId = this.generateNotificationId();
      
      // 构建通知内容
      const notificationContent = this.buildNotificationContent(content);
      
      // 创建通知请求
      const notificationRequest: notificationManager.NotificationRequest = {
        id: parseInt(notificationId),
        content: notificationContent,
        deliveryTime: Date.now(),
        autoCancel: content.autoCancel ?? true,
        isOngoing: content.ongoing ?? false,
        channelId: NOTIFICATION_CHANNEL_ID,
        badgeIconStyle: notificationManager.BadgeIconStyle.SMALL,
        level: content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL],
        isUnremovable: content.ongoing ?? false,
        tapDismissed: content.autoCancel ?? true,
        notificationCount: content.badge,
        requestAsync: false
      };
      
      // 添加操作按钮
      if (content.actions && content.actions.length > 0) {
        notificationContent.buttons = content.actions.map(action => ({
          title: action.title,
          actionData: {
            data: {
              actionId: action.id,
              ...action.actionData
            }
          },
          type: notificationManager.ButtonType. COMMON_BUTTON
        }));
      }
      
      // 发送通知
      await notificationManager.publish(notificationRequest);
      
      // 保存活跃通知
      this.activeNotifications.set(notificationId, notificationRequest);
      
      Logger.info(TAG, `Notification sent: ${notificationId}`);
      return notificationId;
    } catch (error) {
      Logger.error(TAG, `Failed to send notification: ${error}`);
      return '';
    }
  }

  /**
   * 构建通知内容
   */
  private buildNotificationContent(content: NotificationContent): notificationManager.NotificationContent {
    const notificationContent: notificationManager.NotificationContent = {
      contentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image instanceof Error ? normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image : new Error(String(normal: {
        title: content.title,
        text: content.body,
        additionalText: content.subtitle
      }
    };
    
    // 设置通知级别
    notificationContent.level = content.level ?? this.config.notificationLevels[content.type || NotificationType.GENERAL];
    
    // 如果有图片，使用多行文本类型
    if (content.image))))))) {
      notificationContent.contentType = notificationManager.ContentType.NOTIFICATION_CONTENT_LONG_TEXT;
      notificationContent.longText = {
        title: content.title,
        text: content.body,
        briefText: content.subtitle || content.body,
        expandedTitle: content.title,
        expandedText: content.body,
        bigPicture: {
          uri: content.image,
          sourceType: 1 // 网络图片
        }
      };
    }
    
    return notificationContent;
  }

  /**
   * 发送进度通知
   */
  public async sendProgressNotification(config: ProgressNotificationConfig): Promise<string> {
    if (!this.canSendNotification()) {
      return '';
    }

    try {
      const notificationId = this.generateNotificationId();
      
      // 构建进度通知内容
      const progressBar = {
        progress: config.progress,
        maxProgress: config.maxProgress,
        indeterminate: config.indeterminate ?? false,
        progressText: `${config.progress}%`
      };
      
      const content: notificationManager.NotificationContent = {
        contentType: notificationManager.ContentType.NOTIFICATION_CONTENT_PROGRESS_BAR,
        progressBar: {
          title: this.formatProgressText(config.titleFormat || config.title, config),
          text: this.formatProgressText(config.bodyFormat || config.body, config),
          progress: progressBar.progress,
          maxProgress: progressBar.maxProgress,
          indeterminate: progressBar.indeterminate
        }
      };
      
      const notificationRequest: notificationManager.NotificationRequest = {
        id: parseInt(notificationId),
        content,
        deliveryTime: Date.now(),
        autoCancel: config.autoCancel ?? false,
        isOngoing: config.ongoing ?? true,
        channelId: NOTIFICATION_CHANNEL_ID,
        badgeIconStyle: notificationManager.BadgeIconStyle.SMALL,
        level: config.level ?? this.config.notificationLevels[NotificationType.DOWNLOAD]
      };
      
      await notificationManager.publish(notificationRequest);
      this.activeNotifications.set(notificationId, notificationRequest);
      
      Logger.info(TAG, `Progress notification sent: ${notificationId}`);
      return notificationId;
    } catch (error) {
      Logger.error(TAG, `Failed to send progress notification: ${error}`);
      return '';
    }
  }

  /**
   * 发送下载通知
   */
  public async sendDownloadNotification(config: DownloadNotificationConfig): Promise<string> {
    if (!this.canSendNotification()) {
      return '';
    }

    try {
      // 默认标题和内容格�?      const defaultTitleFormat = '正在下载: {{fileName}}';
      const defaultBodyFormat = '{{statusText}} - {{progress}}% ({{speed}})';
      
      // 状态文本映�?      const statusTextMap: Record<string, string | number | boolean | null> = { ... };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? string | number | boolean | null> = { ... };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String(string | number | boolean | null> = { ... };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number instanceof Error ? 'paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number : new Error(String('paused': '已暂�?,
        'completed': '下载完成',
        'failed': '下载失败'
      };
      
      // 格式化速度
      const formatSpeed = (speed: number))))))): string => {
        if (speed < 1024) return `${speed} B/s`;
        if (speed < 1024 * 1024) return `${(speed / 1024).toFixed(1)} KB/s`;
        return `${(speed / (1024 * 1024)).toFixed(1)} MB/s`;
      };
      
      // 扩展配置
      const extendedConfig: Record<string, string | number | boolean | null> = { ... };
      
      // 如果下载完成，转为普通通知
      if (config.status === 'completed' || config.status === 'failed') {
        const notificationContent: NotificationContent = {
          title: this.formatProgressText(extendedConfig.titleFormat, extendedConfig),
          body: this.formatProgressText(extendedConfig.bodyFormat, extendedConfig),
          type: NotificationType.DOWNLOAD,
          autoCancel: config.autoCancel ?? true,
          ongoing: false,
          level: config.level
        };
        
        // 添加操作按钮
        if (config.status === 'completed') {
          notificationContent.actions = [
            {
              id: 'open_file',
              title: '打开文件',
              actionData: { fileName: config.fileName }
            }
          ];
        }
        
        return this.sendNotification(notificationContent);
      }
      
      // 否则发送进度通知
      return this.sendProgressNotification(extendedConfig);
    } catch (error) {
      Logger.error(TAG, `Failed to send download notification: ${error}`);
      return '';
    }
  }

  /**
   * 格式化进度文�?   */
  private formatProgressText(format: string, config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null> instanceof Error ? config: Record<string, string | number | boolean | null> : new Error(String(config: Record<string, string | number | boolean | null>))))))): string {
    return format
      .replace('{{fileName}}', config.fileName || '')
      .replace('{{progress}}', config.progress || 0)
      .replace('{{statusText}}', config.statusText || '')
      .replace('{{speed}}', config.speed || '');
  }

  /**
   * 更新通知
   */
  public async updateNotification(notificationId: string, content: NotificationContent): Promise<boolean> {
    try {
      // 先取消旧通知
      await this.cancelNotification(notificationId);
      
      // 发送新通知，保持回�?      const callback = this.clickCallbacks.get(notificationId);
      const newId = await this.sendNotification(content);
      
      if (newId && callback) {
        this.clickCallbacks.set(newId, callback);
        this.clickCallbacks.delete(notificationId);
      }
      
      return !!newId;
    } catch (error) {
      Logger.error(TAG, `Failed to update notification ${notificationId}: ${error}`);
      return false;
    }
  }

  /**
   * 更新进度通知
   */
  public async updateProgressNotification(notificationId: string, progress: number, status?: string instanceof Error ? progress: number, status?: string : new Error(String(progress: number, status?: string instanceof Error ? progress: number, status?: string instanceof Error ? progress: number, status?: string : new Error(String(progress: number, status?: string : new Error(String(progress: number, status?: string instanceof Error ? progress: number, status?: string : new Error(String(progress: number, status?: string instanceof Error ? progress: number, status?: string instanceof Error ? progress: number, status?: string : new Error(String(progress: number, status?: string instanceof Error ? progress: number, status?: string instanceof Error ? progress: number, status?: string : new Error(String(progress: number, status?: string : new Error(String(progress: number, status?: string instanceof Error ? progress: number, status?: string : new Error(String(progress: number, status?: string : new Error(String(progress: number, status?: string instanceof Error ? progress: number, status?: string : new Error(String(progress: number, status?: string instanceof Error ? progress: number, status?: string instanceof Error ? progress: number, status?: string : new Error(String(progress: number, status?: string : new Error(String(progress: number, status?: string instanceof Error ? progress: number, status?: string : new Error(String(progress: number, status?: string))))))): Promise<boolean> {
    try {
      const notification = this.activeNotifications.get(notificationId);
      if (!notification || !notification.content.progressBar) {
        return false;
      }
      
      // 更新进度
      notification.content.progressBar.progress = progress;
      
      \n      // 更新通知
      await notificationManager.publish(notification);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to update progress notification ${notificationId}: ${error}`);
      return false;
    }
  }

  /**
   * 取消通知
   */
  public async cancelNotification(notificationId: string): Promise<void> {
    try {
      await notificationManager.cancel(parseInt(notificationId));
      
      // 移除活跃通知和回�?      this.activeNotifications.delete(notificationId);
      this.clickCallbacks.delete(notificationId);
      
      Logger.debug(TAG, `Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}` instanceof Error ? `Notification cancelled: ${notificationId}` : new Error(String(`Notification cancelled: ${notificationId}`)))))));
    } catch (error) {
      Logger.error(TAG, `Failed to cancel notification ${notificationId}: ${error}`);
    }
  }

  /**
   * 取消所有通知
   */
  public async cancelAll(): Promise<void> {
    try {
      await notificationManager.cancelAll();
      
      // 清空所有活跃通知和回�?      this.activeNotifications.clear();
      this.clickCallbacks.clear();
      
      Logger.info(TAG, 'All notifications cancelled' instanceof Error ? 'All notifications cancelled' : new Error(String('All notifications cancelled' instanceof Error ? 'All notifications cancelled' instanceof Error ? 'All notifications cancelled' : new Error(String('All notifications cancelled' : new Error(String('All notifications cancelled' instanceof Error ? 'All notifications cancelled' : new Error(String('All notifications cancelled' instanceof Error ? 'All notifications cancelled' instanceof Error ? 'All notifications cancelled' : new Error(String('All notifications cancelled' instanceof Error ? 'All notifications cancelled' instanceof Error ? 'All notifications cancelled' : new Error(String('All notifications cancelled' : new Error(String('All notifications cancelled' instanceof Error ? 'All notifications cancelled' : new Error(String('All notifications cancelled' : new Error(String('All notifications cancelled' instanceof Error ? 'All notifications cancelled' : new Error(String('All notifications cancelled' instanceof Error ? 'All notifications cancelled' instanceof Error ? 'All notifications cancelled' : new Error(String('All notifications cancelled' : new Error(String('All notifications cancelled' instanceof Error ? 'All notifications cancelled' : new Error(String('All notifications cancelled')))))));
    } catch (error) {
      Logger.error(TAG, `Failed to cancel all notifications: ${error}`);
    }
  }

  /**
   * 设置通知点击回调
   */
  public setNotificationClickCallback(notificationId: string, callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback instanceof Error ? callback: NotificationClickCallback : new Error(String(callback: NotificationClickCallback))))))): void {
    this.clickCallbacks.set(notificationId, callback);
  }

  /**
   * 移除通知点击回调
   */
  public removeNotificationClickCallback(notificationId: string): void {
    this.clickCallbacks.delete(notificationId);
  }

  /**
   * 生成通知ID
   */
  private generateNotificationId(): string {
    this.notificationIdCounter++;
    return `${Date.now()}_${this.notificationIdCounter}`;
  }

  /**
   * 检查是否可以发送通知
   */
  private canSendNotification(): boolean {
    return this.isInitialized && this.config.enabled && this.hasPermission;
  }

  /**
   * 获取活跃通知数量
   */
  public getActiveNotificationCount(): number {
    return this.activeNotifications.size;
  }

  /**
   * 设置应用角标
   */
  public async setBadgeNumber(count: number): Promise<void> {
    if (!this.config.badgeEnabled || !this.hasPermission) {
      return;
    }

    try {
      await notificationManager.setBadgeCount({ badgeCount: count });
      Logger.debug(TAG, `Badge number set to: ${count}`);
    } catch (error) {
      Logger.error(TAG, `Failed to set badge number: ${error}`);
    }
  }

  /**
   * 清除应用角标
   */
  public async clearBadge(): Promise<void> {
    await this.setBadgeNumber(0);
  }

  /**
   * 发送提醒通知
   */
  public async sendReminder(title: string, message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date instanceof Error ? message: string, remindTime?: Date : new Error(String(message: string, remindTime?: Date))))))): Promise<string> {
    const content: NotificationContent = {
      title,
      body: message,
      type: NotificationType.REMINDER,
      priority: NotificationPriority.HIGH,
      level: NotificationLevel.HIGH,
      sound: this.config.soundEnabled,
      vibrate: this.config.vibrationEnabled,
      autoCancel: true
    };
    
    return this.sendNotification(content);
  }

  /**
   * 发送错误通知
   */
  public async sendErrorNotification(title: string, errorMessage: string, autoCancel: boolean = true): Promise<string> {
    const content: NotificationContent = {
      title,
      body: errorMessage,
      type: NotificationType.ERROR,
      priority: NotificationPriority.HIGH,
      level: NotificationLevel.HIGH,
      sound: this.config.soundEnabled,
      vibrate: this.config.vibrationEnabled,
      autoCancel
    };
    
    return this.sendNotification(content);
  }

  /**
   * 发送系统通知
   */
  public async sendSystemNotification(title: string, message: string): Promise<string> {
    const content: NotificationContent = {
      title,
      body: message,
      type: NotificationType.SYSTEM,
      priority: NotificationPriority.HIGH,
      level: NotificationLevel.HIGH,
      sound: this.config.soundEnabled,
      vibrate: this.config.vibrationEnabled,
      autoCancel: true
    };
    
    return this.sendNotification(content);
  }

  /**
   * 关闭通知服务
   */
  public close(): void {
    if (!this.isInitialized) {
      return;
    }

    // 取消所有通知
    this.cancelAll().catch(error => {
      Logger.error(TAG, `Error cancelling notifications on close: ${error}`);
    });

    this.isInitialized = false;
    Logger.info(TAG, 'Notification service closed' instanceof Error ? 'Notification service closed' : new Error(String('Notification service closed' instanceof Error ? 'Notification service closed' instanceof Error ? 'Notification service closed' : new Error(String('Notification service closed' : new Error(String('Notification service closed' instanceof Error ? 'Notification service closed' : new Error(String('Notification service closed' instanceof Error ? 'Notification service closed' instanceof Error ? 'Notification service closed' : new Error(String('Notification service closed' instanceof Error ? 'Notification service closed' instanceof Error ? 'Notification service closed' : new Error(String('Notification service closed' : new Error(String('Notification service closed' instanceof Error ? 'Notification service closed' : new Error(String('Notification service closed' : new Error(String('Notification service closed' instanceof Error ? 'Notification service closed' : new Error(String('Notification service closed' instanceof Error ? 'Notification service closed' instanceof Error ? 'Notification service closed' : new Error(String('Notification service closed' : new Error(String('Notification service closed' instanceof Error ? 'Notification service closed' : new Error(String('Notification service closed')))))));
  }
}


