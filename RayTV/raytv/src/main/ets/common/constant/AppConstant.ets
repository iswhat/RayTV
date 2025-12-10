// AppConstant - 应用基本常量定义

/**
 * 应用常量�? * 定义应用级别的常量值，包括版本号、包名、路径等
 */
export class AppConstant {
  // 应用基本信息
  public static readonly APP_NAME: string = 'RayTV';
  public static readonly PACKAGE_NAME: string = 'com.raytv.app';
  public static readonly VERSION_NAME: string = '1.0.0';
  public static readonly VERSION_CODE: number = 100;

  // 存储路径相关
  public static readonly CACHE_DIR: string = 'cache';
  public static readonly DOWNLOAD_DIR: string = 'download';
  public static readonly CONFIG_DIR: string = 'config';
  public static readonly LOG_DIR: string = 'logs';
  public static readonly TEMP_DIR: string = 'temp';
  public static readonly COOKIES_DIR: string = 'cookies';

  // 网络相关
  public static readonly DEFAULT_TIMEOUT: number = 30000; // 30�?  public static readonly MAX_RETRY_COUNT: number = 3;
  public static readonly USER_AGENT: string = `${AppConstant.APP_NAME}/${AppConstant.VERSION_NAME} HarmonyOS/2.0`;
  public static readonly NETWORK_CHECK_URL: string = 'https://www.baidu.com';

  // 数据库相�?  public static readonly DATABASE_NAME: string = 'raytv.db';
  public static readonly DATABASE_VERSION: number = 1;

  // 沙箱相关
  public static readonly SANDBOX_PREFIX: string = 'raytv_sandbox_';

  // 配置文件�?  public static readonly CONFIG_FILE_NAME: string = 'app_config.json';
  public static readonly CUSTOM_CONFIG_FILE_NAME: string = 'custom_config.json';

  // 播放相关
  public static readonly MAX_PLAY_HISTORY: number = 100;
  public static readonly MAX_FAVORITES: number = 500;

  // 安全相关
  public static readonly ENCRYPTION_KEY_LENGTH: number = 256;
  public static readonly SECURE_STORAGE_ALIAS: string = 'raytv_secure';

  // 线程池配�?  public static readonly CORE_POOL_SIZE: number = 2;
  public static readonly MAX_POOL_SIZE: number = 4;
  public static readonly KEEP_ALIVE_TIME: number = 60; // �?
  // 缓存配置
  public static readonly MAX_CACHE_SIZE: number = 50 * 1024 * 1024; // 50MB
  public static readonly CACHE_EXPIRE_TIME: number = 24 * 60 * 60 * 1000; // 24小时

  // 延迟加载相关
  public static readonly ITEM_LOAD_DELAY: number = 50; // ms
  public static readonly LIST_PAGE_SIZE: number = 20;

  // 手势相关
  public static readonly MIN_SWIPE_DISTANCE: number = 50; // px
  public static readonly MIN_SWIPE_VELOCITY: number = 50; // px/s

  // 其他
  public static readonly DEFAULT_FONT_SIZE: number = 16;
  public static readonly ANIMATION_DURATION: number = 300; // ms
  public static readonly THROTTLING_DELAY: number = 200; // ms
}
