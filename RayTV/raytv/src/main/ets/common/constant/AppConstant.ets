/**
 * AppConstant - App basic constant definitions | 应用基本常量定义
 * Define app-level common values, including version number, package name, paths, etc. | 定义应用级别的常用值，包括版本号、包名、路径等
 */
export class AppConstant {
  // App basic information | 应用基本信息
  public static readonly APP_NAME: string = 'RayTV'; // App name | 应用名称
  public static readonly PACKAGE_NAME: string = 'com.raytv.app'; // Package name | 包名
  public static readonly APP_PACKAGE_NAME: string = 'com.raytv.app'; // Compatible with old code | 兼容旧代码
  public static readonly VERSION_NAME: string = '1.0.0'; // Version name | 版本名称
  public static readonly VERSION_CODE: number = 100; // Version code | 版本代码
  
  // Preferences related | 偏好设置相关
  public static readonly PREFERENCES_NAME: string = 'raytv_preferences'; // Preferences name | 偏好设置名称

  // Storage path related | 存储路径相关
  public static readonly CACHE_DIR: string = 'cache'; // Cache directory | 缓存目录
  public static readonly DOWNLOAD_DIR: string = 'download'; // Download directory | 下载目录
  public static readonly CONFIG_DIR: string = 'config'; // Configuration directory | 配置目录
  public static readonly LOG_DIR: string = 'logs'; // Log directory | 日志目录
  public static readonly TEMP_DIR: string = 'temp'; // Temporary directory | 临时目录
  public static readonly COOKIES_DIR: string = 'cookies'; // Cookies directory | Cookies目录

  // Network related | 网络相关
  public static readonly DEFAULT_TIMEOUT: number = 30000; // 30 seconds | 30秒
  public static readonly MAX_RETRY_COUNT: number = 3; // Maximum retry count | 最大重试次数
  public static readonly USER_AGENT: string = `${AppConstant.APP_NAME}/${AppConstant.VERSION_NAME} HarmonyOS/2.0`; // User agent | 用户代理
  public static readonly NETWORK_CHECK_URL: string = 'https://www.baidu.com'; // Network check URL | 网络检查URL

  // Database related | 数据库相关
  public static readonly DATABASE_NAME: string = 'raytv.db'; // Database name | 数据库名称
  public static readonly DATABASE_VERSION: number = 1; // Database version | 数据库版本

  // Sandbox related | 沙箱相关
  public static readonly SANDBOX_PREFIX: string = 'raytv_sandbox_'; // Sandbox prefix | 沙箱前缀

  // Configuration files | 配置文件
  public static readonly CONFIG_FILE_NAME: string = 'app_config.json'; // Configuration file name | 配置文件名
  public static readonly CUSTOM_CONFIG_FILE_NAME: string = 'custom_config.json'; // Custom configuration file name | 自定义配置文件名

  // Playback related | 播放相关
  public static readonly MAX_PLAY_HISTORY: number = 100; // Maximum play history | 最大播放历史
  public static readonly MAX_FAVORITES: number = 500; // Maximum favorites | 最大收藏数

  // Security related | 安全相关
  public static readonly ENCRYPTION_KEY_LENGTH: number = 256; // Encryption key length | 加密密钥长度
  public static readonly SECURE_STORAGE_ALIAS: string = 'raytv_secure'; // Secure storage alias | 安全存储别名

  // Thread pool configuration | 线程池配置
  public static readonly CORE_POOL_SIZE: number = 2; // Core pool size | 核心线程池大小
  public static readonly MAX_POOL_SIZE: number = 4; // Maximum pool size | 最大线程池大小
  public static readonly KEEP_ALIVE_TIME: number = 60; // seconds | 秒
  
  // Cache configuration | 缓存配置
  public static readonly MAX_CACHE_SIZE: number = 50 * 1024 * 1024; // 50MB | 50兆
  public static readonly CACHE_EXPIRE_TIME: number = 24 * 60 * 60 * 1000; // 24 hours | 24小时

  // Lazy loading related | 懒加载相关
  public static readonly ITEM_LOAD_DELAY: number = 50; // ms | 毫秒
  public static readonly LIST_PAGE_SIZE: number = 20; // List page size | 列表每页大小

  // Gesture related | 手势相关
  public static readonly MIN_SWIPE_DISTANCE: number = 50; // px | 像素
  public static readonly MIN_SWIPE_VELOCITY: number = 50; // px/s | 像素/秒

  // Others | 其他
  public static readonly DEFAULT_FONT_SIZE: number = 16; // Default font size | 默认字体大小
  public static readonly ANIMATION_DURATION: number = 300; // ms | 毫秒
  public static readonly THROTTLING_DELAY: number = 200; // ms | 毫秒
}
