// 配置信息数据模型
// 管理应用全局配置，包括界面设置、播放设置、网络设置、安全设置等分类配置

/**
 * 广告屏蔽配置
 */
export interface AdBlockConfig {
  enabled: boolean;            // 启用广告屏蔽
  rules: string[];             // 屏蔽规则
  whitelist: string[];         // 白名单
  updateInterval: number;      // 更新间隔（小时）
  blockVideoAds: boolean;      // 屏蔽视频广告
  blockPopupAds: boolean;      // 屏蔽弹窗广告
  lastUpdateTime?: number;     // 最后更新时间
  customFilters?: string[];    // 自定义过滤规则
}

/**
 * 播放器配置
 */
export interface PlayerConfig {
  defaultPlayer: string;       // 默认播放器
  enableHardwareDecode: boolean; // 启用硬件解码
  autoContinuePlay: boolean;   // 自动续播
  rememberPosition: boolean;   // 记住播放位置
  speedList: number[];         // 播放速度列表
}

/**
 * 显示配置
 */
export interface DisplayConfig {
  theme: string;               // 主题
  fontSize: number;            // 字体大小
  autoFullScreen: boolean;     // 自动全屏
  enableGestures: boolean;     // 启用手势
}

/**
 * 网络配置
 */
export interface NetworkConfig {
  timeout: number;             // 超时时间（秒）
  retryCount: number;          // 重试次数
  enableCache: boolean;        // 启用缓存
  cacheSize: number;           // 缓存大小（MB）
}

/**
 * 安全配置
 */
export interface SecurityConfig {
  enableSandbox: boolean;      // 启用沙箱
  allowThirdParty: boolean;    // 允许第三方JAR加载
}

/**
 * 鸿蒙特有配置
 */
export interface HarmonyConfig {
  app: {
    name: string;              // 应用名称
    version: string;           // 应用版本
    debug: boolean;            // 调试模式
  };
  services: {
    autoStart: boolean;        // 自动启动
    backgroundRefresh: boolean; // 后台刷新
    dataSync: boolean;         // 数据同步
  };
  player: {
    defaultEngine: string;     // 默认播放引擎
    autoPlayNext: boolean;     // 自动播放下一集
    rememberPosition: boolean; // 记住播放位置
    subtitles: {
      enabled: boolean;        // 启用字幕
    };
  };
  ui: {
    theme: string;             // 主题
    fontSize: string;          // 字体大小
    layout: string;            // 布局
  };
  security: {
    enableScreenLock: boolean; // 启用屏幕锁定
    allowScreenshots: boolean; // 允许截图
    dataEncryption: boolean;   // 数据加密
  };
  sites?: any[];               // 站点列表
  updateTime: number;          // 更新时间
  enableVoiceAssistant: boolean; // 启用语音助手
  enableDeviceFlow: boolean;    // 启用设备流转
  enableGestureControl: boolean; // 启用手势控制
}

/**
 * 应用配置
 */
export interface AppConfig {
  player: PlayerConfig;        // 播放器配置
  display: DisplayConfig;      // 显示配置
  network: NetworkConfig;      // 网络配置
  security: SecurityConfig;    // 安全配置
  adBlock: AdBlockConfig;      // 广告屏蔽配置
  harmony: HarmonyConfig;      // 鸿蒙特有配置
}