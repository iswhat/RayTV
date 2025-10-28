// 站点信息数据模型
// 管理爬虫站点配置，包括站点基本信息、请求配置、搜索规则等

/**
 * 站点类型枚举
 */
export enum SiteType {
  JS = 'JS',
  PY = 'PY',
  JAR = 'JAR'
}

/**
 * 站点状态枚举
 */
export enum SiteStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  ERROR = 'ERROR',
  LOADING = 'LOADING'
}

/**
 * 请求配置
 */
export interface RequestConfig {
  timeout: number;             // 超时时间（秒）
  retryCount: number;          // 重试次数
  headers: Record<string, string>; // 请求头
  userAgent: string;           // User-Agent
  referer?: string;            // Referer
  cookies?: string;            // Cookies
}

/**
 * 搜索规则
 */
export interface SearchRule {
  url: string;                 // 搜索URL
  keywordField: string;        // 关键词字段名
  method: string;              // 请求方法
  dataFormat?: string;         // 数据格式
}

/**
 * 详情页规则
 */
export interface DetailRule {
  urlPattern: string;          // URL模式
  titleSelector?: string;      // 标题选择器
  coverSelector?: string;      // 封面选择器
  descSelector?: string;       // 描述选择器
  playListSelector?: string;   // 播放列表选择器
}

/**
 * 播放规则
 */
export interface PlayRule {
  urlPattern: string;          // URL模式
  playUrlExtractor?: string;   // 播放地址提取器
  headers?: Record<string, string>; // 播放请求头
}

/**
 * 站点信息
 */
export interface SiteInfo {
  id: string;                  // 站点唯一标识
  key: string;                 // 站点键名
  name: string;                // 站点名称
  logo?: string;               // 站点Logo
  description?: string;        // 站点描述
  type: SiteType;              // 站点类型
  status: SiteStatus;          // 站点状态
  url: string;                 // 站点URL
  scriptUrl?: string;          // 脚本URL
  jarPath?: string;            // JAR文件路径
  pyPath?: string;             // Python脚本路径
  requestConfig: RequestConfig; // 请求配置
  searchRule: SearchRule;      // 搜索规则
  detailRule: DetailRule;      // 详情页规则
  playRule: PlayRule;          // 播放规则
  categories?: string[];       // 分类列表
  userAgent?: string;          // 用户代理
  referer?: string;            // 引用页
  homepage?: string;           // 首页URL
  supportedFeatures?: string[]; // 支持的特性
  updatedAt: number;           // 更新时间
  lastTestResult?: {
    success: boolean;          // 测试是否成功
    message?: string;          // 测试消息
    timestamp: number;         // 测试时间
  };
  errorCount: number;          // 错误计数
  isFavorite: boolean;         // 是否收藏
}

/**
 * 站点配置集合
 */
export interface SiteCollection {
  sites: SiteInfo[];           // 站点列表
  version: string;             // 版本号
  updatedAt: number;           // 更新时间
}

/**
 * 站点配置验证结果
 */
export interface SiteValidationResult {
  isValid: boolean;            // 是否有效
  errors?: string[];           // 错误列表
  warnings?: string[];         // 警告列表
}