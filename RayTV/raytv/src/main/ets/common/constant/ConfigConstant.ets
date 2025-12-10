// ConfigConstant - 配置相关常量定义

/**
 * 配置常量�? * 定义应用配置相关的常量，包括默认配置、配置键名等
 */
export class ConfigConstant {
  // 配置分组键名
  public static readonly GROUP_PLAYER: string = 'player';
  public static readonly GROUP_DISPLAY: string = 'display';
  public static readonly GROUP_NETWORK: string = 'network';
  public static readonly GROUP_SECURITY: string = 'security';
  public static readonly GROUP_ADBLOCK: string = 'adBlock';
  public static readonly GROUP_HARMONY: string = 'harmony';

  // 播放器配置键�?  public static readonly PLAYER_DEFAULT_PLAYER: string = 'defaultPlayer';
  public static readonly PLAYER_ENABLE_HARDWARE_DECODE: string = 'enableHardwareDecode';
  public static readonly PLAYER_AUTO_CONTINUE_PLAY: string = 'autoContinuePlay';
  public static readonly PLAYER_REMEMBER_POSITION: string = 'rememberPosition';
  public static readonly PLAYER_SPEED_LIST: string = 'speedList';
  public static readonly PLAYER_SCREEN_SCALE: string = 'screenScale';
  public static readonly PLAYER_PLAY_MODE: string = 'playMode';
  public static readonly PLAYER_AUTO_HIDE_CONTROLS: string = 'autoHideControls';
  public static readonly PLAYER_HIDE_CONTROLS_DELAY: string = 'hideControlsDelay';

  // 显示配置键名
  public static readonly DISPLAY_THEME: string = 'theme';
  public static readonly DISPLAY_FONT_SIZE: string = 'fontSize';
  public static readonly DISPLAY_AUTO_FULL_SCREEN: string = 'autoFullScreen';
  public static readonly DISPLAY_ENABLE_GESTURES: string = 'enableGestures';
  public static readonly DISPLAY_SHOW_QUALITY_BADGE: string = 'showQualityBadge';
  public static readonly DISPLAY_ENABLE_ANIMATIONS: string = 'enableAnimations';

  // 网络配置键名
  public static readonly NETWORK_TIMEOUT: string = 'timeout';
  public static readonly NETWORK_RETRY_COUNT: string = 'retryCount';
  public static readonly NETWORK_ENABLE_CACHE: string = 'enableCache';
  public static readonly NETWORK_CACHE_SIZE: string = 'cacheSize';
  public static readonly NETWORK_USER_AGENT: string = 'userAgent';
  public static readonly NETWORK_PROXY_ENABLED: string = 'proxyEnabled';
  public static readonly NETWORK_PROXY_SERVER: string = 'proxyServer';
  public static readonly NETWORK_PROXY_PORT: string = 'proxyPort';

  // 安全配置键名
  public static readonly SECURITY_ENABLE_SANDBOX: string = 'enableSandbox';
  public static readonly SECURITY_ALLOW_THIRD_PARTY: string = 'allowThirdParty';
  public static readonly SECURITY_ENABLE_ENCRYPTION: string = 'enableEncryption';
  public static readonly SECURITY_CLEAR_CACHE_ON_EXIT: string = 'clearCacheOnExit';
  public static readonly SECURITY_PRIVATE_MODE: string = 'privateMode';

  // 广告屏蔽配置键名
  public static readonly ADBLOCK_ENABLED: string = 'enabled';
  public static readonly ADBLOCK_RULES: string = 'rules';
  public static readonly ADBLOCK_UPDATE_INTERVAL: string = 'updateInterval';
  public static readonly ADBLOCK_LAST_UPDATE: string = 'lastUpdate';

  // 鸿蒙特有配置键名
  public static readonly HARMONY_ENABLE_VOICE_ASSISTANT: string = 'enableVoiceAssistant';
  public static readonly HARMONY_ENABLE_DEVICE_FLOW: string = 'enableDeviceFlow';
  public static readonly HARMONY_ENABLE_GESTURE_CONTROL: string = 'enableGestureControl';
  public static readonly HARMONY_ENABLE_PUSH_NOTIFICATION: string = 'enablePushNotification';
  public static readonly HARMONY_SMART_REMOTE_ENABLED: string = 'smartRemoteEnabled';

  // 默认�?  public static readonly DEFAULT_THEME: string = 'dark';
  public static readonly DEFAULT_FONT_SIZE: number = 16;
  public static readonly DEFAULT_TIMEOUT: number = 30000;
  public static readonly DEFAULT_RETRY_COUNT: number = 3;
  public static readonly DEFAULT_CACHE_SIZE: number = 50 * 1024 * 1024; // 50MB
  public static readonly DEFAULT_HIDE_CONTROLS_DELAY: number = 3000;

  // 主题选项
  public static readonly THEME_LIGHT: string = 'light';
  public static readonly THEME_DARK: string = 'dark';
  public static readonly THEME_SYSTEM: string = 'system';

  // 播放器类�?  public static readonly PLAYER_TYPE_NATIVE: string = 'native';
  public static readonly PLAYER_TYPE_EXTERNAL: string = 'external';

  // 配置版本
  public static readonly CONFIG_VERSION: number = 1;

  /**
   * 获取默认配置对象
   * @returns 默认配置对象
   */
  public static getDefaultConfig(): Record<string, unknown> {
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
