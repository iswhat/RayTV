/**
 * ConfigConstant - Configuration related constant definitions | 配置相关常量定义
 * Define app configuration related constants, including default configurations, config keys, etc. | 定义应用配置相关的常量，包括默认配置、配置键名等
 */

/**
 * Player configuration type | 播放器配置类型
 */
export interface PlayerConfig {
  defaultPlayer: string;
  enableHardwareDecode: boolean;
  autoContinuePlay: boolean;
  rememberPosition: boolean;
  speedList: number[];
  screenScale: number;
  playMode: number;
  autoHideControls: boolean;
  hideControlsDelay: number;
}

/**
 * Display configuration type | 显示配置类型
 */
export interface DisplayConfig {
  theme: string;
  fontSize: number;
  autoFullScreen: boolean;
  enableGestures: boolean;
  showQualityBadge: boolean;
  enableAnimations: boolean;
}

/**
 * Network configuration type | 网络配置类型
 */
export interface NetworkConfig {
  timeout: number;
  retryCount: number;
  enableCache: boolean;
  cacheSize: number;
  userAgent?: string;
  proxyEnabled: boolean;
  proxyServer?: string;
  proxyPort?: number;
}

/**
 * Security configuration type | 安全配置类型
 */
export interface SecurityConfig {
  enableSandbox: boolean;
  allowThirdParty: boolean;
  enableEncryption: boolean;
  clearCacheOnExit?: boolean;
  privateMode?: boolean;
}

/**
 * Ad block configuration type | 广告拦截配置类型
 */
export interface AdBlockConfig {
  enabled: boolean;
  rules?: string[];
  updateInterval: number;
  lastUpdate?: number;
}

/**
 * HarmonyOS configuration type | 鸿蒙配置类型
 */
export interface HarmonyConfig {
  enableVoiceAssistant: boolean;
  enableDeviceFlow: boolean;
  enableGestureControl: boolean;
  enablePushNotification: boolean;
  smartRemoteEnabled?: boolean;
}

/**
 * Configuration type | 配置类型
 */
export interface ConfigType {
  player?: PlayerConfig;
  display?: DisplayConfig;
  network?: NetworkConfig;
  security?: SecurityConfig;
  adBlock?: AdBlockConfig;
  harmony?: HarmonyConfig;
  version: number;
}

export class ConfigConstant {
  // Configuration group names | 配置分组名称
  public static readonly GROUP_PLAYER: string = 'player'; // Player configuration group | 播放器配置分组
  public static readonly GROUP_DISPLAY: string = 'display'; // Display configuration group | 显示配置分组
  public static readonly GROUP_NETWORK: string = 'network'; // Network configuration group | 网络配置分组
  public static readonly GROUP_SECURITY: string = 'security'; // Security configuration group | 安全配置分组
  public static readonly GROUP_ADBLOCK: string = 'adBlock'; // Ad block configuration group | 广告拦截配置分组
  public static readonly GROUP_HARMONY: string = 'harmony'; // HarmonyOS configuration group | 鸿蒙配置分组

  // Player configuration keys | 播放器配置键名
  public static readonly PLAYER_DEFAULT_PLAYER: string = 'defaultPlayer'; // Default player | 默认播放器
  public static readonly PLAYER_ENABLE_HARDWARE_DECODE: string = 'enableHardwareDecode'; // Enable hardware decode | 启用硬件解码
  public static readonly PLAYER_AUTO_CONTINUE_PLAY: string = 'autoContinuePlay'; // Auto continue play | 自动继续播放
  public static readonly PLAYER_REMEMBER_POSITION: string = 'rememberPosition'; // Remember play position | 记住播放位置
  public static readonly PLAYER_SPEED_LIST: string = 'speedList'; // Playback speed list | 播放速度列表
  public static readonly PLAYER_SCREEN_SCALE: string = 'screenScale'; // Screen scale | 屏幕缩放
  public static readonly PLAYER_PLAY_MODE: string = 'playMode'; // Play mode | 播放模式
  public static readonly PLAYER_AUTO_HIDE_CONTROLS: string = 'autoHideControls'; // Auto hide controls | 自动隐藏控制栏
  public static readonly PLAYER_HIDE_CONTROLS_DELAY: string = 'hideControlsDelay'; // Hide controls delay | 隐藏控制栏延迟

  // Display configuration keys | 显示配置键名
  public static readonly DISPLAY_THEME: string = 'theme'; // Theme | 主题
  public static readonly DISPLAY_FONT_SIZE: string = 'fontSize'; // Font size | 字体大小
  public static readonly DISPLAY_AUTO_FULL_SCREEN: string = 'autoFullScreen'; // Auto full screen | 自动全屏
  public static readonly DISPLAY_ENABLE_GESTURES: string = 'enableGestures'; // Enable gestures | 启用手势
  public static readonly DISPLAY_SHOW_QUALITY_BADGE: string = 'showQualityBadge'; // Show quality badge | 显示画质标识
  public static readonly DISPLAY_ENABLE_ANIMATIONS: string = 'enableAnimations'; // Enable animations | 启用动画

  // Network configuration keys | 网络配置键名
  public static readonly NETWORK_TIMEOUT: string = 'timeout'; // Network timeout | 网络超时
  public static readonly NETWORK_RETRY_COUNT: string = 'retryCount'; // Retry count | 重试次数
  public static readonly NETWORK_ENABLE_CACHE: string = 'enableCache'; // Enable cache | 启用缓存
  public static readonly NETWORK_CACHE_SIZE: string = 'cacheSize'; // Cache size | 缓存大小
  public static readonly NETWORK_USER_AGENT: string = 'userAgent'; // User agent | 用户代理
  public static readonly NETWORK_PROXY_ENABLED: string = 'proxyEnabled'; // Proxy enabled | 启用代理
  public static readonly NETWORK_PROXY_SERVER: string = 'proxyServer'; // Proxy server | 代理服务器
  public static readonly NETWORK_PROXY_PORT: string = 'proxyPort'; // Proxy port | 代理端口

  // Security configuration keys | 安全配置键名
  public static readonly SECURITY_ENABLE_SANDBOX: string = 'enableSandbox'; // Enable sandbox | 启用沙箱
  public static readonly SECURITY_ALLOW_THIRD_PARTY: string = 'allowThirdParty'; // Allow third party | 允许第三方
  public static readonly SECURITY_ENABLE_ENCRYPTION: string = 'enableEncryption'; // Enable encryption | 启用加密
  public static readonly SECURITY_CLEAR_CACHE_ON_EXIT: string = 'clearCacheOnExit'; // Clear cache on exit | 退出时清除缓存
  public static readonly SECURITY_PRIVATE_MODE: string = 'privateMode'; // Private mode | 隐私模式

  // Ad block configuration keys | 广告拦截配置键名
  public static readonly ADBLOCK_ENABLED: string = 'enabled'; // Ad block enabled | 启用广告拦截
  public static readonly ADBLOCK_RULES: string = 'rules'; // Ad block rules | 广告拦截规则
  public static readonly ADBLOCK_UPDATE_INTERVAL: string = 'updateInterval'; // Update interval | 更新间隔
  public static readonly ADBLOCK_LAST_UPDATE: string = 'lastUpdate'; // Last update time | 最后更新时间

  // HarmonyOS specific configuration keys | 鸿蒙特有配置键名
  public static readonly HARMONY_ENABLE_VOICE_ASSISTANT: string = 'enableVoiceAssistant'; // Enable voice assistant | 启用语音助手
  public static readonly HARMONY_ENABLE_DEVICE_FLOW: string = 'enableDeviceFlow'; // Enable device flow | 启用设备流转
  public static readonly HARMONY_ENABLE_GESTURE_CONTROL: string = 'enableGestureControl'; // Enable gesture control | 启用手势控制
  public static readonly HARMONY_ENABLE_PUSH_NOTIFICATION: string = 'enablePushNotification'; // Enable push notification | 启用推送通知
  public static readonly HARMONY_SMART_REMOTE_ENABLED: string = 'smartRemoteEnabled'; // Smart remote enabled | 启用智能遥控

  // Default values | 默认值
  public static readonly DEFAULT_THEME: string = 'dark'; // Default theme | 默认主题
  public static readonly DEFAULT_FONT_SIZE: number = 16; // Default font size | 默认字体大小
  public static readonly DEFAULT_TIMEOUT: number = 30000; // Default timeout | 默认超时
  public static readonly DEFAULT_RETRY_COUNT: number = 3; // Default retry count | 默认重试次数
  public static readonly DEFAULT_CACHE_SIZE: number = 50 * 1024 * 1024; // 50MB | 50兆
  public static readonly DEFAULT_HIDE_CONTROLS_DELAY: number = 3000; // Default hide controls delay | 默认隐藏控制栏延迟

  // Theme options | 主题选项
  public static readonly THEME_LIGHT: string = 'light'; // Light theme | 浅色主题
  public static readonly THEME_DARK: string = 'dark'; // Dark theme | 深色主题
  public static readonly THEME_SYSTEM: string = 'system'; // System theme | 系统主题

  // Player types | 播放器类型
  public static readonly PLAYER_TYPE_NATIVE: string = 'native'; // Native player | 原生播放器
  public static readonly PLAYER_TYPE_EXTERNAL: string = 'external'; // External player | 外部播放器

  // Configuration version | 配置版本
  public static readonly CONFIG_VERSION: number = 1; // Configuration version | 配置版本

  /**
   * Get default configuration object | 获取默认配置对象
   * @returns Default configuration object | 默认配置对象
   */
  public static getDefaultConfig(): ConfigType {
    return {
      [this.GROUP_PLAYER]: {
        [this.PLAYER_DEFAULT_PLAYER]: this.PLAYER_TYPE_NATIVE,
        [this.PLAYER_ENABLE_HARDWARE_DECODE]: true,
        [this.PLAYER_AUTO_CONTINUE_PLAY]: true,
        [this.PLAYER_REMEMBER_POSITION]: true,
        [this.PLAYER_SPEED_LIST]: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        [this.PLAYER_SCREEN_SCALE]: 0,
        [this.PLAYER_PLAY_MODE]: 0,
        [this.PLAYER_AUTO_HIDE_CONTROLS]: true,
        [this.PLAYER_HIDE_CONTROLS_DELAY]: this.DEFAULT_HIDE_CONTROLS_DELAY
      },
      [this.GROUP_DISPLAY]: {
        [this.DISPLAY_THEME]: this.DEFAULT_THEME,
        [this.DISPLAY_FONT_SIZE]: this.DEFAULT_FONT_SIZE,
        [this.DISPLAY_AUTO_FULL_SCREEN]: true,
        [this.DISPLAY_ENABLE_GESTURES]: true,
        [this.DISPLAY_SHOW_QUALITY_BADGE]: true,
        [this.DISPLAY_ENABLE_ANIMATIONS]: true
      },
      [this.GROUP_NETWORK]: {
        [this.NETWORK_TIMEOUT]: this.DEFAULT_TIMEOUT,
        [this.NETWORK_RETRY_COUNT]: this.DEFAULT_RETRY_COUNT,
        [this.NETWORK_ENABLE_CACHE]: true,
        [this.NETWORK_CACHE_SIZE]: this.DEFAULT_CACHE_SIZE,
        [this.NETWORK_PROXY_ENABLED]: false
      },
      [this.GROUP_SECURITY]: {
        [this.SECURITY_ENABLE_SANDBOX]: true,
        [this.SECURITY_ALLOW_THIRD_PARTY]: false,
        [this.SECURITY_ENABLE_ENCRYPTION]: true
      },
      [this.GROUP_ADBLOCK]: {
        [this.ADBLOCK_ENABLED]: true,
        [this.ADBLOCK_RULES]: [],
        [this.ADBLOCK_UPDATE_INTERVAL]: 24
      },
      [this.GROUP_HARMONY]: {
        [this.HARMONY_ENABLE_VOICE_ASSISTANT]: true,
        [this.HARMONY_ENABLE_DEVICE_FLOW]: true,
        [this.HARMONY_ENABLE_GESTURE_CONTROL]: true,
        [this.HARMONY_ENABLE_PUSH_NOTIFICATION]: true
      },
      version: this.CONFIG_VERSION
    };
  }
}
